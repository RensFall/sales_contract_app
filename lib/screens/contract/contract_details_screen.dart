// lib/screens/contracts/contract_details_screen.dart
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:url_launcher/url_launcher.dart";
import "../../model/contract_model.dart";
import "../../services/auth_service.dart";
import "../../services/contract_service.dart";
import "../../widget/contract_preview.dart";

class ContractDetailsScreen extends StatelessWidget {
  final ContractModel contract;

  const ContractDetailsScreen({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final isParticipant = auth.currentUser != null &&
        (contract.sellerId == auth.currentUser!.uid ||
            contract.buyerId == auth.currentUser!.uid ||
            contract.witnessIds.contains(auth.currentUser!.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text("Contract #".tr() + "${contract.id.substring(0, 8)}"),
        actions: [
          if (contract.finalPdfUrl != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadPdf(context),
            ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              if (contract.status == ContractStatus.approved &&
                  contract.finalPdfUrl != null)
                PopupMenuItem(
                  value: "share",
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 12),
                      Text("Share".tr()),
                    ],
                  ),
                ),
              if (isParticipant &&
                  contract.status == ContractStatus.pendingSignatures)
                PopupMenuItem(
                  value: "cancel",
                  child: Row(
                    children: [
                      Icon(Icons.cancel, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text("Cancel Contract".tr(),
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: _getStatusColor(contract.status),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(contract.status),
                    size: 48,
                    color: _getStatusColor(contract.status),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getStatusText(contract.status),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(contract.status),
                    ),
                  ),
                  if (contract.status == ContractStatus.approved &&
                      contract.approvedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Approved on".tr() +
                          "${DateFormat("dd/MM/yyyy").format(contract.approvedAt!)}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),

            // Contract Preview
            ContractPreview(contract: contract),

            // Signatures Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Signatures".tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSignatureList(context),
                ],
              ),
            ),

            // Admin Stamp (if approved)
            if (contract.status == ContractStatus.approved &&
                contract.adminStampUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Official Stamp".tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 48,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Contract Verified".tr(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "This contract has been officially verified and stamped"
                                      .tr(),
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildSignatureList(BuildContext context) {
    final allParticipants = [
      {"id": contract.sellerId, "role": "Seller"}, // ✅ Add role
      {"id": contract.buyerId, "role": "Buyer"}, // ✅ Add role
      ...contract.witnessIds.map((id) => {"id": id, "role": "Witness"}),
    ];

    return Column(
      children: allParticipants.map((participant) {
        final signature = contract.signatures[participant["id"]];
        final isSigned = signature != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSigned ? Colors.green : Colors.grey,
              child: Icon(
                isSigned ? Icons.check : Icons.pending,
                color: Colors.white,
              ),
            ),
            title: Text(participant["role"]!.tr()), // Now safe to use
            subtitle: isSigned
                ? Text("Signed on ".tr() +
                    DateFormat("dd/MM/yyyy HH:mm").format(signature.signedAt))
                : Text("Pending signature".tr()),
            trailing: isSigned && signature.isVerified
                ? const Icon(Icons.verified_user, color: Colors.green)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.draft:
        return Colors.grey;
      case ContractStatus.pendingSignatures:
        return Colors.orange;
      case ContractStatus.signed:
        return Colors.blue;
      case ContractStatus.pendingApproval:
        return Colors.purple;
      case ContractStatus.approved:
        return Colors.green;
      case ContractStatus.cancelled:
        return Colors.red;
      case ContractStatus.pendingPayment:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ContractStatus.pendingDepartment:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  IconData _getStatusIcon(ContractStatus status) {
    switch (status) {
      case ContractStatus.draft:
        return Icons.edit_outlined;
      case ContractStatus.pendingSignatures:
        return Icons.pending_outlined;
      case ContractStatus.signed:
        return Icons.done_all;
      case ContractStatus.pendingApproval:
        return Icons.hourglass_empty;
      case ContractStatus.approved:
        return Icons.verified;
      case ContractStatus.cancelled:
        return Icons.cancel;
      case ContractStatus.pendingPayment:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ContractStatus.pendingDepartment:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String _getStatusText(ContractStatus status) {
    switch (status) {
      case ContractStatus.draft:
        return "Draft".tr();
      case ContractStatus.pendingSignatures:
        return "Pending Signatures".tr();
      case ContractStatus.signed:
        return "All Parties Signed".tr();
      case ContractStatus.pendingApproval:
        return "Pending Official Approval".tr();
      case ContractStatus.approved:
        return "Officially Approved".tr();
      case ContractStatus.cancelled:
        return "Cancelled".tr();
      case ContractStatus.pendingPayment:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ContractStatus.pendingDepartment:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Future<void> _downloadPdf(BuildContext context) async {
    if (contract.finalPdfUrl != null) {
      try {
        await launchUrl(Uri.parse(contract.finalPdfUrl!));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Could not download PDF".tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case "share":
        // Implement share functionality
        break;
      case "cancel":
        _cancelContract(context);
        break;
    }
  }

  Future<void> _cancelContract(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CancelContractDialog(),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await context
            .read<ContractService>()
            .cancelContract(contract.id, reason);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Contract cancelled".tr()),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error:".tr() + "${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _CancelContractDialog extends StatefulWidget {
  @override
  State<_CancelContractDialog> createState() => _CancelContractDialogState();
}

class _CancelContractDialogState extends State<_CancelContractDialog> {
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Cancel Contract".tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Are you sure you want to cancel this contract? This action cannot be undone."
                .tr(),
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: "Reason for cancellation".tr(),
              hintText: "Please provide a reason".tr(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Keep Contract".tr()),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _reasonController.text),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text("Cancel Contract".tr()),
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
