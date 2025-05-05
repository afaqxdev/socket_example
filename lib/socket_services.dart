// ignore_for_file: library_prefixes, avoid_print

import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef MessageCallback = void Function(Map<String, dynamic>);

class SocketService {
  late IO.Socket socket;

  // Callback for receiving messages, keyed by chatId
  Map<String, MessageCallback> messageCallbacks = {};

  bool isConnected = false;

  void connect(String chatId) async {
    try {
      print('✅ Socket connecting...');

      socket = IO.io('add the server link', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      socket.onAny((event, data) {
        print('📡 Received event: $event with data: $data');
      });

      socket.connect();

      socket.onConnect((_) {
        print('✅ Socket connected successfully');
        socket.emit("joinChat", {"chatId": chatId});
        listenForIncomingMessages(chatId: chatId); // 👈 pass chatId
      });

      socket.onConnectError((err) {
        print('❌ Socket connection error: $err');
      });

      socket.onError((err) {
        print('⚠️ Socket error: $err');
      });
    } catch (e) {
      print('⚠️ Error initializing socket: $e');
    }
  }

  void listenForIncomingMessages({required String chatId}) {
    print("👂 Listening for incoming messages...");

    socket.on('receive_message', (data) {
      print('✉️ New message received: $data');

      if (messageCallbacks.containsKey(chatId)) {
        messageCallbacks[chatId]!(data);
      } else {
        print("⚠️ No callback registered for chat: $chatId");
      }
    });
  }

  void registerMessageCallback(String chatId, MessageCallback callback) {
    messageCallbacks[chatId] = callback;
  }

  void sendMessage(String chatId, Map<String, dynamic> content) {
    if (socket.connected) {
      socket.emit('send_message', {
        'room': chatId,
        'content': content,
      });
    } else {
      print('⚠️ Socket not connected. Cannot send message.');
    }
  }

  void disconnect() {
    if (socket.connected) {
      socket.disconnect();
      print('🔌 Socket disconnected');
    }
  }
}
