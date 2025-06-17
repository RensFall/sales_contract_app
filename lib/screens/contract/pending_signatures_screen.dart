// lib/screens/contracts/pending_signatures_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/contract_model.dart';
import '../../services/auth_service.dart';
import '../../services/contract_service.dart';
import 'package:intl/intl.dart';

import 'signature_screen.dart';

class PendingSignaturesScreen extends StatefulWidget {
  const PendingSignaturesScreen({super.key});

  @override
  State<PendingSignaturesScreen> createState() =>
      _PendingSignaturesScreenState();
}

class _PendingSignaturesScreenState extends State<PendingSignaturesScreen> {
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
    final contracts = context.watch<ContractService>();
    final pendingContracts = contracts.pendingSignatures;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Signatures'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadContracts,
        child: pendingContracts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pending signatures',
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
                itemCount: pendingContracts.length,
                itemBuilder: (context, index) {
                  final contract = pendingContracts[index];
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
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.directions_boat, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  // COULD be wrong here !!
                  (contract.boatDetails).toString(),
                  // COULD be wrong here !!
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.payments, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'SAR ${NumberFormat('#,###').format(contract.saleAmount)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignatureScreen(contract: contract),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Sign Contract'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
