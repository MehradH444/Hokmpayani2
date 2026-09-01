/**
 * Auth & User Controller
 * File: authController.js
 * Description: Controller handling user authentication, OTP validation, guest logins, and profile data retrieval.
 */

const jwt = require('jsonwebtoken');
const User = require('./User');

/**
 * تولید توکن امنیتی JWT
 */
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
};

/**
 * @desc    ثبت‌نام کاربر جدید
 * @route   POST /api/auth/register
 */
exports.register = async (req, res) => {
  try {
    const { username, password, phoneNumber, email } = req.body;

    // بررسی تکراری نبودن نام کاربری
    const existingUser = await User.findOne({ $or: [{ username }, { phoneNumber }] });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'نام کاربری یا شماره تلفن قبلاً ثبت شده است',
      });
    }

    // ساخت کاربر جدید با پاداش ثبت‌نام
    const user = await User.create({
      username,
      password,
      phoneNumber,
      email,
      wallet: {
        coins: parseInt(process.env.INITIAL_USER_COINS) || 1000,
        gems: parseInt(process.env.INITIAL_USER_GEMS) || 10,
      },
    });

    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      token,
      user: {
        id: user._id,
        username: user.username,
        avatar: user.avatar,
        wallet: user.wallet,
        levelInfo: user.levelInfo,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * @desc    ورود کاربر با نام کاربری و رمز عبور
 * @route   POST /api/auth/login
 */
exports.login = async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ success: false, message: 'نام کاربری و کلمه عبور را وارد کنید' });
    }

    const user = await User.findOne({ username }).select('+password');
    if (!user || !(await user.matchPassword(password))) {
      return res.status(401).json({ success: false, message: 'اطلاعات ورود نادرست است' });
    }

    user.lastLoginAt = Date.now();
    await user.save();

    const token = generateToken(user._id);

    res.status(200).json({
      success: true,
      token,
      user: {
        id: user._id,
        username: user.username,
        avatar: user.avatar,
        wallet: user.wallet,
        levelInfo: user.levelInfo,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * @desc    ورود سریع کاربر مهمان (Guest Login)
 * @route   POST /api/auth/guest
 */
exports.loginAsGuest = async (req, res) => {
  try {
    const randomGuestNum = Math.floor(100000 + Math.random() * 900000);
    const guestUsername = `Guest_${randomGuestNum}`;
    const guestPassword = `GuestPass_${randomGuestNum}_Secret`;

    const user = await User.create({
      username: guestUsername,
      password: guestPassword,
      wallet: {
        coins: parseInt(process.env.INITIAL_USER_COINS) || 1000,
        gems: parseInt(process.env.INITIAL_USER_GEMS) || 10,
      },
    });

    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      token,
      user: {
        id: user._id,
        username: user.username,
        avatar: user.avatar,
        wallet: user.wallet,
        levelInfo: user.levelInfo,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * @desc    دریافت اطلاعات پروفایل کاربر احراز هویت شده
 * @route   GET /api/auth/me
 */
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate('clan.clanId', 'name badge level');
    res.status(200).json({
      success: true,
      user,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
