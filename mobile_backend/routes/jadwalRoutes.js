const express = require('express');
const router = express.Router();
const db = require('../config/db');

// 4. Create Jadwal Baru (Psikolog) -> CREATE
router.post('/', async (req, res) => {
    const { psikolog_id, tanggal, jam_mulai, jam_selesai } = req.body;
    try {
        await db.query('INSERT INTO jadwal_sesi (psikolog_id, tanggal, jam_mulai, jam_selesai) VALUES (?, ?, ?, ?)', 
        [psikolog_id, tanggal, jam_mulai, jam_selesai]);
        res.status(201).json({ message: "Jadwal berhasil ditambahkan" });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 5. Get Semua Jadwal Tersedia (Untuk Flutter Mahasiswa) -> READ
router.get('/tersedia', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT j.*, p.nama_lengkap, p.spesialisasi FROM jadwal_sesi j JOIN psikolog_profiles p ON j.psikolog_id = p.user_id WHERE j.status = "tersedia"');
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 6. Get Semua Jadwal Berdasarkan Psikolog (Untuk Web) -> READ
router.get('/psikolog/:id', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM jadwal_sesi WHERE psikolog_id = ?', [req.params.id]);
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 7. Get Detail Satu Jadwal -> READ
router.get('/:id', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM jadwal_sesi WHERE id = ?', [req.params.id]);
        res.json(rows[0]);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 8. Update Jadwal (Ubah Jam/Tanggal) -> UPDATE
router.put('/:id', async (req, res) => {
    const { tanggal, jam_mulai, jam_selesai, status } = req.body;
    try {
        await db.query('UPDATE jadwal_sesi SET tanggal = ?, jam_mulai = ?, jam_selesai = ?, status = ? WHERE id = ?', 
        [tanggal, jam_mulai, jam_selesai, status, req.params.id]);
        res.json({ message: "Jadwal berhasil diperbarui" });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 9. Delete Jadwal -> DELETE
router.delete('/:id', async (req, res) => {
    try {
        await db.query('DELETE FROM jadwal_sesi WHERE id = ?', [req.params.id]);
        res.json({ message: "Jadwal berhasil dihapus" });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;