import 'package:flutter/material.dart';
import '../../../models/shipment.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/shared_profile_tab.dart';
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
  // Available missions (no transporter assigned yet, status=requested)
  List<Shipment> _availableMissions = [];
  // My assigned shipments
  List<Shipment> _myShipments = [];
  bool _loading = true;
  int? _currentUserId;

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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await SessionService.getUser();
      _currentUserId = user?.id;
      // Fetch all shipments then split client-side
      final data = await ApiService.getShipments();
      final all = data
          .map((e) => Shipment.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _availableMissions = all
              .where((s) =>
                  s.transporterId == null &&
                  s.status == ShipmentStatus.requested)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _myShipments = all
              .where((s) => s.transporterId == _currentUserId)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── My shipments stats ────────────────────────────────
  int get _activeCount => _myShipments
      .where((s) =>
          s.status == ShipmentStatus.inTransit ||
          s.status == ShipmentStatus.pickedUp)
      .length;

  int get _deliveredCount =>
      _myShipments.where((s) => s.status == ShipmentStatus.delivered).length;

  int get _pendingCount => _myShipments
      .where((s) =>
          s.status != ShipmentStatus.delivered &&
          s.status != ShipmentStatus.cancelled)
      .length;

  double get _completionRate {
    if (_myShipments.isEmpty) return 0;
    return (_deliveredCount / _myShipments.length) * 100;
  }

  double get _pendingRate {
    if (_myShipments.isEmpty) return 0;
    return (_pendingCount / _myShipments.length).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      currentIndex: _currentIndex,
      userRole: 'Transporteur',
      userId: _currentUserId,
      navItems: const [
        NavItem(icon: Icons.home_outlined, label: 'Home'),
        NavItem(icon: Icons.assignment_outlined, label: 'Missions'),
        NavItem(icon: Icons.chat_bubble_outline, label: 'Messages'),
        NavItem(icon: Icons.route_outlined, label: 'My Trips'),
        NavItem(icon: Icons.person_outline, label: 'Profile'),
      ],
      onTabSelected: (i) => setState(() => _currentIndex = i),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildMissionsTab(),
          const ConversationsScreen(),
          _buildMyTripsTab(),
          _buildProfileTab(),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
            const SizedBox(height: 24),
            // ── Action Buttons (same style as Buyer dashboard) ──
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = 1),
                    child: _buildActionButton(
                      'Open\nMissions',
                      Icons.assignment_outlined,
                      false,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = 3),
                    child: _buildActionButton(
                      'My\nTrips',
                      Icons.route_outlined,
                      true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                  'MY ACTIVE SHIPMENTS',
                  Icons.timeline,
                  Colors.pink,
                  _loading ? 0 : _pendingRate,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── MISSIONS TAB ─────────────────────────────────────
  Widget _buildMissionsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _primaryGreen,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVAILABLE MISSIONS',
                    style: TextStyle(
                      color: _primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Open Missions',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap a mission to view details and accept it.',
                    style: TextStyle(color: _textLight, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_availableMissions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No available missions right now',
                      style: TextStyle(color: _textLight, fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final mission = _availableMissions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _missionCard(mission),
                    );
                  },
                  childCount: _availableMissions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _missionCard(Shipment mission) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_shipping_outlined,
                      color: _primaryGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#SHP-${mission.id}',
                        style: TextStyle(
                          color: _textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${mission.pickupLocation} → ${mission.deliveryLocation}',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'OPEN',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _missionDetailRow(
                  Icons.fitness_center_outlined,
                  'Weight',
                  mission.weight != null
                      ? '${(mission.weight! / 1000).toStringAsFixed(1)} tons'
                      : 'N/A',
                ),
                const SizedBox(height: 8),
                _missionDetailRow(
                  Icons.straighten_outlined,
                  'Distance',
                  mission.estimatedDistance != null
                      ? '${mission.estimatedDistance!.toStringAsFixed(0)} km'
                      : 'N/A',
                ),
                const SizedBox(height: 8),
                _missionDetailRow(
                  Icons.calendar_today_outlined,
                  'Expected delivery',
                  mission.estimatedDeliveryDate != null
                      ? _formatDate(mission.estimatedDeliveryDate!)
                      : 'N/A',
                ),
                if ((mission.trackingNote ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _missionDetailRow(
                    Icons.info_outline,
                    'Note',
                    mission.trackingNote!,
                  ),
                ],
              ],
            ),
          ),
          // Contact + Accept + Refuse buttons row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // "View Details & Contact" button
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () => _showMissionDetailSheet(mission),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('View Details & Contact'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryGreen,
                      side: BorderSide(color: _primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Accept / Refuse row
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () => _refuseMission(mission),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Refuse'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAcceptMissionSheet(mission),
                          icon: const Icon(Icons.check_circle_outline,
                              size: 16),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _missionDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _textLight),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: _textLight,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: _textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  // ── Action button — same style as Buyer dashboard ─────
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
          Icon(icon,
              color: isPrimary ? Colors.white : _textColor, size: 20),
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

  // ── Refuse mission (mark cancelled on the server) ────
  Future<void> _refuseMission(Shipment mission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Refuse Mission',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to refuse mission #SHP-${mission.id}?\n'
            '${mission.pickupLocation} → ${mission.deliveryLocation}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Refuse',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.updateShipment(mission.id!, {'status': 'cancelled'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission refused')),
        );
      }
      await _loadData();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to refuse mission')),
        );
      }
    }
  }

  // ── Mission detail bottom sheet with contact ──────────
  void _showMissionDetailSheet(Shipment mission) async {
    final user = await SessionService.getUser();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MissionDetailSheet(
        mission: mission,
        currentUserId: user?.id ?? 0,
        currentUserName: user?.fullName ?? widget.fullName,
        primaryGreen: _primaryGreen,
        textColor: _textColor,
        textLight: _textLight,
      ),
    );
  }

  void _showAcceptMissionSheet(Shipment mission) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Accept Mission #SHP-${mission.id}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${mission.pickupLocation} → ${mission.deliveryLocation}',
              style: TextStyle(color: _textLight, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (mission.weight != null)
              Text(
                'Weight: ${(mission.weight! / 1000).toStringAsFixed(1)} tons',
                style: TextStyle(color: _textLight, fontSize: 13),
              ),
            if (mission.estimatedDistance != null)
              Text(
                'Distance: ${mission.estimatedDistance!.toStringAsFixed(0)} km',
                style: TextStyle(color: _textLight, fontSize: 13),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _acceptMission(mission);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Confirm & Accept',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptMission(Shipment mission) async {
    try {
      await ApiService.updateShipment(mission.id!, {
        'transporterId': _currentUserId,
        'transporterName': widget.fullName,
        'status': 'accepted',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Mission #SHP-${mission.id} accepted!'),
            backgroundColor: _primaryGreen,
          ),
        );
      }
      await _loadData();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to accept mission')),
        );
      }
    }
  }

  // ── MY TRIPS TAB ──────────────────────────────────────
  Widget _buildMyTripsTab() {
    final active = _myShipments
        .where((s) =>
            s.status == ShipmentStatus.accepted ||
            s.status == ShipmentStatus.pickedUp ||
            s.status == ShipmentStatus.inTransit)
        .toList();
    final delivered =
        _myShipments.where((s) => s.status == ShipmentStatus.delivered).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _primaryGreen,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY DELIVERIES',
                    style: TextStyle(
                      color: _primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'My Trips',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap a trip to update its delivery status.',
                    style: TextStyle(color: _textLight, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_myShipments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.route_outlined,
                        size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No trips yet — accept a mission first',
                      style: TextStyle(color: _textLight, fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Active section
            if (active.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'ACTIVE (${active.length})',
                    style: TextStyle(
                      color: _primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final s = active[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => _showStatusUpdateSheet(s),
                          child: _myTripCard(s),
                        ),
                      );
                    },
                    childCount: active.length,
                  ),
                ),
              ),
            ],
            // Delivered section
            if (delivered.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'COMPLETED (${delivered.length})',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final s = delivered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _myTripCard(s),
                      );
                    },
                    childCount: delivered.length,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _myTripCard(Shipment s) {
    final Color statusColor;
    final IconData statusIcon;
    switch (s.status) {
      case ShipmentStatus.accepted:
        statusColor = Colors.blue;
        statusIcon = Icons.check_outlined;
        break;
      case ShipmentStatus.pickedUp:
        statusColor = Colors.purple;
        statusIcon = Icons.inventory_2_outlined;
        break;
      case ShipmentStatus.inTransit:
        statusColor = Colors.orange;
        statusIcon = Icons.route_outlined;
        break;
      case ShipmentStatus.delivered:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    final bool canUpdate = s.status != ShipmentStatus.delivered &&
        s.status != ShipmentStatus.cancelled;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#SHP-${s.id}',
                        style: TextStyle(
                            color: _textLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${s.pickupLocation} → ${s.deliveryLocation}',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.status.label.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (s.weight != null) ...[
                  Icon(Icons.fitness_center_outlined,
                      size: 13, color: _textLight),
                  const SizedBox(width: 4),
                  Text(
                    '${(s.weight! / 1000).toStringAsFixed(1)}t',
                    style: TextStyle(color: _textLight, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                ],
                if (s.estimatedDistance != null) ...[
                  Icon(Icons.straighten_outlined,
                      size: 13, color: _textLight),
                  const SizedBox(width: 4),
                  Text(
                    '${s.estimatedDistance!.toStringAsFixed(0)} km',
                    style: TextStyle(color: _textLight, fontSize: 12),
                  ),
                ],
                const Spacer(),
                if (canUpdate)
                  TextButton.icon(
                    onPressed: () => _showStatusUpdateSheet(s),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Update'),
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryGreen,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            if ((s.trackingNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                s.trackingNote!,
                style: TextStyle(color: _textLight, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SharedProfileTab(
      fullName: widget.fullName,
      subtitle: 'TRANSPORTER • ${widget.vehicleType}',
      primaryGreen: _primaryGreen,
      textColor: _textColor,
      textLight: _textLight,
      infoItems: [
        ProfileInfoItem(
          icon: Icons.email_outlined,
          iconColor: const Color(0xFF1565C0),
          label: 'EMAIL',
          value: widget.email,
        ),
        ProfileInfoItem(
          icon: Icons.phone_outlined,
          iconColor: const Color(0xFFE65100),
          label: 'PHONE',
          value: widget.phone,
        ),
        ProfileInfoItem(
          icon: Icons.location_on_outlined,
          iconColor: const Color(0xFFAD1457),
          label: 'CITY',
          value: widget.city,
        ),
        ProfileInfoItem(
          icon: Icons.local_shipping_outlined,
          iconColor: const Color(0xFF00695C),
          label: 'VEHICLE TYPE',
          value: widget.vehicleType,
        ),
        ProfileInfoItem(
          icon: Icons.fitness_center_outlined,
          iconColor: const Color(0xFF6A1B9A),
          label: 'CAPACITY',
          value: widget.capacity,
        ),
      ],
    );
  }

  void _showStatusUpdateSheet(Shipment shipment) {
    if (shipment.status == ShipmentStatus.delivered) return;
    final nextStatuses = <String, String>{
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
                      _loadData();
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
    final pending = _myShipments
        .where((s) =>
            s.status != ShipmentStatus.delivered &&
            s.status != ShipmentStatus.cancelled)
        .toList();
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

}

// ─────────────────────────────────────────────────────────────────────────────
//  Mission Detail & Contact Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _MissionDetailSheet extends StatefulWidget {
  final Shipment mission;
  final int currentUserId;
  final String currentUserName;
  final Color primaryGreen;
  final Color textColor;
  final Color textLight;

  const _MissionDetailSheet({
    required this.mission,
    required this.currentUserId,
    required this.currentUserName,
    required this.primaryGreen,
    required this.textColor,
    required this.textLight,
  });

  @override
  State<_MissionDetailSheet> createState() => _MissionDetailSheetState();
}

class _MissionDetailSheetState extends State<_MissionDetailSheet> {
  Map<String, dynamic>? _contactUser;
  bool _chatOpen = false;

  // For the integrated chat
  final TextEditingController _msgCtrl = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _chatLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContactUser();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContactUser() async {
    // The contact is the buyer who published the mission, fallback to farmer
    final contactId = widget.mission.farmerId;
    try {
      final data = await ApiService.getUserById(contactId);
      if (mounted) setState(() => _contactUser = data);
    } catch (_) {}
  }

  Future<void> _loadChatMessages() async {
    setState(() => _chatLoading = true);
    try {
      final partnerId = widget.mission.farmerId;
      final sent = await ApiService.getMessages(
        senderId: '${widget.currentUserId}',
        receiverId: '$partnerId',
      );
      final received = await ApiService.getMessages(
        senderId: '$partnerId',
        receiverId: '${widget.currentUserId}',
      );
      final combined = [
        ...sent.cast<Map<String, dynamic>>(),
        ...received.cast<Map<String, dynamic>>(),
      ];
      combined.sort(
          (a, b) => (a['createdAt'] ?? '').compareTo(b['createdAt'] ?? ''));
      if (mounted) {
        setState(() {
          _messages = combined;
          _chatLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    final partnerId = widget.mission.farmerId;
    final partnerName =
        _contactUser?['fullName'] as String? ?? widget.mission.farmerName;
    try {
      await ApiService.sendMessage({
        'senderId': widget.currentUserId,
        'senderName': widget.currentUserName,
        'receiverId': partnerId,
        'receiverName': partnerName,
        'content': text,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await _loadChatMessages();
    } catch (_) {}
  }

  void _openChat() {
    _loadChatMessages();
    setState(() => _chatOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final contactName =
        _contactUser?['fullName'] as String? ?? m.farmerName;
    final contactCity =
        _contactUser?['city'] as String? ?? '';
    final contactPhone =
        _contactUser?['phone'] as String? ?? '';
    final contactRole =
        _contactUser?['role'] as String? ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle ──────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_shipping_outlined,
                      color: widget.primaryGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#SHP-${m.id}',
                        style: TextStyle(
                            color: widget.textLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${m.pickupLocation} → ${m.deliveryLocation}',
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: widget.textLight),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 20),

          // ── Body ────────────────────────────────────────
          Expanded(
            child: _chatOpen ? _buildChatView() : _buildDetailView(
              m, contactName, contactCity, contactPhone, contactRole),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView(Shipment m, String contactName, String contactCity,
      String contactPhone, String contactRole) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Mission info ─────────────────────────────
          Text(
            'MISSION DETAILS',
            style: TextStyle(
              color: widget.primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow(Icons.location_on_outlined, 'Pickup',
              m.pickupLocation),
          _detailRow(Icons.flag_outlined, 'Delivery',
              m.deliveryLocation),
          if (m.weight != null)
            _detailRow(Icons.fitness_center_outlined, 'Weight',
                '${(m.weight! / 1000).toStringAsFixed(1)} tons'),
          if (m.estimatedDistance != null)
            _detailRow(Icons.straighten_outlined, 'Distance',
                '${m.estimatedDistance!.toStringAsFixed(0)} km'),
          if (m.estimatedDeliveryDate != null)
            _detailRow(Icons.calendar_today_outlined, 'Expected delivery',
                '${m.estimatedDeliveryDate!.day.toString().padLeft(2, '0')}/${m.estimatedDeliveryDate!.month.toString().padLeft(2, '0')}/${m.estimatedDeliveryDate!.year}'),
          if ((m.trackingNote ?? '').isNotEmpty)
            _detailRow(Icons.info_outline, 'Note', m.trackingNote!),

          const SizedBox(height: 24),

          // ── Contact card ─────────────────────────────
          Text(
            'PUBLISHED BY',
            style: TextStyle(
              color: widget.primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5ED),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: widget.primaryGreen.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: widget.primaryGreen,
                  child: Text(
                    contactName.isNotEmpty ? contactName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contactName,
                        style: TextStyle(
                          color: widget.textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (contactRole.isNotEmpty)
                        Text(
                          contactRole,
                          style: TextStyle(
                              color: widget.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      if (contactCity.isNotEmpty)
                        Text(contactCity,
                            style: TextStyle(
                                color: widget.textLight, fontSize: 12)),
                      if (contactPhone.isNotEmpty)
                        Text(contactPhone,
                            style: TextStyle(
                                color: widget.textLight, fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _openChat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_rounded,
                            size: 18, color: Color(0xFF1565C0)),
                        SizedBox(height: 4),
                        Text(
                          'Send\nMessage',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Accept / Refuse ─────────────────────────
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // parent handles refuse via _refuseMission
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Refuse'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Re-open accept sheet from parent
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: widget.textLight),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
                color: widget.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: widget.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Chat View ────────────────────────────────────────
  Widget _buildChatView() {
    final contactName =
        _contactUser?['fullName'] as String? ?? widget.mission.farmerName;
    return Column(
      children: [
        // Chat header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _chatOpen = false),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new,
                        color: widget.primaryGreen, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                          color: widget.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 16,
                backgroundColor: widget.primaryGreen,
                child: Text(
                  contactName.isNotEmpty
                      ? contactName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  contactName,
                  style: TextStyle(
                      color: widget.textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 20),
        // Messages list
        Expanded(
          child: _chatLoading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? Center(
                      child: Text('No messages yet. Say hello!',
                          style: TextStyle(
                              color: widget.textLight, fontSize: 14)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final msg = _messages[i];
                        final isMe =
                            msg['senderId'] == widget.currentUserId;
                        return _buildBubble(
                            msg['content'] ?? '', isMe: isMe);
                      },
                    ),
        ),
        // Input area
        Container(
          padding: EdgeInsets.fromLTRB(
              20, 10, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F4),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(String text, {required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          color: isMe ? widget.primaryGreen : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : widget.textColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}