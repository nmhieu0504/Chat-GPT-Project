// ignore_for_file: avoid_print

import 'package:chat_gpt/chat_gpt_api/chat_gpt_ultis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
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

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  double _confidence = 1.0;

  _speak(String text) async {
    if (languages == TtsLanguage.vn) {
      await flutterTts.setLanguage("vi-VN");
    } else {
      await flutterTts.setLanguage("en-US");
    }
    flutterTts.setPitch(1.0);
    flutterTts.setVolume(1.0);
    await flutterTts.speak(text);
  }

  _stop() async {
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
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() {
        _isListening = false;
        isButtonDisabled = true;
        textFieldController.clear();

        // messageList.add(Message(
        //     message: textFieldController.text,
        //     date: DateTime.now(),
        //     isUser: true));
        // messageList.add(Message(
        //     message: textFieldController.text,
        //     date: DateTime.now(),
        //     isUser: false));
      });
      _speech.stop();
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
                onChanged: (value) {
                  setState(() {
                    isAutoTTS = value;
                  });
                }),
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
                            Navigator.pop(context);
                            setState(() {
                              languages = TtsLanguage.en;
                              isEnglish = true;
                              isVietnamese = false;
                            });
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
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              languages = TtsLanguage.vn;
                              isEnglish = false;
                              isVietnamese = true;
                            });
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
                    messageList.clear();
                    ChatGPTUltils.history.clear();
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
        itemBuilder: (context, message) {
          var isRequest =
              (messageList.length - 1 == messageList.indexOf(message)) &&
                  (messageList.elementAt(messageList.length - 2).message ==
                      message.message);

          return Row(children: [
            Expanded(
              flex: 9,
              child: Bubble(
                  elevation: 5,
                  margin: const BubbleEdges.only(
                    top: 5,
                    bottom: 5,
                  ),
                  alignment:
                      message.isUser ? Alignment.topRight : Alignment.topLeft,
                  nip: message.isUser ? BubbleNip.rightTop : BubbleNip.leftTop,
                  color: message.isUser ? Colors.blue : Colors.grey[100],
                  child: message.isUser
                      ? Text(
                          message.message,
                          style: const TextStyle(color: Colors.white),
                        )
                      : isRequest
                          ? !ChatGPTUltils.isProcessing
                              ? FutureBuilder<String?>(
                                  future: chatGPTUltils
                                      .getResponse(message.message),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      print(
                                          "message remove: ${messageList.last.message}");
                                      messageList.removeLast();
                                      messageList.add(Message(
                                          message: snapshot.data.toString(),
                                          date: DateTime.now(),
                                          isUser: false));
                                      print(
                                          "message last after remove: ${messageList.last.message}");
                                      if (isAutoTTS) {
                                        _speak(snapshot.data.toString());
                                      }
                                      Future.delayed(Duration.zero, () {
                                        setState(() {
                                          isButtonDisabled = false;
                                        });
                                      });
                                      return Text(
                                        snapshot.data.toString(),
                                        style: const TextStyle(
                                            color: Colors.black),
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
                              : Container()
                          : Text(
                              message.message,
                              style: const TextStyle(color: Colors.blue),
                            )),
            ),
            message.isUser
                ? Container()
                : Expanded(
                    flex: 1,
                    child: IconButton(
                        onPressed: () {
                          _speak(message.message);
                        },
                        icon: const Icon(Icons.play_circle_outline)),
                  )
          ]);
        },
      ),
    );
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
            icon: Icon(
              Icons.send,
              color: isButtonDisabled ? null : Colors.blue,
            ),
            onPressed: () {
              isButtonDisabled
                  ? null
                  : setState(() {
                      isButtonDisabled = true;
                      messageList.add(Message(
                          message: textFieldController.text,
                          date: DateTime.now(),
                          isUser: true));
                      messageList.add(Message(
                          // decoy message
                          message: textFieldController.text,
                          date: DateTime.now(),
                          isUser: false));
                    });
              textFieldController.clear();
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
