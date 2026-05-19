import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart'; // Pastikan path ke ApiClient sudah benar

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
        const SnackBar(
          content: Text('Gagal memuat profil: ID Psikolog tidak ditemukan / Null!'),
          backgroundColor: Colors.red,
        ),
      );
      return; 
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _PsikologProfileContent(
              // Konversi aman memastikan tipenya int
              psikologId: psikologId is int ? psikologId : int.parse(psikologId.toString()),
              scrollController: scrollController,
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
  State<_PsikologProfileContent> createState() => _PsikologProfileContentState();
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
      final response = await _api.dio.get('/psikolog/profile/${widget.psikologId}');
      
      if (response.statusCode == 200 && response.data != null) {
        final profile = response.data['profile'];
        final ulasan = response.data['ulasan'] ?? [];

        setState(() {
          _profileData = profile;
          _ulasanList = ulasan as List<dynamic>;

          // Parsing aman ke double dan int, lalu simpan ke variabel class
          _rating = double.tryParse(profile['rata_rating']?.toString() ?? '') ?? 0.0;
          _totalUlasan = int.tryParse(profile['total_ulasan']?.toString() ?? '') ?? 0;

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
          const SnackBar(content: Text('Gagal memuat profil lengkap psikolog.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF007AFF))),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
        ),
      );
    }

    final profile = _profileData ?? {};

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // Handle bar penunjuk bottom sheet
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 24),
        
        // Avatar Foto
        CircleAvatar(
          radius: 40,
          backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
          child: const Icon(Icons.person_rounded, size: 45, color: Color(0xFF007AFF)),
        ),
        const SizedBox(height: 14),
        
        // Nama Lengkap & Keahlian/Spesialisasi asli dari DB
        Text(
          profile['nama_lengkap'] ?? 'Nama Psikolog',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          profile['spesialisasi'] ?? 'Spesialis',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        
        // RATING BINTANG MENGGUNAKAN VARIABEL _rating DAN _totalUlasan
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
            const SizedBox(width: 4),
            Text(_rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(' ($_totalUlasan ulasan sesi)', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
        const Divider(height: 32, thickness: 0.5),
        
        // Deskripsi/Bio Psikolog
        const Text('Tentang Psikolog', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6),
        Text(
          profile['bio'] ?? 'Psikolog ini aktif melayani konseling mahasiswa secara anonim untuk menangani kasus kecemasan akademik, stress, dan masalah adaptasi kampus.',
          style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black54),
        ),
        const Divider(height: 32, thickness: 0.5),
        
        // DAFTAR HISTORI REVIEW MAHASISWA
        const Text('Ulasan Masuk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        
        if (_ulasanList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Belum ada ulasan review untuk psikolog ini.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          ..._ulasanList.map((review) {
            final int score = review['rating'] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        review['nama_mahasiswa'] ?? 'Anonim',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Row(
                        children: List.generate(5, (starIdx) {
                          return Icon(
                            starIdx < score ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 15,
                          );
                        }),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review['ulasan'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}