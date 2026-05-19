const express = require('express');
const router = express.Router();
const db = require('../config/db');

// Get Detail Profil Psikolog, Keahlian, Rerata Rating, dan Semua Histori Ulasan
router.get('/profile/:id', async (req, res) => {
    try {
        // Query 1: Menghitung rata-rata rating & total ulasan dari tabel relasional booking_sesi
        const [profileRows] = await db.query(`
            SELECT p.*, 
                   COALESCE(ROUND(AVG(b.rating), 1), 0.0) as rata_rating, 
                   COUNT(b.rating) as total_ulasan
            FROM psikolog_profiles p
            LEFT JOIN jadwal_sesi j ON p.user_id = j.psikolog_id
            LEFT JOIN booking_sesi b ON j.id = b.jadwal_id
            WHERE p.user_id = ?
            GROUP BY p.id
        `, [req.params.id]);

        if (profileRows.length === 0) {
            return res.status(404).json({ error: "Profil psikolog tidak ditemukan" });
        }

        // Query 2: Mengambil daftar list ulasan dari para mahasiswa (menggunakan nama_samaran/username)
        const [ulasanRows] = await db.query(`
            SELECT b.rating, b.ulasan, b.created_at, u.username as nama_mahasiswa
            FROM booking_sesi b
            JOIN jadwal_sesi j ON b.jadwal_id = j.id
            JOIN users u ON b.mahasiswa_id = u.id
            WHERE j.psikolog_id = ? AND b.rating IS NOT NULL
            ORDER BY b.created_at DESC
        `, [req.params.id]);

        res.json({
            profile: profileRows[0],
            ulasan: ulasanRows
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;