/**
 * Tournament Schema & Model
 * File: Tournament.js
 * Description: Data structure for managing competitive tournaments, brackets, rewards, and entry fees.
 */

const mongoose = require('mongoose');

const MatchSchema = new mongoose.Schema({
  round: {
    type: Number,
    required: true, // مثلاً ۱ برای ۱/۸ نهایی، ۲ برای ۱/۴ نهایی، ۳ برای فینال
  },
  team1: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
  ],
  team2: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
  ],
  winnerTeam: {
    type: Number, // 1 یا 2
    default: null,
  },
  status: {
    type: String,
    enum: ['pending', 'in_progress', 'completed'],
    default: 'pending',
  },
});

const TournamentSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'عنوان تورنمنت الزامی است'],
      trim: true,
    },
    description: {
      type: String,
      default: '',
    },
    bannerImage: {
      type: String,
      default: 'banner_tournament_gold',
    },
    entryFee: {
      type: {
        type: String,
        enum: ['coins', 'gems', 'free'],
        default: 'coins',
      },
      amount: {
        type: Number,
        default: 1000,
      },
    },
    prizePool: {
      firstPlaceCoins: { type: Number, default: 10000 },
      firstPlaceGems: { type: Number, default: 50 },
      secondPlaceCoins: { type: Number, default: 4000 },
      secondPlaceGems: { type: Number, default: 20 },
    },
    maxParticipants: {
      type: Number,
      enum: [8, 16, 32, 64],
      default: 16,
    },
    currentParticipants: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    status: {
      type: String,
      enum: ['registration', 'in_progress', 'completed', 'cancelled'],
      default: 'registration',
    },
    brackets: [MatchSchema],
    startDate: {
      type: Date,
      required: true,
    },
    winner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    runnerUp: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// متد بررسی تکمیل بودن ظرفیت برای شروع خودکار
TournamentSchema.methods.isFull = function () {
  return this.currentParticipants.length >= this.maxParticipants;
};

module.exports = mongoose.model('Tournament', TournamentSchema);
