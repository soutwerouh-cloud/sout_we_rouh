import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart' show kIsWeb;

class ChatRadioScreen extends StatefulWidget {
  final bool isSubscribed; 
  final String currentUserName;

  const ChatRadioScreen({
    super.key, 
    this.isSubscribed = true, 
    required this.currentUserName,
  });

  @override
  State<ChatRadioScreen> createState() => _ChatRadioScreenState();
}

class _ChatRadioScreenState extends State<ChatRadioScreen> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String activeUserName;
  
  final List<Map<String, String>> _playlist = [
    {"title": "Dol-Mish-Habayeb", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Dol-Mish-Habayeb.mp3"},
    {"title": "Mai_Mahmoud_Ana_El_Motayyam", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Mai_Mahmoud_Ana_El_Motayyam.mp3"},
    {"title": "Habayeb_Eh", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Habayeb_Eh.mp3"},
    {"title": "Mai_Mahmoud_Day_El_Qamar", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Mai_Mahmoud_Day_El_Qamar.mp3"},
    {"title": "lakayetk", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/lakayetk.mp3"},
    {"title": "Mai_Mahmoud_Bakam_Thamani", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Mai_Mahmoud_Bakam_Thamani.mp3"},
    {"title": "Oddam_El_Nas", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Oddam_El_Nas.mp3"},
    {"title": "Mai_Mahmoud_Hafez_El_Rouh", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Mai_Mahmoud_Hafez_El_Rouh.mp3"},
    {"title": "algay_btaay", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/algay_btaay.mp3"},
    {"title": "set_elnas", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/set_elnas.mp3"},
    {"title": "Mai_Mahmoud_Sir_El_Hawa", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Mai_Mahmoud_Sir_El_Hawa.mp3"},
    {"title": "Nesyanak Sa3b Akid", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Nesyanak%20Sa3b%20Akid.mp3"},
    {"title": "atakhr_atabna", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/atakhr_atabna.mp3"},
    {"title": "halwanhm", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/halwanhm.mp3"},
    {"title": "Mai_Mahmoud_Khayan", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Mai_Mahmoud_Khayan.mp3"},
  ];
  
  int _currentSongIndex = 0;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();

  final List<String> _activeChatWindows = [];
  final Map<String, Offset> _windowPositions = {};
  final Map<String, bool> _minimizedWindows = {};
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ap.AudioPlayer _voicePlayer = ap.AudioPlayer();

  bool _isRecordingVoice = false;
  int _lastKnownUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    activeUserName = widget.currentUserName.isNotEmpty ? widget.currentUserName : "مستخدم";
    _player = AudioPlayer();
    _initAudio();

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  Future<void> _initAudio() async {
    try {
      await _player.setUrl(_playlist[_currentSongIndex]["url"]!);
      _player.play();
      if (mounted) {
        setState(() { _isPlaying = true; });
      }
    } catch (e) {
      debugPrint("خطأ في التشغيل: $e");
    }
  }

  Future<void> _playNotificationSound() async {
    try {
      await _voicePlayer.play(ap.UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'));
    } catch (e) {
      debugPrint("خطأ في تشغيل الصوت: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _textFieldFocusNode.dispose();
    _audioRecorder.dispose();
    _voicePlayer.dispose();
    super.dispose();
  }

  void _playNext() {
    setState(() {
      _currentSongIndex = (_currentSongIndex + 1) % _playlist.length;
    });
    _player.setUrl(_playlist[_currentSongIndex]["url"]!);
    _player.play();
    setState(() { _isPlaying = true; });
  }

  void _playPrevious() {
    setState(() {
      _currentSongIndex = (_currentSongIndex - 1 + _playlist.length) % _playlist.length;
    });
    _player.setUrl(_playlist[_currentSongIndex]["url"]!);
    _player.play();
    setState(() { _isPlaying = true; });
  }

  Future<void> _cleanupPublicMessages() async {
    try {
      var snapshot = await _firestore.collection('messages').orderBy('timestamp', descending: true).get();
      if (snapshot.docs.length > 50) {
        for (int i = 50; i < snapshot.docs.length; i++) {
          await snapshot.docs[i].reference.delete();
        }
      }
    } catch (e) {
      debugPrint("خطأ في تنظيف الشات العام: $e");
    }
  }

  void _sendPublicMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      String msgText = _messageController.text.trim();
      _messageController.clear();
      _textFieldFocusNode.requestFocus();

      await _firestore.collection('messages').add({
        "sender": activeUserName,
        "text": msgText,
        "isImage": false,
        "isVoice": false,
        "timestamp": FieldValue.serverTimestamp(),
      });

      _cleanupPublicMessages();
    }
  }

  Future<void> _toggleRecordVoice(Function(String, bool, bool) onSendVoice) async {
    if (_isRecordingVoice) {
      try {
        final path = await _audioRecorder.stop();
        setState(() { _isRecordingVoice = false; });
        if (path != null) {
          String audioData = path;
          if (!kIsWeb) {
            final bytes = await File(path).readAsBytes();
            audioData = 'data:audio/aac;base64,${base64Encode(bytes)}';
          }
          onSendVoice(audioData, false, true);
        }
      } catch (e) {
        setState(() { _isRecordingVoice = false; });
      }
    } else {
      try {
        if (await _audioRecorder.hasPermission()) {
          await _audioRecorder.start(const RecordConfig(), path: '');
          setState(() { _isRecordingVoice = true; });
        }
      } catch (e) {
        debugPrint("خطأ في بدء التسجيل: $e");
      }
    }
  }

  void _openPrivateChat(String memberName) {
    if (!_activeChatWindows.contains(memberName)) {
      setState(() {
        _activeChatWindows.add(memberName);
        _windowPositions[memberName] = const Offset(80, 150);
        _minimizedWindows[memberName] = false;
      });
    } else {
      setState(() {
        _minimizedWindows[memberName] = false;
      });
    }
  }

  void _closePrivateChat(String memberName) {
    setState(() {
      _activeChatWindows.remove(memberName);
    });
  }

  void _toggleMinimizeChat(String memberName) {
    setState(() {
      _minimizedWindows[memberName] = !(_minimizedWindows[memberName] ?? false);
    });
  }

  Future<void> _pickAndSendImage(Function(String, bool) onImageSelected) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 30);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      onImageSelected(base64Image, true);
    }
  }

  void _showImageDialog(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.memory(imageBytes),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMembersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.people, color: Colors.purple),
                  SizedBox(width: 8),
                  Text("قائمة الأعضاء والمواهب", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 16)),
                ],
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('talents').where('isApproved', isEqualTo: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final memberDocs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: memberDocs.length,
                      itemBuilder: (context, index) {
                        final memberData = memberDocs[index].data() as Map<String, dynamic>;
                        final memberName = memberData["name"] ?? "مستخدم";
                        final talentType = memberData["talentType"] ?? "موهبة جديدة";

                        if (memberName == activeUserName) {
                          return const SizedBox.shrink();
                        }

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.shade200,
                              child: Text(memberName.isNotEmpty ? memberName[0] : "", style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(memberName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: Text(talentType, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.purple),
                            onTap: () {
                              Navigator.pop(context);
                              _openPrivateChat(memberName);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700; 

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.mic_rounded, color: Colors.blueAccent, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "راديو وشات صوت وروح ($activeUserName)", 
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.purple.shade800,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (isMobile)
              IconButton(
                icon: const Icon(Icons.people_alt, color: Colors.white, size: 24),
                onPressed: () => _showMembersBottomSheet(context),
              ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('inbox').snapshots(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.hasData ? snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['receiver'] == activeUserName && (data['isRead'] == false || data['isRead'] == null);
                }).length : 0;

                if (unreadCount > _lastKnownUnreadCount) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _playNotificationSound();
                  });
                }
                _lastKnownUnreadCount = unreadCount;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.mail_outline, color: Colors.white, size: 26),
                      onPressed: () => _showInboxDialog(context),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                Container(
                  color: Colors.purple.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note, color: Colors.purple, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _playlist[_currentSongIndex]["title"]!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.purple, size: 28),
                        onPressed: _playPrevious,
                      ),
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          size: 38,
                          color: Colors.purple.shade800,
                        ),
                        onPressed: () async {
                          setState(() { _isPlaying = !_isPlaying; });
                          if (_isPlaying) {
                            await _player.play();
                          } else {
                            await _player.pause();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.purple, size: 28),
                        onPressed: _playNext,
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          if (!isMobile)
                            Container(
                              width: 250,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(left: BorderSide(color: Colors.grey.shade300)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    color: Colors.purple.shade100,
                                    child: const Row(
                                      children: [
                                        Icon(Icons.people, color: Colors.purple, size: 20),
                                        SizedBox(width: 8),
                                        Text("قائمة الأعضاء والمواهب", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: _firestore
                                          .collection('talents')
                                          .where('isApproved', isEqualTo: true)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        final memberDocs = snapshot.data!.docs;

                                        return ListView.builder(
                                          itemCount: memberDocs.length,
                                          itemBuilder: (context, index) {
                                            final memberData = memberDocs[index].data() as Map<String, dynamic>;
                                            final memberName = memberData["name"] ?? "مستخدم";
                                            final talentType = memberData["talentType"] ?? "موهبة جديدة";

                                            if (memberName == activeUserName) {
                                              return const SizedBox.shrink();
                                            }

                                            return Material(
                                              color: Colors.transparent,
                                              child: ListTile(
                                                leading: CircleAvatar(
                                                  backgroundColor: Colors.purple.shade200,
                                                  child: Text(memberName.isNotEmpty ? memberName[0] : "", style: const TextStyle(color: Colors.white)),
                                                ),
                                                title: Text(memberName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                                subtitle: Text(talentType, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                trailing: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.purple),
                                                onTap: () {
                                                  _openPrivateChat(memberName);
                                                },
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Expanded(
                            child: Container(
                              color: Colors.grey.shade100,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    color: Colors.purple.shade50,
                                    width: double.infinity,
                                    child: const Text(
                                      "غرفة [ الشات العام ] - للمشتركين فقط",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: _firestore.collection('messages').snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        
                                        final docs = snapshot.data!.docs.toList();
                                        docs.sort((a, b) {
                                          var tA = (a.data() as Map<String, dynamic>)['timestamp'];
                                          var tB = (b.data() as Map<String, dynamic>)['timestamp'];
                                          if (tA == null || tB == null) return 0;
                                          return (tB as Timestamp).compareTo(tA as Timestamp);
                                        });

                                        return ListView.builder(
                                          controller: _scrollController,
                                          reverse: true,
                                          padding: const EdgeInsets.all(12),
                                          itemCount: docs.length,
                                          itemBuilder: (context, index) {
                                            final msg = docs[index].data() as Map<String, dynamic>;
                                            final isMe = msg["sender"] == activeUserName;
                                            final bool isVoice = msg["isVoice"] == true;
                                            final String voicePath = msg["text"] ?? "";

                                            return Align(
                                              alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                                              child: Container(
                                                margin: const EdgeInsets.symmetric(vertical: 4),
                                                padding: const EdgeInsets.all(10),
                                                constraints: BoxConstraints(maxWidth: isMobile ? screenWidth * 0.75 : 350),
                                                decoration: BoxDecoration(
                                                  color: isMe ? Colors.purple.shade700 : Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      msg["sender"] ?? "مجهول",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: isMe ? Colors.white70 : Colors.purple,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    isVoice
                                                        ? Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              IconButton(
                                                                icon: const Icon(Icons.play_arrow, color: Colors.greenAccent),
                                                                onPressed: () async {
                                                                  if (voicePath.isNotEmpty) {
                                                                    await _voicePlayer.play(ap.UrlSource(voicePath));
                                                                  }
                                                                },
                                                              ),
                                                              const Text("تسجيل صوتي 🎤", style: TextStyle(fontSize: 13)),
                                                            ],
                                                          )
                                                        : (msg["isImage"] == true
                                                            ? ClipRRect(
                                                                borderRadius: BorderRadius.circular(8),
                                                                child: Builder(
                                                                  builder: (context) {
                                                                    try {
                                                                      final textVal = msg["text"].toString();
                                                                      if (textVal.contains(',')) {
                                                                        final imageBytes = base64Decode(textVal.split(',').last);
                                                                        return GestureDetector(
                                                                          onTap: () => _showImageDialog(context, imageBytes),
                                                                          child: Image.memory(
                                                                            imageBytes,
                                                                            width: 140,
                                                                            height: 140,
                                                                            fit: BoxFit.cover,
                                                                            errorBuilder: (c, e, s) => const Text("صورة غير صالحة ⚠️", style: TextStyle(fontSize: 10, color: Colors.red)),
                                                                          ),
                                                                        );
                                                                      } else {
                                                                        return const Text("صورة قديمة ⚠️", style: TextStyle(fontSize: 10, color: Colors.grey));
                                                                      }
                                                                    } catch (e) {
                                                                      return const Text("خطأ في التحميل ❌", style: TextStyle(fontSize: 10, color: Colors.red));
                                                                    }
                                                                  },
                                                                ),
                                                              )
                                                            : Text(
                                                                msg["text"] ?? "",
                                                                style: TextStyle(
                                                                  fontSize: 15,
                                                                  color: isMe ? Colors.white : Colors.black87,
                                                                ),
                                                              )),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border(top: BorderSide(color: Colors.grey.shade300)),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.image, color: Colors.purple, size: 22),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () async {
                                            await _pickAndSendImage((path, isImg) async {
                                              await _firestore.collection('messages').add({
                                                "sender": activeUserName,
                                                "text": path,
                                                "isImage": isImg,
                                                "isVoice": false,
                                                "timestamp": FieldValue.serverTimestamp(),
                                              });
                                              _cleanupPublicMessages();
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(Icons.mic, color: _isRecordingVoice ? Colors.red : Colors.purple, size: 22),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _toggleRecordVoice((txt, img, voice) async {
                                            await _firestore.collection('messages').add({
                                              "sender": activeUserName,
                                              "text": txt,
                                              "isImage": img,
                                              "isVoice": voice,
                                              "timestamp": FieldValue.serverTimestamp(),
                                            });
                                            _cleanupPublicMessages();
                                          }),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SizedBox(
                                            height: 38,
                                            child: TextField(
                                              controller: _messageController,
                                              focusNode: _textFieldFocusNode,
                                              autofocus: true,
                                              onSubmitted: (value) {
                                                _sendPublicMessage();
                                              },
                                              decoration: InputDecoration(
                                                hintText: _isRecordingVoice ? "جاري التسجيل..." : "اكتب رسالة في الشات العام...",
                                                hintStyle: const TextStyle(fontSize: 12),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                                filled: true,
                                                fillColor: Colors.grey.shade100,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.send, color: Colors.purple, size: 22),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: _sendPublicMessage,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      ..._activeChatWindows.map((memberName) {
                        final isMinimized = _minimizedWindows[memberName] ?? false;
                        final index = _activeChatWindows.indexOf(memberName);

                        final pos = isMinimized
                            ? Offset(10, MediaQuery.of(context).size.height - 80.0 - (index * 45))
                            : (_windowPositions[memberName] ?? const Offset(50, 100));

                        return Positioned(
                          left: isMobile ? 10 : pos.dx,
                          top: isMobile ? (80.0 + (index * 45)) : pos.dy,
                          right: isMobile ? 10 : null,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (details) {
                              if (!isMobile && !isMinimized) {
                                setState(() {
                                  final currentPos = _windowPositions[memberName] ?? const Offset(50, 100);
                                  _windowPositions[memberName] = Offset(
                                    currentPos.dx + details.delta.dx,
                                    currentPos.dy + details.delta.dy,
                                  );
                                });
                              }
                            },
                            child: Container(
                              width: isMobile ? null : 280,
                              height: isMinimized ? 40 : 320,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                                border: Border.all(color: Colors.purple.shade400),
                              ),
                              child: StreamBuilder<QuerySnapshot>(
                                stream: _firestore.collection('inbox').snapshots(),
                                builder: (context, snapshot) {
                                  final allDocs = snapshot.data?.docs ?? [];
                                  final messages = allDocs.map((doc) => doc.data() as Map<String, dynamic>).where((msg) {
                                    String sender = msg['sender'] ?? '';
                                    String receiver = msg['receiver'] ?? '';
                                    return (sender == activeUserName && receiver == memberName) ||
                                           (sender == memberName && receiver == activeUserName);
                                  }).toList();

                                  messages.sort((a, b) {
                                    var tA = a['timestamp'];
                                    var tB = b['timestamp'];
                                    if (tA == null || tB == null) return 0;
                                    return (tA as Timestamp).compareTo(tB as Timestamp);
                                  });

                                  return FloatingChatBox(
                                    memberName: memberName,
                                    currentUserName: activeUserName,
                                    messages: messages,
                                    isMinimized: isMinimized,
                                    onClose: () => _closePrivateChat(memberName),
                                    onMinimize: () => _toggleMinimizeChat(memberName),
                                    onSend: (text, isImg, isVoiceMsg) async {
                                      await _firestore.collection('inbox').add({
                                        "sender": activeUserName, 
                                        "receiver": memberName, 
                                        "text": text,
                                        "isImage": isImg,
                                        "isVoice": isVoiceMsg,
                                        "isRead": false,
                                        "timestamp": FieldValue.serverTimestamp(),
                                      });
                                    },
                                    onPickImage: () async {
                                      await _pickAndSendImage((path, isImg) async {
                                        await _firestore.collection('inbox').add({
                                          "sender": activeUserName,
                                          "receiver": memberName,
                                          "text": path,
                                          "isImage": isImg,
                                          "isVoice": false,
                                          "isRead": false,
                                          "timestamp": FieldValue.serverTimestamp(),
                                        });
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInboxDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("صندوق البريد الخاص"),
          content: SizedBox(
            width: 300,
            height: 200,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('inbox').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final inboxDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['receiver'] == activeUserName;
                }).toList();

                if (inboxDocs.isEmpty) {
                  return const Center(child: Text("لا توجد رسائل خاصة جديدة"));
                }

                final Map<String, DocumentSnapshot> latestMessagePerSender = {};
                for (var doc in inboxDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final sender = data["sender"] ?? "مجهول";
                  latestMessagePerSender[sender] = doc;
                }

                final uniqueSendersDocs = latestMessagePerSender.values.toList();

                return ListView.builder(
                  itemCount: uniqueSendersDocs.length,
                  itemBuilder: (context, index) {
                    final doc = uniqueSendersDocs[index];
                    final msgData = doc.data() as Map<String, dynamic>;
                    final senderName = msgData["sender"] ?? "مجهول";
                    final messageText = msgData["text"] ?? "";
                    
                    final bool hasUnread = inboxDocs.any((d) {
                      final dData = d.data() as Map<String, dynamic>;
                      return dData['sender'] == senderName && (dData['isRead'] == false || dData['isRead'] == null);
                    });

                    return ListTile(
                      leading: Icon(
                        hasUnread ? Icons.mark_email_unread : Icons.message, 
                        color: hasUnread ? Colors.red : Colors.purple,
                      ),
                      title: Text(
                        senderName, 
                        style: TextStyle(
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal, 
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(messageText, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () async {
                        final batch = _firestore.batch();
                        for (var d in inboxDocs) {
                          final dData = d.data() as Map<String, dynamic>;
                          if (dData['sender'] == senderName && (dData['isRead'] == false || dData['isRead'] == null)) {
                            batch.update(d.reference, {'isRead': true});
                          }
                        }
                        await batch.commit();

                        Navigator.pop(context);
                        _openPrivateChat(senderName);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إغلاق"),
            ),
          ],
        );
      },
    );
  }
}

// دالة تسجيل الدخول
void showChatRadioLoginDialog(BuildContext context) {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('دخول غرفة الشات والراديو 🎧', style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'اسمك الحقيقي المسجل', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'كلمة المرور الشخصية للحساب', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
          onPressed: () async {
            String enteredName = nameController.text.trim();
            String enteredPassword = passwordController.text.trim();

            if (enteredName.isEmpty || enteredPassword.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الرجاء إدخال الاسم وكلمة المرور ❌'), backgroundColor: Colors.red),
              );
              return;
            }

            var querySnapshot = await FirebaseFirestore.instance
                .collection('talents')
                .where('name', isEqualTo: enteredName)
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              var talentData = querySnapshot.docs.first.data() as Map<String, dynamic>;
              String savedPassword = (talentData['password'] ?? '').toString().trim();
              bool isApproved = talentData['isApproved'] ?? false;

              if (!isApproved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('هذا الحساب قيد المراجعة أو غير مفعل من الأدمن ⏳'), backgroundColor: Colors.orange),
                );
                return;
              }

              if (savedPassword == enteredPassword) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRadioScreen(currentUserName: enteredName),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('كلمة المرور غير صحيحة ❌'), backgroundColor: Colors.red),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('لم يتم العثور على اسم الموهبة بهذا الاسم ❌'), backgroundColor: Colors.red),
              );
            }
          },
          child: const Text('دخول 🚀', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

// كلاس صندوق الدردشة العائم
class FloatingChatBox extends StatefulWidget {
  final String memberName;
  final String currentUserName;
  final List<Map<String, dynamic>> messages;
  final bool isMinimized;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final Function(String, bool, bool) onSend;
  final Future<void> Function() onPickImage;

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
  final TextEditingController _controller = TextEditingController();
  final FocusNode _privateFocusNode = FocusNode();
  final ScrollController _privateScrollController = ScrollController();
  final AudioRecorder _privateAudioRecorder = AudioRecorder();
  final ap.AudioPlayer _privateVoicePlayer = ap.AudioPlayer();
  
  bool _isRecordingPrivateVoice = false;

  @override
  void dispose() {
    _controller.dispose();
    _privateFocusNode.dispose();
    _privateScrollController.dispose();
    _privateAudioRecorder.dispose();
    _privateVoicePlayer.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_privateScrollController.hasClients) {
      _privateScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showPrivateImageDialog(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.memory(imageBytes),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePrivateRecord() async {
    if (_isRecordingPrivateVoice) {
      try {
        final path = await _privateAudioRecorder.stop();
        setState(() { _isRecordingPrivateVoice = false; });
        if (path != null) {
          String audioData = path;
          if (!kIsWeb) {
            final bytes = await File(path).readAsBytes();
            audioData = 'data:audio/aac;base64,${base64Encode(bytes)}';
          }
          widget.onSend(audioData, false, true);
        }
      } catch (e) {
        setState(() { _isRecordingPrivateVoice = false; });
      }
    } else {
      try {
        if (await _privateAudioRecorder.hasPermission()) {
          await _privateAudioRecorder.start(const RecordConfig(), path: '');
          setState(() { _isRecordingPrivateVoice = true; });
        }
      } catch (e) {
        debugPrint("خطأ في تسجيل الخاص: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.shade800,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              const Icon(Icons.open_with, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.memberName,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(widget.isMinimized ? Icons.add : Icons.remove, color: Colors.white, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onMinimize,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
        if (!widget.isMinimized) ...[
          Expanded(
            child: ListView.builder(
              controller: _privateScrollController,
              reverse: true,
              padding: const EdgeInsets.all(8),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final reversedIndex = widget.messages.length - 1 - index;
                final msg = widget.messages[reversedIndex];
                final isMe = msg["sender"] == widget.currentUserName; 
                final bool isVoice = msg["isVoice"] == true;
                final String voicePath = msg["text"] ?? "";

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.purple.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isVoice
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow, color: Colors.purple, size: 20),
                                onPressed: () async {
                                  if (voicePath.isNotEmpty) {
                                    await _privateVoicePlayer.play(ap.UrlSource(voicePath));
                                  }
                                },
                              ),
                              const Text("تسجيل صوتي 🎤", style: TextStyle(fontSize: 12)),
                            ],
                          )
                        : (msg["isImage"] == true
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Builder(
                                  builder: (context) {
                                    try {
                                      final textVal = msg["text"].toString();
                                      if (textVal.contains(',')) {
                                        final imageBytes = base64Decode(textVal.split(',').last);
                                        return GestureDetector(
                                          onTap: () => _showPrivateImageDialog(context, imageBytes),
                                          child: Image.memory(
                                            imageBytes,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => const Text("صورة غير صالحة ⚠️", style: TextStyle(fontSize: 10, color: Colors.red)),
                                          ),
                                        );
                                      } else {
                                        return const Text("صورة قديمة ⚠️", style: TextStyle(fontSize: 10, color: Colors.grey));
                                      }
                                    } catch (e) {
                                      return const Text("خطأ في التحميل ❌", style: TextStyle(fontSize: 10, color: Colors.red));
                                    }
                                  },
                                ),
                              )
                            : Text(
                                msg["text"] ?? "",
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              )),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.purple, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onPickImage,
                ),
                IconButton(
                  icon: Icon(Icons.mic, color: _isRecordingPrivateVoice ? Colors.red : Colors.purple, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _togglePrivateRecord,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _privateFocusNode,
                    autofocus: true,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        widget.onSend(value, false, false);
                        _controller.clear();
                        _privateFocusNode.requestFocus();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: _isRecordingPrivateVoice ? "جاري التسجيل..." : "اكتب رسالة...",
                      hintStyle: const TextStyle(fontSize: 11),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purple, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      widget.onSend(_controller.text, false, false);
                      _controller.clear();
                      _privateFocusNode.requestFocus();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}