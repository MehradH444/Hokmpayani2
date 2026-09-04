/**
 * Main Application Server Entry Point
 * File: server.js
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

const app = express();
const server = http.createServer(app);

connectDB();

app.use(cors({ origin: '*' }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));
app.use(express.static('public'));

app.use('/api', routes);

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'online',
    game: 'Hokm Master Server',
    timestamp: new Date(),
  });
});

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  pingTimeout: 30000,
  pingInterval: 10000,
});

io.use(socketAuth);
socketHandler(io);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(` HOKM MASTER GAME SERVER RUNNING ON PORT: ${PORT}`);
  console.log(` Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`====================================================`);
});

process.on('unhandledRejection', (err) => {
  console.error(`[Unhandled Rejection]: ${err.message}`);
});
