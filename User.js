/**
 * User Schema & Model
 * File: User.js
 * Description: Complete User data representation including wallet, statistics, level progression, cosmetics, and clan relationships.
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const UserSchema = new mongoose.Schema(
  {
    username: {
      type: String,
      required: [true, 'نام کاربری الزامی است'],
      unique: true,
      trim: true,
      minlength: [3, 'نام کاربری باید حداقل ۳ کاراکتر باشد'],
      maxlength: [20, 'نام کاربری نمی‌تواند بیشتر از ۲۰ کاراکتر باشد'],
    },
    phoneNumber: {
      type: String,
      unique: true,
      sparse: true,
      trim: true,
    },
    email: {
      type: String,
      unique: true,
      sparse: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: [true, 'کلمه عبور الزامی است'],
      minlength: [6, 'کلمه عبور باید حداقل ۶ کاراکتر باشد'],
      select: false,
    },
    avatar: {
      type: String,
      default: 'avatar_default_1',
    },
    avatarFrame: {
      type: String,
      default: 'frame_default',
    },
    cardSkin: {
      type: String,
      default: 'skin_classic_blue',
    },
    tableTheme: {
      type: String,
      default: 'theme_felt_green',
    },
    wallet: {
      coins: {
        type: Number,
        default: 1000,
        min: 0,
      },
      gems: {
        type: Number,
        default: 10,
        min: 0,
      },
    },
    levelInfo: {
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
        default: 100,
      },
    },
    stats: {
      gamesPlayed: { type: Number, default: 0 },
      gamesWon: { type: Number, default: 0 },
      gamesLost: { type: Number, default: 0 },
      handsWon: { type: Number, default: 0 },
      kootCount: { type: Number, default: 0 },
      hakimKootCount: { type: Number, default: 0 },
      bamdadCount: { type: Number, default: 0 },
      currentWinStreak: { type: Number, default: 0 },
      maxWinStreak: { type: Number, default: 0 },
      totalCoinsEarned: { type: Number, default: 0 },
    },
    clan: {
      clanId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Clan',
        default: null,
      },
      role: {
        type: String,
        enum: ['member', 'elder', 'co_leader', 'leader', 'none'],
        default: 'none',
      },
      joinedAt: {
        type: Date,
        default: null,
      },
    },
    isVIP: {
      type: Boolean,
      default: false,
    },
    vipExpiresAt: {
      type: Date,
      default: null,
    },
    lastLoginAt: {
      type: Date,
      default: Date.now,
    },
    dailyRewardLastClaimed: {
      type: Date,
      default: null,
    },
    referralCode: {
      type: String,
      unique: true,
    },
    referredBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    isOnline: {
      type: Boolean,
      default: false,
    },
    currentSocketId: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// کدگذاری کلمه عبور قبل از ذخیره‌سازی در دیتابیس
UserSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  
  // تولید کد معرف اختصاصی در صورت عدم وجود
  if (!this.referralCode) {
    this.referralCode = Math.random().toString(36).substring(2, 8).toUpperCase();
  }
  next();
});

// متد مقایسه کلمه عبور ورودی با هش ذخیره‌شده
UserSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

// متد افزایش XP و محاسبه خودکار لول‌آپ
UserSchema.methods.addXP = function (amount) {
  this.levelInfo.xp += amount;
  while (this.levelInfo.xp >= this.levelInfo.requiredXpNextLevel) {
    this.levelInfo.xp -= this.levelInfo.requiredXpNextLevel;
    this.levelInfo.level += 1;
    this.levelInfo.requiredXpNextLevel = Math.floor(this.levelInfo.requiredXpNextLevel * 1.25);
    // پاداش لول آپ (سکه و الماس)
    this.wallet.coins += this.levelInfo.level * 200;
    this.wallet.gems += 2;
  }
};

module.exports = mongoose.model('User', UserSchema);
