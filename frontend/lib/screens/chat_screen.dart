import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({Key? key, required this.otherUserId, required this.otherUserName}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  List<dynamic> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await ApiService.get('/chats/${widget.otherUserId}');
      if (response.statusCode == 200) {
        setState(() {
          _messages = jsonDecode(response.body);
        });
      }
    } catch (e) {
      // Ignored
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isNotEmpty) {
      _msgController.clear();
      // Add fake for instant UI feedback
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final myId = authProvider.user?['_id'];
      
      setState(() {
        _messages.add({
          "sender": myId,
          "text": text,
          "createdAt": DateTime.now().toIso8601String(),
        });
      });
      
      await ApiService.post('/chats', {
        'receiverId': widget.otherUserId,
        'text': text,
      });
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentIcon(Icons.image, Colors.blue, 'Images'),
                _buildAttachmentIcon(Icons.videocam, Colors.pink, 'Videos'),
                _buildAttachmentIcon(Icons.insert_drive_file, Colors.orange, 'Files'),
                _buildAttachmentIcon(Icons.audiotrack, Colors.purple, 'Audio'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentIcon(IconData icon, Color color, String label) {
    return Column(
      children: [
        CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 30)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final myId = authProvider.user?['_id'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.otherUserName, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    bool isMe = msg['sender'] == myId;
                    // Format time simply (H:MM)
                    String timeStr = '';
                    if (msg['createdAt'] != null) {
                      final dt = DateTime.parse(msg['createdAt']);
                      timeStr = '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                    }
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryColor : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(msg['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(timeStr, style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppTheme.cardColor,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.textSecondaryColor, size: 28),
                  onPressed: _showAttachmentMenu,
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions, color: AppTheme.textSecondaryColor, size: 26),
                  onPressed: () {}, // Emoji picker
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.accentColor, size: 28),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
