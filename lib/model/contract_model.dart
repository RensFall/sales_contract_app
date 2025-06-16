// // lib/main.dart

// lib/models/contract_model.dart
enum ContractStatus {
  draft,
  pendingSignatures,
  signed,
  pendingPayment,
  pendingApproval,
  approved,
  cancelled
}

class ContractModel {
  final String id;
  final String sellerId;
  final String buyerId;
  final List<String> witnessIds;
  final ContractStatus status;
  final DateTime createdAt;
  final DateTime? signedAt;
  final DateTime? paidAt;
  final DateTime? approvedAt;

  // Contract Details
  final Map<String, dynamic> boatDetails;
  final double saleAmount;
  final String paymentMethod;
  final Map<String, dynamic> additionalTerms;
  final String saleLocation;
  final DateTime saleDate;

  // Signatures
  final Map<String, SignatureData> signatures;

  // Payment Details
  final PaymentData? paymentData;

  // Admin Approval
  final String? adminId;
  final String? adminSignatureUrl;
  final String? adminStampUrl;
  final String? finalPdfUrl;

  // Participants array for easier querying
  List<String> get participants => [sellerId, buyerId, ...witnessIds];

  ContractModel({
    required this.id,
    required this.sellerId,
    required this.buyerId,
    required this.witnessIds,
    required this.status,
    required this.createdAt,
    this.signedAt,
    this.paidAt,
    this.approvedAt,
    required this.boatDetails,
    required this.saleAmount,
    required this.paymentMethod,
    required this.additionalTerms,
    required this.saleLocation,
    required this.saleDate,
    required this.signatures,
    this.paymentData,
    this.adminId,
    this.adminSignatureUrl,
    this.adminStampUrl,
    this.finalPdfUrl,
  });

  factory ContractModel.fromMap(Map<String, dynamic> map) {
    return ContractModel(
      id: map['id'] ?? '',
      sellerId: map['sellerId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      witnessIds: List<String>.from(map['witnessIds'] ?? []),
      status: ContractStatus.values[map['status'] ?? 0],
      createdAt: DateTime.parse(map['createdAt']),
      signedAt:
          map['signedAt'] != null ? DateTime.parse(map['signedAt']) : null,
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
      approvedAt:
          map['approvedAt'] != null ? DateTime.parse(map['approvedAt']) : null,
      boatDetails: Map<String, dynamic>.from(map['boatDetails'] ?? {}),
      saleAmount: (map['saleAmount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      additionalTerms: Map<String, dynamic>.from(map['additionalTerms'] ?? {}),
      saleLocation: map['saleLocation'] ?? '',
      saleDate: DateTime.parse(map['saleDate']),
      signatures: (map['signatures'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, SignatureData.fromMap(value)),
          ) ??
          {},
      paymentData: map['paymentData'] != null
          ? PaymentData.fromMap(map['paymentData'])
          : null,
      adminId: map['adminId'],
      adminSignatureUrl: map['adminSignatureUrl'],
      adminStampUrl: map['adminStampUrl'],
      finalPdfUrl: map['finalPdfUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'witnessIds': witnessIds,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'signedAt': signedAt?.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'boatDetails': boatDetails,
      'saleAmount': saleAmount,
      'paymentMethod': paymentMethod,
      'additionalTerms': additionalTerms,
      'saleLocation': saleLocation,
      'saleDate': saleDate.toIso8601String(),
      'signatures':
          signatures.map((key, value) => MapEntry(key, value.toMap())),
      'paymentData': paymentData?.toMap(),
      'adminId': adminId,
      'adminSignatureUrl': adminSignatureUrl,
      'adminStampUrl': adminStampUrl,
      'finalPdfUrl': finalPdfUrl,
      'participants': participants,
    };
  }
}

class SignatureData {
  final String userId;
  final DateTime signedAt;
  final String signatureUrl;
  final bool isVerified;

  SignatureData({
    required this.userId,
    required this.signedAt,
    required this.signatureUrl,
    required this.isVerified,
  });

  factory SignatureData.fromMap(Map<String, dynamic> map) {
    return SignatureData(
      userId: map['userId'] ?? '',
      signedAt: DateTime.parse(map['signedAt']),
      signatureUrl: map['signatureUrl'] ?? '',
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'signedAt': signedAt.toIso8601String(),
      'signatureUrl': signatureUrl,
      'isVerified': isVerified,
    };
  }
}

class PaymentData {
  final String paymentId;
  final String transactionId;
  final double amount;
  final String currency;
  final String status;
  final DateTime paidAt;
  final String paymentMethod;
  final Map<String, dynamic>? metadata;

  PaymentData({
    required this.paymentId,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paidAt,
    required this.paymentMethod,
    this.metadata,
  });

  factory PaymentData.fromMap(Map<String, dynamic> map) {
    return PaymentData(
      paymentId: map['paymentId'] ?? '',
      transactionId: map['transactionId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'SAR',
      status: map['status'] ?? '',
      paidAt: DateTime.parse(map['paidAt']),
      paymentMethod: map['paymentMethod'] ?? '',
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'transactionId': transactionId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paidAt': paidAt.toIso8601String(),
      'paymentMethod': paymentMethod,
      'metadata': metadata,
    };
  }
}
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:provider/provider.dart';

// import '../screens/auth/login_screen.dart';
// import '../screens/home_screen.dart';
// import '../screens/splash_screen.dart';
// import '../services/auth_service.dart';
// import '../services/contract_service.dart';
// import '../util/theme.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(const MarineContractsApp());
// }

// class MarineContractsApp extends StatelessWidget {
//   const MarineContractsApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthService()),
//         ChangeNotifierProvider(create: (_) => ContractService()),
//       ],
//       child: MaterialApp(
//         title: 'Marine Contracts',
//         theme: AppTheme.lightTheme,
//         debugShowCheckedModeBanner: false,
//         home: const SplashScreen(),
//         routes: {
//           '/login': (context) => const LoginScreen(),
//           '/home': (context) => const HomeScreen(),
//         },
//       ),
//     );
//   }
// }

// // lib/models/user_model.dart
// class UserModel {
//   final String uid;
//   final String email;
//   final String fullName;
//   final String idNumber;
//   final String mobileNumber;
//   final String userType; // seller, buyer, witness, admin
//   final DateTime createdAt;
//   final bool isVerified;

//   UserModel({
//     required this.uid,
//     required this.email,
//     required this.fullName,
//     required this.idNumber,
//     required this.mobileNumber,
//     required this.userType,
//     required this.createdAt,
//     this.isVerified = false,
//   });

//   factory UserModel.fromMap(Map<String, dynamic> map) {
//     return UserModel(
//       uid: map['uid'] ?? '',
//       email: map['email'] ?? '',
//       fullName: map['fullName'] ?? '',
//       idNumber: map['idNumber'] ?? '',
//       mobileNumber: map['mobileNumber'] ?? '',
//       userType: map['userType'] ?? 'buyer',
//       createdAt:
//           DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
//       isVerified: map['isVerified'] ?? false,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'uid': uid,
//       'email': email,
//       'fullName': fullName,
//       'idNumber': idNumber,
//       'mobileNumber': mobileNumber,
//       'userType': userType,
//       'createdAt': createdAt.toIso8601String(),
//       'isVerified': isVerified,
//     };
//   }
// }

// // lib/models/contract_model.dart
// enum ContractStatus {
//   draft,
//   pendingSignatures,
//   signed,
//   pendingApproval,
//   approved,
//   cancelled
// }

// class ContractModel {
//   final String id;
//   final String sellerId;
//   final String buyerId;
//   final List<String> witnessIds;
//   final ContractStatus status;
//   final DateTime createdAt;
//   final DateTime? signedAt;
//   final DateTime? approvedAt;

//   // Contract Details
//   final Map<String, dynamic> boatDetails;
//   final double saleAmount;
//   final String paymentMethod;
//   final Map<String, dynamic> additionalTerms;
//   final String saleLocation;
//   final DateTime saleDate;

//   // Signatures
//   final Map<String, SignatureData> signatures;

//   // Admin Approval
//   final String? adminId;
//   final String? adminStampUrl;
//   final String? finalPdfUrl;

//   ContractModel({
//     required this.id,
//     required this.sellerId,
//     required this.buyerId,
//     required this.witnessIds,
//     required this.status,
//     required this.createdAt,
//     this.signedAt,
//     this.approvedAt,
//     required this.boatDetails,
//     required this.saleAmount,
//     required this.paymentMethod,
//     required this.additionalTerms,
//     required this.saleLocation,
//     required this.saleDate,
//     required this.signatures,
//     this.adminId,
//     this.adminStampUrl,
//     this.finalPdfUrl,
//   });

//   factory ContractModel.fromMap(Map<String, dynamic> map) {
//     return ContractModel(
//       id: map['id'] ?? '',
//       sellerId: map['sellerId'] ?? '',
//       buyerId: map['buyerId'] ?? '',
//       witnessIds: List<String>.from(map['witnessIds'] ?? []),
//       status: ContractStatus.values[map['status'] ?? 0],
//       createdAt: DateTime.parse(map['createdAt']),
//       signedAt:
//           map['signedAt'] != null ? DateTime.parse(map['signedAt']) : null,
//       approvedAt:
//           map['approvedAt'] != null ? DateTime.parse(map['approvedAt']) : null,
//       boatDetails: Map<String, dynamic>.from(map['boatDetails'] ?? {}),
//       saleAmount: map['saleAmount']?.toDouble() ?? 0.0,
//       paymentMethod: map['paymentMethod'] ?? '',
//       additionalTerms: Map<String, dynamic>.from(map['additionalTerms'] ?? {}),
//       saleLocation: map['saleLocation'] ?? '',
//       saleDate: DateTime.parse(map['saleDate']),
//       signatures: (map['signatures'] as Map<String, dynamic>?)?.map(
//             (key, value) => MapEntry(key, SignatureData.fromMap(value)),
//           ) ??
//           {},
//       adminId: map['adminId'],
//       adminStampUrl: map['adminStampUrl'],
//       finalPdfUrl: map['finalPdfUrl'],
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'sellerId': sellerId,
//       'buyerId': buyerId,
//       'witnessIds': witnessIds,
//       'status': status.index,
//       'createdAt': createdAt.toIso8601String(),
//       'signedAt': signedAt?.toIso8601String(),
//       'approvedAt': approvedAt?.toIso8601String(),
//       'boatDetails': boatDetails,
//       'saleAmount': saleAmount,
//       'paymentMethod': paymentMethod,
//       'additionalTerms': additionalTerms,
//       'saleLocation': saleLocation,
//       'saleDate': saleDate.toIso8601String(),
//       'signatures':
//           signatures.map((key, value) => MapEntry(key, value.toMap())),
//       'adminId': adminId,
//       'adminStampUrl': adminStampUrl,
//       'finalPdfUrl': finalPdfUrl,
//     };
//   }
// }

// class SignatureData {
//   final String userId;
//   final DateTime signedAt;
//   final String signatureUrl;
//   final bool isVerified;

//   SignatureData({
//     required this.userId,
//     required this.signedAt,
//     required this.signatureUrl,
//     required this.isVerified,
//   });

//   factory SignatureData.fromMap(Map<String, dynamic> map) {
//     return SignatureData(
//       userId: map['userId'] ?? '',
//       signedAt: DateTime.parse(map['signedAt']),
//       signatureUrl: map['signatureUrl'] ?? '',
//       isVerified: map['isVerified'] ?? false,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'userId': userId,
//       'signedAt': signedAt.toIso8601String(),
//       'signatureUrl': signatureUrl,
//       'isVerified': isVerified,
//     };
//   }
// }
