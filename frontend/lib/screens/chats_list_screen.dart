import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({Key? key}) : super(key: key);

  @override
  _ChatsListScreenState createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  List<dynamic> _recentChats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecentChats();
  }

  Future<void> _fetchRecentChats() async {
    try {
      final response = await ApiService.get('/chats/recent');
      if (response.statusCode == 200) {
        setState(() {
          _recentChats = jsonDecode(response.body);
        });
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Chats')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _recentChats.isEmpty
          ? const Center(child: Text('You have no chat history. Messages will appear here.'))
          : ListView.builder(
              itemCount: _recentChats.length,
              itemBuilder: (context, index) {
                final chat = _recentChats[index];
                final otherUser = chat['user'];
                final lastMessage = chat['lastMessage'] ?? '';
                final time = chat['time'] ?? '';

                return ListTile(
                  leading: const CircleAvatar(backgroundColor: AppTheme.accentColor, child: Icon(Icons.person, color: Colors.white)),
                  title: Text(otherUser['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Text('...', style: TextStyle(color: AppTheme.accentColor, fontSize: 12)),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                      otherUserId: otherUser['_id'],
                      otherUserName: otherUser['name'] ?? 'User',
                    )));
                  },
                );
              },
            ),
    );
  }
}
