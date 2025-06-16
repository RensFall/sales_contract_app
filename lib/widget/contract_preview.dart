// lib/widgets/contract_preview.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/contract_model.dart';

class ContractPreview extends StatelessWidget {
  final ContractModel contract;

  const ContractPreview({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.directions_boat,
                  size: 48,
                  color: Color(0xFF1A3A6F),
                ),
                const SizedBox(height: 12),
                const Text(
                  'BOAT SALE CONTRACT',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A6F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${DateFormat('dd/MM/yyyy').format(contract.saleDate)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('BOAT DETAILS', [
            'Type: ${contract.boatDetails['type']}',
            'Hull Number: ${contract.boatDetails['hullNumber']}',
            'Dimensions: ${contract.boatDetails['length']}m × ${contract.boatDetails['width']}m',
            if (contract.boatDetails['registration']?.isNotEmpty ?? false)
              'Registration: ${contract.boatDetails['registration']}',
            'Condition: ${contract.boatDetails['condition']}',
          ]),
          _buildSection('SALE TERMS', [
            'Sale Amount: SAR ${NumberFormat('#,###').format(contract.saleAmount)}',
            'Payment Method: ${contract.paymentMethod}',
            'Location: ${contract.saleLocation}',
          ]),
          if (contract.additionalTerms['includesEquipment'] == true) ...[
            _buildSection('INCLUDED EQUIPMENT', [
              contract.additionalTerms['equipmentDetails'] ??
                  'Equipment included',
            ]),
          ],
          _buildSection('TERMS & CONDITIONS', [
            if (contract.additionalTerms['freeOfLiens'] == true)
              '✓ The seller declares the boat is free of liens and mortgages',
            if (contract.additionalTerms['buyerInspected'] == true)
              '✓ The buyer has inspected the boat and accepts its condition',
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3A6F),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              )),
        ],
      ),
    );
  }
}
