const mongoose = require('mongoose');
require('dotenv').config();

const connectMongoDB = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB Terhubung Mulus!');
    } catch (err) {
        console.error('Gagal konek ke MongoDB:', err.message);
        process.exit(1);
    }
};

module.exports = connectMongoDB;