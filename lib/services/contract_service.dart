// lib/services/contract_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
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
        // Admin sees contracts pending department approval
        query = query.where('status', whereIn: [
          ContractStatus.pendingApproval.index,
          ContractStatus.pendingDepartment.index
        ]);
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
          .where((c) =>
              c.status == ContractStatus.pendingApproval ||
              c.status == ContractStatus.pendingDepartment)
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
    required Map<String, dynamic> sellerDetails,
    required Map<String, dynamic> buyerDetails,
    required BoatDetails boatDetails,
    required double saleAmount,
    required String saleAmountText,
    required String paymentMethod,
    required Map<String, dynamic> additionalTerms,
    required String saleLocation,
    required DateTime saleDate,
  }) async {
    try {
      final contractId = _firestore.collection('contracts').doc().id;
      final contractNumber = await _generateContractNumber();

      // Add seller signature automatically
      final sellerSignature = {
        sellerId: SignatureData(
          userId: sellerId,
          signedAt: DateTime.now(),
          signatureUrl: 'auto_signed', // Seller auto-signs on creation
          agreedToTerms: true,
        )
      };

      final contract = ContractModel.fromMap({
        'id': contractId,
        'contractNumber': contractNumber,
        'sellerId': sellerId,
        'buyerId': buyerId,
        'witnessIds': witnessIds,
        'status': ContractStatus.pendingSignatures.index,
        'createdAt': DateTime.now().toIso8601String(),
        'sellerDetails': sellerDetails,
        'buyerDetails': buyerDetails,
        'boatDetails': boatDetails.toMap(),
        'saleAmount': saleAmount,
        'saleAmountText': saleAmountText,
        'paymentMethod': paymentMethod,
        'additionalTerms': additionalTerms,
        'saleLocation': saleLocation,
        'saleDate': saleDate.toIso8601String(),
        'signatures': sellerSignature.map((k, v) => MapEntry(k, v.toMap())),
      });

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

  Future<String> _generateContractNumber() async {
    // Get the last contract number
    final lastContract = await _firestore
        .collection('contracts')
        .orderBy('contractNumber', descending: true)
        .limit(1)
        .get();

    if (lastContract.docs.isEmpty) {
      return '0001';
    }

    final lastNumber =
        int.parse(lastContract.docs.first.data()['contractNumber']);
    return (lastNumber + 1).toString().padLeft(4, '0');
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

  // Updated signature method without OTP
  Future<void> signContract(
      String contractId, String userId, String signatureData,
      {required bool agreedToTerms}) async {
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
          'agreedToTerms': agreedToTerms,
        },
      });

      // Check if all signatures are collected
      await _checkAllSignatures(contractId);

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

      // Notify admins
      await _notifyAdminsForApproval(contractId);

      notifyListeners();
    } catch (e) {
      print('Error processing payment: $e');
      throw Exception('Failed to process payment: $e');
    }
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
        'title': 'Contract Ready for Processing',
        'message':
            'A paid contract is ready for PDF generation and department submission',
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    }

    await batch.commit();
  }

  // New methods for updated workflow
  Future<void> updateContractPdfUrl(String contractId, String pdfUrl) async {
    try {
      await _firestore.collection('contracts').doc(contractId).update({
        'generatedPdfUrl': pdfUrl,
      });
      notifyListeners();
    } catch (e) {
      print('Error updating PDF URL: $e');
      throw Exception('Failed to update PDF URL: $e');
    }
  }

  Future<void> markContractAsSentToDepartment(
      String contractId, String adminId) async {
    try {
      await _firestore.collection('contracts').doc(contractId).update({
        'status': ContractStatus.pendingDepartment.index,
        'sentToDepartment': true,
        'sentToDepartmentAt': DateTime.now().toIso8601String(),
        'adminId': adminId,
      });

      // Notify all parties
      await _notifyPartiesAboutDepartmentSubmission(contractId);

      notifyListeners();
    } catch (e) {
      print('Error marking as sent to department: $e');
      throw Exception('Failed to update contract status: $e');
    }
  }

  Future<void> uploadDepartmentApprovedPdf(
    String contractId,
    String approvedPdfUrl,
    String adminId,
  ) async {
    try {
      await _firestore.collection('contracts').doc(contractId).update({
        'status': ContractStatus.approved.index,
        'departmentApprovedPdfUrl': approvedPdfUrl,
        'departmentApprovedAt': DateTime.now().toIso8601String(),
        'approvedAt': DateTime.now().toIso8601String(),
        'finalPdfUrl': approvedPdfUrl, // Set the final PDF URL
      });

      // Notify all parties
      await _notifyContractApproval(contractId);

      notifyListeners();
    } catch (e) {
      print('Error uploading approved PDF: $e');
      throw Exception('Failed to upload approved PDF: $e');
    }
  }

  // Add the missing approveContract method
  Future<void> approveContract(String contractId, String adminId) async {
    try {
      await _firestore.collection('contracts').doc(contractId).update({
        'status': ContractStatus.approved.index,
        'approvedAt': DateTime.now().toIso8601String(),
        'adminId': adminId,
      });

      // Notify all parties
      await _notifyContractApproval(contractId);

      notifyListeners();
    } catch (e) {
      print('Error approving contract: $e');
      throw Exception('Failed to approve contract: $e');
    }
  }

  Future<void> _notifyPartiesAboutDepartmentSubmission(
      String contractId) async {
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
        'type': 'department_submission',
        'title': 'Contract Submitted to Department',
        'message':
            'Your contract has been submitted to the Transportation Department for approval.',
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    }

    await batch.commit();
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
        'title': 'Contract Officially Approved',
        'message':
            'Your boat sale contract has been approved by the Transportation Department. You can now download the final document.',
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    }

    await batch.commit();
  }

  // PDF Download method
  Future<void> downloadPdf(String pdfUrl, String fileName) async {
    try {
      if (kIsWeb) {
        // Web download
        final anchor = html.AnchorElement(href: pdfUrl)
          ..setAttribute('download', fileName)
          ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
      } else {
        // Mobile download - use url_launcher
        final uri = Uri.parse(pdfUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $pdfUrl';
        }
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      throw Exception('Failed to download PDF: $e');
    }
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
