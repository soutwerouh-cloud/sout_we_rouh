import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'dart:convert';
import 'dart:typed_data';

import 'radio_player_manager.dart';
import 'floating_chat_box.dart';
import 'media_handlers.dart';
import 'inbox_notifications_manager.dart';
import 'chat_input_controller_widget.dart';
import 'presence_manager.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final RadioPlayerManager _radioManager;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String activeUserName;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _activeChatWindows = [];
  final Map<String, Offset> _windowPositions = {};
  final Map<String, bool> _minimizedWindows = {};
  final ap.AudioPlayer _voicePlayer = ap.AudioPlayer();
  int _lastKnownUnreadCount = 0;
  
  String? _currentlyPlayingVoiceUrl;

  @override
  void initState() {
    super.initState();
    activeUserName = widget.currentUserName.isNotEmpty ? widget.currentUserName : "مستخدم";
    PresenceManager.setOnline(activeUserName);
    _radioManager = RadioPlayerManager();
    _radioManager.initAudio(() {
      if (mounted) setState(() {});
    });
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
    PresenceManager.setOffline(activeUserName);
    _radioManager.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _voicePlayer.dispose();
    super.dispose();
  }

  Future<void> _cleanupPublicMessages() async {
    try {
      var snapshot = await _firestore.collection('messages').orderBy('timestamp', descending: true).get();
      if (snapshot.docs.length > 30) {
        for (int i = 30; i < snapshot.docs.length; i++) {
          await snapshot.docs[i].reference.delete();
        }
      }
    } catch (e) {
      debugPrint("خطأ تنظيف الشات العام: $e");
    }
  }

  Future<void> _cleanupPrivateMessages(String otherUser) async {
    try {
      var snapshot = await _firestore.collection('inbox')
          .orderBy('timestamp', descending: true)
          .get();

      var conversationDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        String sender = data['sender'] ?? '';
        String receiver = data['receiver'] ?? '';
        return (sender == activeUserName && receiver == otherUser) ||
               (sender == otherUser && receiver == activeUserName);
      }).toList();

      if (conversationDocs.length > 30) {
        for (int i = 30; i < conversationDocs.length; i++) {
          await conversationDocs[i].reference.delete();
        }
      }
    } catch (e) {
      debugPrint("خطأ تنظيف الشات الخاص: $e");
    }
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
      debugPrint("خطأ تشغيل الصوت: $e");
      setState(() {
        _currentlyPlayingVoiceUrl = null;
      });
    }
  }

  void _sendPublicMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      String msgText = _messageController.text.trim();
      _messageController.clear();
      await _firestore.collection('messages').add({
        "sender": activeUserName,
        "text": msgText,
        "isImage": false,
        "isVoice": false,
        "timestamp": FieldValue.serverTimestamp(),
      });
      _cleanupPublicMessages();
      
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _openPrivateChat(String memberName) {
    if (!_activeChatWindows.contains(memberName)) {
      setState(() {
        _activeChatWindows.add(memberName);
        double startX = 50.0 + (_activeChatWindows.length * 30.0);
        double startY = 50.0 + (_activeChatWindows.length * 20.0);
        _windowPositions[memberName] = Offset(startX, startY);
        _minimizedWindows[memberName] = false;
      });
    } else {
      setState(() {
        _minimizedWindows[memberName] = false;
      });
    }
  }

  void _closePrivateChat(String memberName) {
    setState(() => _activeChatWindows.remove(memberName));
  }

  void _toggleMinimizeChat(String memberName) {
    setState(() => _minimizedWindows[memberName] = !(_minimizedWindows[memberName] ?? false));
  }

  Widget _buildTalentsSidebar() {
    return Container(
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
              stream: _firestore.collection('talents').where('isApproved', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                final memberDocs = snapshot.hasData ? snapshot.data!.docs : [];

                return ListView.builder(
                  itemCount: memberDocs.length,
                  itemBuilder: (context, index) {
                    final memberData = memberDocs[index].data() as Map<String, dynamic>;
                    final memberName = memberData["name"] ?? "مستخدم";
                    final talentType = memberData["talentType"] ?? "موهبة جديدة";
                    final bool isOnline = memberData["isOnline"] == true;

                    if (memberName == activeUserName) return const SizedBox.shrink();

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.purple.shade200,
                            child: Text(memberName.isNotEmpty ? memberName[0] : "", style: const TextStyle(color: Colors.white)),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(memberName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(talentType, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.purple),
                      onTap: () {
                        if (MediaQuery.of(context).size.width < 700) {
                          Navigator.pop(context); // قفل القائمة الجانبية على الموبايل
                        }
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
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isMobile = screenWidth < 700; 

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        endDrawer: isMobile ? Drawer(child: _buildTalentsSidebar()) : null,
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
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('inbox').snapshots(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.hasData ? snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['receiver'] == activeUserName && (data['isRead'] == false || data['isRead'] == null);
                }).length : 0;

                if (unreadCount > _lastKnownUnreadCount) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _playNotificationSound());
                }
                _lastKnownUnreadCount = unreadCount;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.mail_outline, color: Colors.white, size: 26),
                      onPressed: () => InboxNotificationsManager.showInboxDialog(context, activeUserName, _openPrivateChat),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 10),
          ],
        ),
        
        bottomNavigationBar: _activeChatWindows.any((name) => _minimizedWindows[name] == true)
            ? Container(
                color: Colors.purple.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                height: 45,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _activeChatWindows.where((name) => _minimizedWindows[name] == true).map((memberName) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.chat, size: 16, color: Colors.greenAccent),
                          label: Text(memberName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _toggleMinimizeChat(memberName),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            : null,

        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: Column(
              children: [
                // شريط الراديو
                Container(
                  color: Colors.purple.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note, color: Colors.purple, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _radioManager.playlist[_radioManager.currentSongIndex]["title"]!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.purple, size: 28),
                        onPressed: () => _radioManager.playPrevious(() => setState(() {})),
                      ),
                      IconButton(
                        icon: Icon(
                          _radioManager.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          size: 38,
                          color: Colors.purple.shade800,
                        ),
                        onPressed: () => _radioManager.togglePlayPause(() => setState(() {})),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.purple, size: 28),
                        onPressed: () => _radioManager.playNext(() => setState(() {})),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          if (!isMobile) _buildTalentsSidebar(),

                          // الشات العام
                          Expanded(
                            child: Container(
                              color: Colors.grey.shade100,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    color: Colors.purple.shade50,
                                    width: double.infinity,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "غرفة [ الشات العام ] - للمشتركين فقط",
                                          style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.bold),
                                        ),
                                        if (isMobile) ...[
                                          const SizedBox(width: 10),
                                          InkWell(
                                            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.shade700,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.people, size: 14, color: Colors.white),
                                                  SizedBox(width: 4),
                                                  Text("الأعضاء", style: TextStyle(color: Colors.white, fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: _firestore.collection('messages').orderBy('timestamp', descending: true).limit(30).snapshots(),
                                      builder: (context, snapshot) {
                                        final docs = snapshot.hasData ? snapshot.data!.docs : [];

                                        return ListView.builder(
                                          controller: _scrollController,
                                          reverse: true,
                                          padding: const EdgeInsets.all(12),
                                          itemCount: docs.length,
                                          itemBuilder: (context, index) {
                                            final msg = docs[index].data() as Map<String, dynamic>;
                                            final isMe = msg["sender"] == activeUserName;
                                            final bool isVoice = msg["isVoice"] == true;
                                            final String textVal = msg["text"] ?? "";
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
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          msg["sender"] ?? "مجهول",
                                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isMe ? Colors.white70 : Colors.purple),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          dateStr,
                                                          style: TextStyle(fontSize: 9, color: isMe ? Colors.white60 : Colors.grey),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    isVoice
                                                        ? Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              IconButton(
                                                                icon: Icon(
                                                                  isPlayingThis ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                                                  color: Colors.greenAccent,
                                                                  size: 28,
                                                                ),
                                                                onPressed: () => _playVoiceMessage(textVal),
                                                              ),
                                                              Text(
                                                                isPlayingThis ? "جاري التشغيل... 🔊" : "تسجيل صوتي 🎤",
                                                                style: TextStyle(fontSize: 13, color: isMe ? Colors.white : Colors.black87),
                                                              ),
                                                            ],
                                                          )
                                                        : (msg["isImage"] == true
                                                            ? ClipRRect(
                                                                borderRadius: BorderRadius.circular(8),
                                                                child: InkWell(
                                                                  onTap: () => MediaHandlers.showImageDialog(context, base64Decode(textVal.split(',').last)),
                                                                  child: Image.memory(
                                                                    base64Decode(textVal.split(',').last),
                                                                    width: 140,
                                                                    height: 140,
                                                                    fit: BoxFit.cover,
                                                                  ),
                                                                ),
                                                              )
                                                            : Text(textVal, style: TextStyle(fontSize: 15, color: isMe ? Colors.white : Colors.black87))),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),

                                  // شريط إدخال الشات العام
                                  ChatInputControllerWidget(
                                    textController: _messageController,
                                    onSendText: _sendPublicMessage,
                                    onPickImage: () async {
                                      await MediaHandlers.pickAndSendImage((path, isImg) async {
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
                                    onSendVoice: (audioData) async {
                                      await _firestore.collection('messages').add({
                                        "sender": activeUserName,
                                        "text": audioData,
                                        "isImage": false,
                                        "isVoice": true,
                                        "timestamp": FieldValue.serverTimestamp(),
                                      });
                                      _cleanupPublicMessages();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // نوافذ الشات الخاص العائمة
                      ..._activeChatWindows.where((memberName) => !(_minimizedWindows[memberName] ?? false)).map((memberName) {
                        double boxHeight = 420; 
                        double boxWidth = 340; 
                        double safeTop = _windowPositions[memberName]?.dy ?? 20.0;
                        double safeLeft = _windowPositions[memberName]?.dx ?? 20.0;

                        return Positioned(
                          left: safeLeft,
                          top: safeTop,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (details) {
                              setState(() {
                                _windowPositions[memberName] = Offset(
                                  safeLeft + details.delta.dx,
                                  safeTop + details.delta.dy,
                                );
                              });
                            },
                            child: Container(
                              width: boxWidth,
                              height: boxHeight,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                                border: Border.all(color: Colors.purple.shade400),
                              ),
                              child: StreamBuilder<QuerySnapshot>(
                                stream: _firestore.collection('inbox').orderBy('timestamp', descending: false).snapshots(),
                                builder: (context, snapshot) {
                                  final allDocs = snapshot.data?.docs ?? [];
                                  final messages = allDocs.map((doc) => doc.data() as Map<String, dynamic>).where((msg) {
                                    String sender = msg['sender'] ?? '';
                                    String receiver = msg['receiver'] ?? '';
                                    return (sender == activeUserName && receiver == memberName) ||
                                           (sender == memberName && receiver == activeUserName);
                                  }).toList();

                                  return FloatingChatBox(
                                    memberName: memberName,
                                    currentUserName: activeUserName,
                                    messages: messages,
                                    isMinimized: false,
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
                                      _cleanupPrivateMessages(memberName);
                                    },
                                    onPickImage: () async {
                                      await MediaHandlers.pickAndSendImage((path, isImg) async {
                                        await _firestore.collection('inbox').add({
                                          "sender": activeUserName,
                                          "receiver": memberName,
                                          "text": path,
                                          "isImage": isImg,
                                          "isVoice": false,
                                          "isRead": false,
                                          "timestamp": FieldValue.serverTimestamp(),
                                        });
                                        _cleanupPrivateMessages(memberName);
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
}