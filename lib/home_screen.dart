import 'package:flutter/material.dart';

import 'socket_services.dart'; // import your socket service here

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SocketService _socketService = SocketService();
  final String _chatId = "chat_123"; // sample chatId
  String _latestMessage = "";

  @override
  void initState() {
    super.initState();

    // Register callback
    _socketService.registerMessageCallback(_chatId, (data) {
      setState(() {
        _latestMessage = data['text'] ?? 'No message';
      });
    });

    // Connect to socket
    _socketService.connect(_chatId);
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  void _sendTestMessage() {
    _socketService.sendMessage(_chatId, {
      'text': 'Hello from Flutter!',
      'sender': 'FlutterUser',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Socket Chat')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Latest Message:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_latestMessage.isEmpty ? 'No messages yet' : _latestMessage),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _sendTestMessage,
              child: const Text('Send Test Message'),
            ),
          ],
        ),
      ),
    );
  }
}
