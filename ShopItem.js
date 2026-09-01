/**
 * ShopItem Schema & Model
 * File: ShopItem.js
 * Description: Data structure for managing store items, microtransactions, VIP plans, and custom cosmetic assets.
 */

const mongoose = require('mongoose');

const ShopItemSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'عنوان آیتم الزامی است'],
      trim: true,
    },
    description: {
      type: String,
      default: '',
    },
    category: {
      type: String,
      enum: ['coins', 'gems', 'vip', 'card_skin', 'table_theme', 'avatar_frame'],
      required: [true, 'دسته‌بندی آیتم الزامی است'],
    },
    itemId: {
      type: String,
      required: [true, 'شناسه یکتای آیتم الزامی است'],
      unique: true,
      trim: true,
    },
    iconUrl: {
      type: String,
      default: 'shop_default_icon',
    },
    price: {
      currency: {
        type: String,
        enum: ['irr', 'gems', 'coins'], // ریال، الماس یا سکه
        default: 'irr',
      },
      amount: {
        type: Number,
        required: [true, 'مبلغ/قیمت الزامی است'],
        min: 0,
      },
    },
    reward: {
      coins: { type: Number, default: 0 },
      gems: { type: Number, default: 0 },
      vipDays: { type: Number, default: 0 },
    },
    discountPercentage: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },
    isBestSeller: {
      type: Boolean,
      default: false,
    },
    isLimitedTime: {
      type: Boolean,
      default: false,
    },
    expiresAt: {
      type: Date,
      default: null,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// متد محاسبه قیمت نهایی پس از اعمال تخفیف
ShopItemSchema.methods.getFinalPrice = function () {
  if (this.discountPercentage > 0) {
    return Math.floor(this.price.amount * (1 - this.discountPercentage / 100));
  }
  return this.price.amount;
};

module.exports = mongoose.model('ShopItem', ShopItemSchema);
