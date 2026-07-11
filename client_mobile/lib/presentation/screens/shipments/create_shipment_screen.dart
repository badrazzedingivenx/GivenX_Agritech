import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../../../services/session_service.dart';

/// Standalone shipment-request screen reached from a confirmed buyer order.
///
/// [orderId] and [farmerId] are pre-filled so the created shipment is already
/// linked to the order and the producer. The buyer is resolved from the
/// current session.
class CreateShipmentScreen extends StatefulWidget {
  static const routeName = '/create-shipment';

  final int orderId;
  final int farmerId;
  final String farmerName;
  final String? deliveryLocation;

  const CreateShipmentScreen({
    super.key,
    required this.orderId,
    required this.farmerId,
    this.farmerName = '',
    this.deliveryLocation,
  });

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  static const Color _primaryGreen = Color(0xFF23763D);

  static const List<String> _locations = [
    'Agadir',
    'Casablanca',
    'Rabat',
    'Marrakech',
    'Fes',
    'Meknes',
    'Tangier',
    'Oujda',
  ];

  final TextEditingController _weightCtrl = TextEditingController();
  String? _pickupLocation;
  String? _deliveryLocation;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _deliveryLocation =
        _locations.contains(widget.deliveryLocation) ? widget.deliveryLocation : null;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pickup = _pickupLocation;
    final delivery = _deliveryLocation;
    final weight = double.tryParse(_weightCtrl.text.trim());

    if (pickup == null || delivery == null) {
      _toast('Please select pickup and delivery locations');
      return;
    }
    if (pickup == delivery) {
      _toast('Pickup and delivery locations must be different');
      return;
    }
    if (weight == null || weight <= 0) {
      _toast('Weight must be greater than 0');
      return;
    }

    setState(() => _submitting = true);
    try {
      final user = await SessionService.getUser();
      await ApiService.createShipment({
        'orderId': widget.orderId,
        'buyerId': user?.id,
        'buyerType': user?.buyerType?.toJson(),
        'farmerId': widget.farmerId,
        'farmerName': widget.farmerName,
        'pickupLocation': pickup,
        'deliveryLocation': delivery,
        'weight': weight,
        'status': 'requested',
        'estimatedDeliveryDate':
            DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transport requested successfully!'),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _toast('Failed to request transport');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Request Transport'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1D1A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryCard(),
            const SizedBox(height: 24),
            const Text('Pickup location',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            _locationDropdown(
              hint: 'Select pickup location',
              value: _pickupLocation,
              onChanged: (v) => setState(() => _pickupLocation = v),
            ),
            const SizedBox(height: 20),
            const Text('Delivery location',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            _locationDropdown(
              hint: 'Select delivery location',
              value: _deliveryLocation,
              onChanged: (v) => setState(() => _deliveryLocation = v),
            ),
            const SizedBox(height: 20),
            const Text('Total weight (kg)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Enter weight in kg',
                  prefixIcon: Icon(Icons.scale_outlined),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.local_shipping_outlined),
                label: Text(_submitting ? 'Requesting...' : 'Request Transport',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 18, color: _primaryGreen),
              const SizedBox(width: 8),
              Text('Order #ORD-${widget.orderId}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          if (widget.farmerName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.agriculture_outlined,
                    size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Farmer: ${widget.farmerName}',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationDropdown({
    required String hint,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: Colors.grey)),
          items: _locations
              .map((l) => DropdownMenuItem(value: l, child: Text(l)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
