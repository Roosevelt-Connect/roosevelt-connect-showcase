// Excerpt from Roosevelt Connect (lib/pages/students/model/messages.dart).
// Lightly trimmed for the showcase; school-specific identifiers replaced. Full source is private.

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;

  Message({required this.senderId, required this.senderEmail, required this.message, required this.receiverId, required this.timestamp});

  Map <String, dynamic> toMap() {
    return {
      'senderId' : senderId,
      'senderEmail' : senderEmail,
      'receiverId' : receiverId,
      'message' : message,
      'timestamp' : timestamp,
    };
  }
}