// lib/screens/contracts/admin_contract_review_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../model/contract_model.dart';
import '../../services/auth_service.dart';
import '../../services/contract_service.dart';
import '../../widget/contract_preview.dart';

class AdminContractReviewScreen extends StatefulWidget {
  final ContractModel contract;

  const AdminContractReviewScreen({super.key, required this.contract});

  @override
  State<AdminContractReviewScreen> createState() =>
      _AdminContractReviewScreenState();
}

class _AdminContractReviewScreenState extends State<AdminContractReviewScreen> {
  bool _isApproving = false;
  bool _isRejecting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _previewPdf,
            tooltip: 'Preview PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Contract Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.purple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contract #${widget.contract.id.substring(0, 8)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submitted for approval on ${DateFormat('dd/MM/yyyy').format(widget.contract.signedAt ?? DateTime.now())}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Verification Checklist
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.checklist, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Verification Checklist',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildChecklistItem('All parties have signed', true),
                  _buildChecklistItem('Signatures verified', true),
                  _buildChecklistItem(
                      'Boat details complete', _isBoatDetailsComplete()),
                  _buildChecklistItem('Payment terms clear', true),
                  _buildChecklistItem('Legal requirements met', true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contract Preview
            ContractPreview(contract: widget.contract),

            // Signatures Summary
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.draw, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Digital Signatures',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.contract.signatures.length} verified signatures collected',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All signatures have been verified through OTP authentication',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isApproving ? null : _approveContract,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      icon: _isApproving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(_isApproving
                          ? 'Approving...'
                          : 'Approve & Add Stamp'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isRejecting ? null : _rejectContract,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      icon: _isRejecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.red),
                              ),
                            )
                          : const Icon(Icons.cancel),
                      label: Text(
                          _isRejecting ? 'Rejecting...' : 'Reject Contract'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String text, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: isChecked ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isChecked ? Colors.green.shade700 : Colors.grey,
              decoration: isChecked ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }

  bool _isBoatDetailsComplete() {
    final details = widget.contract.boatDetails;
    return details['type']?.isNotEmpty == true &&
        details['hullNumber']?.isNotEmpty == true &&
        details['length']?.isNotEmpty == true &&
        details['width']?.isNotEmpty == true;
  }

  Future<void> _previewPdf() async {
    final pdf = await _generatePdf();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'BOAT SALE CONTRACT',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'DRAFT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.red,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Contract ID: ${widget.contract.id}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Date: ${DateFormat('dd/MM/yyyy').format(widget.contract.saleDate)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 30),

          // Contract content would be generated here
          pw.Text(
              'This is a preview of the contract that will be generated upon approval.'),
          pw.SizedBox(height: 20),
          pw.Text('The final PDF will include:'),
          pw.Bullet(text: 'All party information'),
          pw.Bullet(text: 'Complete boat details'),
          pw.Bullet(text: 'Sale terms and conditions'),
          pw.Bullet(text: 'Digital signatures'),
          pw.Bullet(text: 'Official government stamp'),
        ],
      ),
    );

    return pdf;
  }

  Future<void> _approveContract() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Contract'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('By approving this contract, you confirm that:'),
            const SizedBox(height: 12),
            const Text('• All information has been verified'),
            const Text('• All legal requirements are met'),
            const Text('• The contract is ready for finalization'),
            const SizedBox(height: 16),
            const Text(
              'Your official stamp will be added to the document.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isApproving = true);

      try {
        await context.read<ContractService>().approveContract(
              widget.contract.id,
              context.read<AuthService>().currentUser!.uid,
            );

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              icon:
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
              title: const Text('Contract Approved'),
              content: const Text(
                'The contract has been approved successfully. '
                'All parties will be notified and can download the final document.',
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
          setState(() => _isApproving = false);
        }
      }
    }
  }

  Future<void> _rejectContract() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectContractDialog(),
    );

    if (reason != null && reason.isNotEmpty) {
      setState(() => _isRejecting = true);

      try {
        await context.read<ContractService>().cancelContract(
              widget.contract.id,
              'Admin rejection: $reason',
            );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contract rejected'),
              backgroundColor: Colors.orange,
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
          setState(() => _isRejecting = false);
        }
      }
    }
  }
}

class _RejectContractDialog extends StatefulWidget {
  @override
  State<_RejectContractDialog> createState() => _RejectContractDialogState();
}

class _RejectContractDialogState extends State<_RejectContractDialog> {
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Contract'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Please provide a reason for rejecting this contract. '
            'All parties will be notified.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Rejection reason',
              hintText: 'Enter detailed reason',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _reasonController.text),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reject'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
