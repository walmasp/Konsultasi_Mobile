import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../auth/screens/auth_screen.dart';
import '../../chat/screens/chat_screen.dart'; // Import halaman chat
import 'jadwal_page.dart';

// ─── Sanctuary Design Tokens ────────────────────────────────────────────────
const _kPrimary      = Color(0xFF5C6BC0);
const _kPrimaryDeep  = Color(0xFF3949AB);
const _kPrimaryLight = Color(0xFFE8EAF6);
const _kBg           = Color(0xFFF0F2F8);
const _kCardBg       = Color(0xFFFFFFFF);
const _kTextPrimary  = Color(0xFF1C1F33);
const _kTextSub      = Color(0xFF6B7280);
const _kSuccess      = Color(0xFF26A69A);
const _kError        = Color(0xFFEF5350);

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
          _createdAt = response.data['created_at']?.toString() ?? '-';
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
          _jadwalList = (response.data is List) ? response.data as List<dynamic> : [];
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
          _riwayatList = (response.data is List) ? response.data as List<dynamic> : [];
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
              backgroundColor: _kCardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              contentPadding: EdgeInsets.zero,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7986CB), _kPrimary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.white, size: 36),
                        SizedBox(height: 8),
                        Text(
                          'Bagaimana sesimu?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Berikan penilaianmu untuk psikolog ini',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      children: [
                        // Bintang Interaktif (1-5)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () => setState(() => selectedStars = index + 1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  index < selectedStars
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: Colors.amber[600],
                                  size: 40,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: ulasanController,
                          maxLines: 3,
                          style: const TextStyle(color: _kTextPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Tulis ulasan opsional...',
                            hintStyle: const TextStyle(color: _kTextSub, fontSize: 13),
                            fillColor: _kBg,
                            filled: true,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: Colors.grey[200]!),
                                  ),
                                ),
                                child: const Text('Batal',
                                    style: TextStyle(
                                        color: _kTextSub, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF7986CB), _kPrimary],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
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
                                          SnackBar(
                                            content: const Text(
                                                'Terima kasih atas ulasan & penilaian Anda!'),
                                            backgroundColor: _kSuccess,
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14)),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                        _fetchRiwayat(); // Reload otomatis riwayat di layar belakang
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Gagal mengirim rating, coba lagi.'),
                                            backgroundColor: _kError,
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14)),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Kirim',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700, color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
      backgroundColor: _kBg,
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      {'icon': Icons.home_rounded, 'label': 'Beranda'},
      {'icon': Icons.assignment_rounded, 'label': 'Riwayat'},
      {'icon': Icons.person_rounded, 'label': 'Profil'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(items.length, (index) {
              final isSelected = _selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimaryLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[index]['icon'] as IconData,
                          color: isSelected ? _kPrimary : Colors.grey[400],
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[index]['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected ? _kPrimary : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ==================== TAB 1: BERANDA ====================
  Widget _buildBerandaTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient Hero Header ─────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimaryDeep, _kPrimary, Color(0xFF7986CB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Stack(
              children: [
                // Decorative circle
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 60,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF69F0AE),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('Anonim Mode',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Halo, $_username 👋',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Butuh teman cerita hari ini?\nPrivasimu dijamin aman.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Konseling Card ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 14),
                  child: Text(
                    'Mulai Konseling',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7986CB), _kPrimary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.security_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Konseling Anonim 100%',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: _kTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Konsultasikan kesehatan mentalmu secara bebas tanpa perlu khawatir identitas aslimu diketahui oleh siapapun.',
                          style: TextStyle(
                            color: _kTextSub,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Info badges
                      Row(
                        children: [
                          _InfoBadge(
                              icon: Icons.lock_rounded,
                              label: 'Terenkripsi'),
                          const SizedBox(width: 8),
                          _InfoBadge(
                              icon: Icons.verified_rounded,
                              label: 'Psikolog Terverifikasi'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7986CB), _kPrimary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _kPrimary.withOpacity(0.30),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
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
                            icon: const Icon(Icons.calendar_month_rounded,
                                size: 20, color: Colors.white),
                            label: const Text(
                              'Cari Jadwal Psikolog',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: RIWAYAT & RATING ====================
  Widget _buildRiwayatTab() {
    if (_isLoadingRiwayat) {
      return const Center(
          child: CircularProgressIndicator(color: _kPrimary));
    }

    if (_riwayatList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_outlined,
                  size: 40, color: _kPrimary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada riwayat sesi',
              style: TextStyle(
                  color: _kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Riwayat konseling kamu akan muncul di sini',
              style: TextStyle(color: _kTextSub, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Text(
            'Riwayat Sesi',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _kTextPrimary,
              letterSpacing: -0.4,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchRiwayat,
            color: _kPrimary,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              itemCount: _riwayatList.length,
              itemBuilder: (context, index) {
                final riwayat = _riwayatList[index];
                final String status = riwayat['status_konseling'] ?? 'menunggu';
                final int? rateValue = riwayat['rating'] != null
                    ? (riwayat['rating'] as num).toInt()
                    : null;

                String rawDate = riwayat['tanggal'] ?? '';
                String formattedDate =
                    rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;

                return _RiwayatCard(
                  riwayat: riwayat,
                  status: status,
                  rateValue: rateValue,
                  formattedDate: formattedDate,
                  onRatePressed: () =>
                      _showRatingDialog(context, riwayat['id']),
                  onChatPressed: () {
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
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ==================== TAB 3: PROFIL ====================
  Widget _buildProfilTab() {
    String formattedJoinDate = _createdAt;
    if (_createdAt.length >= 10) {
      formattedJoinDate = _createdAt.substring(0, 10);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7986CB), _kPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.sentiment_satisfied_alt_rounded,
                size: 46, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            _username,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _kTextPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _kPrimaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Pengguna Anonim',
              style: TextStyle(
                  fontSize: 12,
                  color: _kPrimary,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 28),

          // Info Card
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.calendar_month_rounded,
                  'Bergabung Sejak',
                  formattedJoinDate,
                ),
                Divider(
                    height: 1, thickness: 1, color: Colors.grey[100]),
                _buildInfoRow(
                  Icons.analytics_rounded,
                  'Total Konseling',
                  '${_riwayatList.length} Sesi',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _kError.withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text(
                  'Keluar Aplikasi',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kError,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _kPrimaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _kPrimary, size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _kTextSub),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary),
          ),
        ],
      ),
    );
  }
}

// ─── Riwayat Card Widget ─────────────────────────────────────────────────────
class _RiwayatCard extends StatelessWidget {
  final Map<String, dynamic> riwayat;
  final String status;
  final int? rateValue;
  final String formattedDate;
  final VoidCallback onRatePressed;
  final VoidCallback onChatPressed;

  const _RiwayatCard({
    required this.riwayat,
    required this.status,
    required this.rateValue,
    required this.formattedDate,
    required this.onRatePressed,
    required this.onChatPressed,
  });

  Color get _statusColor {
    if (status == 'selesai') return const Color(0xFF26A69A);
    if (status == 'dibatalkan') return const Color(0xFFEF5350);
    if (status == 'berjalan') return const Color(0xFF5C6BC0);
    return const Color(0xFFFF8F00);
  }

  IconData get _statusIcon {
    if (status == 'selesai') return Icons.check_circle_rounded;
    if (status == 'dibatalkan') return Icons.cancel_rounded;
    if (status == 'berjalan') return Icons.radio_button_checked_rounded;
    return Icons.access_time_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C6BC0).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // Left accent bar + content
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: _statusColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  riwayat['nama_psikolog'] ?? 'Psikolog',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: _kTextPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_statusIcon,
                                        size: 11, color: _statusColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 14, color: _kTextSub),
                              const SizedBox(width: 5),
                              Text(
                                '$formattedDate  •  ${riwayat['jam_mulai']?.substring(0, 5)} WIB',
                                style: const TextStyle(
                                    color: _kTextSub, fontSize: 13),
                              ),
                            ],
                          ),
                          if (riwayat['catatan_mahasiswa'] != null &&
                              riwayat['catatan_mahasiswa']
                                  .toString()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _kBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      size: 13, color: _kTextSub),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '"${riwayat['catatan_mahasiswa']}"',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _kTextSub,
                                        fontStyle: FontStyle.italic,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // ── BLOK TOMBOL CHAT ─────────────────────────
                          if (status == 'berjalan') ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: onChatPressed,
                                icon: const Icon(
                                    Icons.chat_bubble_rounded,
                                    size: 16),
                                label: const Text(
                                  'Masuk Room Chat (Anonim)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF26A69A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                          ],

                          // ── BLOK TOMBOL RATING ───────────────────────
                          if (status == 'selesai') ...[
                            const SizedBox(height: 14),
                            if (rateValue == null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: onRatePressed,
                                  icon: const Icon(Icons.star_rounded,
                                      size: 16),
                                  label: const Text('Beri Rating Sesi',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber[700],
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Penilaianmu: ',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.amber[800],
                                          fontWeight: FontWeight.w600),
                                    ),
                                    ...List.generate(5, (starIndex) {
                                      return Icon(
                                        starIndex < rateValue!
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: Colors.amber[600],
                                        size: 18,
                                      );
                                    }),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Badge Widget ───────────────────────────────────────────────────────
class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kPrimaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _kPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _kPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}