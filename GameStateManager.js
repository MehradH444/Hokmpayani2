
/**
 * Game State Manager
 * File: GameStateManager.js
 * Description: In-memory table room state management, turn timeouts, player seating, trick evaluation, and match tracking.
 */

const CardEngine = require('./CardEngine');

class GameStateManager {
  constructor() {
    // کلید: roomId | مقدار: شیء کامل وضعیت میز
    this.rooms = new Map();
  }

  /**
   * ساخت یک اتاق جدید بازی حکم ۴ نفره
   */
  createRoom(roomId, roomConfig = {}) {
    const room = {
      id: roomId,
      title: roomConfig.title || 'میز حکم آنلاین',
      entryFee: roomConfig.entryFee || 1000,
      players: [null, null, null, null], // ۴ صندلی: [0: تیم1، 1: تیم2، 2: تیم1، 3: تیم2]
      status: 'waiting', // waiting, hakem_selection, hokm_selection, playing, finished
      hakemIndex: 0,
      hokmSuit: null,
      currentTurnIndex: 0,
      deck: [],
      hands: [[], [], [], []], // کارت‌های دست ۴ بازیکن
      currentTrick: [], // کارت‌های روی میز در دست جاری [{ playerIndex, card }]
      leadSuit: null,
      trickWins: [0, 0, 0, 0], // دست‌های برده‌شده هر بازیکن در این دور
      teamScore: { team1: 0, team2: 0 }, // مجموع دست‌های برده در این راند (تا ۷)
      matchScore: { team1: 0, team2: 0 }, // مجموع امتیازات کل بازی (تا ۷)
      turnTimeout: null,
      turnDuration: 15, // زمان هر نوبت به ثانیه
    };

    this.rooms.set(roomId, room);
    return room;
  }

  /**
   * دریافت اطلاعات یک اتاق
   */
  getRoom(roomId) {
    return this.rooms.get(roomId);
  }

  /**
   * افزودن بازیکن به صندلی خالی میز
   */
  joinPlayer(roomId, user) {
    const room = this.rooms.get(roomId);
    if (!room) return { success: false, message: 'اتاق یافت نشد' };

    const emptySeatIndex = room.players.findIndex((p) => p === null);
    if (emptySeatIndex === -1) {
      return { success: false, message: 'ظرفیت میز تکمیل است' };
    }

    const playerData = {
      id: user._id.toString(),
      username: user.username,
      avatar: user.avatar,
      seatIndex: emptySeatIndex,
      team: emptySeatIndex % 2 === 0 ? 1 : 2, // صندلی ۰ و ۲ تیم ۱ | صندلی ۱ و ۳ تیم ۲
      isReady: true,
      socketId: user.currentSocketId,
    };

    room.players[emptySeatIndex] = playerData;

    // اگر ۴ نفر کامل شدند، بازی شروع می‌شود
    if (room.players.every((p) => p !== null)) {
      room.status = 'hokm_selection';
      this.startNewHand(roomId);
    }

    return { success: true, seatIndex: emptySeatIndex, room };
  }

  /**
   * خروج بازیکن از میز
   */
  leavePlayer(roomId, userId) {
    const room = this.rooms.get(roomId);
    if (!room) return null;

    const seatIndex = room.players.findIndex((p) => p && p.id === userId.toString());
    if (seatIndex !== -1) {
      room.players[seatIndex] = null;
      room.status = 'waiting';
      if (room.turnTimeout) clearTimeout(room.turnTimeout);
    }

    // اگر میز خالی شد، اتاق حذف می‌شود
    if (room.players.every((p) => p === null)) {
      this.rooms.delete(roomId);
      return null;
    }

    return room;
  }

  /**
   * شروع دست جدید (بر زدن و پخش ۵ کارت اول برای تعیین حکم)
   */
  startNewHand(roomId) {
    const room = this.rooms.get(roomId);
    if (!room) return;

    room.deck = CardEngine.shuffleDeck(CardEngine.createDeck());
    room.hands = [[], [], [], []];
    room.currentTrick = [];
    room.leadSuit = null;
    room.hokmSuit = null;

    // پخش ۵ کارت اول به تمام بازیکنان (ابتدا حاکم)
    for (let i = 0; i < 4; i++) {
      room.hands[i] = room.deck.splice(0, 5);
    }

    room.currentTurnIndex = room.hakemIndex;
    room.status = 'hokm_selection';
  }

  /**
   * تعیین خال حکم توسط حاکم و پخش مابقی کارت‌ها (۸ کارت بعدی به هر نفر)
   */
  setHokm(roomId, hokmSuit) {
    const room = this.rooms.get(roomId);
    if (!room || room.status !== 'hokm_selection') return false;

    room.hokmSuit = hokmSuit;
    room.status = 'playing';

    // پخش باقی‌مانده کارت‌ها (۸ کارت به هر نفر در دسته‌های ۴تایی)
    for (let i = 0; i < 4; i++) {
      const remainingCards = room.deck.splice(0, 8);
      room.hands[i] = [...room.hands[i], ...remainingCards];
    }

    return true;
  }

  /**
   * انجام بازی یک کارت توسط بازیکن
   */
  playCard(roomId, seatIndex, cardId) {
    const room = this.rooms.get(roomId);
    if (!room || room.status !== 'playing') return { success: false, message: 'بازی در جریان نیست' };
    if (room.currentTurnIndex !== seatIndex) return { success: false, message: 'نوبت شما نیست' };

    const playerHand = room.hands[seatIndex];
    const cardIndex = playerHand.findIndex((c) => c.id === cardId);
    if (cardIndex === -1) return { success: false, message: 'کارت در دست شما وجود ندارد' };

    const cardToPlay = playerHand[cardIndex];
    const leadCard = room.currentTrick.length > 0 ? room.currentTrick[0].card : null;

    // اعتبارسنجی حرکت با موتور حکم
    const isValid = CardEngine.isValidMove(cardToPlay, playerHand, leadCard);
    if (!isValid) return { success: false, message: 'باید خال زمینه را بازی کنید' };

    // برداشتن کارت از دست بازیکن و گذاشتن روی میز
    playerHand.splice(cardIndex, 1);
    room.currentTrick.push({ seatIndex, card: cardToPlay });

    if (room.currentTrick.length === 1) {
      room.leadSuit = cardToPlay.suit;
    }

    // چرخش نوبت به نفر بعدی
    room.currentTurnIndex = (room.currentTurnIndex + 1) % 4;

    return { success: true, cardPlayed: cardToPlay, isTrickComplete: room.currentTrick.length === 4 };
  }

  /**
   * جمع‌آوری کارت‌های روی میز و تعیین برنده دست
   */
  resolveTrick(roomId) {
    const room = this.rooms.get(roomId);
    if (!room || room.currentTrick.length < 4) return null;

    const winningPlay = CardEngine.determineTrickWinner(room.currentTrick, room.hokmSuit);
    const winnerSeat = winningPlay.seatIndex;
    const winningTeam = winnerSeat % 2 === 0 ? 'team1' : 'team2';

    room.teamScore[winningTeam] += 1;
    room.trickWins[winnerSeat] += 1;
    room.currentTrick = [];
    room.leadSuit = null;
    room.currentTurnIndex = winnerSeat; // برنده دست شروع‌کننده دست بعدی است

    // بررسی رسیدن یکی از تیم‌ها به ۷ دست
    let handEnded = false;
    let endStatus = null;

    if (room.teamScore.team1 === 7 || room.teamScore.team2 === 7) {
      handEnded = true;
      const isTeam1Winner = room.teamScore.team1 === 7;
      const winnerScore = isTeam1Winner ? room.teamScore.team1 : room.teamScore.team2;
      const loserScore = isTeam1Winner ? room.teamScore.team2 : room.teamScore.team1;
      const isHakemTeamWinner = isTeam1Winner ? room.hakemIndex % 2 === 0 : room.hakemIndex % 2 !== 0;

      endStatus = CardEngine.calculateGameEndStatus(winnerScore, loserScore, isHakemTeamWinner);

      if (isTeam1Winner) {
        room.matchScore.team1 += endStatus.pointsMultiplier;
      } else {
        room.matchScore.team2 += endStatus.pointsMultiplier;
      }

      // تعیین حاکم جدید برای راند بعدی
      if (!isHakemTeamWinner) {
        room.hakemIndex = (room.hakemIndex + 1) % 4; // چرخش حاکم در صورت باخت تیم حاکم
      }

      // ریست امتیاز دست برای راند جدید
      room.teamScore = { team1: 0, team2: 0 };
    }

    return {
      winnerSeat,
      winningTeam,
      teamScore: room.teamScore,
      matchScore: room.matchScore,
      handEnded,
      endStatus,
    };
  }
}

module.exports = new GameStateManager();
