import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'talent_model.dart';
import 'talent_detail_screen.dart';
import 'shared_widgets.dart';
import 'talent_messaging_helper.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('دليل كل المواهب 📖'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('talents').where('isApproved', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: Center(child: Text('الدليل فارغ حالياً، بانتظار تفعيل المواهب', style: TextStyle(color: Colors.black54))),
            );
          }

          var docs = snapshot.data!.docs;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن اسم موهبة أو عمل...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ...docs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                var talent = TalentModel.fromMap(data, doc.id);

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('artist_works')
                      .where('artistName', isEqualTo: talent.name.trim())
                      .snapshots(),
                  builder: (context, workSnapshot) {
                    List<String> workTitles = [];
                    if (workSnapshot.hasData) {
                      for (var wDoc in workSnapshot.data!.docs) {
                        var wData = wDoc.data() as Map<String, dynamic>;
                        if (wData['title'] != null) workTitles.add(wData['title']);
                      }
                    }

                    String worksText = workTitles.isNotEmpty ? 'الأعمال: ${workTitles.join(' - ')}' : 'لا توجد أعمال';

                    return Center(
                      child: SizedBox(
                        width: 600,
                        child: Card(
                          color: Colors.white,
                          elevation: 1.5,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(talent.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF7B1FA2))),
                                    Text(talent.category, style: const TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(worksText, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.purple, fontSize: 12)),
                                const Divider(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF7B1FA2),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: const Icon(Icons.mail, size: 12, color: Colors.white),
                                      label: const Text('مراسلة ✉️', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      onPressed: () => showDirectMessageDialog(context, talent.name),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF7B1FA2)),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TalentDetailScreen(
                                              talent: talent, 
                                              icon: Icons.menu_book,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('التفاصيل 📖', style: TextStyle(color: Color(0xFF7B1FA2), fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isAuthenticated = false;
  final TextEditingController _passwordController = TextEditingController();
  final String _adminPassword = "125587";

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showSmallMessage(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: customAppBar('حماية لوحة الأدمن 🔐'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Color(0xFF7B1FA2)),
                const SizedBox(height: 20),
                const Text(
                  'هذه الصفحة محمية ولا يمكن الوصول إليها\nالرجاء إدخال كلمة المرور للمتابعة',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'كلمة المرور...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.key, color: Color(0xFF7B1FA2)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B1FA2),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (_passwordController.text == _adminPassword) {
                      setState(() {
                        _isAuthenticated = true;
                      });
                    } else {
                      _showSmallMessage(context, 'كلمة المرور غير صحيحة ❌');
                    }
                  },
                  child: const Text('دخول', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'للاستفسار أو استعادة كلمة المرور، تواصل عبر:\nhayamahmoud049@gmail.com',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('حسابي والأدمن 👤'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, backgroundColor: Color(0xFF7B1FA2), child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white)),
            const SizedBox(height: 10),
            const Text('مي محمود (أدمن التطبيق 👑)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Text('hayamahmoud049@gmail.com', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerRight,
              child: Text('طلبات الاشتراك والتحقق من الدفع (للأدمن فقط):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('talents').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('لا توجد أي طلبات اشتراك مسجلة حتى الآن', style: TextStyle(color: Colors.black54)));
                  }

                  var docs = snapshot.data!.docs.toList();

                  docs.sort((a, b) {
                    var dataA = a.data() as Map<String, dynamic>;
                    var dataB = b.data() as Map<String, dynamic>;
                    Timestamp? timeA = dataA['joinedAt'] as Timestamp?;
                    Timestamp? timeB = dataB['joinedAt'] as Timestamp?;

                    if (timeA == null && timeB == null) return 0;
                    if (timeA == null) return 1;
                    if (timeB == null) return -1;
                    return timeB.compareTo(timeA);
                  });

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var doc = docs[index];
                      var data = doc.data() as Map<String, dynamic>;

                      String name = data['name'] ?? 'بدون اسم';
                      String category = data['category'] ?? 'غناء';
                      String email = data['email'] ?? '';
                      String phone = data['transactionRef'] ?? '';
                      bool isApproved = data['isApproved'] ?? false;

                      Timestamp? joinedTimestamp = data['joinedAt'] as Timestamp?;
                      String adminDateStr = joinedTimestamp != null 
                          ? "تاريخ الانضمام: ${joinedTimestamp.toDate().year}/${joinedTimestamp.toDate().month}/${joinedTimestamp.toDate().day}" 
                          : "غير مسجل التاريخ";

                      return Card(
                        elevation: 2,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('القسم: $category'),
                              if (email.isNotEmpty)
                                Text('البريد: $email', style: const TextStyle(color: Colors.grey)),
                              Text('الهاتف المحول منه: $phone', style: const TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
                              Text('الحالة: ${isApproved ? "مفعل ✅" : "قيد المراجعة للتحقق من الدفع ⏳"}', 
                                  style: TextStyle(color: isApproved ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                              Text(adminDateStr, style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isApproved)
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  tooltip: 'تفعيل الموهبة',
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('talents').doc(doc.id).update({
                                      'isApproved': true,
                                      'joinedAt': FieldValue.serverTimestamp(),
                                    });
                                    if (!mounted) return;
                                    _showSmallMessage(context, 'تم تفعيل الموهبة بنجاح ✅', isError: false);
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'حذف الطلب',
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('talents').doc(doc.id).delete();
                                  if (!mounted) return;
                                  _showSmallMessage(context, 'تم حذف الطلب 🗑️');
                                },
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
          ],
        ),
      ),
    );
  }
}