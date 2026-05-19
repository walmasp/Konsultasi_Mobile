import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String namaPsikolog;

  const ChatScreen({
    super.key, 
    required this.bookingId, 
    required this.namaPsikolog
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  
  // Data dummy sementara agar UI bisa dites
  final List<Map<String, dynamic>> _messages = [
    {
      'message_text': 'Halo, ini ruang konseling anonim Anda. Ada yang ingin diceritakan?',
      'is_me': false,
    }
  ];

  void _kirimPesan() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'message_text': text,
        'is_me': true,
      });
    });
    
    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Light Gray One UI
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.namaPsikolog,
              style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9500), // Warna orange (Mode Dummy)
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Mode Offline (UI Only)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner Keamanan
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, color: Color(0xFF007AFF), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Obrolan ini dienkripsi end-to-end. Identitas aslimu tidak terekspos.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // List Pesan Chat
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final chat = _messages[index];
                final bool isMe = chat['is_me'];

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF007AFF) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 20),
                      ),
                    ),
                    child: Text(
                      chat['message_text'] ?? '',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.3
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan rahasia...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _kirimPesan(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 23,
                  backgroundColor: const Color(0xFF007AFF),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: _kirimPesan,
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