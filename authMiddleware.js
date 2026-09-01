/**
 * Authentication Middleware
 * File: authMiddleware.js
 * Description: Validates JWT tokens for protected Express REST API routes and Socket.io handshake requests.
 */

const jwt = require('jsonwebtoken');
const User = require('./User');

/**
 * Express Route Guard Middleware
 * checks for Authorization Bearer token header
 */
const protect = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    try {
      token = req.headers.authorization.split(' ')[1];

      // رمزگشایی و اعتبارسنجی توکن
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // دریافت اطلاعات کاربر بدون رمز عبور
      req.user = await User.findById(decoded.id).select('-password');

      if (!req.user) {
        return res.status(401).json({
          success: false,
          message: 'کاربر مربوط به این توکن یافت نشد',
        });
      }

      next();
    } catch (error) {
      console.error(`[Auth Error] Invalid Token: ${error.message}`);
      return res.status(401).json({
        success: false,
        message: 'توکن نامعتبر یا منقضی شده است',
      });
    }
  }

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'دسترسی غیرمجاز؛ توکن امنیتی یافت نشد',
    });
  }
};

/**
 * Socket.io Handshake Middleware
 * Authenticates real-time WebSockets connections via handshake auth token
 */
const socketAuth = async (socket, next) => {
  try {
    const token =
      socket.handshake.auth?.token ||
      socket.handshake.headers?.authorization?.split(' ')[1];

    if (!token) {
      return next(new Error('Authentication error: Token missing'));
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id).select('-password');

    if (!user) {
      return next(new Error('Authentication error: User not found'));
    }

    // متصل کردن اطلاعات کاربر به شیء سوکت
    socket.user = user;
    next();
  } catch (error) {
    return next(new Error('Authentication error: Invalid or expired token'));
  }
};

module.exports = { protect, socketAuth };
