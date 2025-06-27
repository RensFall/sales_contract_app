// lib/screens/contracts/admin_home_screen.dart
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../services/auth_service.dart";
import "../../services/contract_service.dart";
import "../../widget/home_card.dart";
import "admin_approval_screen.dart";

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
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
    final contracts = context.watch<ContractService>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Admin Dashboard".tr()),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.signOut();
              Navigator.pushReplacementNamed(context, "/login");
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.deepPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 30,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome".tr() +
                                ",${auth.currentUser?.fullName ?? "Admin"}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ADMINISTRATOR".tr(),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Pending Approvals".tr(),
                      contracts.pendingApprovals.length.toString(),
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "Approved Today".tr(),
                      contracts.getApprovedToday().toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                "Admin Actions".tr(),
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
                childAspectRatio: 1.5,
                children: [
                  HomeCard(
                    icon: Icons.approval,
                    title: "Pending Approvals".tr(),
                    subtitle: "${contracts.pendingApprovals.length}" +
                        "contracts".tr(),
                    color: Colors.purple,
                    badge: contracts.pendingApprovals.length.toString(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminApprovalScreen(),
                        ),
                      );
                    },
                  ),
                  HomeCard(
                    icon: Icons.history,
                    title: "All Contracts".tr(),
                    subtitle: "View all contracts".tr(),
                    color: Colors.blue,
                    onTap: () {
                      // Navigate to all contracts with filters
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Recent Contracts for Approval
              Text(
                "Recent Contracts Awaiting Approval".tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A6F),
                ),
              ),
              const SizedBox(height: 16),

              if (contracts.pendingApprovals.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
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
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contracts.pendingApprovals.take(5).length,
                  itemBuilder: (context, index) {
                    final contract = contracts.pendingApprovals[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(
                            Icons.assignment,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          "Contract".tr() + "#${contract.id.substring(0, 8)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Amount: SAR".tr() + "${contract.saleAmount}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminApprovalScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                          child: Text("Review".tr()),
                        ),
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
