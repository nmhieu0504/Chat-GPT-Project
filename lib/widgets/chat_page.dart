// ignore_for_file: avoid_print

import 'package:chat_gpt/chat_gpt_api/chat_gpt_ultis.dart';
import 'package:chat_gpt/model/db_ultils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/message.dart';
import 'package:bubble/bubble.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

enum TtsLanguage { en, vn }

class _ChatPageState extends State<ChatPage> {
  final textFieldController = TextEditingController();
  final ChatGPTUltils chatGPTUltils = ChatGPTUltils();
  List<Message> messageList = [];

  FlutterTts flutterTts = FlutterTts();
  TtsLanguage languages = TtsLanguage.en;
  late bool isEnglish;
  late bool isVietnamese;

  bool isAutoTTS = true;

  bool isButtonDisabled = ChatGPTUltils.isProcessing;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadMessage();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isAutoTTS = prefs.getBool('isAutoTTS') ?? true;
      isEnglish = prefs.getBool('isEnglish') ?? true;
      isVietnamese = prefs.getBool('isVietnamese') ?? false;
    });
    languages = isEnglish ? TtsLanguage.en : TtsLanguage.vn;
    flutterTts.setLanguage(isEnglish ? "en-US" : "vi-VN");
  }

  Future<void> _loadMessage() async {
    messageList = await DB_Ultils.loadAll();
    for (var element in messageList) {
      ChatGPTUltils.history.add({
        "role": element.isUser ? "user" : "assistant",
        "content": element.message
      });
    }
    setState(() {});
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            textFieldController.text = val.recognizedWords;
            // if (val.hasConfidenceRating && val.confidence > 0) {
            //   _confidence = val.confidence;
            // }
          }),
        );
      }
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const SizedBox(
            height: 120,
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
                activeColor: Colors.blue,
                value: isAutoTTS,
                onChanged: (value) async {
                  setState(() {
                    isAutoTTS = value;
                  });
                  // obtain shared preferences
                  final prefs = await SharedPreferences.getInstance();
                  // set value
                  prefs.setBool('isAutoTTS', value);
                }),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Speech Language'),
            onTap: () => showDialog<void>(
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
                          onTap: () async {
                            Navigator.pop(context);
                            setState(() {
                              languages = TtsLanguage.en;
                              isEnglish = true;
                              isVietnamese = false;
                            });
                            flutterTts.setLanguage("en-US");
                            // obtain shared preferences
                            final prefs = await SharedPreferences.getInstance();
                            // set value
                            prefs.setBool('isEnglish', isEnglish);
                            prefs.setBool('isVietnamese', isVietnamese);
                          },
                          child: ListTile(
                            leading: SizedBox(
                                width: 50,
                                height: 50,
                                child:
                                    Image.asset('assets/images/us_flag.png')),
                            title: const Text('English (United States)'),
                            trailing: isEnglish
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : null,
                          ),
                        ),
                      ),
                      Card(
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          splashColor: Colors.blue.withAlpha(30),
                          onTap: () async {
                            Navigator.pop(context);
                            setState(() {
                              languages = TtsLanguage.vn;
                              isEnglish = false;
                              isVietnamese = true;
                            });
                            flutterTts.setLanguage("vi-VN");
                            // obtain shared preferences
                            final prefs = await SharedPreferences.getInstance();
                            // set value
                            prefs.setBool('isEnglish', isEnglish);
                            prefs.setBool('isVietnamese', isVietnamese);
                          },
                          child: ListTile(
                            leading: SizedBox(
                                width: 50,
                                height: 50,
                                child:
                                    Image.asset('assets/images/vn_flag.png')),
                            title: const Text('Vietnamese'),
                            trailing: isVietnamese
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Close',
                            style: TextStyle(color: Colors.blue)),
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
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete all messages'),
                          content: const Text('This action cannot be undone. '
                              'Do you want to continue?'),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                textStyle:
                                    Theme.of(context).textTheme.labelLarge,
                              ),
                              child: const Text(
                                'Ok',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 16),
                              ),
                              onPressed: () {
                                setState(() {
                                  messageList.clear();
                                  ChatGPTUltils.history.clear();
                                });
                                DB_Ultils.deleteAll();
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                textStyle:
                                    Theme.of(context).textTheme.labelLarge,
                              ),
                              child: const Text('Cancel',
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 16)),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  });
                },
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red)),
                child: const Text('Delete all messages')),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageListView() {
    return Expanded(
      child: GroupedListView<Message, DateTime>(
        // order: GroupedListOrder.DESC,
        // reverse: true,
        addAutomaticKeepAlives: true,
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
        indexedItemBuilder: (context, message, index) {
          return message.isUser
              ? Bubble(
                  elevation: 5,
                  margin: const BubbleEdges.only(
                    top: 5,
                    bottom: 5,
                  ),
                  alignment: Alignment.topRight,
                  nip: BubbleNip.rightTop,
                  color: Colors.blue,
                  child: Text(
                    message.message,
                    style: const TextStyle(color: Colors.white),
                  ))
              : Row(children: [
                  Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    child: Bubble(
                        elevation: 5,
                        margin: const BubbleEdges.only(
                          top: 5,
                          bottom: 5,
                        ),
                        alignment: Alignment.topLeft,
                        nip: BubbleNip.leftTop,
                        color: Colors.grey[100],
                        child: Text(
                          message.message,
                          style: const TextStyle(color: Colors.black),
                        )),
                  ),
                  IconButton(
                      onPressed: () {
                        setState(() {
                          message.state = !message.state;
                          if (message.state) {
                            for (var i = 0; i < messageList.length; i++) {
                              if (i != index) {
                                messageList[i].state = false;
                              }
                            }
                            flutterTts.speak(message.message);
                            flutterTts.setCompletionHandler(() {
                              setState(() {
                                message.state = false;
                              });
                            });
                          } else {
                            flutterTts.stop();
                          }
                        });
                      },
                      icon: message.state
                          ? LoadingAnimationWidget.beat(
                              color: Colors.blue,
                              size: 20,
                            )
                          : const Icon(
                              Icons.play_circle_outline,
                              color: Colors.blue,
                            ))
                ]);
        },
      ),
    );
  }

  Future<void> _sendRequest(String message) async {
    textFieldController.clear();
    String result = await chatGPTUltils.getResponse(message);
    int idx = messageList.length;
    if (isAutoTTS) {
      flutterTts.speak(result);
      flutterTts.setCompletionHandler(() {
        setState(() {
          messageList[idx].state = false;
        });
      });
    }
    setState(() {
      messageList.add(Message(
          message: result,
          date: DateTime.now(),
          isUser: false,
          state: isAutoTTS));
      isButtonDisabled = false;
    });
    DB_Ultils.insertMessage(
        Message(message: result, date: DateTime.now(), isUser: false));
  }

  Widget _buildInputMessage() {
    return Container(
      margin: const EdgeInsets.fromLTRB(30, 15, 30, 15),
      child: Theme(
        data: ThemeData(
          primaryColor: Colors.blue,
          primaryColorDark: Colors.blue,
        ),
        child: TextField(
          cursorColor: Colors.blue,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          decoration: InputDecoration(
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(40.0))),
            hintText: "Start typing or talking ...",
            contentPadding:
                const EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
            suffixIcon: IconButton(
              icon: !isButtonDisabled
                  ? const Icon(
                      Icons.send,
                      color: Colors.blue,
                    )
                  : LoadingAnimationWidget.discreteCircle(
                      color: Colors.blue,
                      size: 20,
                    ),
              onPressed: () {
                String text = textFieldController.text;
                setState(() {
                  isButtonDisabled = true;
                  messageList.add(Message(
                      message: text, date: DateTime.now(), isUser: true));
                });
                DB_Ultils.insertMessage(
                    Message(message: text, date: DateTime.now(), isUser: true));
                _sendRequest(text);
              },
            ),
          ),
          controller: textFieldController,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: SingleChildScrollView(
        child: Column(children: [
          AvatarGlow(
            animate: _isListening,
            glowColor: Theme.of(context).primaryColor,
            endRadius: 50.0,
            duration: const Duration(milliseconds: 2000),
            repeatPauseDuration: const Duration(milliseconds: 100),
            repeat: true,
            child: SizedBox(
              height: 80.0,
              width: 80.0,
              child: ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.blue)),
                onPressed: _listen,
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Text(
            _isListening ? "Listening..." : "Tap to Talk",
            style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 18,
                color: Colors.blue[600]),
          )
        ]),
      ),
    );
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
          centerTitle: true,
          title: const Text("Chat",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ))),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(children: [
          _buildMessageListView(),
          _buildInputMessage(),
        ]),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
