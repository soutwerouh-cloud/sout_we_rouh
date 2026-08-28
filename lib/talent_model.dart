import 'package:flutter/material.dart';

// نموذج الموهبة
class TalentModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final IconData icon;
  final Color themeColor;
  final String paymentMethod;
  final String transactionRef;
  final String phone;
  int likesCount;
  bool isLiked;
  bool isApproved;
  final String email;
  final String bio;
  final String password;
  final String profileImage;

  TalentModel({
    this.id = '',
    required this.name,
    required this.category,
    this.description = '',
    this.icon = Icons.mic,
    this.themeColor = Colors.deepPurple,
    this.paymentMethod = 'Vodafone Cash',
    this.transactionRef = '',
    this.phone = '',
    this.likesCount = 12,
    this.isLiked = false,
    this.isApproved = false,
    this.email = '',
    this.bio = '',
    this.password = '',
    this.profileImage = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'paymentMethod': paymentMethod,
      'transactionRef': transactionRef,
      'phone': phone,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'isApproved': isApproved,
      'email': email,
      'bio': bio,
      'password': password,
      'profileImage': profileImage,
    };
  }

  factory TalentModel.fromMap(Map<String, dynamic> map, String docId) {
    IconData defaultIcon = Icons.mic;
    Color defaultColor = Colors.deepPurple;
    
    if (map['category'] == 'poetry') {
      defaultIcon = Icons.history_edu;
      defaultColor = Colors.purple;
    } else if (map['category'] == 'composing') {
      defaultIcon = Icons.music_note;
      defaultColor = Colors.indigo;
    }

    return TalentModel(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? 'singing',
      description: map['description'] ?? '',
      icon: defaultIcon,
      themeColor: defaultColor,
      paymentMethod: map['paymentMethod'] ?? 'Vodafone Cash',
      transactionRef: map['transactionRef'] ?? '',
      phone: map['phone'] ?? map['transactionRef'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      isLiked: map['isLiked'] ?? false,
      isApproved: map['isApproved'] ?? false,
      email: map['email'] ?? '',
      bio: map['description'] ?? '',
      password: map['password'] ?? '',
      profileImage: map['profileImage'] ?? '',
    );
  }
}