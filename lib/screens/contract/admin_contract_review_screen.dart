// lib/screens/contracts/admin_contract_review_screen.dart
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:open_file/open_file.dart";
import "package:permission_handler/permission_handler.dart";
import "package:provider/provider.dart";
import "package:file_picker/file_picker.dart";
// import "package:firebase_storage/firebase_storage.dart";
import "dart:io";
import "../../model/contract_model.dart";
import "../../services/auth_service.dart";
import "../../services/contract_service.dart";
import "../../services/pdf_service.dart";
import "../../widget/contract_preview.dart";

class AdminContractReviewScreen extends StatefulWidget {
  final ContractModel contract;

  const AdminContractReviewScreen({super.key, required this.contract});

  @override
  State<AdminContractReviewScreen> createState() =>
      _AdminContractReviewScreenState();
}

class _AdminContractReviewScreenState extends State<AdminContractReviewScreen> {
  bool _isGeneratingPdf = false;
  bool _isMarkingAsSent = false;
  bool _isUploadingApproval = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Contract Review").tr(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Contract Status Card
            _buildStatusCard(),

            // Contract Preview
            ContractPreview(contract: widget.contract),

            // Signatures Summary
            _buildSignaturesSummary(),

            // Admin Actions based on status
            _buildAdminActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    if (widget.contract.departmentApprovedPdfUrl != null) {
      icon = Icons.verified;
      color = Colors.green;
      title = "Contract Approved".tr();
      subtitle = "Department approval received".tr();
    } else if (widget.contract.sentToDepartment) {
      icon = Icons.hourglass_empty;
      color = Colors.orange;
      title = "Pending Department Approval".tr();
      subtitle = "Waiting for Transportation Department".tr();
    } else {
      icon = Icons.assignment;
      color = Colors.blue;
      title = "Ready for Processing".tr();
      subtitle = "Generate PDF and submit to department".tr();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          if (widget.contract.sentToDepartmentAt != null) ...[
            const SizedBox(height: 8),
            Text(
              "Sent on:".tr() +
                  "${DateFormat("dd/MM/yyyy").format(widget.contract.sentToDepartmentAt!)}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignaturesSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
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
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(height: 8),
              Text(
                "All Signatures Collected".tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${widget.contract.signatures.length}" + "signatures verified",
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "Payment completed on".tr() +
                "${widget.contract.paidAt != null ? DateFormat("dd/MM/yyyy").format(widget.contract.paidAt!) : "N/A"}",
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Step 1: Generate PDF
          if (widget.contract.generatedPdfUrl == null &&
              !widget.contract.sentToDepartment) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingPdf ? null : _generatePdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isGeneratingPdf
                    ? "Generating PDF...".tr()
                    : "Generate Contract PDF".tr()),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Step 2: Download generated PDF and mark as sent
          if (widget.contract.generatedPdfUrl != null &&
              !widget.contract.sentToDepartment) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.download),
                label: Text("Download Generated PDF").tr(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isMarkingAsSent ? null : _markAsSentToDepartment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                icon: _isMarkingAsSent
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isMarkingAsSent
                      ? "Updating Status...".tr()
                      : "Mark as Sent to Department".tr(),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Click after submitting to Transportation Department".tr(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],

          // Step 3: Upload approved PDF

          // if (widget.contract.sentToDepartment &&
          //     widget.contract.departmentApprovedPdfUrl == null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber),
            ),
            child: Column(
              children: [
                Icon(Icons.upload_file, size: 48, color: Colors.amber.shade700),
                const SizedBox(height: 12),
                Text(
                  "Upload Department Approved PDF".tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Once you receive the approved PDF from the Transportation Department, upload it here"
                      .tr(),
                  style: TextStyle(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingApproval ? null : _uploadApprovedPdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    icon: _isUploadingApproval
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isUploadingApproval
                        ? "Uploading...".tr()
                        : "Upload Approved PDF".tr()),
                  ),
                ),
              ],
            ),
          ),
          // ],

          // Step 4: Contract is fully approved
          if (widget.contract.departmentApprovedPdfUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle,
                      size: 48, color: Colors.green.shade700),
                  const SizedBox(height: 12),
                  Text(
                    "Contract Fully Approved".tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "The contract has been approved by the Transportation Department and is now finalized."
                        .tr(),
                    style: TextStyle(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _downloadPdf(),
                    icon: const Icon(Icons.download),
                    label: Text("Download Final PDF".tr()),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    setState(() => _isGeneratingPdf = true);

    try {
      final pdfBytes = await PdfService.generateContractPdf(widget.contract);

      // Ensure permission is granted
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) throw Exception("Storage permission denied");
      }

      final downloadsDir = Directory('/storage/emulated/0/Download');
      final pdfFile = File(
          '${downloadsDir.path}/contract_${widget.contract.contractNumber}.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PDF generated and saved successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error generating PDF: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _markAsSentToDepartment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Submission".tr()),
        content: Text(
          "Have you submitted the contract to the Transportation Department?"
              .tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Yes, Submitted".tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isMarkingAsSent = true);

      try {
        await context.read<ContractService>().markContractAsSentToDepartment(
              widget.contract.id,
              context.read<AuthService>().currentUser!.uid,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Contract marked as sent to department".tr()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error:" + "${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isMarkingAsSent = false);
        }
      }
    }
  }

  Future<void> _uploadApprovedPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isUploadingApproval = true);

        final pickedFile = File(result.files.single.path!);

        // Ensure permission is granted
        if (Platform.isAndroid) {
          var status = await Permission.storage.request();
          if (!status.isGranted) throw Exception("Storage permission denied");
        }

        // Save file to Downloads folder
        final downloadsDir = Directory('/storage/emulated/0/Download');
        final targetFile = File(
            '${downloadsDir.path}/approved_${widget.contract.contractNumber}.pdf');
        await pickedFile.copy(targetFile.path);

        // IMPORTANT: Update the contract in Firestore
        // Since you're not using Firebase Storage, you need to store the local path
        // or implement a different solution
        await context.read<ContractService>().uploadDepartmentApprovedPdf(
              widget.contract.id,
              targetFile.path, // Store the local path
              context.read<AuthService>().currentUser!.uid,
            );

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              icon:
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
              title: Text("Contract Finalized".tr()),
              content: Text(
                "The department-approved PDF has been uploaded successfully. "
                        .tr() +
                    "All parties have been notified and can now download the final contract."
                        .tr(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text("OK".tr()),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error uploading PDF:".tr() + " ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingApproval = false);
    }
  }

  void _downloadPdf() async {
    final filePath =
        '/storage/emulated/0/Download/contract_${widget.contract.contractNumber}.pdf';
    final file = File(filePath);

    if (await file.exists()) {
      // Use any PDF viewer plugin (like open_file or advance_pdf_viewer)
      await OpenFile.open(filePath);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF file not found.")),
      );
    }
  }
}
