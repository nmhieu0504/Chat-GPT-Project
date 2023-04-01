class Message {
  final String message;
  final DateTime date;
  final bool isUser;

  const Message(
      {required this.message, required this.date, required this.isUser});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
        message: json['message'] as String,
        date: DateTime.parse(json['date'] as String),
        isUser: json['isUser'] as bool);
  }
}
