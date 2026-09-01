/**
 * ChatMessage Schema & Model
 * File: ChatMessage.js
 * Description: Real-time message storage supporting in-game table chat, clan chat, quick voice responses, and stickers.
 */

const mongoose = require('mongoose');

const ChatMessageSchema = new mongoose.Schema(
  {
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'فرستنده پیام الزامی است'],
    },
    senderUsername: {
      type: String,
      required: true,
    },
    senderAvatar: {
      type: String,
      default: 'avatar_default_1',
    },
    chatType: {
      type: String,
      enum: ['table', 'clan', 'global', 'private'],
      required: [true, 'نوع چت الزامی است'],
    },
    // شناسه اتاق میز بازی یا کلن جهت تفکیک پیام‌ها
    targetId: {
      type: String,
      required: [true, 'شناسه مقصد چت الزامی است'],
      index: true,
    },
    messageType: {
      type: String,
      enum: ['text', 'sticker', 'quick_chat', 'audio_taunt'],
      default: 'text',
    },
    content: {
      type: String,
      required: [true, 'محتوای پیام الزامی است'],
      trim: true,
      maxlength: [500, 'پیام نمی‌تواند بیشتر از ۵۰۰ کاراکتر باشد'],
    },
    stickerId: {
      type: String,
      default: null,
    },
    isReadBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
  },
  {
    timestamps: true,
  }
);

// ایندکس ترکیبی برای سرعت بالای کوئری گرفتن از تاریخچه چت‌ها
ChatMessageSchema.index({ targetId: 1, createdAt: -1 });

module.exports = mongoose.model('ChatMessage', ChatMessageSchema);
