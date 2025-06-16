// lib/services/contract_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import '../model/contract_model.dart';

class ContractService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<ContractModel> _contracts = [];
  List<ContractModel> get contracts => _contracts;

  List<ContractModel> _pendingSignatures = [];
  List<ContractModel> get pendingSignatures => _pendingSignatures;

  List<ContractModel> _pendingPayment = [];
  List<ContractModel> get pendingPayment => _pendingPayment;

  List<ContractModel> _pendingApprovals = [];
  List<ContractModel> get pendingApprovals => _pendingApprovals;

  Future<void> loadContracts(String userId, String userType) async {
    try {
      Query query = _firestore.collection('contracts');

      if (userType == 'admin') {
        // Admin sees contracts pending approval (after payment)
        query = query.where('status',
            isEqualTo: ContractStatus.pendingApproval.index);
      } else {
        // Regular users see contracts they're involved in
        query = query.where('participants', arrayContains: userId);
      }

      final snapshot = await query.get();
      _contracts = snapshot.docs
          .map((doc) => ContractModel.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();

      _filterContracts(userId, userType);
      notifyListeners();
    } catch (e) {
      print('Error loading contracts: $e');
      throw Exception('Failed to load contracts: $e');
    }
  }

  void _filterContracts(String userId, String userType) {
    if (userType == 'admin') {
      _pendingApprovals = _contracts
          .where((c) => c.status == ContractStatus.pendingApproval)
          .toList();
    } else {
      // Pending signatures - contracts where user hasn't signed yet
      _pendingSignatures = _contracts
          .where((c) =>
              c.status == ContractStatus.pendingSignatures &&
              !c.signatures.containsKey(userId) &&
              (c.buyerId == userId || c.witnessIds.contains(userId)))
          .toList();

      // Pending payment - contracts signed by all parties but not paid
      _pendingPayment = _contracts
          .where((c) =>
              c.status == ContractStatus.pendingPayment &&
              c.sellerId == userId) // Only seller can make payment
          .toList();
    }
  }

  Future<String> createContract({
    required String sellerId,
    required String buyerId,
    required List<String> witnessIds,
    required Map<String, dynamic> boatDetails,
    required double saleAmount,
    required String paymentMethod,
    required Map<String, dynamic> additionalTerms,
    required String saleLocation,
    required DateTime saleDate,
  }) async {
    try {
      final contractId = _firestore.collection('contracts').doc().id;

      // Add seller signature automatically
      final sellerSignature = {
        sellerId: SignatureData(
          userId: sellerId,
          signedAt: DateTime.now(),
          signatureUrl: 'auto_signed', // Seller auto-signs on creation
          isVerified: true,
        )
      };

      final contract = ContractModel(
        id: contractId,
        sellerId: sellerId,
        buyerId: buyerId,
        witnessIds: witnessIds,
        status: ContractStatus.pendingSignatures,
        createdAt: DateTime.now(),
        boatDetails: boatDetails,
        saleAmount: saleAmount,
        paymentMethod: paymentMethod,
        additionalTerms: additionalTerms,
        saleLocation: saleLocation,
        saleDate: saleDate,
        signatures: sellerSignature,
      );

      // Create contract document
      await _firestore
          .collection('contracts')
          .doc(contractId)
          .set(contract.toMap());

      // Send signature requests to buyer and witnesses
      await _sendSignatureRequests(contract);

      return contractId;
    } catch (e) {
      print('Error creating contract: $e');
      throw Exception('Failed to create contract: $e');
    }
  }

  Future<void> _sendSignatureRequests(ContractModel contract) async {
    final batch = _firestore.batch();

    // Create notifications for buyer and witnesses
    final participants = [contract.buyerId, ...contract.witnessIds];
    for (final userId in participants) {
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'id': notificationRef.id,
        'userId': userId,
        'contractId': contract.id,
        'type': 'signature_request',
        'title': 'New Contract Signature Request',
        'message': 'You have been requested to sign a boat sale contract',
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    }

    await batch.commit();
  }

  Future<void> signContract(
      String contractId, String userId, String signatureData) async {
    try {
      // Upload signature image
      final signatureUrl =
          await _uploadSignature(contractId, userId, signatureData);

      // Update contract with signature
      await _firestore.collection('contracts').doc(contractId).update({
        'signatures.$userId': {
          'userId': userId,
          'signedAt': DateTime.now().toIso8601String(),
          'signatureUrl': signatureUrl,
          'isVerified': true,
        },
      });

      // Check if all signatures are collected
      await _checkAllSignatures(contractId);

      // Reload contracts
      notifyListeners();
    } catch (e) {
      print('Error signing contract: $e');
      throw Exception('Failed to sign contract: $e');
    }
  }

  Future<String> _uploadSignature(
      String contractId, String userId, String signatureData) async {
    try {
      // Convert base64 to bytes
      final bytes = base64Decode(signatureData);

      // Create reference
      final ref = _storage.ref().child('signatures/$contractId/$userId.png');

      // Upload
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/png'),
      );

      // Get download URL
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading signature: $e');
      return signatureData; // Return base64 as fallback
    }
  }

  Future<void> _checkAllSignatures(String contractId) async {
    final doc = await _firestore.collection('contracts').doc(contractId).get();
    final contract = ContractModel.fromMap({
      ...doc.data()!,
      'id': doc.id,
    });

    // All required signatories
    final requiredSignatures = [
      contract.sellerId,
      contract.buyerId,
      ...contract.witnessIds
    ];

    // Check if everyone has signed
    final hasAllSignatures = requiredSignatures
        .every((userId) => contract.signatures.containsKey(userId));

    if (hasAllSignatures) {
      // Update status to pending payment
      await _firestore.collection('contracts').doc(contractId).update({
        'status': ContractStatus.pendingPayment.index,
        'signedAt': DateTime.now().toIso8601String(),
      });

      // Notify seller to make payment
      await _notifyForPayment(contract);
    }
  }

  Future<void> _notifyForPayment(ContractModel contract) async {
    final notificationRef = _firestore.collection('notifications').doc();
    await notificationRef.set({
      'id': notificationRef.id,
      'userId': contract.sellerId,
      'contractId': contract.id,
      'type': 'payment_required',
      'title': 'Payment Required',
      'message':
          'All parties have signed. Please proceed with payment to finalize the contract.',
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    });
  }

  Future<void> processPayment({
    required String contractId,
    required String paymentId,
    required String transactionId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      // Create payment data
      final paymentData = PaymentData(
        paymentId: paymentId,
        transactionId: transactionId,
        amount: amount,
        currency: 'SAR',
        status: 'completed',
        paidAt: DateTime.now(),
        paymentMethod: paymentMethod,
      );

      // Update contract with payment info and change status
      await _firestore.collection('contracts').doc(contractId).update({
        'status': ContractStatus.pendingApproval.index,
        'paidAt': DateTime.now().toIso8601String(),
        'paymentData': paymentData.toMap(),
      });

      // Generate initial PDF
      await _generateSignedPdf(contractId);

      // Notify admins
      await _notifyAdminsForApproval(contractId);

      notifyListeners();
    } catch (e) {
      print('Error processing payment: $e');
      throw Exception('Failed to process payment: $e');
    }
  }

  Future<void> _generateSignedPdf(String contractId) async {
    // TODO: Implement PDF generation with all signatures
    // This would generate a PDF with all the contract details and signatures
    // For now, we'll use a placeholder
    await _firestore.collection('contracts').doc(contractId).update({
      'signedPdfUrl': 'placeholder_signed_pdf_url',
    });
  }

  Future<void> _notifyAdminsForApproval(String contractId) async {
    // Get all admin users
    final admins = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'admin')
        .get();

    final batch = _firestore.batch();

    for (final admin in admins.docs) {
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'id': notificationRef.id,
        'userId': admin.id,
        'contractId': contractId,
        'type': 'approval_request',
        'title': 'Contract Pending Approval',
        'message':
            'A paid contract is ready for your approval and digital stamp',
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    }

    await batch.commit();
  }

  Future<void> approveContract(String contractId, String adminId) async {
    try {
      // Generate final PDF with admin stamp
      final finalPdfUrl = await _generateFinalPdf(contractId, adminId);

      await _firestore.collection('contracts').doc(contractId).update({
        'status': ContractStatus.approved.index,
        'approvedAt': DateTime.now().toIso8601String(),
        'adminId': adminId,
        'adminSignatureUrl':
            'admin_digital_signature_url', // TODO: Implement actual signature
        'adminStampUrl': 'official_stamp_url', // TODO: Implement actual stamp
        'finalPdfUrl': finalPdfUrl,
      });

      // Notify all parties
      await _notifyContractApproval(contractId);

      notifyListeners();
    } catch (e) {
      print('Error approving contract: $e');
      throw Exception('Failed to approve contract: $e');
    }
  }

  Future<String> _generateFinalPdf(String contractId, String adminId) async {
    // TODO: Implement PDF generation with admin stamp
    // This would:
    // 1. Take the signed PDF
    // 2. Add admin digital signature
    // 3. Add official stamp
    // 4. Upload to storage
    return 'final_pdf_url_placeholder';
  }

  Future<void> _notifyContractApproval(String contractId) async {
    final doc = await _firestore.collection('contracts').doc(contractId).get();
    final contract = ContractModel.fromMap({
      ...doc.data()!,
      'id': doc.id,
    });

    final participants = contract.participants;
    final batch = _firestore.batch();

    for (final userId in participants) {
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'id': notificationRef.id,
        'userId': userId,
        'contractId': contractId,
        'type': 'contract_approved',
        'title': 'Contract Approved',
        'message':
            'Your boat sale contract has been officially approved. You can now download the final document.',
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    }

    await batch.commit();
  }

  Future<void> cancelContract(String contractId, String reason) async {
    try {
      await _firestore.collection('contracts').doc(contractId).update({
        'status': ContractStatus.cancelled.index,
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancellationReason': reason,
      });

      notifyListeners();
    } catch (e) {
      print('Error cancelling contract: $e');
      throw Exception('Failed to cancel contract: $e');
    }
  }

  // Helper method to get approved contracts count for today (admin dashboard)
  int getApprovedToday() {
    final today = DateTime.now();
    return _contracts.where((c) {
      if (c.approvedAt == null) return false;
      return c.approvedAt!.year == today.year &&
          c.approvedAt!.month == today.month &&
          c.approvedAt!.day == today.day;
    }).length;
  }

  // Get user's contract statistics
  Map<String, int> getContractStats(String userId) {
    final userContracts =
        _contracts.where((c) => c.participants.contains(userId)).toList();

    return {
      'total': userContracts.length,
      'pending': userContracts
          .where((c) =>
              c.status == ContractStatus.pendingSignatures ||
              c.status == ContractStatus.pendingPayment)
          .length,
      'approved': userContracts
          .where((c) => c.status == ContractStatus.approved)
          .length,
      'cancelled': userContracts
          .where((c) => c.status == ContractStatus.cancelled)
          .length,
    };
  }
}
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';

// import '../model/contract_model.dart';

// class ContractService extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   List<ContractModel> _contracts = [];
//   List<ContractModel> get contracts => _contracts;

//   List<ContractModel> _pendingSignatures = [];
//   List<ContractModel> get pendingSignatures => _pendingSignatures;

//   List<ContractModel> _pendingApprovals = [];
//   List<ContractModel> get pendingApprovals => _pendingApprovals;

//   Future<void> loadContracts(String userId, String userType) async {
//     try {
//       Query query = _firestore.collection('contracts');

//       if (userType == 'admin') {
//         query = query.where('status',
//             isEqualTo: ContractStatus.pendingApproval.index);
//       } else {
//         query = query.where('participants', arrayContains: userId);
//       }

//       final snapshot = await query.get();
//       _contracts = snapshot.docs
//           .map((doc) =>
//               ContractModel.fromMap(doc.data() as Map<String, dynamic>))
//           .toList();

//       _filterContracts(userId, userType);
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to load contracts: $e');
//     }
//   }

//   void _filterContracts(String userId, String userType) {
//     if (userType == 'admin') {
//       _pendingApprovals = _contracts
//           .where((c) => c.status == ContractStatus.pendingApproval)
//           .toList();
//     } else {
//       _pendingSignatures = _contracts
//           .where((c) =>
//               c.status == ContractStatus.pendingSignatures &&
//               !c.signatures.containsKey(userId))
//           .toList();
//     }
//   }

//   Future<String> createContract({
//     required String sellerId,
//     required String buyerId,
//     required List<String> witnessIds,
//     required Map<String, dynamic> boatDetails,
//     required double saleAmount,
//     required String paymentMethod,
//     required Map<String, dynamic> additionalTerms,
//     required String saleLocation,
//     required DateTime saleDate,
//   }) async {
//     try {
//       final contractId = _firestore.collection('contracts').doc().id;

//       final contract = ContractModel(
//         id: contractId,
//         sellerId: sellerId,
//         buyerId: buyerId,
//         witnessIds: witnessIds,
//         status: ContractStatus.draft,
//         createdAt: DateTime.now(),
//         boatDetails: boatDetails,
//         saleAmount: saleAmount,
//         paymentMethod: paymentMethod,
//         additionalTerms: additionalTerms,
//         saleLocation: saleLocation,
//         saleDate: saleDate,
//         signatures: {},
//       );

//       await _firestore
//           .collection('contracts')
//           .doc(contractId)
//           .set(contract.toMap());

//       // Send signature requests
//       await _sendSignatureRequests(contract);

//       return contractId;
//     } catch (e) {
//       throw Exception('Failed to create contract: $e');
//     }
//   }

//   Future<void> _sendSignatureRequests(ContractModel contract) async {
//     // Send notifications to buyer and witnesses
//     final batch = _firestore.batch();

//     // Update contract status
//     batch.update(
//       _firestore.collection('contracts').doc(contract.id),
//       {'status': ContractStatus.pendingSignatures.index},
//     );

//     // Create notifications
//     final participants = [contract.buyerId, ...contract.witnessIds];
//     for (final userId in participants) {
//       final notificationRef = _firestore.collection('notifications').doc();
//       batch.set(notificationRef, {
//         'id': notificationRef.id,
//         'userId': userId,
//         'contractId': contract.id,
//         'type': 'signature_request',
//         'title': 'New Contract Signature Request',
//         'message': 'You have been requested to sign a boat sale contract',
//         'createdAt': DateTime.now().toIso8601String(),
//         'read': false,
//       });
//     }

//     await batch.commit();
//   }

//   Future<void> signContract(
//       String contractId, String userId, String signatureData) async {
//     try {
//       // Upload signature image
//       final signatureUrl =
//           await _uploadSignature(contractId, userId, signatureData);

//       // Update contract with signature
//       await _firestore.collection('contracts').doc(contractId).update({
//         'signatures.$userId': {
//           'userId': userId,
//           'signedAt': DateTime.now().toIso8601String(),
//           'signatureUrl': signatureUrl,
//           'isVerified': true,
//         },
//       });

//       // Check if all signatures are collected
//       await _checkAllSignatures(contractId);
//     } catch (e) {
//       throw Exception('Failed to sign contract: $e');
//     }
//   }

//   Future<String> _uploadSignature(
//       String contractId, String userId, String signatureData) async {
//     // Convert signature data to file and upload
//     // This is a placeholder - implement actual signature upload
//     return 'signature_url_placeholder';
//   }

//   Future<void> _checkAllSignatures(String contractId) async {
//     final doc = await _firestore.collection('contracts').doc(contractId).get();
//     final contract = ContractModel.fromMap(doc.data()!);

//     final requiredSignatures = [
//       contract.sellerId,
//       contract.buyerId,
//       ...contract.witnessIds
//     ];
//     final hasAllSignatures = requiredSignatures
//         .every((userId) => contract.signatures.containsKey(userId));

//     if (hasAllSignatures) {
//       await _firestore.collection('contracts').doc(contractId).update({
//         'status': ContractStatus.signed.index,
//         'signedAt': DateTime.now().toIso8601String(),
//       });

//       // Generate PDF and submit for admin approval
//       await _generateAndSubmitForApproval(contract);
//     }
//   }

//   Future<void> _generateAndSubmitForApproval(ContractModel contract) async {
//     // Generate PDF with all signatures
//     // Upload to storage
//     // Update contract status to pendingApproval

//     await _firestore.collection('contracts').doc(contract.id).update({
//       'status': ContractStatus.pendingApproval.index,
//     });

//     // Notify admins
//     await _notifyAdmins(contract.id);
//   }

//   Future<void> _notifyAdmins(String contractId) async {
//     final admins = await _firestore
//         .collection('users')
//         .where('userType', isEqualTo: 'admin')
//         .get();

//     final batch = _firestore.batch();

//     for (final admin in admins.docs) {
//       final notificationRef = _firestore.collection('notifications').doc();
//       batch.set(notificationRef, {
//         'id': notificationRef.id,
//         'userId': admin.id,
//         'contractId': contractId,
//         'type': 'approval_request',
//         'title': 'Contract Pending Approval',
//         'message': 'A new contract is ready for your approval',
//         'createdAt': DateTime.now().toIso8601String(),
//         'read': false,
//       });
//     }

//     await batch.commit();
//   }

//   Future<void> approveContract(String contractId, String adminId) async {
//     try {
//       // Generate final PDF with admin stamp
//       final finalPdfUrl = await _generateFinalPdf(contractId);

//       await _firestore.collection('contracts').doc(contractId).update({
//         'status': ContractStatus.approved.index,
//         'approvedAt': DateTime.now().toIso8601String(),
//         'adminId': adminId,
//         'finalPdfUrl': finalPdfUrl,
//       });

//       // Notify all parties
//       await _notifyContractApproval(contractId);
//     } catch (e) {
//       throw Exception('Failed to approve contract: $e');
//     }
//   }

//   Future<String> _generateFinalPdf(String contractId) async {
//     // Generate PDF with admin stamp
//     // Upload to storage
//     return 'final_pdf_url_placeholder';
//   }

//   Future<void> _notifyContractApproval(String contractId) async {
//     final doc = await _firestore.collection('contracts').doc(contractId).get();
//     final contract = ContractModel.fromMap(doc.data()!);

//     final participants = [
//       contract.sellerId,
//       contract.buyerId,
//       ...contract.witnessIds
//     ];
//     final batch = _firestore.batch();

//     for (final userId in participants) {
//       final notificationRef = _firestore.collection('notifications').doc();
//       batch.set(notificationRef, {
//         'id': notificationRef.id,
//         'userId': userId,
//         'contractId': contractId,
//         'type': 'contract_approved',
//         'title': 'Contract Approved',
//         'message': 'Your boat sale contract has been approved and finalized',
//         'createdAt': DateTime.now().toIso8601String(),
//         'read': false,
//       });
//     }

//     await batch.commit();
//   }

//   Future<void> cancelContract(String contractId, String reason) async {
//     await _firestore.collection('contracts').doc(contractId).update({
//       'status': ContractStatus.cancelled.index,
//       'cancelledAt': DateTime.now().toIso8601String(),
//       'cancellationReason': reason,
//     });
//   }
// }
