import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'dart:convert';
import 'dart:typed_data';
import 'media_handlers.dart';
import 'chat_input_controller_widget.dart';

class FloatingChatBox extends StatefulWidget {
  final String memberName;
  final String currentUserName;
  final List<Map<String, dynamic>> messages;
  final bool isMinimized;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final Function(String, bool, bool) onSend; // text, isImage, isVoice
  final VoidCallback onPickImage;

  const FloatingChatBox({
    super.key,
    required this.memberName,
    required this.currentUserName,
    required this.messages,
    required this.isMinimized,
    required this.onClose,
    required this.onMinimize,
    required this.onSend,
    required this.onPickImage,
  });

  @override
  State<FloatingChatBox> createState() => _FloatingChatBoxState();
}

class _FloatingChatBoxState extends State<FloatingChatBox> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ap.AudioPlayer _voicePlayer = ap.AudioPlayer();
  
  String? _currentlyPlayingVoiceUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant FloatingChatBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _voicePlayer.dispose();
    super.dispose();
  }

  Future<void> _playVoiceMessage(String voicePath) async {
    try {
      if (_currentlyPlayingVoiceUrl == voicePath) {
        await _voicePlayer.stop();
        setState(() {
          _currentlyPlayingVoiceUrl = null;
        });
        return;
      }

      if (voicePath.startsWith('data:audio')) {
        final base64Str = voicePath.split(',').last;
        final bytes = base64Decode(base64Str);
        await _voicePlayer.play(ap.BytesSource(bytes));
      } else {
        await _voicePlayer.play(ap.UrlSource(voicePath));
      }

      setState(() {
        _currentlyPlayingVoiceUrl = voicePath;
      });

      _voicePlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            if (_currentlyPlayingVoiceUrl == voicePath) {
              _currentlyPlayingVoiceUrl = null;
            }
          });
        }
      });
    } catch (e) {
      debugPrint("خطأ تشغيل الصوت الخاص: $e");
      setState(() {
        _currentlyPlayingVoiceUrl = null;
      });
    }
  }

  void _sendTextMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      widget.onSend(_messageController.text.trim(), false, false);
      _messageController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMinimized) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenSize.height * 0.6,
        maxWidth: screenSize.width > 500 ? 380 : screenSize.width * 0.92,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط العنوان العلوي للشات الخاص مع تصميم واضح جداً لزر التصغير
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.purple.shade700,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // أزرار التصغير والإغلاق على اليمين بتصميم بارز
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.remove, color: Colors.black, size: 16),
                        onPressed: widget.onMinimize,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        tooltip: 'تصغير',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onPressed: widget.onClose,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        tooltip: 'إغلاق',
                      ),
                    ),
                  ],
                ),
                // اسم الشخص والأيقونة على اليسار
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 170,
                      child: Text(
                        widget.memberName, 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chat_bubble, color: Colors.white, size: 14),
                  ],
                ),
              ],
            ),
          ),
          
          // محتوى الرسائل
          Flexible(
            child: Container(
              color: Colors.grey.shade100,
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: widget.messages.length,
                itemBuilder: (context, index) {
                  final msg = widget.messages[index];
                  final isMe = msg['sender'] == widget.currentUserName;
                  final bool isVoice = msg['isVoice'] == true;
                  final String textVal = msg['text'] ?? "";
                  final bool isPlayingThis = (_currentlyPlayingVoiceUrl == textVal);

                  var timestamp = msg['timestamp'] as Timestamp?;
                  String dateStr = 'منذ قليل';
                  if (timestamp != null) {
                    DateTime dt = timestamp.toDate();
                    String hour = dt.hour > 12 ? '${dt.hour - 12}' : '${dt.hour == 0 ? 12 : dt.hour}';
                    String minute = dt.minute.toString().padLeft(2, '0');
                    String period = dt.hour >= 12 ? 'م' : 'ص';
                    dateStr = '${dt.year}/${dt.month}/${dt.day} - $hour:$minute $period';
                  }

                  return Align(
                    alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(maxWidth: 240),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.purple.shade700 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 1)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          isVoice
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isPlayingThis ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                        color: Colors.greenAccent,
                                        size: 26,
                                      ),
                                      onPressed: () => _playVoiceMessage(textVal),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isPlayingThis ? "جاري التشغيل... 🔊" : "تسجيل صوتي 🎤",
                                      style: TextStyle(fontSize: 12, color: isMe ? Colors.white : Colors.black87),
                                    ),
                                  ],
                                )
                              : (msg['isImage'] == true
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: InkWell(
                                        onTap: () => MediaHandlers.showImageDialog(context, base64Decode(textVal.split(',').last)),
                                        child: Image.memory(
                                          base64Decode(textVal.split(',').last),
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : Text(textVal, style: TextStyle(fontSize: 13, color: isMe ? Colors.white : Colors.black87))),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              dateStr,
                              style: TextStyle(fontSize: 9, color: isMe ? Colors.white60 : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // شريط الإدخال السفلي للشات الخاص
          ChatInputControllerWidget(
            textController: _messageController,
            onSendText: _sendTextMessage,
            onPickImage: widget.onPickImage,
            onSendVoice: (audioData) {
              widget.onSend(audioData, false, true);
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            },
          ),
        ],
      ),
    );
  }
}