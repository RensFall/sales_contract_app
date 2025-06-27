// lib/screens/contracts/payment_screen.dart
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:intl/intl.dart";
import "../../model/contract_model.dart";
import "../../services/contract_service.dart";

class PaymentScreen extends StatefulWidget {
  final ContractModel contract;

  const PaymentScreen({super.key, required this.contract});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = "bank";
  bool _isProcessing = false;

  // Card details controllers
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Payment".tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contract Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Contract Summary".tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Contract ID:".tr()),
                        Text(
                          "#${widget.contract.id.substring(0, 8)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Boat:".tr()),
                        Text(
                          widget.contract.boatDetails.vesselName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Amount:".tr(),
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          "SAR".tr() +
                              "${NumberFormat("#,###").format(widget.contract.saleAmount)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A6F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment Method Selection
            Text(
              "Payment Method".tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildPaymentMethodOption(
              "bank",
              "Bank Transfer".tr(),
              Icons.account_balance,
            ),
            const SizedBox(height: 32),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Pay SAR".tr() +
                            "${NumberFormat("#,###").format(widget.contract.saleAmount)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String label, IconData icon) {
    return Card(
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (newValue) {
          setState(() {
            _selectedPaymentMethod = newValue!;
          });
        },
        title: Text(label),
        secondary: Icon(icon),
      ),
    );
  }

  Widget _buildBankTransferInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bank Transfer Instructions".tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBankDetail("Bank Name:".tr(), "Al Rajhi Bank"),
            _buildBankDetail("Account Name:".tr(), "Abher sailing unt"),
            _buildBankDetail("IBAN:", "SA2080000247608016275078"),
            _buildBankDetail(
                "Amount:".tr(),
                "SAR".tr() +
                    "${NumberFormat("#,###").format(widget.contract.saleAmount)}"),
            _buildBankDetail("Reference:", widget.contract.id.substring(0, 8)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Please use the contract reference when making the transfer"
                          .tr(),
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Copied to clipboard".tr()),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 3));

      // Process payment through contract service
      await context.read<ContractService>().processPayment(
            contractId: widget.contract.id,
            paymentId: "PAY${DateTime.now().millisecondsSinceEpoch}",
            transactionId: "TXN${DateTime.now().millisecondsSinceEpoch}",
            amount: widget.contract.saleAmount,
            paymentMethod: _selectedPaymentMethod,
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
            title: Text("Payment Successful".tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Your payment has been processed successfully.".tr(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "The contract has been sent to our admin for final approval and digital stamping."
                        .tr(),
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to payment list
                  Navigator.pop(context); // Go back to home
                },
                child: Text("OK".tr()),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment failed:".tr() + "${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
}

// Input formatters for card details
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.replaceAll(" ", "");
    final buffer = StringBuffer();

    for (int i = 0; i < newText.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(" ");
      }
      buffer.write(newText[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.replaceAll("/", "");
    if (newText.length > 4) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      if (i == 2) {
        buffer.write("/");
      }
      buffer.write(newText[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
