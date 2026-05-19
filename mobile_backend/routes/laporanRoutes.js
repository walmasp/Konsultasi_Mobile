const express = require('express');
const router = express.Router();
const db = require('../config/db');

// 16. Buat Laporan Konseling Baru (Psikolog) -> CREATE
router.post('/', async (req, res) => {
    const { booking_id, psikolog_id, ringkasan_sesi, status_tindak_lanjut } = req.body;
    try {
        await db.query(
            'INSERT INTO laporan_konseling (booking_id, psikolog_id, ringkasan_sesi, status_tindak_lanjut) VALUES (?, ?, ?, ?)',
            [booking_id, psikolog_id, ringkasan_sesi, status_tindak_lanjut]
        );
        res.status(201).json({ message: "Laporan konseling berhasil disimpan" });
    } catch (err) {
        // Menangani error jika booking_id sudah memiliki laporan (karena sifatnya UNIQUE)
        if (err.code === 'ER_DUP_ENTRY') {
            return res.status(400).json({ error: "Laporan untuk sesi ini sudah ada" });
        }
        res.status(500).json({ error: err.message });
    }
});

// 17. Get Semua Laporan yang Dibuat Psikolog Tertentu -> READ
router.get('/psikolog/:id', async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT l.*, b.catatan_mahasiswa, j.tanggal, u.username as nama_samaran_mhs 
            FROM laporan_konseling l
            JOIN booking_sesi b ON l.booking_id = b.id
            JOIN jadwal_sesi j ON b.jadwal_id = j.id
            JOIN users u ON b.mahasiswa_id = u.id
            WHERE l.psikolog_id = ?
            ORDER BY l.created_at DESC`, 
            [req.params.id]
        );
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 18. Get Laporan Spesifik Berdasarkan ID Booking -> READ
router.get('/booking/:bookingId', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM laporan_konseling WHERE booking_id = ?', [req.params.bookingId]);
        if (rows.length === 0) return res.status(404).json({ message: "Laporan belum dibuat untuk sesi ini" });
        res.json(rows[0]);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 19. Update Laporan Konseling -> UPDATE
router.put('/:id', async (req, res) => {
    const { ringkasan_sesi, status_tindak_lanjut } = req.body;
    try {
        await db.query(
            'UPDATE laporan_konseling SET ringkasan_sesi = ?, status_tindak_lanjut = ? WHERE id = ?',
            [ringkasan_sesi, status_tindak_lanjut, req.params.id]
        );
        res.json({ message: "Laporan konseling berhasil diperbarui" });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 20. Hapus Laporan Konseling -> DELETE
router.delete('/:id', async (req, res) => {
    try {
        await db.query('DELETE FROM laporan_konseling WHERE id = ?', [req.params.id]);
        res.json({ message: "Laporan konseling berhasil dihapus" });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;