// lib/screens/contracts/admin_approval_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../model/contract_model.dart';
import '../../services/auth_service.dart';
import '../../services/contract_service.dart';
import 'admin_contract_review_screen.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    final auth = context.read<AuthService>();
    final contracts = context.read<ContractService>();

    if (auth.currentUser != null) {
      await contracts.loadContracts(
        auth.currentUser!.uid,
        auth.currentUser!.userType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contracts = context.watch<ContractService>().pendingApprovals;

    return Scaffold(
      appBar: AppBar(
        title: Text("Pending Approvals").tr(),
      ),
      body: RefreshIndicator(
        onRefresh: _loadContracts,
        child: contracts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.approval,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No contracts pending approval".tr(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: contracts.length,
                itemBuilder: (context, index) {
                  final contract = contracts[index];
                  return _buildContractCard(contract);
                },
              ),
      ),
    );
  }

  Widget _buildContractCard(ContractModel contract) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Contract #".tr() + "${contract.contractNumber}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(contract.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(contract.status),
                    style: TextStyle(
                      color: _getStatusColor(contract.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.directions_boat,
                '${contract.boatDetails.vesselName} - ${contract.boatDetails.workNature}'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.payments,
                "SAR" + "${NumberFormat('#,###').format(contract.saleAmount)}"),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.calendar_today,
                DateFormat('dd/MM/yyyy').format(contract.saleDate)),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.check_circle,
                "${contract.signatures.length}" + "signatures verified".tr()),
            if (contract.status == ContractStatus.pendingDepartment) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Awaiting department approval".tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminContractReviewScreen(
                        contract: contract,
                      ),
                    ),
                  );
                },
                child: Text("Review Contract".tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return Colors.purple;
      case ContractStatus.pendingDepartment:
        return Colors.orange;
      case ContractStatus.approved:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return "Review Required".tr();
      case ContractStatus.pendingDepartment:
        return "Sent to Department".tr();
      case ContractStatus.approved:
        return "Approved".tr();
      default:
        return "Unknown".tr();
    }
  }
}
