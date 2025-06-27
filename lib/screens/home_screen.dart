// lib/screens/home_screen.dart
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../model/contract_model.dart";
import "../services/auth_service.dart";
import "../services/contract_service.dart";
import "../widget/home_card.dart";
import "contract/admin_home_screen.dart";
import "contract/my_contracts_screen.dart";
import "contract/new_contract_screen.dart";
import "contract/pending_payment_screen.dart";
import "contract/pending_signatures_screen.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
    final auth = context.watch<AuthService>();

    // Redirect to admin home if user is admin
    if (auth.isAdmin) {
      return const AdminHomeScreen();
    }

    final contracts = context.watch<ContractService>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Marine Contracts".tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "profile") {
                // Navigate to profile
              } else if (value == "logout") {
                auth.signOut();
                Navigator.pushReplacementNamed(context, "/login");
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "profile",
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 12),
                    Text("Profile".tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "logout",
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 12),
                    Text("Logout".tr()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A3A6F), Color(0xFF2E5090)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        auth.currentUser?.fullName
                                .substring(0, 1)
                                .toUpperCase() ??
                            "U",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome".tr() +
                                ", ${auth.currentUser?.fullName ?? "User"}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ID: ${auth.currentUser?.idNumber ?? ""}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                "Quick Actions".tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A6F),
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  // Everyone can create contracts now
                  HomeCard(
                    icon: Icons.add_box,
                    title: "New Contract".tr(),
                    subtitle: "Create a new sale contract".tr(),
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewContractScreen(),
                        ),
                      );
                    },
                  ),

                  HomeCard(
                    icon: Icons.pending_actions,
                    title: "Pending Signatures".tr(),
                    subtitle: "${contracts.pendingSignatures.length}" +
                        "contracts".tr(),
                    color: Colors.orange,
                    badge: contracts.pendingSignatures.length.toString(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PendingSignaturesScreen(),
                        ),
                      );
                    },
                  ),

                  HomeCard(
                    icon: Icons.payment,
                    title: "Pending Payment".tr(),
                    subtitle:
                        "${contracts.pendingPayment.length}" "contracts".tr(),
                    color: Colors.amber,
                    badge: contracts.pendingPayment.length.toString(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PendingPaymentScreen(),
                        ),
                      );
                    },
                  ),

                  HomeCard(
                    icon: Icons.description,
                    title: "My Contracts".tr(),
                    subtitle: "View all contracts".tr(),
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyContractsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Recent Activity
              Text(
                "Recent Activity".tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A6F),
                ),
              ),
              const SizedBox(height: 16),

              if (contracts.contracts.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No contracts yet".tr(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contracts.contracts.take(5).length,
                  itemBuilder: (context, index) {
                    final contract = contracts.contracts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _getStatusColor(contract.status).withOpacity(0.2),
                          child: Icon(
                            _getStatusIcon(contract.status),
                            color: _getStatusColor(contract.status),
                          ),
                        ),
                        title: Text(
                          "Contract".tr() + "#${contract.id.substring(0, 8)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusText(contract.status),
                              style: TextStyle(
                                color: _getStatusColor(contract.status),
                              ),
                            ),
                            if (contract.status ==
                                ContractStatus.pendingPayment)
                              Text(
                                "Awaiting payment".tr(),
                                style: TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Text(
                          _formatDate(contract.createdAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          // Navigate to contract details
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
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
      case ContractStatus.pendingPayment:
        return Colors.amber;
      case ContractStatus.pendingApproval:
        return Colors.purple;
      case ContractStatus.approved:
        return Colors.green;
      case ContractStatus.cancelled:
        return Colors.red;
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
        return Icons.done;
      case ContractStatus.pendingPayment:
        return Icons.payment;
      case ContractStatus.pendingApproval:
        return Icons.hourglass_empty;
      case ContractStatus.approved:
        return Icons.check_circle_outline;
      case ContractStatus.cancelled:
        return Icons.cancel_outlined;
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
        return "Signed - Awaiting Payment".tr();
      case ContractStatus.pendingPayment:
        return "Payment Required".tr();
      case ContractStatus.pendingApproval:
        return "Pending Admin Approval".tr();
      case ContractStatus.approved:
        return "Approved & Finalized".tr();
      case ContractStatus.cancelled:
        return "Cancelled".tr();
      case ContractStatus.pendingDepartment:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "Today".tr();
    } else if (difference.inDays == 1) {
      return "Yesterday".tr();
    } else if (difference.inDays < 7) {
      return "${difference.inDays}+" + "days ago".tr();
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}
