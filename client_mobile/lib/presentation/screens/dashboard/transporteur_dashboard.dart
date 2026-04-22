import 'package:flutter/material.dart';
import '../../../models/shipment.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../chat/conversations_screen.dart';

class TransporteurDashboard extends StatefulWidget {
  final String fullName;
  final String email;
  final String phone;
  final String vehicleType;
  final String capacity;
  final String city;

  const TransporteurDashboard({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.capacity,
    required this.city,
  });

  @override
  State<TransporteurDashboard> createState() => _TransporteurDashboardState();
}

class _TransporteurDashboardState extends State<TransporteurDashboard> {
  static const Color _primaryGreen = Color(0xFF23763D);
  static const Color _textColor = Color(0xFF1A1D1A);
  static const Color _textLight = Color(0xFF757575);

  int _currentIndex = 0;
  List<Shipment> _shipments = [];
  bool _loading = true;

  int _gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1280) return 4;
    if (width >= 900) return 3;
    if (width >= 420) return 2;
    return 1;
  }

  double _gridAspectRatio(BuildContext context) {
    final columns = _gridColumns(context);
    if (columns >= 4) return 0.95;
    if (columns == 3) return 0.9;
    if (columns == 2) return 0.96;
    return 1.14;
  }

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  Future<void> _loadShipments() async {
    try {
      final user = await SessionService.getUser();
      final data = await ApiService.getShipments(
        transporterId: user?.id.toString(),
      );
      if (mounted) {
        setState(() {
          _shipments = data
              .map((e) => Shipment.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _activeCount =>
      _shipments.where((s) => s.status == ShipmentStatus.inTransit || s.status == ShipmentStatus.pickedUp).length;

  int get _deliveredCount =>
      _shipments.where((s) => s.status == ShipmentStatus.delivered).length;

  int get _pendingCount =>
      _shipments.where((s) => s.status != ShipmentStatus.delivered && s.status != ShipmentStatus.cancelled).length;

  double get _completionRate {
    if (_shipments.isEmpty) return 0;
    return (_deliveredCount / _shipments.length) * 100;
  }

  double get _pendingRate {
    if (_shipments.isEmpty) return 0;
    return (_pendingCount / _shipments.length).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      currentIndex: _currentIndex,
      navItems: const [
        NavItem(icon: Icons.home_outlined, label: 'Home'),
        NavItem(icon: Icons.route_outlined, label: 'Trips'),
        NavItem(icon: Icons.chat_bubble_outline, label: 'Messages'),
        NavItem(icon: Icons.inventory_2_outlined, label: 'Deliveries'),
        NavItem(icon: Icons.person_outline, label: 'Profile'),
      ],
      onTabSelected: (i) => setState(() => _currentIndex = i),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildTripsTab(),
          const ConversationsScreen(),
          _buildDeliveriesTab(),
          _buildProfileTab(),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRANSPORT DASHBOARD',
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hello, ${widget.fullName}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Here is the status of your route activity today.',
            style: TextStyle(color: _textLight, fontSize: 13),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: _gridColumns(context),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: _gridAspectRatio(context),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _fleetCard(),
              _nextPickupCard(),
              _statCard(
                'LIVE',
                _loading ? '...' : '${_completionRate.toStringAsFixed(0)}%',
                'DELIVERY COMPLETION',
                Icons.local_shipping,
                Colors.green,
                _loading ? 0 : (_completionRate / 100).clamp(0, 1).toDouble(),
              ),
              _statCard(
                'OPEN',
                _loading ? '...' : '$_pendingCount',
                'SHIPMENTS IN PIPELINE',
                Icons.timeline,
                Colors.pink,
                _loading ? 0 : _pendingRate,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTripsTab() {
    final activeTrips = _shipments
        .where((s) => s.status == ShipmentStatus.inTransit || s.status == ShipmentStatus.pickedUp)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRANSPORT DASHBOARD',
            style: TextStyle(color: _primaryGreen, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            'Hello, ${widget.fullName}',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _textColor, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text('Here are your active trips and latest updates.', style: TextStyle(color: _textLight, fontSize: 13)),
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (activeTrips.isEmpty)
            const Center(child: Text('No active trips'))
          else
            GridView.count(
              crossAxisCount: _gridColumns(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: _gridAspectRatio(context),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: activeTrips.map((s) => GestureDetector(
                    onTap: () => _showStatusUpdateSheet(s),
                    child: _deliveryCard(
                      icon: Icons.route,
                      title: '${s.pickupLocation} → ${s.deliveryLocation}',
                      subtitle: '${s.weight != null ? "${s.weight!.toStringAsFixed(0)} kg" : ""} • #SHP-${s.id}',
                      status: s.status.label.toUpperCase(),
                      statusColor: s.status == ShipmentStatus.inTransit ? Colors.orange : Colors.blue,
                      time: s.trackingNote ?? '',
                    ),
                  )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveriesTab() {
    final recent = _shipments.where((s) => s.status == ShipmentStatus.delivered).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRANSPORT DASHBOARD',
            style: TextStyle(color: _primaryGreen, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            'Hello, ${widget.fullName}',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _textColor, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text('Here are your completed deliveries.', style: TextStyle(color: _textLight, fontSize: 13)),
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (recent.isEmpty)
            const Center(child: Text('No activity yet'))
          else
            GridView.count(
              crossAxisCount: _gridColumns(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: _gridAspectRatio(context),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: recent.map((s) => _deliveryCard(
                    icon: Icons.check_circle_outline,
                    title: '${s.pickupLocation} → ${s.deliveryLocation}',
                    subtitle: '#SHP-${s.id}',
                    status: 'DELIVERED',
                    statusColor: Colors.green,
                    time: s.trackingNote ?? '',
                  )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRANSPORT DASHBOARD',
            style: TextStyle(color: _primaryGreen, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            'Hello, ${widget.fullName}',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _textColor, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${widget.email}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Text('Phone: ${widget.phone}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Text('City: ${widget.city}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Text('Vehicle: ${widget.vehicleType}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Text('Capacity: ${widget.capacity}', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateSheet(Shipment shipment) {
    if (shipment.status == ShipmentStatus.delivered) return;
    final nextStatuses = <String, String>{
      if (shipment.status == ShipmentStatus.requested) 'accepted': 'Accept Shipment',
      if (shipment.status == ShipmentStatus.accepted) 'pickedUp': 'Mark as Picked Up',
      if (shipment.status == ShipmentStatus.pickedUp) 'inTransit': 'Mark In Transit',
      if (shipment.status == ShipmentStatus.inTransit) 'delivered': 'Mark Delivered',
    };
    if (nextStatuses.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Update Shipment #${shipment.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${shipment.pickupLocation} → ${shipment.deliveryLocation}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ...nextStatuses.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      final data = <String, dynamic>{'status': e.key};
                      if (e.key == 'delivered') {
                        data['actualDeliveryDate'] = DateTime.now().toIso8601String();
                      }
                      await ApiService.updateShipment(shipment.id!, data);
                      _loadShipments();
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to update status')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(e.value),
                ),
              ),
            )),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fleetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping, color: Color(0xFF23763D), size: 20),
              ),
              Text(
                'LIVE',
                style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _loading ? '...' : '$_activeCount',
            style: const TextStyle(
              color: Color(0xFF1A1D1A),
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Active Shipments',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            _loading ? '...' : '$_deliveredCount delivered',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isPrimary ? _primaryGreen : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isPrimary
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isPrimary ? Colors.white : _textColor, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isPrimary ? Colors.white : _textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String tag, String val, String sub, IconData icon, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Text(tag, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1D1A))),
          const SizedBox(height: 4),
          Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF757575), fontSize: 12)),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress, color: color, backgroundColor: Colors.grey.shade100, minHeight: 6),
        ],
      ),
    );
  }

  Widget _nextPickupCard() {
    final pending = _shipments.where((s) =>
        s.status != ShipmentStatus.delivered && s.status != ShipmentStatus.cancelled).toList();
    final next = pending.isNotEmpty ? pending.first : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.inventory_2_outlined, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            next != null ? 'Next: ${next.pickupLocation}' : 'No upcoming pickups',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            next != null ? '${next.deliveryLocation} • ${next.status.label}' : '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _deliveryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required String time,
    double? progress,
  }) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF5A5E5A), size: 22),
              ),
              if (progress == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(8)),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1A1D1A)),
          )
          ,
          const SizedBox(height: 4),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF757575), fontSize: 12)),
          const Spacer(),
          if (progress != null)
            LinearProgressIndicator(value: progress, color: Colors.green, minHeight: 4),
          const SizedBox(height: 6),
          Text(time, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}