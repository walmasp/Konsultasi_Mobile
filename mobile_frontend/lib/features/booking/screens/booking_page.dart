import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'psikolog_profile_sheet.dart'; // Import sudah diperbaiki!

class BookingPage extends StatefulWidget {
  final dynamic jadwalData;
  final VoidCallback onBookingSuccess;

  const BookingPage({
    super.key,
    required this.jadwalData,
    required this.onBookingSuccess,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final ApiClient _api = ApiClient();
  final TextEditingController _catatanController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitBooking() async {
    setState(() => _isSubmitting = true);
    try {
      final meRes = await _api.dio.get('/auth/me');
      final mhsId = meRes.data['id'];

      await _api.dio.post('/booking', data: {
        'mahasiswa_id': mhsId,
        'jadwal_id': widget.jadwalData['id'],
        'catatan_mahasiswa': _catatanController.text.trim().isEmpty 
            ? 'Sesi Keluhan Anonim' 
            : _catatanController.text.trim()
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sesi berhasil dipesan secara anonim!'),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        widget.onBookingSuccess();
        Navigator.pop(context); // Kembali ke list jadwal
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal booking: ${e.response?.data['error'] ?? e.message}'),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String tgl = widget.jadwalData['tanggal'] ?? '';
    String cleanTgl = tgl.length >= 10 ? tgl.substring(0, 10) : tgl;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pendaftaran',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // ================ CARD INFO PSIKOLOG (BISA DIPENCET UNTUK LIHAT PROFIL) ================
              InkWell(
                onTap: () {
                  // Memicu munculnya Bottom Sheet Profil Psikolog saat ditekan
                  PsikologProfileSheet.show(context, Map<String, dynamic>.from(widget.jadwalData));
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(24),
                    // Kasih border biru tipis agar user tahu kotak ini bisa ditekan (interaktif)
                    border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.4), width: 1.5), 
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Klik untuk lihat profil psikolog', style: TextStyle(fontSize: 12, color: Color(0xFF007AFF), fontWeight: FontWeight.bold)),
                          Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF007AFF)), 
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(widget.jadwalData['nama_lengkap'] ?? 'Psikolog', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(widget.jadwalData['spesialisasi'] ?? 'Umum', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const Divider(height: 24, thickness: 0.5),
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, color: Color(0xFF007AFF), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '$cleanTgl  •  ${widget.jadwalData['jam_mulai']?.substring(0,5)} - ${widget.jadwalData['jam_selesai']?.substring(0,5)}',
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // ====================================================================
              
              const Text('  Catatan Tambahan (Opsional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: _catatanController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tuliskan keluhan singkat Anda...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(18),
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Konfirmasi & Ambil Sesi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}