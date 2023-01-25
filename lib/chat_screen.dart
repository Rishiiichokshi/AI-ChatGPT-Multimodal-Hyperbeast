import 'dart:async';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:chatgpt_3/threedots.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

import 'chatmessage.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _controller = TextEditingController();
  List<ChatMessage> _messages = [];
  ChatGPT? chatGPT;
  bool _isImageSearch = false;

  StreamSubscription? _subscription;
  bool _isTyping = false;

  @override
  void initState() {
    chatGPT = ChatGPT.instance
        .builder("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");
    super.initState();
  }

  @override
  void dispose() {
    chatGPT!.genImgClose();
    _subscription?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    ChatMessage message = ChatMessage(
      text: _controller.text,
      sender: "user",
      isImage: false,
    );

    setState(() {
      _messages.insert(0, message);
      _isTyping = true;
    });

    _controller.clear();
    if (_isImageSearch) {
      final request = GenerateImage(message.text, 1, size: "256x256");
      _subscription = chatGPT!
          .generateImageStream(request)
          .asBroadcastStream()
          .listen((response) {
        Vx.log(response.data!.last!.url!);
        insertNewData(response.data!.last!.url!, isImage: true);
      });
    } else {
      //The max_tokens parameter is used to specify the maximum
      // number of tokens (words or word pieces) that the model
      // should generate in its response.
      final request = CompleteReq(
        prompt: message.text,
        model: kTranslateModelV3,
        max_tokens: 1024,
        temperature: 0.9,
      );

      _subscription = chatGPT
          ?.onCompleteStream(request: request)
          .asBroadcastStream()
          .listen((response) {
        Vx.log(response!.choices[0].text);
        insertNewData(response.choices[0].text, isImage: false);
      });
    }
  }

  void insertNewData(String response, {bool isImage = false}) {
    ChatMessage botMessage = ChatMessage(
      text: response,
      sender: "bot",
      isImage: isImage,
    );

    setState(() {
      _isTyping = false;
      _messages.insert(0, botMessage);
    });
  }

  Widget _buildTextComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: (value) => _sendMessage(),
            decoration:
                InputDecoration.collapsed(hintText: "Question/Description"),
          ),
        ),
        ButtonBar(
          children: [
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                _isImageSearch = false;
                _sendMessage();
              },
            ),
            TextButton(
              onPressed: () {
                _isImageSearch = true;
                _sendMessage();
              },
              child: const Text('Generate Image'),
            ),
          ],
        ),
      ],
    ).px16();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('The AI Hyperbeast'),
      ),
      body: SafeArea(
        child: Column(children: [
          Flexible(
            child: ListView.builder(
              reverse: true,
              padding: Vx.m8,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          if (_isTyping) const ThreeDots(),
          const Divider(
            height: 1.0,
          ),
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
            ),
            child: _buildTextComposer(),
          )
        ]),
      ),
    );
  }
}
