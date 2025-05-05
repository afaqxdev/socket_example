
# 🧩 Flutter Socket.IO Chat

A real-time chat feature built using **Flutter** and **Socket.IO**. This project demonstrates how to use WebSocket communication in Flutter using a service class to handle Socket.IO connection, message listening, and sending.

---

## 🚀 Features

- 🔌 Real-time communication using Socket.IO
- 📲 Connect to individual chat rooms
- 📥 Receive messages with dynamic callbacks
- 📤 Send messages to a specific chat
- 🧼 Clean architecture using a reusable service class

---

## 📁 Project Structure

```
lib/
├── main.dart              # Entry point
├── home_screen.dart       # UI screen to test SocketService
└── socket_service.dart    # Socket.IO communication service
```

---

## 📸 Screenshots

_You can add your own screenshots here_

---

## ⚙️ How It Works

1. `SocketService` manages all socket connections.
2. It connects to the server and emits a `joinChat` event with the `chatId`.
3. You can register a message callback that will be called when a message is received.
4. You can send messages with `sendMessage()`.
5. You can disconnect the socket with `disconnect()`.

---

## 🧠 How to Use the `SocketService` in Your Code

### 1. ✅ Import the service:

```dart
import 'socket_service.dart';
```

### 2. 🔌 Connect to the server and join a chat room:

```dart
SocketService socketService = SocketService();
socketService.connect('chat_123'); // your chatId
```

### 3. 👂 Register a callback to receive messages:

```dart
socketService.registerMessageCallback('chat_123', (data) {
  print('📥 Message received: $data');
});
```

### 4. 📤 Send a message:

```dart
socketService.sendMessage('chat_123', {
  'text': 'Hello!',
  'sender': 'FlutterUser',
});
```

### 5. 🔌 Disconnect when not needed:

```dart
socketService.disconnect();
```

---

## 🧪 Example `home_screen.dart` Implementation

```dart
import 'package:flutter/material.dart';
import 'socket_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SocketService socketService = SocketService();

    // Connect and register callback
    socketService.connect('chat_123');
    socketService.registerMessageCallback('chat_123', (message) {
      print("📥 New Message: $message");
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Socket.IO Chat')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            socketService.sendMessage('chat_123', {
              'text': 'Hello from Flutter!',
              'sender': 'User',
            });
          },
          child: const Text('Send Message'),
        ),
      ),
    );
  }
}
```

---

## 🔧 Setup Instructions

### 1. Clone the Repo

```bash
git clone https://github.com/your-username/flutter-socket-chat.git
cd flutter-socket-chat
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Update Server Link

In `socket_service.dart`, replace:

```dart
socket = IO.io('add the server link', ...)
```

with:

```dart
socket = IO.io('http://your-server-url:port', <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': false,
});
```

### 4. Run the App

```bash
flutter run
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  socket_io_client: ^2.0.3+1
```

---

## 👨‍💻 Author

**Afaq Zahir**  
[LinkedIn](https://www.linkedin.com/in/afaqxdev) • [GitHub](https://github.com/afaqxdev) • [Email](mailto:afaqxdev@gmail.com)

---

## 🪪 License

This project is licensed under the [MIT License](LICENSE).

---

## 💡 Want More?

If you’d like:

- a working Node.js backend example for this app
- to expand this into a full chat UI
- Firebase + Socket.IO hybrid

Let me know! I'm happy to help.
