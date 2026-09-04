/**
 * Main Application Server Entry Point
 * File: server.js
 * Description: Initializes Express app, connects MongoDB, configures CORS/Security, setups Socket.io engine, and starts listening.
 */

require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const connectDB = require('./db');
const routes = require('./routes');
const { socketAuth } = require('./authMiddleware');
const socketHandler = require('./socketHandler');

// ۱. مقداردهی اولیه برنامه Express و ایجاد سرور HTTP
const app = express();
const server = http.createServer(app);

// ۲. اتصال به پایگاه‌داده MongoDB
connectDB();

// ۳. میدل‌ورهای پایه و تنظیمات امنیت CORS
app.use(cors({ origin: '*' }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ۴. اتصال مسیریاب‌های REST API
app.use('/api', routes);

// اندپوئینت تست سلامت سرور
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'online',
    game: 'Hokm Master Server',
    timestamp: new Date(),
  });
});

// ۵. تنظیم و مقداردهی موتور سوکت (Socket.io Engine)
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  pingTimeout: 30000,
  pingInterval: 10000,
});

// ۶. اعمال میدل‌ور احراز هویت روی اتصال‌های سوکت و متصل کردن هندلر رویدادها
io.use(socketAuth);
socketHandler(io);

// ۷. روشن کردن سرور و گوش دادن روی پورت تعیین‌شده
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(` HOKM MASTER GAME SERVER RUNNING ON PORT: ${PORT}`);
  console.log(` Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`====================================================`);
});

// مدیریت خطاهای غیرمنتظره برای جلوگیری از کرش کردن سرور
process.on('unhandledRejection', (err) => {
  console.error(`[Unhandled Rejection]: ${err.message}`);
});
