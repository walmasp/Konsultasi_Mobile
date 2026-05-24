const express = require('express');
const router = express.Router();
const db = require('../config/db');

// 10. Booking Jadwal Baru (Mahasiswa Flutter) -> CREATE (Transaksi Aman & Konsisten)
router.post('/', async (req, res) => {
    const { mahasiswa_id, jadwal_id, catatan_mahasiswa } = req.body;
    
    if (!mahasiswa_id || !jadwal_id) {
        return res.status(400).json({ error: "mahasiswa_id dan jadwal_id wajib diisi!" });
    }

    // Mendapatkan koneksi tunggal khusus dari pool untuk mengunci transaksi
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction(); // Memulai transaksi

        // Cek ketersediaan jadwal saat ini (Lock baris untuk mencegah double booking)
        const [jadwal] = await connection.query('SELECT status FROM jadwal_sesi WHERE id = ? FOR UPDATE', [jadwal_id]);
        if (jadwal.length === 0) {
            throw new Error("Jadwal konseling tidak ditemukan");
        }
        if (jadwal[0].status === 'terpesan') {
            throw new Error("Jadwal sudah dipesan oleh mahasiswa lain");
        }

        // Simpan data booking ke tabel booking_sesi
        await connection.query(
            'INSERT INTO booking_sesi (mahasiswa_id, jadwal_id, catatan_mahasiswa, status_konseling) VALUES (?, ?, ?, "menunggu")', 
            [mahasiswa_id, jadwal_id, catatan_mahasiswa || 'Sesi Keluhan Anonim']
        );

        // Update status di jadwal_sesi menjadi terpesan
        await connection.query('UPDATE jadwal_sesi SET status = "terpesan" WHERE id = ?', [jadwal_id]);

        await connection.commit(); // Eksekusi sukses, simpan permanen ke DB
        res.status(201).json({ message: "Sesi konseling berhasil dibooking!" });
    } catch (err) {
        await connection.rollback(); // Jika gagal, batalkan semua perubahan di atas
        res.status(500).json({ error: err.message });
    } finally {
        connection.release(); // Kembalikan koneksi ke pool
    }
});

// Endpoint Tambahan: Memberikan Rating & Ulasan Sesi Konseling (Mahasiswa)
router.post('/:id/rate', async (req, res) => {
    const { rating, ulasan } = req.body;
    try {
        if (!rating || rating < 1 || rating > 5) {
            return res.status(400).json({ error: "Rating harus bernilai antara 1 sampai 5" });
        }

        const [result] = await db.query(
            'UPDATE booking_sesi SET rating = ?, ulasan = ? WHERE id = ?',
            [rating, ulasan, req.params.id]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: "Data booking tidak ditemukan" });
        }

        res.json({ message: "Rating dan ulasan berhasil disimpan. Terima kasih!" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 11. Get Riwayat Booking Mahasiswa Tertentu (Flutter) -> READ
router.get('/mahasiswa/:id', async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT b.*, j.tanggal, j.jam_mulai, j.jam_selesai, p.nama_lengkap as nama_psikolog 
            FROM booking_sesi b 
            JOIN jadwal_sesi j ON b.jadwal_id = j.id 
            JOIN psikolog_profiles p ON j.psikolog_id = p.user_id 
            WHERE b.mahasiswa_id = ?`, [req.params.id]);
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 12. Get Riwayat Booking Masuk Psikolog (Web Admin) -> READ - PERBAIKAN ALIAS USERNAME
router.get('/psikolog/:id', async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT b.*, j.tanggal, j.jam_mulai, u.username as username 
            FROM booking_sesi b
            JOIN jadwal_sesi j ON b.jadwal_id = j.id
            JOIN users u ON b.mahasiswa_id = u.id
            WHERE j.psikolog_id = ?`, [req.params.id]);
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 13. Get Detail Satu Booking -> READ
router.get('/:id', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM booking_sesi WHERE id = ?', [req.params.id]);
        res.json(rows[0]);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 14. Update Status Konseling (Selesai/Dibatalkan) -> UPDATE
router.put('/:id', async (req, res) => {
    const { status_konseling } = req.body;
    try {
        await db.query('UPDATE booking_sesi SET status_konseling = ? WHERE id = ?', [status_konseling, req.params.id]);
        
        if (status_konseling === 'dibatalkan') {
            const [booking] = await db.query('SELECT jadwal_id FROM booking_sesi WHERE id = ?', [req.params.id]);
            await db.query('UPDATE jadwal_sesi SET status = "tersedia" WHERE id = ?', [booking[0].jadwal_id]);
        }
        res.json({ message: "Status booking berhasil diupdate" });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 15. Delete/Hapus Data Riwayat Booking -> DELETE
router.delete('/:id', async (req, res) => {
    try {
        await db.query('DELETE FROM booking_sesi WHERE id = ?', [req.params.id]);
        res.json({ message: "Data booking berhasil dihapus dari sistem" });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;