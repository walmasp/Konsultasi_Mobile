FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 3000
CMD ["node", "index.js"]

# Notes : 
# FROM node:20-alpine
  # Menentukan image untuk container Docker. Dimana menggunakan image Node.js resmi berbasis Alpine Linux versi 20, yang ringan dan cocok untuk aplikasi Node.js.

# WORKDIR /app
  # Menetapkan direktori kerja di dalam container Docker. Semua perintah berikutnya akan dijalankan di dalam direktori ini.

# COPY . .
  # Menyalin semua file dari direktori saat ini (di mana Dockerfile berada) ke dalam direktori kerja di dalam container Docker.

# RUN npm install
  # Menjalankan perintah untuk menginstal semua dependensi yang tercantum dalam file package.json menggunakan npm.

# EXPOSE 3000
  # Memberitahu Docker bahwa container akan mendengarkan pada port 3000. Ini tidak membuka port secara otomatis, tetapi memberikan informasi kepada pengguna dan alat lain tentang port yang digunakan oleh aplikasi.

# CMD ["node", "index.js"]
  # Menentukan perintah yang akan dijalankan ketika container dijalankan. Dalam hal ini, perintah tersebut menjalankan aplikasi Node.js dengan menggunakan file index.js sebagai titik masuk.