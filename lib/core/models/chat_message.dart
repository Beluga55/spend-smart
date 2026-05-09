/// A single message in the AI chat conversation.
class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  /// Optional structured action data when the AI wants to create something.
  final ChatAction? action;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.action,
  });

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? timestamp,
    ChatAction? action,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'action': action?.toJson(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    role: ChatRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => ChatRole.assistant,
    ),
    content: json['content'] as String,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    action: json['action'] != null
        ? ChatAction.fromJson(json['action'] as Map<String, dynamic>)
        : null,
  );
}

enum ChatRole { user, assistant, system }

/// Structured action the AI wants the app to perform.
class ChatAction {
  final String type; // 'create_expense', 'create_income', 'create_category'
  final Map<String, dynamic> data;

  const ChatAction({
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
  };

  factory ChatAction.fromJson(Map<String, dynamic> json) => ChatAction(
    type: json['type'] as String,
    data: Map<String, dynamic>.from(json['data'] as Map),
  );
}
