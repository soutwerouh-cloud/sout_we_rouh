import 'package:flutter/material.dart';

// نموذج الموهبة
class TalentItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final IconData icon;
  final Color themeColor;
  final String paymentMethod;
  final String transactionRef;
  int likesCount;
  bool isLiked;
  bool isApproved;
  final String email; // أضفنا الإيميل هنا لضمان ظهوره في صفحة الأدمن

  TalentItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.themeColor,
    this.paymentMethod = 'Vodafone Cash',
    this.transactionRef = '',
    this.likesCount = 12,
    this.isLiked = false,
    this.isApproved = false, // افتراضياً الطلب غير معتمد لحد ما الأدمن يراجعه
    this.email = '',
  });

  // تحويل الكائن إلى Map لتخزينه في Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'paymentMethod': paymentMethod,
      'transactionRef': transactionRef,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'isApproved': isApproved,
      'email': email,
    };
  }

  // إنشاء كائن TalentItem من بيانات Firestore
  factory TalentItem.fromMap(Map<String, dynamic> map, String docId) {
    IconData defaultIcon = Icons.mic;
    Color defaultColor = Colors.deepPurple;
    
    if (map['category'] == 'poetry') {
      defaultIcon = Icons.history_edu;
      defaultColor = Colors.purple;
    } else if (map['category'] == 'composing') {
      defaultIcon = Icons.music_note;
      defaultColor = Colors.indigo;
    }

    return TalentItem(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? 'singing',
      description: map['description'] ?? '',
      icon: defaultIcon,
      themeColor: defaultColor,
      paymentMethod: map['paymentMethod'] ?? 'Vodafone Cash',
      transactionRef: map['transactionRef'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      isLiked: map['isLiked'] ?? false,
      isApproved: map['isApproved'] ?? false,
      email: map['email'] ?? '',
    );
  }
}

const String adminEmail = "hayamahmoud049@gmail.com";
TalentItem? currentUserProfile;

// قائمة المواهب الافتراضية
List<TalentItem> globalTalentsList = [
  TalentItem(
    id: '1',
    name: 'موهبة غناء',
    category: 'singing',
    description: 'صوت غنائي مميز يتمتع بطبقات صوتية قوية وإحساس عالي.',
    icon: Icons.mic,
    themeColor: Colors.deepPurple,
    likesCount: 45,
    isApproved: true,
  ),
  TalentItem(
    id: '2',
    name: 'موهبة شعر',
    category: 'poetry',
    description: 'كتابة قصائد وأغاني درامية ورومانسية بأسلوب عصري جذاب.',
    icon: Icons.history_edu,
    themeColor: Colors.purple,
    likesCount: 60,
    isApproved: true,
  ),
  TalentItem(
    id: '3',
    name: 'موهبة تلحين',
    category: 'composing',
    description: 'صياغة الألحان والتوزيع الموسيقي بأسلوب حديث.',
    icon: Icons.music_note,
    themeColor: Colors.indigo,
    likesCount: 34,
    isApproved: true,
  ),
];