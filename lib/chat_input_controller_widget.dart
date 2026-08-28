import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class ChatInputControllerWidget extends StatefulWidget {
  final TextEditingController textController;
  final VoidCallback onSendText;
  final VoidCallback onPickImage;
  final Function(String) onSendVoice;

  const ChatInputControllerWidget({
    super.key,
    required this.textController,
    required this.onSendText,
    required this.onPickImage,
    required this.onSendVoice,
  });

  @override
  State<ChatInputControllerWidget> createState() => _ChatInputControllerWidgetState();
}

class _ChatInputControllerWidgetState extends State<ChatInputControllerWidget> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ap.AudioPlayer _voicePlayer = ap.AudioPlayer();
  final FocusNode _textFieldFocusNode = FocusNode();
  
  bool _isRecording = false;
  String? _recordedPath;
  bool _isPlayingPreview = false;

  @override
  void dispose() {
    _audioRecorder.dispose();
    _voicePlayer.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _recordedPath = path;
        });
      } else {
        if (await _audioRecorder.hasPermission()) {
          String path = '';
          if (!kIsWeb) {
            final dir = await getTemporaryDirectory();
            path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          }
          await _audioRecorder.start(const RecordConfig(), path: path);
          setState(() {
            _isRecording = true;
            _recordedPath = null;
          });
        }
      }
    } catch (e) {
      debugPrint("خطأ في التسجيل: $e");
      setState(() => _isRecording = false);
    }
  }

  Future<void> _previewAudio() async {
    if (_recordedPath != null) {
      try {
        if (_isPlayingPreview) {
          await _voicePlayer.stop();
          if (mounted) setState(() => _isPlayingPreview = false);
        } else {
          if (mounted) setState(() => _isPlayingPreview = true);
          if (kIsWeb) {
            await _voicePlayer.play(ap.UrlSource(_recordedPath!));
          } else {
            await _voicePlayer.play(ap.DeviceFileSource(_recordedPath!));
          }
          _voicePlayer.onPlayerComplete.listen((_) {
            if (mounted) setState(() => _isPlayingPreview = false);
          });
        }
      } catch (e) {
        debugPrint("خطأ في معاينة الصوت: $e");
        if (mounted) setState(() => _isPlayingPreview = false);
      }
    }
  }

  void _discardAudio() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
    } catch (_) {}
    await _voicePlayer.stop();
    setState(() {
      _recordedPath = null;
      _isPlayingPreview = false;
      _isRecording = false;
    });
  }

  Future<void> _sendAudio() async {
    if (_recordedPath != null) {
      try {
        String audioData = _recordedPath!;
        if (!kIsWeb) {
          final bytes = await File(_recordedPath!).readAsBytes();
          audioData = 'data:audio/aac;base64,${base64Encode(bytes)}';
        }
        widget.onSendVoice(audioData);
        _discardAudio();
      } catch (e) {
        debugPrint("خطأ في إرسال الصوت: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: _recordedPath != null
          ? Row(
              children: [
                IconButton(
                  icon: Icon(_isPlayingPreview ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.green, size: 26),
                  onPressed: _previewAudio,
                ),
                const Expanded(
                  child: Text("تم تسجيل الصوت بنجاح 🎙️", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                  onPressed: _discardAudio,
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purple, size: 24),
                  onPressed: _sendAudio,
                ),
              ],
            )
          : Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.purple, size: 22),
                  onPressed: widget.onPickImage,
                ),
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording ? Colors.white : Colors.purple,
                    size: 22,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : Colors.purple.shade50,
                  ),
                  onPressed: _toggleRecording,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: widget.textController,
                      focusNode: _textFieldFocusNode,
                      autofocus: false,
                      onSubmitted: (_) {
                        widget.onSendText();
                        FocusScope.of(context).requestFocus(_textFieldFocusNode);
                      },
                      decoration: InputDecoration(
                        hintText: _isRecording ? "جاري التسجيل... اضغط المربع للإيقاف" : "اكتب رسالة...",
                        hintStyle: TextStyle(fontSize: 11, color: _isRecording ? Colors.red : Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purple, size: 22),
                  onPressed: () {
                    widget.onSendText();
                    FocusScope.of(context).requestFocus(_textFieldFocusNode);
                  },
                ),
              ],
            ),
    );
  }
}