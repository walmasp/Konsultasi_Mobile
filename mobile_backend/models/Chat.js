const mongoose = require('mongoose');

const ChatSchema = new mongoose.Schema({
    booking_id: {
        type: Number, // Menghubungkan ke ID Transaksi di MySQL
        required: true
    },
    sender_id: {
        type: Number, // ID Pengirim (bisa mahasiswa atau psikolog)
        required: true
    },
    sender_role: {
        type: String,
        enum: ['mahasiswa', 'psikolog'],
        required: true
    },
    message_text: {
        type: String, // Teks curhatan mahasiswa
        required: true
    },
    timestamp: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Chat', ChatSchema);