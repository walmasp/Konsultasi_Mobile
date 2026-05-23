import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart'; // Pastikan path ke ApiClient sudah benar

// ─── Sanctuary Design Tokens ────────────────────────────────────────────────
const _kPrimary      = Color(0xFF5C6BC0);
const _kPrimaryDeep  = Color(0xFF3949AB);
const _kPrimaryLight = Color(0xFFE8EAF6);
const _kBg           = Color(0xFFF0F2F8);
const _kCardBg       = Color(0xFFFFFFFF);
const _kTextPrimary  = Color(0xFF1C1F33);
const _kTextSub      = Color(0xFF6B7280);

// Di file: psikolog_profile_sheet.dart
class PsikologProfileSheet {
  static void show(BuildContext context, Map<String, dynamic> psikologData) {
    // DEBUG: Untuk ngecek isi data yang masuk ke sheet lewat terminal console
    print("DEBUG PROFILE SHEET DATA: $psikologData");

    // Mengambil ID psikolog (bisa dari jadwal_sesi atau psikolog_profiles)
    final psikologId = psikologData['psikolog_id'] ?? psikologData['user_id'];

    // JIKA NULL, JANGAN DI-RENDER biar ga crash 'Null' is not a subtype of 'int'
    if (psikologId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Gagal memuat profil: ID Psikolog tidak ditemukan / Null!'),
          backgroundColor: Colors.red,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: _kCardBg,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: _PsikologProfileContent(
                // Konversi aman memastikan tipenya int
                psikologId: psikologId is int
                    ? psikologId
                    : int.parse(psikologId.toString()),
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }
}

class _PsikologProfileContent extends StatefulWidget {
  final int psikologId;
  final ScrollController scrollController;

  const _PsikologProfileContent({
    required this.psikologId,
    required this.scrollController,
  });

  @override
  State<_PsikologProfileContent> createState() =>
      _PsikologProfileContentState();
}

class _PsikologProfileContentState extends State<_PsikologProfileContent> {
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _profileData;
  List<dynamic> _ulasanList = [];

  // Variabel untuk menampung data rating
  double _rating = 0.0;
  int _totalUlasan = 0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRealProfileAndReviews();
  }

  // Mengambil data aggregasi AVG rating, count, keahlian, & ulasan dari MySQL via Express
  Future<void> _fetchRealProfileAndReviews() async {
    try {
      final response =
          await _api.dio.get('/psikolog/profile/${widget.psikologId}');

      if (response.statusCode == 200 && response.data != null) {
        final profile = response.data['profile'];
        final ulasan = response.data['ulasan'] ?? [];

        setState(() {
          _profileData = profile;
          _ulasanList = ulasan as List<dynamic>;

          // Parsing aman ke double dan int, lalu simpan ke variabel class
          _rating =
              double.tryParse(profile['rata_rating']?.toString() ?? '') ?? 0.0;
          _totalUlasan =
              int.tryParse(profile['total_ulasan']?.toString() ?? '') ?? 0;

          // Loading dimatikan karena data sukses diproses
          _isLoading = false;
        });
      }
    } catch (e) {
      // Tampilkan log error di konsol untuk mempermudah debugging masa depan
      print("Error saat memuat profil psikolog: $e");

      // PENTING: Jika terjadi error network/parsing, loading HARUS tetap dimatikan
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat profil psikolog.'; // Set pesan error untuk UI
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal memuat profil lengkap psikolog.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(
            child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Colors.red[400], size: 42),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                    color: Colors.red[400],
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profileData ?? {};

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.zero,
        children: [
          // ── Gradient Header Section ────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimaryDeep, _kPrimary, Color(0xFF7986CB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Decorative circle
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Column(
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Avatar
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5), width: 2),
                        ),
                        child: const Icon(Icons.person_rounded,
                            size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      // Name
                      Text(
                        profile['nama_lengkap'] ?? 'Nama Psikolog',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Spesialisasi chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          profile['spesialisasi'] ?? 'Spesialis',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Rating row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 22),
                            const SizedBox(width: 6),
                            Text(
                              _rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '  ($_totalUlasan ulasan sesi)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Content Section ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bio
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _kPrimaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.info_outline_rounded,
                                size: 16, color: _kPrimary),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Tentang Psikolog',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile['bio'] ??
                            'Psikolog ini aktif melayani konseling mahasiswa secara anonim untuk menangani kasus kecemasan akademik, stress, dan masalah adaptasi kampus.',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: _kTextSub,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Reviews header
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.star_half_rounded,
                          size: 16, color: Colors.amber[700]),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Ulasan Masuk',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_totalUlasan > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kPrimaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_totalUlasan ulasan',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_ulasanList.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 36, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(
                          'Belum ada ulasan review.',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._ulasanList.map((review) {
                    final int score = review['rating'] != null
                        ? (review['rating'] as num).toInt()
                        : 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: const Color(0xFFE8EAF6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimary.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Mini Avatar
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _kPrimaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_rounded,
                                    size: 18, color: _kPrimary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  review['nama_mahasiswa'] ?? 'Anonim',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextPrimary,
                                  ),
                                ),
                              ),
                              // Star rating
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ...List.generate(5, (starIdx) {
                                      return Icon(
                                        starIdx < score
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: Colors.amber[600],
                                        size: 14,
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (review['ulasan'] != null &&
                              review['ulasan'].toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _kBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                review['ulasan'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kTextSub,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}