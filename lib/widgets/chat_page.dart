import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import '../model/message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Message> messageList = [
    Message(
        message: "abcabcabcabc",
        date: DateTime.now().subtract(const Duration(days: 1, minutes: 1)),
        isUser: true),
    Message(
        message: "defabcabc",
        date: DateTime.now().subtract(const Duration(days: 3, minutes: 2)),
        isUser: false),
    Message(
        message: "ghi",
        date: DateTime.now().subtract(const Duration(days: 3, minutes: 3)),
        isUser: true),
    Message(
        message: "jkl",
        date: DateTime.now().subtract(const Duration(days: 4, minutes: 4)),
        isUser: false),
    Message(
        message: "mno",
        date: DateTime.now().subtract(const Duration(days: 5, minutes: 5)),
        isUser: true),
    Message(
        message: "pqr",
        date: DateTime.now().subtract(const Duration(days: 6, minutes: 6)),
        isUser: false),
    Message(
        message: "stu",
        date: DateTime.now().subtract(const Duration(days: 6, minutes: 7)),
        isUser: true),
    Message(
        message: "vwx",
        date: DateTime.now().subtract(const Duration(days: 6, minutes: 8)),
        isUser: false),
    Message(
        message: "yz",
        date: DateTime.now().subtract(const Duration(days: 8, minutes: 9)),
        isUser: true),
  ].reversed.toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Chat GPT"),
        ),
        body: SafeArea(
          child: Column(children: [
            Expanded(
                child: GroupedListView<Message, DateTime>(
              reverse: true,
              order: GroupedListOrder.DESC,
              useStickyGroupSeparators: true,
              floatingHeader: true,
              padding: const EdgeInsets.all(10),
              elements: messageList,
              groupBy: (message) => DateTime(
                message.date.year,
                message.date.month,
                message.date.day,
              ),
              groupHeaderBuilder: (Message message) => SizedBox(
                  height: 40,
                  child: Center(
                      child: Card(
                          color: Theme.of(context).primaryColor,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              DateFormat.yMMMd().format(message.date),
                              style: const TextStyle(color: Colors.white),
                            ),
                          )))),
              itemBuilder: (context, message) => Align(
                alignment: message.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: message.isUser ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message.message,
                      style: const TextStyle(color: Colors.white),
                    )),
              ),
            )),
            Container(
              color: Colors.grey.shade300,
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Enter a message",
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            )
          ]),
        ));
  }
}
