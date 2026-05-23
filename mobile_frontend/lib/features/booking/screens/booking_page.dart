import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'psikolog_profile_sheet.dart'; // Import sudah diperbaiki!

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
        'catatan_mahasiswa':
            _catatanController.text.trim().isEmpty
                ? 'Sesi Keluhan Anonim'
                : _catatanController.text.trim()
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Sesi berhasil dipesan secara anonim!',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: _kSuccess,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
        widget.onBookingSuccess();
        Navigator.pop(context); // Kembali ke list jadwal
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal booking: ${e.response?.data['error'] ?? e.message}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _kError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
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
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Custom AppBar with gradient ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimaryDeep, _kPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Detail Pendaftaran',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // Balance
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable Body ──────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Psikolog Info Card (clickable) ───────────────────
                  GestureDetector(
                    onTap: () {
                      // Memicu munculnya Bottom Sheet Profil Psikolog saat ditekan
                      PsikologProfileSheet.show(context,
                          Map<String, dynamic>.from(widget.jadwalData));
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimary.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          children: [
                            // Gradient top bar
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF7986CB),
                                    _kPrimary,
                                  ],
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Klik untuk lihat profil psikolog',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded,
                                          size: 16, color: Colors.white70),
                                      SizedBox(width: 4),
                                      Text('Profil',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF7986CB),
                                              _kPrimary
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  _kPrimary.withOpacity(0.25),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            )
                                          ],
                                        ),
                                        child: const Icon(
                                            Icons.person_rounded,
                                            color: Colors.white,
                                            size: 30),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.jadwalData['nama_lengkap'] ??
                                                  'Psikolog',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: _kTextPrimary,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _kPrimaryLight,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                widget.jadwalData[
                                                        'spesialisasi'] ??
                                                    'Umum',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: _kPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  // Divider
                                  Container(
                                    height: 1,
                                    color: const Color(0xFFF0F2F8),
                                  ),
                                  const SizedBox(height: 16),
                                  // Time info
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _kBg,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: _kPrimaryLight,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.access_time_filled_rounded,
                                            color: _kPrimary,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Waktu Sesi',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: _kTextSub,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$cleanTgl  •  ${widget.jadwalData['jam_mulai']?.substring(0, 5)} - ${widget.jadwalData['jam_selesai']?.substring(0, 5)} WIB',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: _kTextPrimary,
                                              ),
                                            ),
                                          ],
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
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Catatan Section ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withOpacity(0.07),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.edit_note_rounded,
                                color: Color(0xFF9C27B0),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Catatan Tambahan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Opsional — identitas tetap anonim',
                                  style: TextStyle(
                                      fontSize: 11, color: _kTextSub),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _catatanController,
                          maxLines: 4,
                          style: const TextStyle(
                              color: _kTextPrimary,
                              fontSize: 14,
                              height: 1.5),
                          decoration: InputDecoration(
                            hintText: 'Tuliskan keluhan singkat Anda...',
                            hintStyle: const TextStyle(
                                color: _kTextSub, fontSize: 13),
                            filled: true,
                            fillColor: _kBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: _kPrimary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Confirm Button ───────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      gradient: _isSubmitting
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF7986CB), _kPrimary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                      color: _isSubmitting ? Colors.grey[300] : null,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _isSubmitting
                          ? []
                          : [
                              BoxShadow(
                                color: _kPrimary.withOpacity(0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isSubmitting ? null : _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 20, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    'Konfirmasi & Ambil Sesi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Privacy note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded,
                          size: 13, color: _kTextSub),
                      const SizedBox(width: 5),
                      Text(
                        'Sesi ini sepenuhnya anonim & terenkripsi',
                        style: TextStyle(
                            fontSize: 12, color: _kTextSub),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}