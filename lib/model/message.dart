class Message {
  final String message;
  final DateTime date;
  final bool isUser;
  bool state;

  Message({required this.message, required this.date, required this.isUser, this.state = false});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
        message: json['message'] as String,
        date: DateTime.parse(json['date'] as String),
        isUser: json['isUser'] as bool);
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'date': date.toIso8601String(),
      'isUser': isUser ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'Message{message: $message, date: $date, isUser: $isUser}';
  }
}
