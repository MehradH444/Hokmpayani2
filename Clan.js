/**
 * Clan Schema & Model
 * File: Clan.js
 * Description: Complete representation of player clans, including levelling, treasury, capacity, and settings.
 */

const mongoose = require('mongoose');

const ClanSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'نام کلن الزامی است'],
      unique: true,
      trim: true,
      minlength: [3, 'نام کلن باید حداقل ۳ کاراکتر باشد'],
      maxlength: [20, 'نام کلن نمی‌تواند بیشتر از ۲۰ کاراکتر باشد'],
    },
    description: {
      type: String,
      default: 'به کلن ما خوش آمدید!',
      maxlength: [200, 'توضیحات نمی‌تواند بیشتر از ۲۰۰ کاراکتر باشد'],
    },
    badge: {
      type: String,
      default: 'badge_shield_1',
    },
    leader: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    level: {
      type: Number,
      default: 1,
    },
    xp: {
      type: Number,
      default: 0,
    },
    requiredXpNextLevel: {
      type: Number,
      default: 1000,
    },
    maxMembers: {
      type: Number,
      default: 30,
    },
    membersCount: {
      type: Number,
      default: 1,
    },
    treasury: {
      coins: {
        type: Number,
        default: 0,
        min: 0,
      },
      gems: {
        type: Number,
        default: 0,
        min: 0,
      },
    },
    settings: {
      type: {
        type: String,
        enum: ['open', 'invite_only', 'closed'],
        default: 'open',
      },
      minLevelRequired: {
        type: Number,
        default: 1,
      },
      minTrophiesRequired: {
        type: Number,
        default: 0,
      },
    },
    pendingRequests: [
      {
        user: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
        },
        requestedAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    trophies: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

// افزایش تجربه (XP) کلن و محاسبه لول‌آپ خودکار
ClanSchema.methods.addXP = function (amount) {
  this.xp += amount;
  while (this.xp >= this.requiredXpNextLevel) {
    this.xp -= this.requiredXpNextLevel;
    this.level += 1;
    this.requiredXpNextLevel = Math.floor(this.requiredXpNextLevel * 1.5);
    // افزایش ظرفیت پذیرش اعضا به ازای هر لول
    if (this.maxMembers < 50) {
      this.maxMembers += 2;
    }
  }
};

module.exports = mongoose.model('Clan', ClanSchema);
