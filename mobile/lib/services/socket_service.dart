import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/chat_message.dart';
import '../controllers/matches_controller.dart';

class SocketService {
  io.Socket? _socket;
  final String _token;
  final String _userId;
  MatchesController? _controller;

  SocketService({required String token, required String userId})
      : _token = token,
        _userId = userId;

  void attach(MatchesController controller) {
    _controller = controller;
  }

  void connect(String baseUrl) {
    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': _token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      // Join current chat room if one is open
      final chatId = _controller?.chatId;
      if (chatId != null) joinChat(chatId);
    });

    _socket!.on('receive_message', (data) {
      if (data is! Map) return;
      final msg = ChatMessage.fromJson(
        Map<String, dynamic>.from(data as Map),
        _userId,
      );
      _controller?.addMessage(msg);
    });

    _socket!.on('message_sent', (data) {
      // Server confirmed our message — already shown optimistically, just ignore
    });

    _socket!.connect();
  }

  void joinChat(String chatId) {
    _socket?.emit('join_chat', chatId);
  }

  void sendMessage(String chatId, String text) {
    _socket?.emit('send_message', {'chatId': chatId, 'text': text});
  }

  void sendTyping(String chatId) {
    _socket?.emit('typing', chatId);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}