// // lib/screens/contracts/new_contract_screen.dart

// lib/screens/contracts/new_contract_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../model/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/contract_service.dart';
import '../../widget/step_indicator.dart';

class NewContractScreen extends StatefulWidget {
  const NewContractScreen({super.key});

  @override
  State<NewContractScreen> createState() => _NewContractScreenState();
}

class _NewContractScreenState extends State<NewContractScreen> {
  final _pageController = PageController();
  final _firestore = FirebaseFirestore.instance;
  int _currentStep = 0;

  // Form keys
  final _buyerFormKey = GlobalKey<FormState>();
  final _boatFormKey = GlobalKey<FormState>();
  final _saleFormKey = GlobalKey<FormState>();
  final _witnessFormKey = GlobalKey<FormState>();

  // Selected buyer
  UserModel? _selectedBuyer;
  final _buyerSearchController = TextEditingController();
  List<UserModel> _searchedBuyers = [];
  bool _isSearchingBuyer = false;

  // Boat details
  final _boatTypeController = TextEditingController();
  final _hullNumberController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _registrationController = TextEditingController();
  String _boatCondition = 'Used';

  // Sale details
  final _saleAmountController = TextEditingController();
  String _paymentMethod = 'Cash';
  final _locationController = TextEditingController();
  DateTime _saleDate = DateTime.now();
  bool _includesEquipment = false;
  bool _freeOfLiens = false;
  bool _buyerInspected = false;
  final _equipmentDetailsController = TextEditingController();

  // Witnesses
  final List<UserModel> _selectedWitnesses = [];
  final _witnessSearchController = TextEditingController();
  List<UserModel> _searchedWitnesses = [];
  bool _isSearchingWitness = false;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale Contract'),
      ),
      body: Column(
        children: [
          StepIndicator(
            currentStep: _currentStep,
            totalSteps: 4,
            titles: const ['Buyer', 'Boat Details', 'Sale Terms', 'Witnesses'],
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBuyerStep(),
                _buildBoatDetailsStep(),
                _buildSaleDetailsStep(),
                _buildWitnessesStep(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // User search functionality
  Future<void> _searchUsers(String query, bool isBuyer) async {
    if (query.length < 3) {
      setState(() {
        if (isBuyer) {
          _searchedBuyers = [];
        } else {
          _searchedWitnesses = [];
        }
      });
      return;
    }

    setState(() {
      if (isBuyer) {
        _isSearchingBuyer = true;
      } else {
        _isSearchingWitness = true;
      }
    });

    try {
      // Get current user to exclude from search
      final currentUserId = context.read<AuthService>().currentUser?.uid;

      // Search by email
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThan: query.toLowerCase() + 'z')
          .limit(5)
          .get();

      // Search by ID number
      final idQuery = await _firestore
          .collection('users')
          .where('idNumber', isEqualTo: query)
          .limit(5)
          .get();

      // Combine results and remove duplicates
      final Map<String, UserModel> usersMap = {};

      for (var doc in emailQuery.docs) {
        final user = UserModel.fromMap({...doc.data(), 'uid': doc.id});
        if (user.uid != currentUserId) {
          usersMap[user.uid] = user;
        }
      }

      for (var doc in idQuery.docs) {
        final user = UserModel.fromMap({...doc.data(), 'uid': doc.id});
        if (user.uid != currentUserId) {
          usersMap[user.uid] = user;
        }
      }

      setState(() {
        if (isBuyer) {
          _searchedBuyers = usersMap.values.toList();
          _isSearchingBuyer = false;
        } else {
          // Filter out already selected witnesses and buyer
          _searchedWitnesses = usersMap.values.where((user) {
            return user.uid != _selectedBuyer?.uid &&
                !_selectedWitnesses.any((w) => w.uid == user.uid);
          }).toList();
          _isSearchingWitness = false;
        }
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        if (isBuyer) {
          _isSearchingBuyer = false;
        } else {
          _isSearchingWitness = false;
        }
      });
    }
  }

  Widget _buildBuyerStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _buyerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Buyer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A6F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Search for registered buyers by email or ID number',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _buyerSearchController,
              decoration: InputDecoration(
                labelText: 'Search Buyer',
                hintText: 'Enter email or ID number',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearchingBuyer
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: (value) => _searchUsers(value, true),
            ),
            const SizedBox(height: 16),

            // Search results
            if (_searchedBuyers.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchedBuyers.length,
                  itemBuilder: (context, index) {
                    final user = _searchedBuyers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1A3A6F),
                        child: Text(
                          user.fullName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user.fullName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${user.idNumber}'),
                          Text(user.email,
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedBuyer = user;
                          _searchedBuyers = [];
                          _buyerSearchController.clear();
                        });
                      },
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Selected buyer display
            if (_selectedBuyer != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedBuyer!.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'ID: ${_selectedBuyer!.idNumber}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            _selectedBuyer!.email,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() => _selectedBuyer = null);
                      },
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

  Widget _buildBoatDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _boatFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Boat Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A6F),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _boatTypeController,
              decoration: const InputDecoration(
                labelText: 'Boat Type',
                hintText: 'e.g., Fishing boat, Yacht, Speedboat',
                prefixIcon: Icon(Icons.directions_boat),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter boat type';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hullNumberController,
              decoration: const InputDecoration(
                labelText: 'Hull Number',
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter hull number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lengthController,
                    decoration: const InputDecoration(
                      labelText: 'Length (meters)',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _widthController,
                    decoration: const InputDecoration(
                      labelText: 'Width (meters)',
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registrationController,
              decoration: const InputDecoration(
                labelText: 'Registration Number (Optional)',
                hintText: 'If registered with maritime authority',
                prefixIcon: Icon(Icons.app_registration),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Boat Condition',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'New', label: Text('New')),
                ButtonSegment(value: 'Used', label: Text('Used')),
              ],
              selected: {_boatCondition},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _boatCondition = newSelection.first;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _saleFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sale Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A6F),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _saleAmountController,
              decoration: const InputDecoration(
                labelText: 'Sale Amount (SAR)',
                prefixIcon: Icon(Icons.payments),
                prefixText: 'SAR ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter sale amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: Icon(Icons.payment),
              ),
              items: ['Cash', 'Bank Transfer', 'Installments']
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _paymentMethod = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Sale Location',
                hintText: 'City, District',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter location';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Sale Date'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_saleDate)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _saleDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _saleDate = picked);
                }
              },
            ),
            const Divider(height: 32),
            const Text(
              'Additional Terms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _includesEquipment,
              onChanged: (value) => setState(() => _includesEquipment = value!),
              title: const Text('Price includes equipment'),
              subtitle: const Text('Engines, navigation devices, etc.'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_includesEquipment) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _equipmentDetailsController,
                decoration: const InputDecoration(
                  labelText: 'Equipment Details',
                  hintText: 'List included equipment',
                ),
                maxLines: 3,
              ),
            ],
            CheckboxListTile(
              value: _freeOfLiens,
              onChanged: (value) => setState(() => _freeOfLiens = value!),
              title: const Text('Free of liens and mortgages'),
              subtitle: const Text('Seller acknowledges'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _buyerInspected,
              onChanged: (value) => setState(() => _buyerInspected = value!),
              title: const Text('Buyer inspected the boat'),
              subtitle: const Text('And accepts its condition'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWitnessesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _witnessFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Witnesses',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A6F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add at least one witness for the contract',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _witnessSearchController,
              decoration: InputDecoration(
                labelText: 'Search Witness',
                hintText: 'Enter email or ID number',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearchingWitness
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: (value) => _searchUsers(value, false),
            ),
            const SizedBox(height: 16),

            // Search results
            if (_searchedWitnesses.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchedWitnesses.length,
                  itemBuilder: (context, index) {
                    final user = _searchedWitnesses[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1A3A6F),
                        child: Text(
                          user.fullName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user.fullName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${user.idNumber}'),
                          Text(user.email,
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedWitnesses.add(user);
                          _searchedWitnesses = [];
                          _witnessSearchController.clear();
                        });
                      },
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Selected witnesses
            if (_selectedWitnesses.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.group_add, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No witnesses added yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedWitnesses.length,
                itemBuilder: (context, index) {
                  final witness = _selectedWitnesses[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1A3A6F),
                        child: Text(
                          witness.fullName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(witness.fullName),
                      subtitle: Text('ID: ${witness.idNumber}'),
                      trailing: IconButton(
                        icon:
                            const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedWitnesses.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
            if (_currentStep == 3) ...[
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Contract Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryItem(
                  'Buyer', _selectedBuyer?.fullName ?? 'Not selected'),
              _buildSummaryItem('Boat',
                  '${_boatTypeController.text} - ${_hullNumberController.text}'),
              _buildSummaryItem('Amount', 'SAR ${_saleAmountController.text}'),
              _buildSummaryItem(
                  'Witnesses', '${_selectedWitnesses.length} witness(es)'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_currentStep == 3 ? _createContract : _nextStep),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_currentStep == 3 ? 'Create Contract' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    setState(() => _currentStep--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_selectedBuyer == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a buyer'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;
      case 1:
        return _boatFormKey.currentState?.validate() ?? false;
      case 2:
        final isValid = _saleFormKey.currentState?.validate() ?? false;
        if (!_freeOfLiens || !_buyerInspected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please accept all required terms'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return isValid;
      case 3:
        if (_selectedWitnesses.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add at least one witness'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  Future<void> _createContract() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthService>();
      final contractService = context.read<ContractService>();

      final contractId = await contractService.createContract(
        sellerId: auth.currentUser!.uid,
        buyerId: _selectedBuyer!.uid,
        witnessIds: _selectedWitnesses.map((w) => w.uid).toList(),
        boatDetails: {
          'type': _boatTypeController.text,
          'hullNumber': _hullNumberController.text,
          'length': _lengthController.text,
          'width': _widthController.text,
          'registration': _registrationController.text,
          'condition': _boatCondition,
        },
        saleAmount: double.parse(_saleAmountController.text),
        paymentMethod: _paymentMethod,
        additionalTerms: {
          'includesEquipment': _includesEquipment,
          'equipmentDetails': _equipmentDetailsController.text,
          'freeOfLiens': _freeOfLiens,
          'buyerInspected': _buyerInspected,
        },
        saleLocation: _locationController.text,
        saleDate: _saleDate,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            title: const Text('Contract Created'),
            content: const Text(
              'Your contract has been created successfully. '
              'Signature requests have been sent to the buyer and witnesses.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to home
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buyerSearchController.dispose();
    _boatTypeController.dispose();
    _hullNumberController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _registrationController.dispose();
    _saleAmountController.dispose();
    _locationController.dispose();
    _equipmentDetailsController.dispose();
    _witnessSearchController.dispose();
    super.dispose();
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import '../../model/contract_model.dart';
// import '../../services/auth_service.dart';
// import '../../services/contract_service.dart';
// import '../../widget/step_indicator.dart';

// class NewContractScreen extends StatefulWidget {
//   const NewContractScreen({super.key});

//   @override
//   State<NewContractScreen> createState() => _NewContractScreenState();
// }

// class _NewContractScreenState extends State<NewContractScreen> {
//   final _pageController = PageController();
//   int _currentStep = 0;

//   // Form keys
//   final _buyerFormKey = GlobalKey<FormState>();
//   final _boatFormKey = GlobalKey<FormState>();
//   final _saleFormKey = GlobalKey<FormState>();
//   final _witnessFormKey = GlobalKey<FormState>();

//   // Selected buyer
//   UserModel? _selectedBuyer;
//   final _buyerSearchController = TextEditingController();

//   // Boat details
//   final _boatTypeController = TextEditingController();
//   final _hullNumberController = TextEditingController();
//   final _lengthController = TextEditingController();
//   final _widthController = TextEditingController();
//   final _registrationController = TextEditingController();
//   String _boatCondition = 'Used';

//   // Sale details
//   final _saleAmountController = TextEditingController();
//   String _paymentMethod = 'Cash';
//   final _locationController = TextEditingController();
//   DateTime _saleDate = DateTime.now();
//   bool _includesEquipment = false;
//   bool _freeOfLiens = false;
//   bool _buyerInspected = false;
//   final _equipmentDetailsController = TextEditingController();

//   // Witnesses
//   final List<UserModel> _selectedWitnesses = [];
//   final _witnessSearchController = TextEditingController();

//   bool _isLoading = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('New Sale Contract'),
//       ),
//       body: Column(
//         children: [
//           StepIndicator(
//             currentStep: _currentStep,
//             totalSteps: 4,
//             titles: const ['Buyer', 'Boat Details', 'Sale Terms', 'Witnesses'],
//           ),
//           Expanded(
//             child: PageView(
//               controller: _pageController,
//               physics: const NeverScrollableScrollPhysics(),
//               children: [
//                 _buildBuyerStep(),
//                 _buildBoatDetailsStep(),
//                 _buildSaleDetailsStep(),
//                 _buildWitnessesStep(),
//               ],
//             ),
//           ),
//           _buildNavigationButtons(),
//         ],
//       ),
//     );
//   }

//   Widget _buildBuyerStep() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Form(
//         key: _buyerFormKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Select Buyer',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1A3A6F),
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Search for registered buyers by email or ID number',
//               style: TextStyle(color: Colors.grey),
//             ),
//             const SizedBox(height: 24),
//             TextFormField(
//               controller: _buyerSearchController,
//               decoration: const InputDecoration(
//                 labelText: 'Search Buyer',
//                 hintText: 'Enter email or ID number',
//                 prefixIcon: Icon(Icons.search),
//               ),
//               onChanged: (value) {
//                 // Implement buyer search
//               },
//             ),
//             const SizedBox(height: 24),
//             if (_selectedBuyer != null) ...[
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.green),
//                 ),
//                 child: Row(
//                   children: [
//                     const CircleAvatar(
//                       backgroundColor: Colors.green,
//                       child: Icon(Icons.check, color: Colors.white),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             _selectedBuyer!.fullName,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           Text(
//                             'ID: ${_selectedBuyer!.idNumber}',
//                             style: const TextStyle(color: Colors.grey),
//                           ),
//                           Text(
//                             _selectedBuyer!.email,
//                             style: const TextStyle(color: Colors.grey),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: () {
//                         setState(() => _selectedBuyer = null);
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBoatDetailsStep() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Form(
//         key: _boatFormKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Boat Information',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1A3A6F),
//               ),
//             ),
//             const SizedBox(height: 24),
//             TextFormField(
//               controller: _boatTypeController,
//               decoration: const InputDecoration(
//                 labelText: 'Boat Type',
//                 hintText: 'e.g., Fishing boat, Yacht, Speedboat',
//                 prefixIcon: Icon(Icons.directions_boat),
//               ),
//               validator: (value) {
//                 if (value?.isEmpty ?? true) return 'Please enter hull number';
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextFormField(
//                     controller: _lengthController,
//                     decoration: const InputDecoration(
//                       labelText: 'Length (meters)',
//                       prefixIcon: Icon(Icons.straighten),
//                     ),
//                     keyboardType: TextInputType.number,
//                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                     validator: (value) {
//                       if (value?.isEmpty ?? true) return 'Required';
//                       return null;
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: TextFormField(
//                     controller: _widthController,
//                     decoration: const InputDecoration(
//                       labelText: 'Width (meters)',
//                       prefixIcon: Icon(Icons.height),
//                     ),
//                     keyboardType: TextInputType.number,
//                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                     validator: (value) {
//                       if (value?.isEmpty ?? true) return 'Required';
//                       return null;
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             TextFormField(
//               controller: _registrationController,
//               decoration: const InputDecoration(
//                 labelText: 'Registration Number (Optional)',
//                 hintText: 'If registered with maritime authority',
//                 prefixIcon: Icon(Icons.app_registration),
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Boat Condition',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             SegmentedButton<String>(
//               segments: const [
//                 ButtonSegment(value: 'New', label: Text('New')),
//                 ButtonSegment(value: 'Used', label: Text('Used')),
//               ],
//               selected: {_boatCondition},
//               onSelectionChanged: (Set<String> newSelection) {
//                 setState(() {
//                   _boatCondition = newSelection.first;
//                 });
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSaleDetailsStep() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Form(
//         key: _saleFormKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Sale Details',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1A3A6F),
//               ),
//             ),
//             const SizedBox(height: 24),
//             TextFormField(
//               controller: _saleAmountController,
//               decoration: const InputDecoration(
//                 labelText: 'Sale Amount (SAR)',
//                 prefixIcon: Icon(Icons.payments),
//                 prefixText: 'SAR ',
//               ),
//               keyboardType: TextInputType.number,
//               inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//               validator: (value) {
//                 if (value?.isEmpty ?? true) return 'Please enter sale amount';
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               value: _paymentMethod,
//               decoration: const InputDecoration(
//                 labelText: 'Payment Method',
//                 prefixIcon: Icon(Icons.payment),
//               ),
//               items: ['Cash', 'Bank Transfer', 'Installments']
//                   .map((method) => DropdownMenuItem(
//                         value: method,
//                         child: Text(method),
//                       ))
//                   .toList(),
//               onChanged: (value) => setState(() => _paymentMethod = value!),
//             ),
//             const SizedBox(height: 16),
//             TextFormField(
//               controller: _locationController,
//               decoration: const InputDecoration(
//                 labelText: 'Sale Location',
//                 hintText: 'City, District',
//                 prefixIcon: Icon(Icons.location_on),
//               ),
//               validator: (value) {
//                 if (value?.isEmpty ?? true) return 'Please enter location';
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             ListTile(
//               contentPadding: EdgeInsets.zero,
//               leading: const Icon(Icons.calendar_today),
//               title: const Text('Sale Date'),
//               subtitle: Text(DateFormat('dd/MM/yyyy').format(_saleDate)),
//               trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//               onTap: () async {
//                 final picked = await showDatePicker(
//                   context: context,
//                   initialDate: _saleDate,
//                   firstDate: DateTime(2000),
//                   lastDate: DateTime.now(),
//                 );
//                 if (picked != null) {
//                   setState(() => _saleDate = picked);
//                 }
//               },
//             ),
//             const Divider(height: 32),
//             const Text(
//               'Additional Terms',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             CheckboxListTile(
//               value: _includesEquipment,
//               onChanged: (value) => setState(() => _includesEquipment = value!),
//               title: const Text('Price includes equipment'),
//               subtitle: const Text('Engines, navigation devices, etc.'),
//               controlAffinity: ListTileControlAffinity.leading,
//               contentPadding: EdgeInsets.zero,
//             ),
//             if (_includesEquipment) ...[
//               const SizedBox(height: 8),
//               TextFormField(
//                 controller: _equipmentDetailsController,
//                 decoration: const InputDecoration(
//                   labelText: 'Equipment Details',
//                   hintText: 'List included equipment',
//                 ),
//                 maxLines: 3,
//               ),
//             ],
//             CheckboxListTile(
//               value: _freeOfLiens,
//               onChanged: (value) => setState(() => _freeOfLiens = value!),
//               title: const Text('Free of liens and mortgages'),
//               subtitle: const Text('Seller acknowledges'),
//               controlAffinity: ListTileControlAffinity.leading,
//               contentPadding: EdgeInsets.zero,
//             ),
//             CheckboxListTile(
//               value: _buyerInspected,
//               onChanged: (value) => setState(() => _buyerInspected = value!),
//               title: const Text('Buyer inspected the boat'),
//               subtitle: const Text('And accepts its condition'),
//               controlAffinity: ListTileControlAffinity.leading,
//               contentPadding: EdgeInsets.zero,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildWitnessesStep() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Form(
//         key: _witnessFormKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Add Witnesses',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1A3A6F),
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Add at least one witness for the contract',
//               style: TextStyle(color: Colors.grey),
//             ),
//             const SizedBox(height: 24),
//             TextFormField(
//               controller: _witnessSearchController,
//               decoration: const InputDecoration(
//                 labelText: 'Search Witness',
//                 hintText: 'Enter email or ID number',
//                 prefixIcon: Icon(Icons.search),
//               ),
//               onChanged: (value) {
//                 // Implement witness search
//               },
//             ),
//             const SizedBox(height: 24),
//             if (_selectedWitnesses.isEmpty)
//               Center(
//                 child: Column(
//                   children: [
//                     Icon(Icons.group_add, size: 64, color: Colors.grey[400]),
//                     const SizedBox(height: 16),
//                     Text(
//                       'No witnesses added yet',
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//               )
//             else
//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: _selectedWitnesses.length,
//                 itemBuilder: (context, index) {
//                   final witness = _selectedWitnesses[index];
//                   return Card(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: const Color(0xFF1A3A6F),
//                         child: Text(
//                           witness.fullName[0].toUpperCase(),
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                       ),
//                       title: Text(witness.fullName),
//                       subtitle: Text('ID: ${witness.idNumber}'),
//                       trailing: IconButton(
//                         icon:
//                             const Icon(Icons.remove_circle, color: Colors.red),
//                         onPressed: () {
//                           setState(() {
//                             _selectedWitnesses.removeAt(index);
//                           });
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             const SizedBox(height: 32),
//             if (_currentStep == 3) ...[
//               const Divider(),
//               const SizedBox(height: 16),
//               const Text(
//                 'Contract Summary',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               _buildSummaryItem(
//                   'Buyer', _selectedBuyer?.fullName ?? 'Not selected'),
//               _buildSummaryItem('Boat',
//                   '${_boatTypeController.text} - ${_hullNumberController.text}'),
//               _buildSummaryItem('Amount', 'SAR ${_saleAmountController.text}'),
//               _buildSummaryItem(
//                   'Witnesses', '${_selectedWitnesses.length} witness(es)'),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryItem(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: const TextStyle(color: Colors.grey)),
//           Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   Widget _buildNavigationButtons() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 4,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           if (_currentStep > 0)
//             Expanded(
//               child: OutlinedButton(
//                 onPressed: _previousStep,
//                 child: const Text('Previous'),
//               ),
//             ),
//           if (_currentStep > 0) const SizedBox(width: 16),
//           Expanded(
//             child: ElevatedButton(
//               onPressed: _isLoading
//                   ? null
//                   : (_currentStep == 3 ? _createContract : _nextStep),
//               child: _isLoading
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     )
//                   : Text(_currentStep == 3 ? 'Create Contract' : 'Next'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _nextStep() {
//     if (_validateCurrentStep()) {
//       setState(() => _currentStep++);
//       _pageController.nextPage(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     }
//   }

//   void _previousStep() {
//     setState(() => _currentStep--);
//     _pageController.previousPage(
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }

//   bool _validateCurrentStep() {
//     switch (_currentStep) {
//       case 0:
//         return _selectedBuyer != null;
//       case 1:
//         return _boatFormKey.currentState?.validate() ?? false;
//       case 2:
//         return _saleFormKey.currentState?.validate() ??
//             false && _freeOfLiens && _buyerInspected;
//       case 3:
//         return _selectedWitnesses.isNotEmpty;
//       default:
//         return false;
//     }
//   }

//   Future<void> _createContract() async {
//     if (!_validateCurrentStep()) return;

//     setState(() => _isLoading = true);

//     try {
//       final auth = context.read<AuthService>();
//       final contractService = context.read<ContractService>();

//       final contractId = await contractService.createContract(
//         sellerId: auth.currentUser!.uid,
//         buyerId: _selectedBuyer!.uid,
//         witnessIds: _selectedWitnesses.map((w) => w.uid).toList(),
//         boatDetails: {
//           'type': _boatTypeController.text,
//           'hullNumber': _hullNumberController.text,
//           'length': _lengthController.text,
//           'width': _widthController.text,
//           'registration': _registrationController.text,
//           'condition': _boatCondition,
//         },
//         saleAmount: double.parse(_saleAmountController.text),
//         paymentMethod: _paymentMethod,
//         additionalTerms: {
//           'includesEquipment': _includesEquipment,
//           'equipmentDetails': _equipmentDetailsController.text,
//           'freeOfLiens': _freeOfLiens,
//           'buyerInspected': _buyerInspected,
//         },
//         saleLocation: _locationController.text,
//         saleDate: _saleDate,
//       );

//       if (mounted) {
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (context) => AlertDialog(
//             title: const Text('Contract Created'),
//             content: const Text(
//               'Your contract has been created successfully. '
//               'Signature requests have been sent to the buyer and witnesses.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context); // Close dialog
//                   Navigator.pop(context); // Go back to home
//                 },
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     _buyerSearchController.dispose();
//     _boatTypeController.dispose();
//     _hullNumberController.dispose();
//     _lengthController.dispose();
//     _widthController.dispose();
//     _registrationController.dispose();
//     _saleAmountController.dispose();
//     _locationController.dispose();
//     _equipmentDetailsController.dispose();
//     _witnessSearchController.dispose();
//     super.dispose();
//   }
// }
