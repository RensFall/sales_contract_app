// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/contract_model.dart';
import '../services/auth_service.dart';
import '../services/contract_service.dart';
import '../widget/home_card.dart';
import 'contract/admin_home_screen.dart';
import 'contract/my_contracts_screen.dart';
import 'contract/new_contract_screen.dart';
import 'contract/pending_payment_screen.dart';
import 'contract/pending_signatures_screen.dart';

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
        title: const Text('Marine Contracts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                // Navigate to profile
              } else if (value == 'logout') {
                auth.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 12),
                    Text('Logout'),
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
                            'U',
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
                            'Welcome, ${auth.currentUser?.fullName ?? 'User'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${auth.currentUser?.idNumber ?? ''}',
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
              const Text(
                'Quick Actions',
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
                    title: 'New Contract',
                    subtitle: 'Create a new sale contract',
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
                    title: 'Pending Signatures',
                    subtitle: '${contracts.pendingSignatures.length} contracts',
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
                    title: 'Pending Payment',
                    subtitle: '${contracts.pendingPayment.length} contracts',
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
                    title: 'My Contracts',
                    subtitle: 'View all contracts',
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
              const Text(
                'Recent Activity',
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
                          'No contracts yet',
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
                          'Contract #${contract.id.substring(0, 8)}',
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
                              const Text(
                                'Awaiting payment',
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
    }
  }

  String _getStatusText(ContractStatus status) {
    switch (status) {
      case ContractStatus.draft:
        return 'Draft';
      case ContractStatus.pendingSignatures:
        return 'Pending Signatures';
      case ContractStatus.signed:
        return 'Signed - Awaiting Payment';
      case ContractStatus.pendingPayment:
        return 'Payment Required';
      case ContractStatus.pendingApproval:
        return 'Pending Admin Approval';
      case ContractStatus.approved:
        return 'Approved & Finalized';
      case ContractStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// // lib/screens/home_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../model/contract_model.dart';
// import '../services/auth_service.dart';
// import '../services/contract_service.dart';
// import '../widget/home_card.dart';
// import 'contract/admin_approval_screen.dart';
// import 'contract/my_contracts_screen.dart';
// import 'contract/new_contract_screen.dart';
// import 'contract/pending_signatures_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     final auth = context.read<AuthService>();
//     final contracts = context.read<ContractService>();

//     if (auth.currentUser != null) {
//       await contracts.loadContracts(
//         auth.currentUser!.uid,
//         auth.currentUser!.userType,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthService>();
//     final contracts = context.watch<ContractService>();

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text('Marine Contracts'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_outlined),
//             onPressed: () {
//               // Navigate to notifications
//             },
//           ),
//           PopupMenuButton<String>(
//             onSelected: (value) {
//               if (value == 'profile') {
//                 // Navigate to profile
//               } else if (value == 'logout') {
//                 auth.signOut();
//                 Navigator.pushReplacementNamed(context, '/login');
//               }
//             },
//             itemBuilder: (context) => [
//               const PopupMenuItem(
//                 value: 'profile',
//                 child: Row(
//                   children: [
//                     Icon(Icons.person_outline, size: 20),
//                     SizedBox(width: 12),
//                     Text('Profile'),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem(
//                 value: 'logout',
//                 child: Row(
//                   children: [
//                     Icon(Icons.logout, size: 20),
//                     SizedBox(width: 12),
//                     Text('Logout'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadData,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // User Info Card
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF1A3A6F), Color(0xFF2E5090)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 30,
//                       backgroundColor: Colors.white.withOpacity(0.2),
//                       child: Text(
//                         auth.currentUser?.fullName
//                                 .substring(0, 1)
//                                 .toUpperCase() ??
//                             'U',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Welcome, ${auth.currentUser?.fullName ?? 'User'}',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             auth.currentUser?.userType.toUpperCase() ?? '',
//                             style: const TextStyle(
//                               color: Colors.white70,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Quick Actions
//               const Text(
//                 'Quick Actions',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1A3A6F),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               GridView.count(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 crossAxisCount: 2,
//                 mainAxisSpacing: 16,
//                 crossAxisSpacing: 16,
//                 childAspectRatio: 1.2,
//                 children: [
//                   if (auth.currentUser?.userType == 'seller')
//                     HomeCard(
//                       icon: Icons.add_box,
//                       title: 'New Contract',
//                       subtitle: 'Create a new sale contract',
//                       color: Colors.green,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const NewContractScreen(),
//                           ),
//                         );
//                       },
//                     ),
//                   if (!auth.isAdmin)
//                     HomeCard(
//                       icon: Icons.pending_actions,
//                       title: 'Pending Signatures',
//                       subtitle:
//                           '${contracts.pendingSignatures.length} contracts',
//                       color: Colors.orange,
//                       badge: contracts.pendingSignatures.length.toString(),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                                 const PendingSignaturesScreen(),
//                           ),
//                         );
//                       },
//                     ),
//                   HomeCard(
//                     icon: Icons.description,
//                     title: 'My Contracts',
//                     subtitle: 'View all contracts',
//                     color: Colors.blue,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const MyContractsScreen(),
//                         ),
//                       );
//                     },
//                   ),
//                   if (auth.isAdmin)
//                     HomeCard(
//                       icon: Icons.approval,
//                       title: 'Pending Approvals',
//                       subtitle:
//                           '${contracts.pendingApprovals.length} contracts',
//                       color: Colors.purple,
//                       badge: contracts.pendingApprovals.length.toString(),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const AdminApprovalScreen(),
//                           ),
//                         );
//                       },
//                     ),
//                 ],
//               ),

//               const SizedBox(height: 32),

//               // Recent Activity
//               const Text(
//                 'Recent Activity',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1A3A6F),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               if (contracts.contracts.isEmpty)
//                 Center(
//                   child: Container(
//                     padding: const EdgeInsets.all(40),
//                     child: Column(
//                       children: [
//                         Icon(
//                           Icons.inbox_outlined,
//                           size: 64,
//                           color: Colors.grey[400],
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'No contracts yet',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//               else
//                 ListView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: contracts.contracts.take(5).length,
//                   itemBuilder: (context, index) {
//                     final contract = contracts.contracts[index];
//                     return Card(
//                       margin: const EdgeInsets.only(bottom: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor:
//                               _getStatusColor(contract.status).withOpacity(0.2),
//                           child: Icon(
//                             _getStatusIcon(contract.status),
//                             color: _getStatusColor(contract.status),
//                           ),
//                         ),
//                         title: Text(
//                           'Contract #${contract.id.substring(0, 8)}',
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         subtitle: Text(
//                           _getStatusText(contract.status),
//                           style: TextStyle(
//                             color: _getStatusColor(contract.status),
//                           ),
//                         ),
//                         trailing: Text(
//                           _formatDate(contract.createdAt),
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                         onTap: () {
//                           // Navigate to contract details
//                         },
//                       ),
//                     );
//                   },
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(ContractStatus status) {
//     switch (status) {
//       case ContractStatus.draft:
//         return Colors.grey;
//       case ContractStatus.pendingSignatures:
//         return Colors.orange;
//       case ContractStatus.signed:
//         return Colors.blue;
//       case ContractStatus.pendingApproval:
//         return Colors.purple;
//       case ContractStatus.approved:
//         return Colors.green;
//       case ContractStatus.cancelled:
//         return Colors.red;
//     }
//   }

//   IconData _getStatusIcon(ContractStatus status) {
//     switch (status) {
//       case ContractStatus.draft:
//         return Icons.edit_outlined;
//       case ContractStatus.pendingSignatures:
//         return Icons.pending_outlined;
//       case ContractStatus.signed:
//         return Icons.done;
//       case ContractStatus.pendingApproval:
//         return Icons.hourglass_empty;
//       case ContractStatus.approved:
//         return Icons.check_circle_outline;
//       case ContractStatus.cancelled:
//         return Icons.cancel_outlined;
//     }
//   }

//   String _getStatusText(ContractStatus status) {
//     switch (status) {
//       case ContractStatus.draft:
//         return 'Draft';
//       case ContractStatus.pendingSignatures:
//         return 'Pending Signatures';
//       case ContractStatus.signed:
//         return 'Signed';
//       case ContractStatus.pendingApproval:
//         return 'Pending Approval';
//       case ContractStatus.approved:
//         return 'Approved';
//       case ContractStatus.cancelled:
//         return 'Cancelled';
//     }
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inDays == 0) {
//       return 'Today';
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return '${difference.inDays} days ago';
//     } else {
//       return '${date.day}/${date.month}/${date.year}';
//     }
//   }
// }
