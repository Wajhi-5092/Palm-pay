import 'package:cloud_firestore/cloud_firestore.dart';

class Merchant {
  final String id;
  final String merchantId; // Unique like MRC-48291
  final String storeName;
  final String ownerName;
  final String category;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String? logoUrl;
  final DateTime createdAt;
  final double walletBalance;
  final bool isActive;

  Merchant({
    required this.id,
    required this.merchantId,
    required this.storeName,
    required this.ownerName,
    required this.category,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    this.logoUrl,
    required this.createdAt,
    this.walletBalance = 0.0,
    this.isActive = true,
  });

  factory Merchant.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Merchant(
      id: doc.id,
      merchantId: data['merchantId'] ?? '',
      storeName: data['storeName'] ?? '',
      ownerName: data['ownerName'] ?? '',
      category: data['category'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      logoUrl: data['logoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      walletBalance: (data['walletBalance'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'merchantId': merchantId,
      'storeName': storeName,
      'ownerName': ownerName,
      'category': category,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'logoUrl': logoUrl,
      'createdAt': createdAt,
      'walletBalance': walletBalance,
      'isActive': isActive,
    };
  }
}
