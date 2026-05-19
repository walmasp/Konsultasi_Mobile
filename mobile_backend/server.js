const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Pemetaan Route API 
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/jadwal', require('./routes/jadwalRoutes'));
app.use('/api/booking', require('./routes/bookingRoutes'));
app.use('/api/laporan', require('./routes/laporanRoutes'));

// ---> INI BARIS YANG KURANG, TAMBAHKAN SEKARANG: <---
app.use('/api/psikolog', require('./routes/psikologRoutes'));

// Root route checking
app.get('/', (req, res) => {
    res.json({ message: "Server Sistem Konseling Mahasiswa Berjalan Lancar (Database 5 Tabel Active)!" });
});

// Jalankan Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});