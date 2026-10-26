import 'dart:convert';

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
}

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderFirm;
  final String text;
  final DateTime timestamp;
  final bool isSystemMessage;
  final MessageStatus status;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderFirm,
    required this.text,
    required this.timestamp,
    this.isSystemMessage = false,
    this.status = MessageStatus.delivered,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'senderName': senderName,
    'senderFirm': senderFirm,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isSystemMessage': isSystemMessage,
    'status': status.name,
  };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => ChatMessageModel(
    id: json['id']?.toString() ?? '',
    conversationId: json['conversationId']?.toString() ?? '',
    senderId: json['senderId']?.toString() ?? '',
    senderName: json['senderName']?.toString() ?? 'Partner',
    senderFirm: json['senderFirm']?.toString() ?? 'Brokerage',
    text: json['text']?.toString() ?? '',
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
        : DateTime.now(),
    isSystemMessage: json['isSystemMessage'] == true,
    status: MessageStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => MessageStatus.delivered,
    ),
  );

  ChatMessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderFirm,
    String? text,
    DateTime? timestamp,
    bool? isSystemMessage,
    MessageStatus? status,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderFirm: senderFirm ?? this.senderFirm,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      status: status ?? this.status,
    );
  }
}

class ChatConversationModel {
  final String id;
  final String title;
  final bool isGroup;
  final String? description;
  final String creatorId;
  final List<String> participantIds;
  final List<String> adminIds;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderName;
  final int unreadCount;
  final int avatarColorIndex;
  final DateTime createdAt;

  ChatConversationModel({
    required this.id,
    required this.title,
    required this.isGroup,
    this.description,
    required this.creatorId,
    required this.participantIds,
    this.adminIds = const [],
    this.lastMessage,
    this.lastMessageTime,
    this.lastSenderName,
    this.unreadCount = 0,
    this.avatarColorIndex = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isGroup': isGroup,
    'description': description,
    'creatorId': creatorId,
    'participantIds': participantIds,
    'adminIds': adminIds,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime?.toIso8601String(),
    'lastSenderName': lastSenderName,
    'unreadCount': unreadCount,
    'avatarColorIndex': avatarColorIndex,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) => ChatConversationModel(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? 'Conversation',
    isGroup: json['isGroup'] == true,
    description: json['description']?.toString(),
    creatorId: json['creatorId']?.toString() ?? '',
    participantIds: (json['participantIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    adminIds: (json['adminIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    lastMessage: json['lastMessage']?.toString(),
    lastMessageTime: json['lastMessageTime'] != null
        ? DateTime.tryParse(json['lastMessageTime'].toString())
        : null,
    lastSenderName: json['lastSenderName']?.toString(),
    unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    avatarColorIndex: (json['avatarColorIndex'] as num?)?.toInt() ?? 0,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now(),
  );

  ChatConversationModel copyWith({
    String? id,
    String? title,
    bool? isGroup,
    String? description,
    String? creatorId,
    List<String>? participantIds,
    List<String>? adminIds,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastSenderName,
    int? unreadCount,
    int? avatarColorIndex,
    DateTime? createdAt,
  }) {
    return ChatConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isGroup: isGroup ?? this.isGroup,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      participantIds: participantIds ?? this.participantIds,
      adminIds: adminIds ?? this.adminIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastSenderName: lastSenderName ?? this.lastSenderName,
      unreadCount: unreadCount ?? this.unreadCount,
      avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
