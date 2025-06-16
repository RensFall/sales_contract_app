// lib/screens/contracts/admin_approval_screen.dart
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
        title: const Text('Pending Approvals'),
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
                      'No contracts pending approval',
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
                  'Contract #${contract.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Review Required',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.directions_boat,
                contract.boatDetails['type'] ?? 'Unknown'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.payments,
                'SAR ${NumberFormat('#,###').format(contract.saleAmount)}'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.calendar_today,
                DateFormat('dd/MM/yyyy').format(contract.saleDate)),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.check_circle,
                '${contract.signatures.length} signatures verified'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
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
                    child: const Text('Review'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveContract(contract),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Quick Approve'),
                  ),
                ),
              ],
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
        Text(
          text,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _approveContract(ContractModel contract) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Contract'),
        content: const Text(
          'Are you sure you want to approve this contract? '
          'Your digital stamp will be added to the final document.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<ContractService>().approveContract(
              contract.id,
              context.read<AuthService>().currentUser!.uid,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contract approved successfully'),
              backgroundColor: Colors.green,
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
      }
    }
  }
}
