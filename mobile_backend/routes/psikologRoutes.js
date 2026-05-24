const express = require('express');
const router = express.Router();
const db = require('../config/db');


// =====================================================
// GET DETAIL PROFILE PSIKOLOG
// =====================================================

router.get('/profile/:id', async (req, res) => {

    try {

        // =========================================
        // PROFILE + RATING
        // =========================================

        const [profileRows] = await db.query(`
        
            SELECT 
            
                p.*, 
                   
                COALESCE(
                    ROUND(AVG(b.rating), 1),
                    0.0
                ) as rata_rating, 
                   
                COUNT(b.rating) as total_ulasan
            
            FROM psikolog_profiles p
            
            LEFT JOIN jadwal_sesi j 
            ON p.user_id = j.psikolog_id
            
            LEFT JOIN booking_sesi b 
            ON j.id = b.jadwal_id
            
            WHERE p.user_id = ?
            
            GROUP BY p.id
        
        `, [req.params.id]);



        // =========================================
        // KALAU PROFILE BELUM ADA
        // =========================================

        if (profileRows.length === 0) {

            return res.status(404).json({

                error:
                "Profil psikolog tidak ditemukan"

            });

        }



        // =========================================
        // AMBIL ULASAN
        // =========================================

        const [ulasanRows] = await db.query(`
        
            SELECT 
            
                b.rating,
                b.ulasan,
                b.created_at,
                
                u.username as nama_mahasiswa
            
            FROM booking_sesi b
            
            JOIN jadwal_sesi j
            ON b.jadwal_id = j.id
            
            JOIN users u
            ON b.mahasiswa_id = u.id
            
            WHERE 
            j.psikolog_id = ?
            AND b.rating IS NOT NULL
            
            ORDER BY b.created_at DESC
        
        `, [req.params.id]);



        // =========================================
        // RESPONSE
        // =========================================

        res.json({

            profile:
            profileRows[0],

            ulasan:
            ulasanRows

        });

    } catch (err) {

        console.log(err);

        res.status(500).json({

            error:
            err.message

        });

    }

});



// =====================================================
// SAVE / UPDATE PROFILE PSIKOLOG
// =====================================================

router.post('/profile', async (req, res) => {

    try{

        const {

            user_id,
            nama_lengkap,
            spesialisasi,
            bio

        } = req.body;



        // =========================================
        // CHECK PROFILE SUDAH ADA / BELUM
        // =========================================

        const [check] = await db.query(

            `
            
            SELECT * 
            
            FROM psikolog_profiles
            
            WHERE user_id = ?
            
            `,

            [user_id]

        );



        // =========================================
        // UPDATE PROFILE
        // =========================================

        if(check.length > 0){

            await db.query(

                `
                
                UPDATE psikolog_profiles
                
                SET
                
                    nama_lengkap = ?,
                    spesialisasi = ?,
                    bio = ?
                
                WHERE user_id = ?
                
                `,

                [

                    nama_lengkap,
                    spesialisasi,
                    bio,
                    user_id

                ]

            );



        }else{

            // =====================================
            // INSERT PROFILE BARU
            // =====================================

            await db.query(

                `
                
                INSERT INTO psikolog_profiles
                
                (
                    user_id,
                    nama_lengkap,
                    spesialisasi,
                    bio
                )
                
                VALUES (?, ?, ?, ?)
                
                `,

                [

                    user_id,
                    nama_lengkap,
                    spesialisasi,
                    bio

                ]

            );

        }



        // =========================================
        // SUCCESS
        // =========================================

        res.json({

            message:
            "Profile berhasil disimpan"

        });



    }catch(err){

        console.log(err);

        res.status(500).json({

            message:
            err.message

        });

    }

});



module.exports = router;