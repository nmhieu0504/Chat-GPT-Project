// ignore_for_file: avoid_print

import 'package:chat_gpt/chat_gpt_api/chat_gpt_ultis.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import '../model/message.dart';
import 'package:bubble/bubble.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final textFieldController = TextEditingController();
  final ChatGPTUltils chatGPTUltils = ChatGPTUltils();
  List<Message> messageList = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        title: const Text("Chat with OpenAI",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const SizedBox(
              height: 100,
              child: DrawerHeader(
                decoration: BoxDecoration(
                    // color: Colors.blue,
                    ),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    // color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
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
                            child: ListTile(
                              leading: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child:
                                      Image.asset('assets/images/us_flag.png')),
                              title: const Text('English (United States)'),
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
                            child: ListTile(
                              leading: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child:
                                      Image.asset('assets/images/vn_flag.png')),
                              title: const Text('Vietnamese'),
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
                  onPressed: () {
                    setState(() {
                      messageList.clear();
                      ChatGPTUltils.history.clear();
                    });
                  },
                  child: const Text('Delete all messages')),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: GroupedListView<Message, DateTime>(
              // order: GroupedListOrder.DESC,
              // reverse: true,
              // floatingHeader: true,
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
              itemBuilder: (context, message) {
                var isLastIndex =
                    messageList.length - 1 == messageList.indexOf(message);

                return Bubble(
                    margin: const BubbleEdges.only(top: 5, bottom: 5),
                    alignment: message.isUser
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    nip:
                        message.isUser ? BubbleNip.rightTop : BubbleNip.leftTop,
                    color: message.isUser ? Colors.blue : Colors.grey[100],
                    child: message.isUser
                        ? Text(
                            message.message,
                            style: const TextStyle(color: Colors.white),
                          )
                        : isLastIndex
                            ? FutureBuilder<String?>(
                                future:
                                    chatGPTUltils.getResponse(message.message),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data.toString() !=
                                          messageList.last.message) {
                                    messageList.removeLast();
                                    messageList.add(Message(
                                        message: snapshot.data.toString(),
                                        date: DateTime.now(),
                                        isUser: false));
                                    return Text(
                                      snapshot.data.toString(),
                                      style:
                                          const TextStyle(color: Colors.black),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Text("${snapshot.error}");
                                  }
                                  return LoadingAnimationWidget.waveDots(
                                    color: Colors.blue,
                                    size: 20,
                                  );
                                },
                              )
                            : Text(
                                message.message,
                                style: const TextStyle(color: Colors.black),
                              ));
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(30, 30, 30, 15),
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
                textFieldController.clear();
                setState(() {
                  messageList.add(Message(
                      message: value, date: DateTime.now(), isUser: true));
                  messageList.add(Message(
                      // decoy message
                      message: value,
                      date: DateTime.now(),
                      isUser: false));
                });
              },
            ),
          )
        ]),
      ),
      bottomNavigationBar: Container(
        width: 90,
        height: 90,
        margin: const EdgeInsets.all(10),
        child: Column(children: [
          IconButton(
              onPressed: () {},
              style: ButtonStyle(
                shape: MaterialStateProperty.all(const CircleBorder()),
                padding: MaterialStateProperty.all(const EdgeInsets.all(20)),
                backgroundColor:
                    MaterialStateProperty.all(Colors.blue), // <-- Button color
              ),
              icon: const Icon(
                Icons.mic_outlined,
                color: Colors.white,
              )),
          const Text(
            "Tap to Talk",
            style: TextStyle(
                fontStyle: FontStyle.italic, fontSize: 18, color: Colors.black),
          )
        ]),
      ),
    );
  }
}
