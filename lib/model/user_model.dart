// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String idNumber;
  final String mobileNumber;
  final String userType; // seller, buyer, witness, admin
  final DateTime createdAt;
  final bool isVerified;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.idNumber,
    required this.mobileNumber,
    required this.userType,
    required this.createdAt,
    this.isVerified = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      idNumber: map['idNumber'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      userType: map['userType'] ?? 'buyer',
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'idNumber': idNumber,
      'mobileNumber': mobileNumber,
      'userType': userType,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
    };
  }
}
