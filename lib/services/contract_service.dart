// lib/services/contract_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../model/contract_model.dart';
import '../services/pdf_service.dart';

// Conditional imports for web and non-web platforms
import 'contract_service_stub.dart'
    if (dart.library.html) 'contract_service_web.dart'
    if (dart.library.io) 'contract_service_mobile.dart' as platform;

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
          ipAddress: '', // You can get this from the request in a real app
          deviceInfo: '', // You can get device info here
          isVerified: true,
        ),
      };

      final contractData = ContractModel(
        id: contractId,
        contractNumber: contractNumber,
        sellerId: sellerId,
        buyerId: buyerId,
        witnessIds: witnessIds,
        status: ContractStatus.pendingSignatures,
        createdAt: DateTime.now(),
        sellerDetails: sellerDetails,
        buyerDetails: buyerDetails,
        boatDetails: boatDetails,
        saleAmount: saleAmount,
        saleAmountText: saleAmountText,
        paymentMethod: paymentMethod,
        additionalTerms: additionalTerms,
        saleLocation: saleLocation,
        saleDate: saleDate,
        signatures: sellerSignature,
      );

      await _firestore
          .collection('contracts')
          .doc(contractId)
          .set(contractData.toMap());

      // Send notifications to buyer and witnesses
      await _sendContractNotifications(contractId, buyerId, witnessIds);

      return contractId;
    } catch (e) {
      print('Error creating contract: $e');
      throw Exception('Failed to create contract: $e');
    }
  }

  Future<String> _generateContractNumber() async {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');

    // Get the count of contracts created this month
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final snapshot = await _firestore
        .collection('contracts')
        .where('createdAt',
            isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('createdAt', isLessThanOrEqualTo: endOfMonth.toIso8601String())
        .get();

    final count = snapshot.docs.length + 1;
    return 'MC-$year$month-${count.toString().padLeft(4, '0')}';
  }

  Future<void> _sendContractNotifications(
      String contractId, String buyerId, List<String> witnessIds) async {
    final batch = _firestore.batch();

    // Notification for buyer
    batch.set(_firestore.collection('notifications').doc(), {
      'userId': buyerId,
      'type': 'contract_signature_required',
      'contractId': contractId,
      'title': 'New Contract Requires Your Signature',
      'message': 'You have been added as a buyer in a new contract.',
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    });

    // Notifications for witnesses
    for (String witnessId in witnessIds) {
      batch.set(_firestore.collection('notifications').doc(), {
        'userId': witnessId,
        'type': 'contract_witness_required',
        'contractId': contractId,
        'title': 'Witness Signature Required',
        'message': 'You have been added as a witness in a new contract.',
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    }

    await batch.commit();
  }

  Future<void> addSignature({
    required String contractId,
    required String userId,
    required String signatureData,
  }) async {
    try {
      final contract = await _firestore
          .collection('contracts')
          .doc(contractId)
          .get()
          .then((doc) => ContractModel.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }));

      // Upload signature image
      final signatureUrl =
          await _uploadSignature(contractId, userId, signatureData);

      // Create signature data
      final signature = SignatureData(
        userId: userId,
        signatureImageUrl: signatureUrl,
        signedAt: DateTime.now(),
        ipAddress: '', // Get from request
        deviceInfo: '', // Get device info
        isVerified: true,
      );

      // Update signatures
      final updatedSignatures =
          Map<String, SignatureData>.from(contract.signatures);
      updatedSignatures[userId] = signature;

      // Check if all parties have signed
      final allParties = [contract.buyerId, ...contract.witnessIds];
      final allSigned =
          allParties.every((id) => updatedSignatures.containsKey(id));

      // Update contract
      await _firestore.collection('contracts').doc(contractId).update({
        'signatures.$userId': signature.toMap(),
        'status': allSigned
            ? ContractStatus.pendingPayment.index
            : ContractStatus.pendingSignatures.index,
        if (allSigned) 'signedAt': DateTime.now().toIso8601String(),
      });

      // If all signed, notify seller about payment
      if (allSigned) {
        await _firestore.collection('notifications').add({
          'userId': contract.sellerId,
          'type': 'payment_required',
          'contractId': contractId,
          'title': 'Contract Signed - Payment Required',
          'message': 'All parties have signed. Please proceed with payment.',
          'createdAt': DateTime.now().toIso8601String(),
          'read': false,
        });
      }

      notifyListeners();
    } catch (e) {
      print('Error adding signature: $e');
      throw Exception('Failed to add signature: $e');
    }
  }

  Future<String> _uploadSignature(
      String contractId, String userId, String signatureData) async {
    try {
      // Convert base64 to bytes
      final bytes = base64Decode(signatureData.split(',').last);

      // Upload to Firebase Storage
      final ref =
          _storage.ref().child('contracts/$contractId/signatures/$userId.png');

      final uploadTask = await ref.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading signature: $e');
      throw Exception('Failed to upload signature: $e');
    }
  }

  Future<void> addPayment({
    required String contractId,
    required String transactionId,
    required String receiptImage,
    required String paymentMethod,
    required double amount,
  }) async {
    try {
      // Upload receipt image
      final receiptUrl = await _uploadReceipt(contractId, receiptImage);

      final paymentData = PaymentData(
        transactionId: transactionId,
        amount: amount,
        paymentMethod: paymentMethod,
        receiptUrl: receiptUrl,
        paidAt: DateTime.now(),
        isVerified: false,
      );

      await _firestore.collection('contracts').doc(contractId).update({
        'paymentData': paymentData.toMap(),
        'status': ContractStatus.pendingApproval.index,
        'paidAt': DateTime.now().toIso8601String(),
      });

      // Notify admin about new contract pending approval
      await _notifyAdminsAboutPendingContract(contractId);

      notifyListeners();
    } catch (e) {
      print('Error adding payment: $e');
      throw Exception('Failed to add payment: $e');
    }
  }

  Future<String> _uploadReceipt(String contractId, String receiptImage) async {
    try {
      final bytes = base64Decode(receiptImage.split(',').last);
      final ref = _storage.ref().child('contracts/$contractId/receipt.png');

      final uploadTask = await ref.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading receipt: $e');
      throw Exception('Failed to upload receipt: $e');
    }
  }

  Future<void> _notifyAdminsAboutPendingContract(String contractId) async {
    // Get all admin users
    final adminsSnapshot = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'admin')
        .get();

    final batch = _firestore.batch();

    for (var doc in adminsSnapshot.docs) {
      batch.set(_firestore.collection('notifications').doc(), {
        'userId': doc.id,
        'type': 'contract_pending_approval',
        'contractId': contractId,
        'title': 'New Contract Pending Approval',
        'message': 'A new contract is ready for review and approval.',
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    }

    await batch.commit();
  }

  // Admin functions
  Future<void> generateAndUploadPDF(String contractId) async {
    try {
      final contract = await _firestore
          .collection('contracts')
          .doc(contractId)
          .get()
          .then((doc) => ContractModel.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }));

      // Generate PDF
      final pdfService = PdfService();
      final pdfBytes = await PdfService.generateContractPdf(contract);

      // Upload to Firebase Storage
      final ref =
          _storage.ref().child('contracts/$contractId/generated_contract.pdf');

      final uploadTask = await ref.putData(pdfBytes);
      final pdfUrl = await uploadTask.ref.getDownloadURL();

      // Update contract with generated PDF URL
      await _firestore.collection('contracts').doc(contractId).update({
        'generatedPdfUrl': pdfUrl,
      });

      notifyListeners();
    } catch (e) {
      print('Error generating PDF: $e');
      throw Exception('Failed to generate PDF: $e');
    }
  }

  // Updated admin methods with correct names
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
        'sentToDepartment': true,
        'sentToDepartmentAt': DateTime.now().toIso8601String(),
        'status': ContractStatus.pendingDepartment.index,
        'adminId': adminId,
      });

      // Notify all parties
      await _notifyPartiesAboutDepartmentSubmission(contractId);

      notifyListeners();
    } catch (e) {
      print('Error marking as sent: $e');
      throw Exception('Failed to update contract: $e');
    }
  }

  Future<void> uploadDepartmentApprovedPdf(
      String contractId, String pdfUrl, String adminId) async {
    try {
      await _firestore.collection('contracts').doc(contractId).update({
        'departmentApprovedPdfUrl': pdfUrl,
        'departmentApprovedAt': DateTime.now().toIso8601String(),
        'status': ContractStatus.approved.index,
        'approvedAt': DateTime.now().toIso8601String(),
        'finalPdfUrl': pdfUrl,
        'adminId': adminId,
      });

      // Notify all parties
      await _notifyAllPartiesAboutApproval(contractId);

      notifyListeners();
    } catch (e) {
      print('Error uploading approval: $e');
      throw Exception('Failed to upload approval: $e');
    }
  }

  // Signature method without OTP
  Future<void> signContract(
      String contractId, String userId, String signatureData,
      {required bool agreedToTerms}) async {
    try {
      // Get the contract first
      final contract = await _firestore
          .collection('contracts')
          .doc(contractId)
          .get()
          .then((doc) => ContractModel.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }));

      // Upload signature image
      final signatureUrl =
          await _uploadSignature(contractId, userId, signatureData);

      // Create signature data
      final signature = SignatureData(
        userId: userId,
        signatureImageUrl: signatureUrl,
        signedAt: DateTime.now(),
        ipAddress: '', // Get from request
        deviceInfo: '', // Get device info
        isVerified: true,
      );

      // Update signatures
      final updatedSignatures =
          Map<String, SignatureData>.from(contract.signatures);
      updatedSignatures[userId] = signature;

      // Check if all parties have signed
      final allParties = [contract.buyerId, ...contract.witnessIds];
      final allSigned =
          allParties.every((id) => updatedSignatures.containsKey(id));

      // Update contract
      await _firestore.collection('contracts').doc(contractId).update({
        'signatures.$userId': signature.toMap(),
        'status': allSigned
            ? ContractStatus.pendingPayment.index
            : ContractStatus.pendingSignatures.index,
        if (allSigned) 'signedAt': DateTime.now().toIso8601String(),
      });

      // If all signed, notify seller about payment
      if (allSigned) {
        await _firestore.collection('notifications').add({
          'userId': contract.sellerId,
          'type': 'payment_required',
          'contractId': contractId,
          'title': 'Contract Signed - Payment Required',
          'message': 'All parties have signed. Please proceed with payment.',
          'createdAt': DateTime.now().toIso8601String(),
          'read': false,
        });
      }

      notifyListeners();
    } catch (e) {
      print('Error signing contract: $e');
      throw Exception('Failed to sign contract: $e');
    }
  }

  // Process payment method
  Future<void> processPayment({
    required String contractId,
    required String paymentId,
    required String transactionId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final paymentData = PaymentData(
        transactionId: transactionId,
        amount: amount,
        paymentMethod: paymentMethod,
        receiptUrl: '', // Add receipt upload if needed
        paidAt: DateTime.now(),
        isVerified: false,
      );

      await _firestore.collection('contracts').doc(contractId).update({
        'paymentData': paymentData.toMap(),
        'status': ContractStatus.pendingApproval.index,
        'paidAt': DateTime.now().toIso8601String(),
      });

      // Notify admin about new contract pending approval
      await _notifyAdminsAboutPendingContract(contractId);

      notifyListeners();
    } catch (e) {
      print('Error processing payment: $e');
      throw Exception('Failed to process payment: $e');
    }
  }

  Future<void> _notifyAllPartiesAboutApproval(String contractId) async {
    final contract = await _firestore
        .collection('contracts')
        .doc(contractId)
        .get()
        .then((doc) => ContractModel.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }));

    final batch = _firestore.batch();
    final allParties = [
      contract.sellerId,
      contract.buyerId,
      ...contract.witnessIds
    ];

    for (String userId in allParties) {
      batch.set(_firestore.collection('notifications').doc(), {
        'userId': userId,
        'type': 'contract_approved',
        'contractId': contractId,
        'title': 'Contract Approved',
        'message':
            'The contract has been officially approved. You can now download the final document.',
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    }

    await batch.commit();
  }

  Future<void> _notifyPartiesAboutDepartmentSubmission(
      String contractId) async {
    final contract = await _firestore
        .collection('contracts')
        .doc(contractId)
        .get()
        .then((doc) => ContractModel.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }));

    final batch = _firestore.batch();
    final allParties = [
      contract.sellerId,
      contract.buyerId,
      ...contract.witnessIds
    ];

    for (String userId in allParties) {
      batch.set(_firestore.collection('notifications').doc(), {
        'userId': userId,
        'type': 'contract_sent_to_department',
        'contractId': contractId,
        'title': 'Contract Sent to Department',
        'message':
            'Your contract has been submitted to the Transportation Department for approval.',
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    }

    await batch.commit();
  }

  // PDF Download method - uses platform-specific implementation
  Future<void> downloadPdf(String pdfUrl, String fileName) async {
    try {
      await platform.downloadFile(pdfUrl, fileName);
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
