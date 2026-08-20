import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'terms_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String selectedPayment = 'vodafone';
  String selectedTalent = 'غناء';
  bool isAccepted = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController(); 
  final TextEditingController bioController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    bioController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Color(0xFF7B1FA2), size: 30),
              ),
            ),
            const SizedBox(width: 12),
            const Text('اشتراك وتسجيل موهبة', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 2,
      ),
      // التعديل هنا: إضافة خاصية لضمان التجاوب مع كيبورد الموبايل وإعطاء مساحة مريحة بالأسفل
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
       padding: EdgeInsets.symmetric(
  horizontal: MediaQuery.of(context).size.width * 0.05,
  vertical: 16.0,
),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.payment, color: Color(0xFF7B1FA2)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'رسوم الاشتراك: 150 جنيه سنوياً أو 5\$ (دولار)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B1FA2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'اختر طريقة الدفع التحويلية:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('فودافون كاش 📱'),
                  selected: selectedPayment == 'vodafone',
                  onSelected: (bool selected) {
                    setState(() {
                      selectedPayment = 'vodafone';
                    });
                  },
                  selectedColor: Colors.pink.shade100,
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('InstaPay ⚡'),
                  selected: selectedPayment == 'instapay',
                  onSelected: (bool selected) {
                    setState(() {
                      selectedPayment = 'instapay';
                    });
                  },
                  selectedColor: Colors.amber.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: selectedPayment == 'vodafone'
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('للتحويل عبر فودافون كاش:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                        SizedBox(height: 4),
                        Text('• من داخل مصر: 01022877114'),
                        Text('• من خارج مصر: 0201022877114'),
                      ],
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('للتحويل عبر إنستا باي (InstaPay):', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2))),
                        SizedBox(height: 4),
                        Text('• soutwerouh@instapay'),
                        Text('• من داخل مصر: 01022877114'),
                        Text('• من خارج مصر: 0201022877114'),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            const Text('اسمك / الاسم الفني:', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'أدخل اسمك أو الاسم الفني',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            const Text('البريد الإلكتروني (اختياري):', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'example@email.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            // خانة كلمة المرور بوضوح تام لكل الشاشات
            const Text('كلمة المرور الشخصية (لدخول الشات وإدارة صفحتك):', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'أدخل كلمة مرور قوية',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            const Text('تخصص الموهبة:', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            DropdownButtonFormField<String>(
              value: selectedTalent,
              items: ['غناء', 'شعر', 'تلحين'].map((String talent) {
                return DropdownMenuItem(
                  value: talent,
                  child: Text(talent),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTalent = value!;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            const Text('نبذة عن أعمالك:', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '...اكتب تفاصيل الموهبة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            const Text('رقم الموبايل المحول منه:', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'مثال: 01012345678',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: isAccepted,
                  onChanged: (bool? value) {
                    setState(() {
                      isAccepted = value!;
                    });
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TermsScreen()),
                      );
                    },
                    child: const Text(
                      "أقر بأنني قرأت جميع الشروط والأحكام وموافق عليها",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2),
                  foregroundColor: Colors.white,
                ),
                onPressed: !isAccepted
                    ? null
                    : () async {
                        if (nameController.text.isEmpty || phoneController.text.isEmpty || passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('الرجاء إدخال الاسم، كلمة المرور، ورقم الهاتف المحول منه ❌')),
                          );
                          return;
                        }

                        try {
                          await FirebaseFirestore.instanceFor(app: Firebase.app()).collection('talents').add({
                            'name': nameController.text.trim(),
                            'category': selectedTalent,
                            'description': bioController.text.isNotEmpty ? bioController.text.trim() : 'لا توجد نبذة',
                            'paymentMethod': selectedPayment == 'vodafone' ? 'فودافون كاش' : 'InstaPay',
                            'transactionRef': phoneController.text.trim(),
                            'email': emailController.text.trim(),
                            'password': passwordController.text.trim(),
                            'likesCount': 0,
                            'isLiked': false,
                            'isApproved': false,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم إرسال طلب الاشتراك بنجاح، بانتظار مراجعة الدفع والتفعيل! ✅')),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('حدث خطأ أثناء الإرسال: $e')),
                            );
                          }
                        }
                      },
                child: const Text(
                  'إرسال طلب الاشتراك للدفع والتفعيل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}