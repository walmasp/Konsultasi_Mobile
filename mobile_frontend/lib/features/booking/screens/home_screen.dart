import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../auth/screens/auth_screen.dart';
import '../../chat/screens/chat_screen.dart'; // Import halaman chat
import 'jadwal_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ApiClient _api = ApiClient();
  
  // State Data
  String _username = 'Anonim';
  String _createdAt = '-';
  List<dynamic> _jadwalList = [];
  List<dynamic> _riwayatList = [];
  bool _isLoadingJadwal = true;
  bool _isLoadingRiwayat = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchJadwal();
    _fetchRiwayat();
  }

  // 1. Load Data User Saat Ini
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Anonim';
    });
    
    try {
      final response = await _api.dio.get('/auth/me');
      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _username = response.data['username'] ?? _username;
          _createdAt = response.data['created_at'] ?? '-';
        });
      }
    } catch (e) {
      debugPrint('Gagal load user detail: $e');
    }
  }

  // 2. Fetch Jadwal Konseling yang Masih "Tersedia"
  Future<void> _fetchJadwal() async {
    setState(() => _isLoadingJadwal = true);
    try {
      final response = await _api.dio.get('/jadwal/tersedia');
      if (mounted) {
        setState(() {
          _jadwalList = response.data;
          _isLoadingJadwal = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _isLoadingJadwal = false);
        debugPrint('Error fetch jadwal: ${e.response?.data}');
      }
    }
  }

  // 3. Fetch Riwayat Transaksi Booking Mahasiswa
  Future<void> _fetchRiwayat() async {
    setState(() => _isLoadingRiwayat = true);
    try {
      // Ambil ID mahasiswa dari profil /me terlebih dahulu
      final meRes = await _api.dio.get('/auth/me');
      final mhsId = meRes.data['id'];

      // Gunakan ID tersebut untuk GET daftar riwayat
      final response = await _api.dio.get('/booking/mahasiswa/$mhsId');
      if (mounted) {
        setState(() {
          _riwayatList = response.data;
          _isLoadingRiwayat = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRiwayat = false);
        debugPrint('Error fetch riwayat: $e');
      }
    }
  }

  // 4. Fungsi Logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  // 5. DIALOG RATING KHUSUS UNTUK SESI YANG SUDAH "SELESAI"
  void _showRatingDialog(BuildContext context, int bookingId) {
    int selectedStars = 5;
    final ulasanController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                'Bagaimana sesimu?',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Berikan penilaianmu untuk psikolog ini', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  
                  // Bintang Interaktif (1-5)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () => setState(() => selectedStars = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: ulasanController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tulis ulasan opsional...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: const Color(0xFFF2F2F7),
                      filled: true,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF), 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    try {
                      // POST / PUT data rating ke MySQL melalui API backend
                      await _api.dio.post('/booking/$bookingId/rate', data: {
                        "rating": selectedStars,
                        "ulasan": ulasanController.text,
                      });

                      if (context.mounted) {
                        Navigator.pop(context); // Tutup dialog penilai
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Terima kasih atas ulasan & penilaian Anda!'), backgroundColor: Colors.green)
                        );
                        _fetchRiwayat(); // Reload otomatis riwayat di layar belakang
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gagal mengirim rating, coba lagi.'), backgroundColor: Colors.red)
                        );
                      }
                    }
                  },
                  child: const Text('Kirim', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            );
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildBerandaTab(),
      _buildRiwayatTab(),
      _buildProfilTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: Colors.grey[400],
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }

  // ==================== TAB 1: BERANDA ====================
  Widget _buildBerandaTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Halo, $_username', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text('Butuh teman cerita hari ini? Privasimu dijamin aman.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 32),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.security_rounded, color: Color(0xFF007AFF), size: 24),
                    SizedBox(width: 8),
                    Text('Konseling Anonim 100%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Konsultasikan kesehatan mentalmu secara bebas tanpa perlu khawatir identitas aslimu diketahui oleh siapapun.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JadwalPage(
                            jadwalList: _jadwalList,
                            isLoading: _isLoadingJadwal,
                            onRefresh: _fetchJadwal,
                            onBookingSuccess: () {
                              _fetchJadwal();
                              _fetchRiwayat();
                              setState(() => _selectedIndex = 1); 
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cari Jadwal Psikolog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ==================== TAB 2: RIWAYAT & RATING ====================
  Widget _buildRiwayatTab() {
    if (_isLoadingRiwayat) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)));
    }

    if (_riwayatList.isEmpty) {
      return Center(
        child: Text('Belum ada riwayat sesi konseling.', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRiwayat,
      color: const Color(0xFF007AFF),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _riwayatList.length,
        itemBuilder: (context, index) {
          final riwayat = _riwayatList[index];
          final String status = riwayat['status_konseling'] ?? 'menunggu';
          final int? rateValue = riwayat['rating']; 

          String rawDate = riwayat['tanggal'] ?? '';
          String formattedDate = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;

          return Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        // NAMA PSIKOLOG: Dikembalikan menjadi teks biasa (Bukan Link) sesuai permintaan
                        child: Text(
                          riwayat['nama_psikolog'] ?? 'Psikolog',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'selesai'
                              ? Colors.green.withOpacity(0.1)
                              : status == 'dibatalkan'
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: status == 'selesai'
                                ? Colors.green[700]
                                : status == 'dibatalkan'
                                    ? Colors.red[700]
                                    : Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Waktu: $formattedDate • ${riwayat['jam_mulai']?.substring(0, 5)} WIB',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (riwayat['catatan_mahasiswa'] != null && riwayat['catatan_mahasiswa'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Keluhan: "${riwayat['catatan_mahasiswa']}"',
                      style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                    ),
                  ],
                  
                  // ================= BLOK TOMBOL CHAT (JIKA STATUS BERJALAN) =================
                  if (status == 'berjalan') ...[
                    const Divider(height: 24, thickness: 0.5),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                bookingId: riwayat['id'].toString(),
                                namaPsikolog: riwayat['nama_psikolog'] ?? 'Psikolog',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                        label: const Text('Masuk Room Chat (Anonim)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34C759),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],

                  // ================= BLOK TOMBOL RATING (JIKA STATUS SELESAI) =================
                  if (status == 'selesai') ...[
                    const Divider(height: 24, thickness: 0.5),
                    
                    if (rateValue == null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showRatingDialog(context, riwayat['id']),
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: const Text('Beri Rating Sesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Text('Penilaianmu: ', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < rateValue ? Icons.star_rounded : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== TAB 3: PROFIL ====================
  Widget _buildProfilTab() {
    String formattedJoinDate = _createdAt;
    if (_createdAt.length >= 10) {
      formattedJoinDate = _createdAt.substring(0, 10);
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
            child: const Icon(Icons.sentiment_satisfied_alt_rounded, size: 44, color: Color(0xFF007AFF)),
          ),
          const SizedBox(height: 16),
          Text('ID: $_username', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _buildInfoRow(Icons.calendar_month_rounded, 'Bergabung Sejak', formattedJoinDate),
                const Divider(height: 24, thickness: 0.5),
                _buildInfoRow(Icons.analytics_rounded, 'Total Konseling', '${_riwayatList.length} Sesi'),
              ],
            ),
          ),
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30), 
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Keluar Aplikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF007AFF), size: 22),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black54)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}