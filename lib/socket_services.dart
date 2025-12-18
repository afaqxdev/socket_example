// // ignore_for_file: library_prefixes, avoid_print

// import 'package:socket_io_client/socket_io_client.dart' as IO;

// typedef MessageCallback = void Function(Map<String, dynamic>);

// class SocketService {
//   late IO.Socket socket;

//   // Callback for receiving messages, keyed by chatId
//   Map<String, MessageCallback> messageCallbacks = {};

//   bool isConnected = false;

//   void connect(String chatId) async {
//     try {
//       print('✅ Socket connecting...');

//       socket = IO.io('add the server link', <String, dynamic>{
//         'transports': ['websocket'],
//         'autoConnect': false,
//       });

//       socket.onAny((event, data) {
//         print('📡 Received event: $event with data: $data');
//       });

//       socket.connect();

//       socket.onConnect((_) {
//         print('✅ Socket connected successfully');
//         socket.emit("joinChat", {"chatId": chatId});
//         listenForIncomingMessages(chatId: chatId); // 👈 pass chatId
//       });

//       socket.onConnectError((err) {
//         print('❌ Socket connection error: $err');
//       });

//       socket.onError((err) {
//         print('⚠️ Socket error: $err');
//       });
//     } catch (e) {
//       print('⚠️ Error initializing socket: $e');
//     }
//   }

//   void listenForIncomingMessages({required String chatId}) {
//     print("👂 Listening for incoming messages...");

//     socket.on('receive_message', (data) {
//       print('✉️ New message received: $data');

//       if (messageCallbacks.containsKey(chatId)) {
//         messageCallbacks[chatId]!(data);
//       } else {
//         print("⚠️ No callback registered for chat: $chatId");
//       }
//     });
//   }

//   void registerMessageCallback(String chatId, MessageCallback callback) {
//     messageCallbacks[chatId] = callback;
//   }

//   void sendMessage(String chatId, Map<String, dynamic> content) {
//     if (socket.connected) {
//       socket.emit('send_message', {
//         'room': chatId,
//         'content': content,
//       });
//     } else {
//       print('⚠️ Socket not connected. Cannot send message.');
//     }
//   }

//   void disconnect() {
//     if (socket.connected) {
//       socket.disconnect();
//       print('🔌 Socket disconnected');
//     }
//   }
// }
// ignore_for_file: library_prefixes

import 'package:penitans_app/app/app.locator.dart';
import 'package:penitans_app/core/constants/logger.dart';
import 'package:penitans_app/services/config_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef ChatMessageCallback = void Function(Map<String, dynamic>);
typedef OfferCallbackAccept = void Function(Map<String, dynamic>);
typedef OfferCallbackWithDraw = void Function(Map<String, dynamic>);
typedef OfferCallbackReject = void Function(Map<String, dynamic>);
typedef OfferCallbackUpdate = void Function(Map<String, dynamic>);
typedef OnlineStatusCallback = void Function({
  required String userId,
  required bool isOnline,
});

/// Callbacks for chat messages, offers, and online status.
final Map<String, ChatMessageCallback> chatMessageCallbacks = {};

final Map<String, OfferCallbackWithDraw> offerStatusCallbacksAccept = {};
final Map<String, OfferCallbackWithDraw> offerStatusCallbacksWithDrawn = {};
final Map<String, OfferCallbackReject> offerStatusCallbacksReject = {};
final Map<String, OfferCallbackUpdate> offerStatusCallbacksUpdate = {};
final Map<String, OnlineStatusCallback> onlineStatusCallbacks = {};

class SocketService {
  late IO.Socket socket;

  final _configService = locator<ConfigService>();

  /// General socket connection status.
  bool isConnected = false;

  /// Used for reporting-specific message callbacks.
  final Map<String, ChatMessageCallback> reportMessageCallbacks = {};

  // === CONNECTION METHODS ===

  void connectToChat(String chatId) async {
    try {
      printLog('✅ Connecting to chat socket...');

      socket = IO.io(_configService.baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      socket.onAny((event, data) {
        printLog('📡 Event: $event | Data: $data');
      });

      socket.connect();

      socket.onConnect((_) {
        printLog('🟢 Chat socket connected');
        socket.emit("joinChat", {"chatId": chatId});

        _listenToChatMessages(chatId);
        _listenToOfferAccept(chatId);
        _listenToOfferReject(chatId);
        _listenToOfferUpdate(chatId);
        _listenToOfferWithDraw(chatId);
        _listenToOnlineUsers();
      });

      socket.onConnectError((err) => printLog('❌ Connection error: $err'));
      socket.onError((err) => printLog('⚠️ Socket error: $err'));
    } catch (e) {
      printLog('⚠️ Chat socket init error: $e');
    }
  }

  void connectForUserPresence(String userId) async {
    try {
      printLog('🔗 Connecting for presence updates...');

      socket = IO.io(_configService.baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      socket.connect();

      socket.onConnect((_) {
        printLog('🟢 Presence socket connected');
        emitUserOnline(userId);
        _listenToOnlineUsers();
      });

      socket.onConnectError((err) => printLog('❌ Presence error: $err'));
      socket.onError((err) => printLog('⚠️ General socket error: $err'));
    } catch (e) {
      printLog('⚠️ Presence socket init error: $e');
    }
  }

  void connectToReportChat(String chatId) async {
    try {
      printLog('✅ Connecting to report chat socket...');

      socket = IO.io(_configService.adminUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      socket.onAny((event, data) {
        printLog('📡 Event: $event | Data: $data');
      });

      socket.connect();

      socket.onConnect((_) {
        printLog('🟢 Report chat socket connected');
        socket.emit("joinReportChat", {"chatId": chatId});
        _listenToReportMessages(chatId);
        _listenToOnlineUsers();
      });

      socket.onConnectError((err) => printLog('❌ Report socket error: $err'));
      socket.onError((err) => printLog('⚠️ General socket error: $err'));
    } catch (e) {
      printLog('⚠️ Report socket init error: $e');
    }
  }

  void disconnect() {
    if (socket.connected) {
      socket.disconnect();
      printLog('🔌 Socket disconnected');
    }
  }

  void emitUserOnline(String userId) {
    if (socket.connected) {
      socket.emit("userOnline", userId);
      printLog("📡 Emitted 'userOnline' for userId: $userId");
    } else {
      printLog("⚠️ Cannot emit 'userOnline' — socket not connected.");
    }
  }

  void sendMessage(String chatId, Map<String, dynamic> content) {
    if (socket.connected) {
      socket.emit('send_message', {
        'room': chatId,
        'content': content,
      });
    } else {
      printLog('⚠️ Socket not connected. Cannot send message.');
    }
  }

  // === LISTEN METHODS ===

  void _listenToChatMessages(String chatId) {
    printLog("👂 Subscribing to chat messages...");

    socket.on('receive_message', (data) {
      printLog('✉️ Message received: $data');

      if (chatMessageCallbacks.containsKey(chatId)) {
        chatMessageCallbacks[chatId]!(data);
      } else {
        printLog("⚠️ No chat callback registered for chatId: $chatId");
      }
    });
  }

  void _listenToOfferAccept(String chatId) {
    printLog("👂 Subscribing to offer status updates...");

    socket.on('offer_status_confirmed', (data) {
      printLog('📦 Offer confirmed: $data');

      if (offerStatusCallbacksAccept.containsKey(chatId)) {
        offerStatusCallbacksAccept[chatId]!(data);
      } else {
        printLog("⚠️ No offer callback registered for chatId: $chatId");
      }
    });
  }

  void _listenToOfferUpdate(String chatId) {
    printLog("👂 Subscribing to offer status updates...");

    socket.on('offer_updated', (data) {
      printLog('📦 Offer confirmed: $data');

      if (offerStatusCallbacksUpdate.containsKey(chatId)) {
        offerStatusCallbacksUpdate[chatId]!(data);
      } else {
        printLog("⚠️ No offer callback registered for chatId: $chatId");
      }
    });
  }

  void _listenToOfferReject(String chatId) {
    printLog("👂 Subscribing to offer status updates...");

    socket.on('offer_rejected', (data) {
      printLog('📦 Offer confirmed: $data');

      if (offerStatusCallbacksReject.containsKey(chatId)) {
        offerStatusCallbacksReject[chatId]!(data);
      } else {
        printLog("⚠️ No offer callback registered for chatId: $chatId");
      }
    });
  }

  void _listenToOfferWithDraw(String chatId) {
    printLog("👂 Subscribing to offer status updates...");

    socket.on('offer_withdrawn', (data) {
      printLog('📦 Offer confirmed: $data');

      if (offerStatusCallbacksWithDrawn.containsKey(chatId)) {
        offerStatusCallbacksWithDrawn[chatId]!(data);
      } else {
        printLog("⚠️ No offer callback registered for chatId: $chatId");
      }
    });
  }

  void _listenToReportMessages(String chatId) {
    printLog("👂 Subscribing to report messages...");

    socket.on('receive_report_message', (data) {
      printLog('📄 Report message received: $data');

      if (reportMessageCallbacks.containsKey(chatId)) {
        reportMessageCallbacks[chatId]!(data);
      } else {
        printLog("⚠️ No report callback registered for chatId: $chatId");
      }
    });
  }

  void _listenToOnlineUsers() {
    socket.on("get_online_user", (data) {
      final String userId = data['id'];
      final bool isOnline = data['isOnline'];

      if (onlineStatusCallbacks.containsKey(userId)) {
        onlineStatusCallbacks[userId]!(
          userId: userId,
          isOnline: isOnline,
        );
      } else {
        printLog("⚠️ No presence callback for userId: $userId");
      }
    });
  }

  // === CALLBACK REGISTRATION ===

  void registerChatMessageCallback(
      String chatId, ChatMessageCallback callback) {
    chatMessageCallbacks[chatId] = callback;
  }

  void registerOfferCallbackReject(
      String chatId, OfferCallbackReject callback) {
    offerStatusCallbacksReject[chatId] = callback;
  }

  void registerOfferCallbackAccept(
      String chatId, OfferCallbackAccept callback) {
    offerStatusCallbacksAccept[chatId] = callback;
  }

  void registerOfferCallbackWithDraw(
      String chatId, OfferCallbackWithDraw callback) {
    offerStatusCallbacksWithDrawn[chatId] = callback;
  }

  void registerOfferCallbackWithUpdate(
      String chatId, OfferCallbackUpdate callback) {
    offerStatusCallbacksUpdate[chatId] = callback;
  }

  void registerOnlineStatusCallback(
      String userId, OnlineStatusCallback callback) {
    onlineStatusCallbacks[userId] = callback;
  }

  void registerReportMessageCallback(
      String chatId, ChatMessageCallback callback) {
    reportMessageCallbacks[chatId] = callback;
  }
}
