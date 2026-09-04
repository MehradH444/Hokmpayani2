/**
 * Real-time Socket.io Event Handler
 * File: socketHandler.js
 * Description: Real-time gameplay events, matchmaking, card plays, in-game chat, stickers, and turn timing.
 */

const GameStateManager = require('./GameStateManager');
const ChatMessage = require('./ChatMessage');

module.exports = (io) => {
  io.on('connection', (socket) => {
    const user = socket.user;
    console.log(`[Socket] Player connected: ${user.username} (${socket.id})`);

    /**
     * پیوستن به یک اتاق/میز بازی
     */
    socket.on('join_room', async ({ roomId }) => {
      let room = GameStateManager.getRoom(roomId);
      if (!room) {
        room = GameStateManager.createRoom(roomId, { title: 'میز حکم حرفه‌ای' });
      }

      const result = GameStateManager.joinPlayer(roomId, user);
      if (!result.success) {
        return socket.emit('error_message', { message: result.message });
      }

      socket.join(roomId);
      socket.roomId = roomId;

      // اطلاع به تمام افراد میز در مورد وارد شدن بازیکن جدید
      io.to(roomId).emit('room_updated', {
        room: GameStateManager.getRoom(roomId),
        message: `${user.username} وارد میز شد`,
      });

      // اگر بازی شروع شده باشد (تعیین حکم)
      if (room.status === 'hokm_selection') {
        io.to(roomId).emit('game_started', {
          hakemIndex: room.hakemIndex,
          hakemUsername: room.players[room.hakemIndex].username,
        });

        // ارسال ۵ کارت اول به هر بازیکن
        room.players.forEach((player, index) => {
          if (player && player.socketId) {
            io.to(player.socketId).emit('receive_cards', {
              cards: room.hands[index],
            });
          }
        });
      }
    });

    /**
     * تعیین خال حکم توسط حاکم
     */
    socket.on('select_hokm', ({ hokmSuit }) => {
      const roomId = socket.roomId;
      const room = GameStateManager.getRoom(roomId);
      if (!room) return;

      const playerSeat = room.players.findIndex((p) => p && p.id === user._id.toString());
      if (playerSeat !== room.hakemIndex) {
        return socket.emit('error_message', { message: 'تنها حاکم می‌تواند حکم را تعیین کند' });
      }

      const success = GameStateManager.setHokm(roomId, hokmSuit);
      if (success) {
        io.to(roomId).emit('hokm_selected', {
          hokmSuit,
          currentTurnIndex: room.currentTurnIndex,
        });

        // ارسال ۸ کارت باقی‌مانده (کارت‌های کامل ۱۳ تایی) به هر بازیکن
        room.players.forEach((player, index) => {
          if (player && player.socketId) {
            io.to(player.socketId).emit('receive_cards', {
              cards: room.hands[index],
            });
          }
        });
      }
    });

    /**
     * بازی کردن یک کارت توسط بازیکن
     */
    socket.on('play_card', ({ cardId }) => {
      const roomId = socket.roomId;
      const room = GameStateManager.getRoom(roomId);
      if (!room) return;

      const playerSeat = room.players.findIndex((p) => p && p.id === user._id.toString());
      const playResult = GameStateManager.playCard(roomId, playerSeat, cardId);

      if (!playResult.success) {
        return socket.emit('error_message', { message: playResult.message });
      }

      // اطلاع به بقیه درباره کارت بازی‌شده
      io.to(roomId).emit('card_played', {
        seatIndex: playerSeat,
        card: playResult.cardPlayed,
        nextTurnIndex: room.currentTurnIndex,
      });

      // اگر ۴ کارت روی میز تکمیل شده باشد
      if (playResult.isTrickComplete) {
        setTimeout(() => {
          const trickResult = GameStateManager.resolveTrick(roomId);
          if (trickResult) {
            io.to(roomId).emit('trick_resolved', {
              winnerSeat: trickResult.winnerSeat,
              winningTeam: trickResult.winningTeam,
              teamScore: trickResult.teamScore,
              matchScore: trickResult.matchScore,
              nextTurnIndex: room.currentTurnIndex,
            });

            // در صورت پایان راند (رسیدن یکی از تیم‌ها به ۷ دست)
            if (trickResult.handEnded) {
              io.to(roomId).emit('hand_ended', {
                endStatus: trickResult.endStatus,
                matchScore: trickResult.matchScore,
              });

              // شروع دست جدید بعد از چند ثانیه
              setTimeout(() => {
                GameStateManager.startNewHand(roomId);
                io.to(roomId).emit('game_started', {
                  hakemIndex: room.hakemIndex,
                  hakemUsername: room.players[room.hakemIndex].username,
                });
                room.players.forEach((p, idx) => {
                  if (p && p.socketId) {
                    io.to(p.socketId).emit('receive_cards', { cards: room.hands[idx] });
                  }
                });
              }, 4000);
            }
          }
        }, 1500); // تاخیر ۱.۵ ثانیه‌ای جهت دیدن کارت برنده روی میز
      }
    });

    /**
     * ارسال چت زنده یا استیکر روی میز
     */
    socket.on('send_table_chat', async ({ messageType, content, stickerId }) => {
      const roomId = socket.roomId;
      if (!roomId) return;

      const chatMsg = await ChatMessage.create({
        sender: user._id,
        senderUsername: user.username,
        senderAvatar: user.avatar,
        chatType: 'table',
        targetId: roomId,
        messageType: messageType || 'text',
        content,
        stickerId,
      });

      io.to(roomId).emit('new_table_chat', {
        senderId: user._id,
        senderUsername: user.username,
        messageType: chatMsg.messageType,
        content: chatMsg.content,
        stickerId: chatMsg.stickerId,
        createdAt: chatMsg.createdAt,
      });
    });

    /**
     * قطع ارتباط بازیکن
     */
    socket.on('disconnect', () => {
      console.log(`[Socket] Player disconnected: ${user.username}`);
      const roomId = socket.roomId;
      if (roomId) {
        const updatedRoom = GameStateManager.leavePlayer(roomId, user._id);
        if (updatedRoom) {
          io.to(roomId).emit('player_left', {
            userId: user._id,
            room: updatedRoom,
          });
        }
      }
    });
  });
};
