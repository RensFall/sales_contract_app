// lib/screens/contracts/signature_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../../model/contract_model.dart';
import '../../services/auth_service.dart';
import '../../services/contract_service.dart';
import '../../widget/contract_preview.dart';

class SignatureScreen extends StatefulWidget {
  final ContractModel contract;

  const SignatureScreen({super.key, required this.contract});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool _hasAgreed = false;
  bool _isSigning = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final currentUserId = auth.currentUser?.uid;

    // Check if user has already signed
    final hasAlreadySigned =
        widget.contract.signatures.containsKey(currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Contract'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showSignatureInfo(context),
          ),
        ],
      ),
      body: hasAlreadySigned
          ? _buildAlreadySignedView()
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Contract Preview
                  ContractPreview(contract: widget.contract),

                  // Agreement Section
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.gavel, color: Colors.amber[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Contract Agreement',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Terms checkboxes
                        CheckboxListTile(
                          value: _hasAgreed,
                          onChanged: (value) =>
                              setState(() => _hasAgreed = value!),
                          title: const Text(
                            'I have read and understood all contract terms',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'By checking this box, you acknowledge that:\n'
                            '• You have reviewed all contract details\n'
                            '• You agree to all terms and conditions\n'
                            '• Your digital signature is legally binding\n'
                            '• You understand this action cannot be undone',
                            style: TextStyle(fontSize: 12, height: 1.5),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                  // Signature Section (shown only when agreed)
                  if (_hasAgreed) ...[
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.draw, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Digital Signature',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Signer info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person,
                                    size: 20, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Signing as: ${auth.currentUser?.fullName ?? ""}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'ID: ${auth.currentUser?.idNumber ?? ""}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm')
                                      .format(DateTime.now()),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'Please draw your signature below:',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),

                          // Signature pad
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  Signature(
                                    controller: _signatureController,
                                    backgroundColor: Colors.white,
                                  ),
                                  if (_signatureController.isEmpty)
                                    Center(
                                      child: Text(
                                        'Sign Here',
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Clear button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () => _signatureController.clear(),
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                ),
                              ),
                              Text(
                                'Your signature will be added to the contract',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Submit button
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSigning ? null : _submitSignature,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: _isSigning
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Submit Signature',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ],

                  // Show agreement prompt if not agreed yet
                  if (!_hasAgreed) ...[
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_turned_in,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Please read and accept the contract terms above',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildAlreadySignedView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green[600],
            ),
            const SizedBox(height: 24),
            const Text(
              'You have already signed this contract',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Signed on: ${widget.contract.signatures[context.read<AuthService>().currentUser?.uid]?.signedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(widget.contract.signatures[context.read<AuthService>().currentUser?.uid]!.signedAt) : ""}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignatureInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Digital Signature Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your digital signature is legally binding and equivalent to a handwritten signature under Saudi law.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'By signing this contract:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• You confirm all information is accurate'),
            Text('• You agree to all terms and conditions'),
            Text('• You understand this is a binding agreement'),
            Text('• Your signature will be permanently recorded'),
            SizedBox(height: 16),
            Text(
              'The signature includes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Your handwritten signature'),
            Text('• Date and time of signing'),
            Text('• Your user ID and name'),
            Text('• Agreement confirmation'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSignature() async {
    // Validate signature
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide your signature'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSigning = true);

    try {
      // Convert signature to base64
      final Uint8List? signatureData = await _signatureController.toPngBytes();
      if (signatureData == null) {
        throw Exception('Failed to capture signature');
      }

      final signatureBase64 = base64Encode(signatureData);

      // Submit signature without OTP verification
      await context.read<ContractService>().signContract(
            widget.contract.id,
            context.read<AuthService>().currentUser!.uid,
            signatureBase64,
            agreedToTerms: true, // Pass the agreement status
          );

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            title: const Text('Signature Submitted Successfully'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your signature has been recorded.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'You will be notified when all parties have signed the contract.',
                    style: TextStyle(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigning = false);
      }
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }
}
