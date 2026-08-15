import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final List<String> _activeChatWindows = [];
  final Map<String, Offset> _windowPositions = {};
  final Map<String, bool> _minimizedWindows = {};
  final ImagePicker _picker = ImagePicker();

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
      setState(() { _isPlaying = true; });
    } catch (e) {
      debugPrint("خطأ في تحميل الأغنية: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _messageController.dispose();
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

  void _sendPublicMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _firestore.collection('messages').add({
        "sender": activeUserName,
        "text": _messageController.text,
        "isImage": false,
        "timestamp": FieldValue.serverTimestamp(),
      });
      _messageController.clear();
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
                  stream: _firestore
                      .collection('talents')
                      .where('isApproved', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("لا توجد أعضاء معتمدة حتى الآن", style: TextStyle(fontSize: 12, color: Colors.grey)));
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

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade200,
                            child: Text(memberName.isNotEmpty ? memberName[0] : "", style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(memberName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text(talentType, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.purple),
                          onTap: () {
                            Navigator.pop(context);
                            _openPrivateChat(memberName);
                          },
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
        resizeToAvoidBottomInset: true, // ضروري جداً لكي ترفع الشاشة عند ظهور الكيبورد
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
          child: Stack(
            children: [
              Column(
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
                    child: Row(
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
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text("لا توجد أعضاء معتمدة حتى الآن", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          ),
                                        );
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

                                          return ListTile(
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
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                        return const Center(child: Text("لا توجد رسائل بعد، ابدأ المحادثة!"));
                                      }
                                      
                                      final docs = snapshot.data!.docs.toList();
                                      docs.sort((a, b) {
                                        var tA = (a.data() as Map<String, dynamic>)['timestamp'];
                                        var tB = (b.data() as Map<String, dynamic>)['timestamp'];
                                        if (tA == null || tB == null) return 0;
                                        return (tB as Timestamp).compareTo(tA as Timestamp);
                                      });

                                      return ListView.builder(
                                        reverse: true,
                                        padding: const EdgeInsets.all(12),
                                        itemCount: docs.length,
                                        itemBuilder: (context, index) {
                                          final msg = docs[index].data() as Map<String, dynamic>;
                                          final isMe = msg["sender"] == activeUserName;
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
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isMe ? Colors.white70 : Colors.purple,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  msg["isImage"] == true
                                                      ? ClipRRect(
                                                          borderRadius: BorderRadius.circular(8),
                                                          child: Builder(
                                                            builder: (context) {
                                                              try {
                                                                final textVal = msg["text"].toString();
                                                                if (textVal.contains(',')) {
                                                                  return Image.memory(
                                                                    base64Decode(textVal.split(',').last),
                                                                    width: 140,
                                                                    height: 140,
                                                                    fit: BoxFit.cover,
                                                                    errorBuilder: (c, e, s) => const Text("صورة غير صالحة ⚠️", style: TextStyle(fontSize: 10, color: Colors.red)),
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
                                                            fontSize: 13,
                                                            color: isMe ? Colors.white : Colors.black87,
                                                          ),
                                                        ),
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
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.white,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.image, color: Colors.purple),
                                        onPressed: () async {
                                          await _pickAndSendImage((path, isImg) {
                                            _firestore.collection('messages').add({
                                              "sender": activeUserName,
                                              "text": path,
                                              "isImage": isImg,
                                              "timestamp": FieldValue.serverTimestamp(),
                                            });
                                          });
                                        },
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: _messageController,
                                          onSubmitted: (value) {
                                            _sendPublicMessage();
                                          },
                                          decoration: InputDecoration(
                                            hintText: "اكتب رسالة في الشات العام...",
                                            hintStyle: const TextStyle(fontSize: 12),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: Colors.grey.shade200,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        backgroundColor: Colors.purple,
                                        radius: 18,
                                        child: IconButton(
                                          icon: const Icon(Icons.send, color: Colors.white, size: 16),
                                          onPressed: _sendPublicMessage,
                                        ),
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
                  ),
                ],
              ),

              ..._activeChatWindows.map((memberName) {
                final pos = _windowPositions[memberName] ?? const Offset(50, 100);
                final isMinimized = _minimizedWindows[memberName] ?? false;

                return Positioned(
                  left: isMobile ? 10 : pos.dx,
                  top: isMobile ? 80 : pos.dy,
                  right: isMobile ? 10 : null,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      if (!isMobile) {
                        setState(() {
                          _windowPositions[memberName] = Offset(
                            pos.dx + details.delta.dx,
                            pos.dy + details.delta.dy,
                          );
                        });
                      }
                    },
                    child: Container(
                      width: isMobile ? null : 260,
                      height: isMinimized ? 40 : 300,
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
                            onSend: (text, isImg) {
                              _firestore.collection('inbox').add({
                                "sender": activeUserName, 
                                "receiver": memberName, 
                                "text": text,
                                "isImage": isImg,
                                "isRead": false,
                                "timestamp": FieldValue.serverTimestamp(),
                              });
                            },
                            onPickImage: () async {
                              await _pickAndSendImage((path, isImg) {
                                _firestore.collection('inbox').add({
                                  "sender": activeUserName,
                                  "receiver": memberName,
                                  "text": path,
                                  "isImage": isImg,
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("لا توجد رسائل خاصة جديدة"));
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
                          fontSize: 13,
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

class FloatingChatBox extends StatefulWidget {
  final String memberName;
  final String currentUserName;
  final List<Map<String, dynamic>> messages;
  final bool isMinimized;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final Function(String, bool) onSend;
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(8),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final msg = widget.messages[index];
                final isMe = msg["sender"] == widget.currentUserName; 
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.purple.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: msg["isImage"] == true
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Builder(
                              builder: (context) {
                                try {
                                  final textVal = msg["text"].toString();
                                  if (textVal.contains(',')) {
                                    return Image.memory(
                                      base64Decode(textVal.split(',').last),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Text("صورة غير صالحة ⚠️", style: TextStyle(fontSize: 10, color: Colors.red)),
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
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
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
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        widget.onSend(value, false);
                        _controller.clear();
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: "اكتب رسالة...",
                      hintStyle: TextStyle(fontSize: 11),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purple, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      widget.onSend(_controller.text, false);
                      _controller.clear();
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