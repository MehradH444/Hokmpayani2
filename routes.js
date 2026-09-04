/**
 * API Routes Definition
 * File: routes.js
 * Description: Connects REST API endpoints to authController and gameController with authMiddleware protection.
 */

const express = require('express');
const router = express.Router();

// بارگذاری کنترلرها و میدل‌ور امنیتی (نام فایل‌ها مطابق با گیت‌هاب اصلاح شد)
const authController = require('./authcontroller');
const gameController = require('./gamecontroller');
const { protect } = require('./authMiddleware');

/* ==========================================================================
   ۱. مسیرهای احراز هویت و حساب کاربری (Authentication Routes)
   ========================================================================== */

// ثبت‌نام کاربر جدید
router.post('/auth/register', authController.register);

// ورود با نام کاربری و کلمه عبور
router.post('/auth/login', authController.login);

// ورود سریع به عنوان مهمان
router.post('/auth/guest', authController.loginAsGuest);

// دریافت مشخصات کامل پروفایل کاربر جریانی (نیازمند توکن)
router.get('/auth/me', protect, authController.getMe);


/* ==========================================================================
   ۲. مسیرهای فروشگاه و اقتصاد بازی (Shop & Economy Routes)
   ========================================================================== */

// دریافت لیست تمام آیتم‌های فعال فروشگاه
router.get('/game/shop/items', protect, gameController.getShopItems);

// خرید آیتم یا بسته از فروشگاه
router.post('/game/shop/buy', protect, gameController.buyShopItem);

// چرخاندن گردونه شانس و دریافت پاداش روزانه
router.post('/game/daily-reward', protect, gameController.claimDailyReward);


/* ==========================================================================
   ۳. مسیرهای رده‌بندی و کلن‌ها (Leaderboard & Clan Routes)
   ========================================================================== */

// دریافت جدول برترین بازیکنان
router.get('/game/leaderboard', protect, gameController.getLeaderboard);

// ساخت کلن جدید
router.post('/game/clan/create', protect, gameController.createClan);

// ارسال درخواست عضویت در کلن
router.post('/game/clan/join', protect, gameController.joinClan);

module.exports = router;
