// ignore_for_file: avoid_debugPrint

import 'package:chat_gpt/chat_gpt_api/api_const.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatGPTUltils {
  final int tokenRemainingLimt = 1000;
  static int totalTokens = 0;
  static List<Map<String, String>> history = [];
  static OpenAI openAI = OpenAI.instance.build(
      token: API_Const.API_KEY,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 60)));
  static bool isProcessing = false;

  static final ChatGPTUltils _chatGPTUltils = ChatGPTUltils._internal();
  ChatGPTUltils._internal();
  factory ChatGPTUltils() => _chatGPTUltils;

  Future<String> getResponse(String inputMessage) async {
    var pref = await SharedPreferences.getInstance();

    if (API_Const.MAX_TOKEN - totalTokens <= tokenRemainingLimt) {
      debugPrint("Eleminating history: ${history[0]["content"]}");
      history.removeAt(0);
      debugPrint("Eleminating history: ${history[0]["content"]}");
      history.removeAt(0);
    }

    try {
      isProcessing = true;
      debugPrint("Message enter: $inputMessage \nMessage processing...");
      history.add({"role": "user", "content": inputMessage});

      final request = ChatCompleteText(
          model: API_Const.CHAT_GPT_TURBO_MODEL,
          maxToken: API_Const.MAX_TOKEN - totalTokens,
          messages: history);

      final response = await openAI.onChatCompletion(request: request);

      if (response != null) {
        debugPrint("PromptTokens: ${response.usage.promptTokens}");
        debugPrint("CompletionTokens: ${response.usage.completionTokens}");
        debugPrint("TotalTokens: ${response.usage.totalTokens}");
        totalTokens = response.usage.totalTokens;
        pref.setInt("totalTokens", totalTokens);

        var botMessage = response.choices[0].message.content;
        history.add({"role": "assistant", "content": botMessage});

        debugPrint("Message received: $botMessage");
        isProcessing = false;
        return botMessage;
      }
    } catch (err) {
      debugPrint(err.toString());
    }
    return "Since we are using free API key of Open AI Service, its token might be used up. Please delete all history and try again!";
  }
}
