const mysql = require('mysql2/promise');
require('dotenv').config();

console.log("HOST:", process.env.DB_HOST);
console.log("USER:", process.env.DB_USER);
console.log("DB:", process.env.DB_NAME);

const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    
    // Tambahkan pengaturan SSL ini agar GCP MySQL 8.4 mau menerima koneksi dari luar
    ssl: {
        rejectUnauthorized: false
    }
});

pool.getConnection()
.then((connection) => {
    console.log("🔥 Cloud SQL Connected");
    connection.release();
})
.catch((err) => {
    console.log("❌ Database Error");
    console.log(err);
});

module.exports = pool;