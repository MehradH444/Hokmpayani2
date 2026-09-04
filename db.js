cat << 'EOF' > db.js
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/hokm', {
      serverSelectionTimeoutMS: 2000
    });
    console.log(`[MongoDB] Connected: ${conn.connection.host}`);
  } catch (err) {
    console.log(`[MongoDB Warning] Running without database: ${err.message}`);
  }
};

module.exports = connectDB;
EOF
node server.js
