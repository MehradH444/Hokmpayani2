/**
 * Core Hokm Card Engine
 * File: CardEngine.js
 * Description: Deck generation, shuffle algorithms, move validation rules, winner detection logic, and trick resolution.
 */

const SUITS = ['SPADES', 'HEARTS', 'CLUBS', 'DIAMONDS']; // پیک، دل، خاج، خشت
const VALUES = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]; // 11: سرباز, 12: بی بی, 13: شاه, 14: آس

class CardEngine {
  /**
   * ساخت دسته کارت ۵۲ تایی استاندارد
   */
  static createDeck() {
    const deck = [];
    for (const suit of SUITS) {
      for (const value of VALUES) {
        deck.push({
          id: `${suit}_${value}`,
          suit: suit,
          value: value,
        });
      }
    }
    return deck;
  }

  /**
   * الگوریتم بر زدن استاندارد (Fisher-Yates Shuffle)
   */
  static shuffleDeck(deck) {
    const shuffled = [...deck];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
  }

  /**
   * بررسی قانونی بودن بازی کردن یک کارت توسط بازیکن
   * @param {Object} cardToPlay - کارتی که بازیکن قصد انداختن دارد
   * @param {Array} playerHand - لیست کارت‌های دست بازیکن
   * @param {Object|null} leadCard - کارتی که زمینه شده است (اولین کارت دست)
   * @returns {Boolean}
   */
  static isValidMove(cardToPlay, playerHand, leadCard) {
    // اگر بازیکن اولین نفر است، هر کارتی دلخواه است
    if (!leadCard) {
      return true;
    }

    const leadSuit = leadCard.suit;
    const hasLeadSuit = playerHand.some((c) => c.suit === leadSuit);

    // اگر بازیکن خال زمینه را دارد، حتماً باید از همان خال بازی کند
    if (hasLeadSuit) {
      return cardToPlay.suit === leadSuit;
    }

    // اگر خال زمینه را ندارد، هر کارتی (از جمله رد دادن یا رد حکم) قانونی است
    return true;
  }

  /**
   * تعیین برنده یک دست ۴ تایی بازی‌شده
   * @param {Array} playedCards - آرایه‌ای از کارت‌های روی میز [{ playerId, card }]
   * @param {String} hokmSuit - خال حکم تعیین‌شده
   * @returns {Object} کارت برنده و شناسه بازیکن برنده
   */
  static determineTrickWinner(playedCards, hokmSuit) {
    if (!playedCards || playedCards.length === 0) return null;

    const leadSuit = playedCards[0].card.suit;

    let winningPlay = playedCards[0];

    for (let i = 1; i < playedCards.length; i++) {
      const current = playedCards[i];
      const best = winningPlay;

      // اگر کارت فعلی حکم است
      if (current.card.suit === hokmSuit) {
        if (best.card.suit !== hokmSuit) {
          winningPlay = current;
        } else if (current.card.value > best.card.value) {
          winningPlay = current;
        }
      } 
      // اگر کارت فعلی خال زمینه است و تا الان کسی حکم نینداخته
      else if (current.card.suit === leadSuit && best.card.suit !== hokmSuit) {
        if (current.card.value > best.card.value) {
          winningPlay = current;
        }
      }
    }

    return winningPlay;
  }

  /**
   * بررسی شرایط کوت، حاکم‌کوت و بامداد در پایان بازی (رسیدن به ۷ دست)
   * @param {Number} winnerTeamHands - تعداد دست‌های برده تیم برنده (۷)
   * @param {Number} loserTeamHands - تعداد دست‌های برده تیم بازنده
   * @param {Boolean} isWinnerHakimTeam - آیا تیم برنده حاکم بوده است؟
   * @returns {Object} { pointsMultiplier, isKoot, isHakimKoot, isBamdad }
   */
  static calculateGameEndStatus(winnerTeamHands, loserTeamHands, isWinnerHakimTeam) {
    let pointsMultiplier = 1; // حالت معمولی: ۱ امتیاز
    let isKoot = false;
    let isHakimKoot = false;
    let isBamdad = false;

    if (loserTeamHands === 0) {
      if (isWinnerHakimTeam) {
        // حاکم‌کوت: ۲ امتیاز (تیم حاکم ۷-۰ برده)
        pointsMultiplier = 2;
        isKoot = true;
        isHakimKoot = true;
      } else {
        // کوت / بامداد: ۳ امتیاز (تیم غیر حاکم ۷-۰ برده)
        pointsMultiplier = 3;
        isKoot = true;
        isBamdad = true;
      }
    }

    return {
      pointsMultiplier,
      isKoot,
      isHakimKoot,
      isBamdad,
    };
  }
}

module.exports = CardEngine;
