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

enum TtsState { playing, stopped }

enum TtsLanguage { en, vn }

class _ChatPageState extends State<ChatPage> {
  final textFieldController = TextEditingController();
  final ChatGPTUltils chatGPTUltils = ChatGPTUltils();
  List<Message> messageList = [];

  FlutterTts flutterTts = FlutterTts();
  TtsLanguage languages = TtsLanguage.en;
  bool isEnglish = true;
  bool isVietnamese = false;

  bool isAutoTTS = true;

  bool isButtonDisabled = ChatGPTUltils.isProcessing;
  bool isSpeaking = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isAutoTTS = prefs.getBool('isAutoTTS') ?? true;
      isEnglish = prefs.getBool('isEnglish') ?? false;
      isVietnamese = prefs.getBool('isVietnamese') ?? false;
    });
    languages = isEnglish ? TtsLanguage.en : TtsLanguage.vn;
  }

  Future _speak(String text) async {
    if (languages == TtsLanguage.vn) {
      await flutterTts.setLanguage("vi-VN");
    } else {
      await flutterTts.setLanguage("en-US");
    }
    flutterTts.setPitch(1.0);
    flutterTts.setVolume(1.0);
    await flutterTts.speak(text);
    var isDoneSpeaking = await flutterTts.awaitSpeakCompletion(true);
    if (isDoneSpeaking == 1) {
      setState(() {
        isSpeaking = false;
      });
    }
  }

  _stop() async {
    setState(() {
      isSpeaking = false;
    });
    await flutterTts.stop();
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
      var message = textFieldController.text;
      textFieldController.clear();
      _speech.stop();
      // DB_Ultils.insertMessage(
      //     Message(message: message, date: DateTime.now(), isUser: true));
      setState(() {
        _isListening = false;
        isButtonDisabled = true;
        messageList
            .add(Message(message: message, date: DateTime.now(), isUser: true));
      });
      _sendRequest(message);
    }
  }

  Widget _buildDrawer() {
    return Drawer(
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
                value: isAutoTTS,
                onChanged: (value) async {
                  setState(() {
                    isAutoTTS = value;
                  });
                  // obtain shared preferences
                  final prefs = await SharedPreferences.getInstance();
                  // set value
                  await prefs.setBool('isAutoTTS', value);
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
                            // obtain shared preferences
                            final prefs = await SharedPreferences.getInstance();
                            // set value
                            await prefs.setBool('isEnglish', isEnglish);
                            await prefs.setBool('isVietnamese', isVietnamese);
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

                            // obtain shared preferences
                            final prefs = await SharedPreferences.getInstance();
                            // set value
                            await prefs.setBool('isEnglish', isEnglish);
                            await prefs.setBool('isVietnamese', isVietnamese);
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
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete all messages?'),
                          content: const Text('This action cannot be undone, '
                              'are you sure you want to continue?'),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                textStyle:
                                    Theme.of(context).textTheme.labelLarge,
                              ),
                              child: const Text('Yes',
                                  style: TextStyle(color: Colors.red)),
                              onPressed: () {
                                setState(() {
                                  messageList.clear();
                                  ChatGPTUltils.history.clear();
                                });
                                // DB_Ultils.deleteAll();
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                textStyle:
                                    Theme.of(context).textTheme.labelLarge,
                              ),
                              child: const Text('No'),
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
                  Expanded(
                    flex: 9,
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
                  Expanded(
                    flex: 1,
                    child: IconButton(
                        onPressed: () {
                          setState(() {
                            message.state = !message.state;
                            // if (isPlaying) {
                            //   isPlaying = false;
                            //   _stop();
                            // } else {
                            //   if (isSpeaking) {
                            //     _stop();
                            //     isPlaying = true;
                            //     isSpeaking = true;
                            //     _speak(message);
                            //   } else {
                            //     isPlaying = true;
                            //     isSpeaking = true;
                            //     _speak(message);
                            //   }
                            // }
                          });
                          // if (message.state) {
                          //   _speak(message.message);
                          // } else {
                          //   _stop();
                          // }
                        },
                        icon: message.state
                            ? LoadingAnimationWidget.beat(
                                color: Colors.blue,
                                size: 20,
                              )
                            : const Icon(
                                Icons.play_circle_outline,
                                color: Colors.blue,
                              )),
                  )
                ]);
        },
      ),
    );
  }

  Future<void> _sendRequest(String message) async {
    String result = await chatGPTUltils.getResponse(message);
    setState(() {
      messageList
          .add(Message(message: result, date: DateTime.now(), isUser: false));
      isButtonDisabled = false;
    });
  }

  Widget _buildInputMessage() {
    return Container(
      margin: const EdgeInsets.fromLTRB(30, 15, 30, 15),
      child: TextField(
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
              textFieldController.clear();
              setState(() {
                isButtonDisabled = true;
                messageList.add(
                    Message(message: text, date: DateTime.now(), isUser: true));
              });
              _sendRequest(text);
              // DB_Ultils.insertMessage(Message(
              //     message: textFieldController.text,
              //     date: DateTime.now(),
              //     isUser: true));
            },
          ),
        ),
        controller: textFieldController,
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      width: 110,
      height: 110,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Column(children: [
        AvatarGlow(
          animate: _isListening,
          glowColor: Theme.of(context).primaryColor,
          endRadius: 40.0,
          duration: const Duration(milliseconds: 2000),
          repeatPauseDuration: const Duration(milliseconds: 100),
          repeat: true,
          child: FloatingActionButton(
            backgroundColor: Colors.blue,
            onPressed: _listen,
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          "Tap to Talk",
          style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 18,
              color: Colors.blue[600]),
        )
      ]),
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
        title: const Text("Chat",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
      ),
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
}
