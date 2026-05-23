import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart'; // Sesuaikan folder jika berbeda
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ─── Sanctuary Design Tokens ────────────────────────────────────────────────
const _kPrimary      = Color(0xFF5C6BC0);
const _kPrimaryDeep  = Color(0xFF3949AB);
const _kPrimaryLight = Color(0xFFE8EAF6);
const _kBg           = Color(0xFFF0F2F8);
const _kCardBg       = Color(0xFFFFFFFF);
const _kTextPrimary  = Color(0xFF1C1F33);
const _kTextSub      = Color(0xFF6B7280);

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String namaPsikolog;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.namaPsikolog,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 1. Tambahkan variabel Socket
  late IO.Socket socket;

  // Data dummy dikosongkan agar chat murni dari database/socket
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initSocket(); // 2. Panggil inisialisasi socket saat layar dibuka
  }

  // 3. Fungsi untuk menghubungkan Flutter ke Node.js via WebSocket
  void _initSocket() {
    String socketUrl = ApiClient.baseUrl.replaceAll('/api', '');
    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Terhubung ke Server Chat WebSocket');
      // Masuk ke room khusus menggunakan bookingId
      // (Pastikan widget.bookingId bertipe String, jika int langsung pakai saja)
      socket.emit('join_room', int.parse(widget.bookingId)); 
    });

    // 4. Mendengarkan pesan masuk dari Psikolog (Web Temanmu)
    socket.on('receive_message', (data) {
      if (!mounted) return;
      
      // Jika yang mengirim adalah psikolog, tambahkan ke layar (is_me: false)
      if (data['sender_role'] == 'psikolog') {
        setState(() {
          _messages.add({
            'message_text': data['text'],
            'is_me': false,
          });
        });
        _scrollToBottom();
      }
    });
  }

  void _kirimPesan() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Tampilkan di layar lokal kita sendiri (Kanan)
    setState(() {
      _messages.add({
        'message_text': text,
        'is_me': true,
      });
    });

    // 5. Tembakkan pesan ke backend & MongoDB
    socket.emit('send_message', {
      'booking_id': int.parse(widget.bookingId),
      'sender_id': 99, // Ganti dengan ID mahasiswa asli dari sesi login nanti
      'sender_role': 'mahasiswa',
      'text': text,
    });

    _messageController.clear();
    _scrollToBottom();
  }

  // Pisahkan logika scroll agar bisa dipanggil juga saat pesan masuk
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    // 6. Putuskan koneksi saat keluar dari layar chat
    socket.disconnect();
    socket.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Custom AppBar ────────────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    // Back button
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
                    const SizedBox(width: 12),

                    // Psikolog avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // Name + status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.namaPsikolog,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF9500),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Mode Offline (UI Only)',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.70),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Lock icon badge
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_rounded,
                          color: Colors.white70, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Security Banner ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _kPrimaryLight, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kPrimaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.security_rounded,
                      color: _kPrimary, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Obrolan ini dienkripsi end-to-end. Identitas aslimu tidak terekspos.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _kTextSub,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Message List ─────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final chat = _messages[index];
                final bool isMe = chat['is_me'];

                return _ChatBubble(
                  message: chat['message_text'] ?? '',
                  isMe: isMe,
                );
              },
            ),
          ),

          // ── Input Area ───────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.10),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              children: [
                // Text input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: const Color(0xFFE0E3F0), width: 1),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(
                          color: _kTextPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan rahasia...',
                        hintStyle: const TextStyle(
                            color: _kTextSub, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 13),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _kirimPesan(),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Send button
                GestureDetector(
                  onTap: _kirimPesan,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7986CB), _kPrimary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat Bubble Widget ──────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // Psikolog mini avatar
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7986CB), _kPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
          // Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(
                      colors: [Color(0xFF7986CB), _kPrimary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isMe ? null : _kCardBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: isMe
                      ? _kPrimary.withOpacity(0.25)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isMe ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : _kTextPrimary,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}