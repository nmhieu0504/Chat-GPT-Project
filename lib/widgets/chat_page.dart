import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import '../model/message.dart';
import 'package:bubble/bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final textFieldController = TextEditingController();
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
        message: "ghdefabci",
        date: DateTime.now().subtract(const Duration(days: 3, minutes: 3)),
        isUser: true),
    Message(
        message: "jkdefabcl",
        date: DateTime.now().subtract(const Duration(days: 4, minutes: 4)),
        isUser: false),
    Message(
        message: "mndefabco",
        date: DateTime.now().subtract(const Duration(days: 5, minutes: 5)),
        isUser: true),
    Message(
        message: "pdefabcqr",
        date: DateTime.now().subtract(const Duration(days: 6, minutes: 6)),
        isUser: false),
    Message(
        message: "stdefabcu",
        date: DateTime.now().subtract(const Duration(days: 6, minutes: 7)),
        isUser: true),
    Message(
        message: "vdefabcwx",
        date: DateTime.now().subtract(const Duration(days: 6, minutes: 8)),
        isUser: false),
    Message(
        message: "yvdefabcz",
        date: DateTime.now().subtract(const Duration(days: 8, minutes: 9)),
        isUser: true),
  ].reversed.toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Chat GPT"),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Drawer Header',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Auto TTS reply'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Speech Language'),
                onTap: () => showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => Dialog(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Card(
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              splashColor: Colors.blue.withAlpha(30),
                              onTap: () {
                                debugPrint('Card tapped.');
                              },
                              child: Card(
                                child: ListTile(
                                  leading: SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: Image.asset(
                                          'assets/images/us_flag.png')),
                                  title: const Text('English (United States)'),
                                ),
                              ),
                            ),
                          ),
                          Card(
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              splashColor: Colors.blue.withAlpha(30),
                              onTap: () {
                                debugPrint('Card tapped.');
                              },
                              child: Card(
                                child: ListTile(
                                  leading: SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: Image.asset(
                                          'assets/images/vn_flag.png')),
                                  title: const Text('Vietnamese'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(20),
                child: FilledButton(
                    onPressed: () {}, child: const Text('Delete all messages')),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: GroupedListView<Message, DateTime>(
                order: GroupedListOrder.DESC,
                reverse: true,
                floatingHeader: true,
                padding: const EdgeInsets.all(10),
                elements: messageList,
                groupBy: (message) => DateTime(
                  message.date.year,
                  message.date.month,
                  message.date.day,
                ),
                groupHeaderBuilder: (Message message) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(DateFormat.yMMMMEEEEd().format(message.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11.0)),
                  ),
                ),
                itemBuilder: (context, message) => Bubble(
                    margin: const BubbleEdges.only(top: 5, bottom: 5),
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    nip:
                        message.isUser ? BubbleNip.rightTop : BubbleNip.leftTop,
                    color: message.isUser ? Colors.blue : Colors.grey,
                    child: Text(
                      message.message,
                      style: const TextStyle(color: Colors.white),
                    )),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(30),
              child: TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40.0))),
                  hintText: "Typing something ...",
                  contentPadding:
                      EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
                ),
                controller: textFieldController,
                onSubmitted: (value) {
                  final message = Message(
                      message: value, date: DateTime.now(), isUser: true);
                  textFieldController.clear();
                  setState(() => messageList.add(message));
                },
              ),
            )
          ]),
        ),
        bottomNavigationBar: const BottomAppBar(
          shape: CircularNotchedRectangle(),
        ));
  }
}
