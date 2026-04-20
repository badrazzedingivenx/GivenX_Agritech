class ChatMessage {
  final int? id;
  final int senderId;
  final String senderName;
  final int receiverId;
  final String receiverName;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessage({
    this.id,
    required this.senderId,
    this.senderName = '',
    required this.receiverId,
    this.receiverName = '',
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int?,
      senderId: json['senderId'] as int? ?? 0,
      senderName: json['senderName'] as String? ?? '',
      receiverId: json['receiverId'] as int? ?? 0,
      receiverName: json['receiverName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'content': content,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ChatMessage copyWith({
    int? id,
    int? senderId,
    String? senderName,
    int? receiverId,
    String? receiverName,
    String? content,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'ChatMessage(id: $id, from: $senderId, to: $receiverId)';
}
