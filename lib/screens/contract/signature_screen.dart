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
  bool _isVerifying = false;
  bool _isVerified = false;
  bool _isSigning = false;

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Progress Indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStepIndicator(
                    '1',
                    'Review',
                    true,
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _hasAgreed
                          ? const Color(0xFF1A3A6F)
                          : Colors.grey[300],
                    ),
                  ),
                  _buildStepIndicator(
                    '2',
                    'Verify',
                    _hasAgreed,
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _isVerified
                          ? const Color(0xFF1A3A6F)
                          : Colors.grey[300],
                    ),
                  ),
                  _buildStepIndicator(
                    '3',
                    'Sign',
                    _isVerified,
                  ),
                ],
              ),
            ),

            // Contract Preview
            ContractPreview(contract: widget.contract),

            // Agreement Checkbox
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.gavel,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Legal Agreement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _hasAgreed,
                    onChanged: _isVerified
                        ? null
                        : (value) => setState(() => _hasAgreed = value!),
                    title: const Text(
                      'I have read and agree to the terms of this contract',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'By checking this box, you acknowledge that you have reviewed all contract details and agree to proceed with the signature.',
                      style: TextStyle(fontSize: 12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // Verification Section
            if (_hasAgreed && !_isVerified) ...[
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Identity Verification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'We will send an OTP to your registered mobile number ending with ${_getMaskedPhone()}',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isVerifying ? null : _requestOTP,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        icon: _isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.phone_android),
                        label: Text(
                          _isVerifying ? 'Sending OTP...' : 'Send OTP',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Signature Section
            if (_isVerified) ...[
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.draw,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Digital Signature',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user,
                              color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Identity verified. Please sign below to complete the process.',
                              style: TextStyle(
                                color: Colors.green[900],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Draw your signature in the box below:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSigning ? null : _submitSignature,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: _isSigning
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Submit Signature',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'This signature is legally binding',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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

  Widget _buildStepIndicator(String number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1A3A6F) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFF1A3A6F) : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _getMaskedPhone() {
    final auth = context.read<AuthService>();
    final phone = auth.currentUser?.mobileNumber ?? '';
    if (phone.length >= 4) {
      return '***${phone.substring(phone.length - 4)}';
    }
    return '****';
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
              'Your digital signature is legally binding and equivalent to a handwritten signature.',
            ),
            SizedBox(height: 12),
            Text('The signature process includes:'),
            SizedBox(height: 8),
            Text('• Identity verification via OTP'),
            Text('• Time and date stamping'),
            Text('• Secure storage and encryption'),
            Text('• Audit trail for legal compliance'),
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

  Future<void> _requestOTP() async {
    setState(() => _isVerifying = true);

    try {
      await context.read<AuthService>().sendVerificationOTP(widget.contract.id);

      if (mounted) {
        // Show OTP dialog
        final otp = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _OTPDialog(),
        );

        if (otp != null) {
          final verified = await context.read<AuthService>().verifyOTP(
                widget.contract.id,
                otp,
              );

          if (verified) {
            setState(() => _isVerified = true);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Identity verified successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid OTP. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
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
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _submitSignature() async {
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
      final Uint8List? signatureData = await _signatureController.toPngBytes();
      if (signatureData == null) {
        throw Exception('Failed to capture signature');
      }

      final signatureBase64 = base64Encode(signatureData);

      await context.read<ContractService>().signContract(
            widget.contract.id,
            context.read<AuthService>().currentUser!.uid,
            signatureBase64,
          );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            title: const Text('Signature Submitted'),
            content: const Text(
              'Your signature has been submitted successfully. '
              'You will be notified when all parties have signed.',
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

class _OTPDialog extends StatefulWidget {
  @override
  State<_OTPDialog> createState() => _OTPDialogState();
}

class _OTPDialogState extends State<_OTPDialog> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter OTP'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Please enter the 6-digit OTP sent to your registered mobile number',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 40,
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Resend OTP logic
            },
            child: const Text('Resend OTP'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final otp = _otpControllers.map((c) => c.text).join();
            if (otp.length == 6) {
              Navigator.pop(context, otp);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter all 6 digits'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          child: const Text('Verify'),
        ),
      ],
    );
  }
}


//   @override
//   void dispose() {
//     for (var controller in _otpControllers) {
//       controller.dispose();
//     }
//     for (var node in _focusNodes) {
//       node.dispose();
//     }
//     super.dispose();
//   }
// } return 'Please enter boat type';
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             TextFormField(
//               controller: _hullNumberController,
//               decoration: const InputDecoration(
//                 labelText: 'Hull Number',
//                 prefixIcon: Icon(Icons.numbers),
//               ),
//               validator: (value) {
//                 if (value?.isEmpty ?? true) {
//                   return 'Please enter hull number';
//                 } 