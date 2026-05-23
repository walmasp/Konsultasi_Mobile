const express = require('express');
const router = express.Router();
const db = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// 1. Register User (CREATE)
router.post('/register', async (req, res) => {
    const { username, password, role } = req.body;
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        const userRole = role || "mahasiswa"; // Default ke mahasiswa jika tidak dikirim
        await db.query('INSERT INTO users (username, password, role) VALUES (?, ?, ?)', 
            [username, hashedPassword, userRole]);
        res.status(201).json({ message: "Registrasi akun berhasil!" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 2. Login User (READ) - STRUKTUR BARU
router.post('/login', async (req, res) => {
    const { username, password } = req.body;
    try {
        const [rows] = await db.query('SELECT * FROM users WHERE username = ?', [username]);
        if (rows.length === 0) return res.status(404).json({ message: "User tidak ditemukan" });

        const isMatch = await bcrypt.compare(password, rows[0].password);
        if (!isMatch) return res.status(401).json({ message: "Password salah" });

        const token = jwt.sign({ id: rows[0].id, role: rows[0].role }, process.env.JWT_SECRET, { expiresIn: '1d' });
        
        // --- INI PERBAIKAN UTAMANYA: MEMBUNGKUS DATA DALAM OBJEK 'user' ---
        res.json({ 
            token, 
            user: {
                id: rows[0].id,
                username: rows[0].username,
                role: rows[0].role
            }
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 3. Get Profil Login Saat Ini (READ)
router.get('/me', async (req, res) => {
    const token = req.headers['authorization']?.split(' ')[1];
    if (!token) return res.status(403).json({ message: "Token tidak disediakan" });
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const [rows] = await db.query('SELECT id, username, role, created_at FROM users WHERE id = ?', [decoded.id]);
        res.json(rows[0]);
    } catch (err) {
        res.status(401).json({ message: "Token tidak valid" });
    }
});

module.exports = router;