const express = require('express');
const cors = require('cors');
const http = require('http'); // 1. Tambahan modul HTTP untuk Socket.io
const { Server } = require('socket.io'); // 2. Tambahan modul Socket.io
const connectMongoDB = require('./config/mongo'); // 3. Panggil fungsi koneksi MongoDB
const Chat = require('./models/Chat'); // 4. Panggil skema/model Chat MongoDB
require('dotenv').config();

const app = express();
const server = http.createServer(app); // 5. Bungkus express ke dalam HTTP Server

// 6. Inisialisasi Socket.io dengan konfigurasi CORS
const io = new Server(server, {
    cors: {
        origin: "*", 
        methods: ["GET", "POST"]
    }
});

// Middleware
app.use(cors());
app.use(express.json());

// 7. Jalankan koneksi ke MongoDB NoSQL
connectMongoDB();

// Pemetaan Route API (Tetap dipertahankan)
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/jadwal', require('./routes/jadwalRoutes'));
app.use('/api/booking', require('./routes/bookingRoutes'));
app.use('/api/laporan', require('./routes/laporanRoutes'));
app.use('/api/psikolog', require('./routes/psikologRoutes'));


// ==========================================
// 8. LOGIKA SOCKET.IO & INTEGRASI MONGODB (CHAT)
// ==========================================
io.on('connection', (socket) => {
    console.log('Ada pengguna baru terhubung ke Chat:', socket.id);

    // Fitur Masuk ke Kamar Konseling berdasarkan ID Booking
    socket.on('join_room', (bookingId) => {
        socket.join(bookingId);
        console.log(`User masuk ke Kamar Konseling ID: ${bookingId}`);
    });

    // Mendengarkan saat ada pesan dikirim (dari Mahasiswa/Psikolog)
    socket.on('send_message', async (data) => {
    try {
        // Simpan ke MongoDB dengan memetakan 'text' ke 'message_text'
        const chatBaru = new Chat({
            booking_id: data.booking_id,
            sender_id: data.sender_id,
            sender_role: data.sender_role,
            message_text: data.text // <--- INI KUNCI PERBAIKANNYA
        });

        await chatBaru.save();

        // Broadcast ke psikolog/mahasiswa di room yang sama
        socket.to(data.booking_id.toString()).emit('receive_message', {
            sender_role: data.sender_role,
            text: data.text // Tetap kirim 'text' agar web temanmu bisa baca
        });

    } catch (error) {
        console.error("Gagal simpan ke MongoDB:", error);
    }
});

    socket.on('disconnect', () => {
        console.log('Pengguna keluar dari chat');
    });
});

// Root route checking
app.get('/', (req, res) => {
    res.json({ message: "Server Sistem Konseling Mahasiswa Berjalan Lancar (Database 5 Tabel & MongoDB Active)!" });
});

app.get('/api/chat/:booking_id', async (req, res) => {
    try {
        const chats = await Chat.find({ booking_id: req.params.booking_id })
                                .sort({ timestamp: 1 }); 
        res.json(chats);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Jalankan Server
const PORT = process.env.PORT || 3000;

// 9. PENTING: Ubah app.listen menjadi server.listen agar Socket.io ikut menyala
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

// =========================================================================
// TAMBAHAN: Pengaman Global agar Server Tidak Crash Saat MySQL Error Access Denied
// =========================================================================
process.on('unhandledRejection', (reason, promise) => {
    console.error('❌ Terjadi kesalahan database (Unhandled Rejection):', reason.message || reason);
    // Server tidak akan dimatikan (process.exit) supaya MongoDB dan Socket.io tetap jalan om
});