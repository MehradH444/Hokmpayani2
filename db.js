/**
 * Database Connection Manager (MongoDB & Mongoose)
 * File: db.js
 * Description: Manages connection lifecycle, event listeners, and graceful teardown for MongoDB.
 */

const mongoose = require('mongoose');

/**
 * Connects to the MongoDB database using the URI provided in environment variables.
 * Implements standard reconnect options and connection status logging.
 */
const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI, {
      autoIndex: true,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });

    console.log(`[MongoDB] Connected successfully: ${conn.connection.host}/${conn.connection.name}`);
  } catch (error) {
    console.error(`[MongoDB] Initial connection error: ${error.message}`);
    process.exit(1);
  }
};

// Event Listeners for Mongoose Connection Lifecycle
mongoose.connection.on('disconnected', () => {
  console.warn('[MongoDB] Connection lost. Attempting to reconnect...');
});

mongoose.connection.on('error', (err) => {
  console.error(`[MongoDB] Runtime error: ${err.message}`);
});

// Graceful shutdown handling
process.on('SIGINT', async () => {
  await mongoose.connection.close();
  console.log('[MongoDB] Connection closed due to application termination.');
  process.exit(0);
});

module.exports = connectDB;
