// lib/screens/contracts/my_contracts_screen.dart
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../model/contract_model.dart";
import "../../services/auth_service.dart";
import "../../services/contract_service.dart";
import "contract_details_screen.dart";

class MyContractsScreen extends StatefulWidget {
  const MyContractsScreen({super.key});

  @override
  State<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends State<MyContractsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final contracts = context.watch<ContractService>().contracts;

    final activeContracts = contracts
        .where((c) =>
            c.status != ContractStatus.cancelled &&
            c.status != ContractStatus.approved)
        .toList();

    final completedContracts =
        contracts.where((c) => c.status == ContractStatus.approved).toList();

    final cancelledContracts =
        contracts.where((c) => c.status == ContractStatus.cancelled).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("My Contracts".tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Active".tr()),
            Tab(text: "Completed".tr()),
            Tab(text: "Cancelled".tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContractList(activeContracts, "active"),
          _buildContractList(completedContracts, "completed"),
          _buildContractList(cancelledContracts, "cancelled"),
        ],
      ),
    );
  }

  Widget _buildContractList(List<ContractModel> contracts, String type) {
    if (contracts.isEmpty) {
      String emptyMessage;
      if (type == "active") {
        emptyMessage = "No active contracts".tr();
      } else if (type == "completed") {
        emptyMessage = "No completed contracts".tr();
      } else if (type == "cancelled") {
        emptyMessage = "No cancelled contracts".tr();
      } else {
        emptyMessage = "No contracts".tr();
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == "cancelled" // Remove .tr() here too
                  ? Icons.cancel_outlined
                  : Icons.description_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContracts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contracts.length,
        itemBuilder: (context, index) {
          final contract = contracts[index];
          return _buildContractCard(contract);
        },
      ),
    );
  }

  Widget _buildContractCard(ContractModel contract) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContractDetailsScreen(contract: contract),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // Add this
                    child: Text(
                      "Contract #".tr() + "${contract.contractNumber}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis, // Add this
                    ),
                  ),
                  const SizedBox(width: 8), // Add spacing
                  _buildStatusBadge(contract.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.directions_boat,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${contract.boatDetails.vesselName} - ${contract.boatDetails.hullNumber}",
                      style: const TextStyle(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.payments, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    "SAR" +
                        "${NumberFormat("#,###").format(contract.saleAmount)}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat("dd/MM/yyyy").format(contract.saleDate),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              if (contract.status == ContractStatus.pendingSignatures) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: contract.signatures.length /
                      (2 +
                          contract
                              .witnessIds.length), // seller + buyer + witnesses
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 4),
                Text(
                  "${contract.signatures.length} " +
                      "of" +
                      " ${2 + contract.witnessIds.length} " +
                      "signatures_".tr(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ContractStatus status) {
    Color color;
    String text;

    switch (status) {
      case ContractStatus.draft:
        color = Colors.grey;
        text = "Draft".tr();
        break;
      case ContractStatus.pendingSignatures:
        color = Colors.orange;
        text = "Pending".tr();
        break;
      case ContractStatus.signed:
        color = Colors.blue;
        text = "Signed".tr();
        break;
      case ContractStatus.pendingPayment:
        color = Colors.blue;
        text = "Payment Required".tr();
        break;
      case ContractStatus.pendingDepartment:
        color = Colors.purple;
        text = "Dept. Review".tr();
        break;
      case ContractStatus.pendingApproval:
        color = Colors.purple;
        text = "In Review".tr();
        break;
      case ContractStatus.approved:
        color = Colors.green;
        text = "Approved".tr();
        break;
      case ContractStatus.cancelled:
        color = Colors.red;
        text = "Cancelled".tr();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
