import 'package:flutter/material.dart';

import '../../../models/payment.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/shared_profile_tab.dart';
import '../chat/chat_screen.dart';
import '../chat/conversations_screen.dart';

class BanqueDashboard extends StatefulWidget {
  final String bankName;
  final String officialId;
  final String email;
  final String phone;
  final String logoPath;

  const BanqueDashboard({
    super.key,
    required this.bankName,
    required this.officialId,
    required this.email,
    required this.phone,
    required this.logoPath,
  });

  @override
  State<BanqueDashboard> createState() => _BanqueDashboardState();
}

class _BanqueDashboardState extends State<BanqueDashboard> {
  static const Color _primaryGreen = Color(0xFF23763D);
  static const Color _textColor = Color(0xFF1A1D1A);
  static const Color _textLight = Color(0xFF757575);

  int _currentIndex = 0;
  List<Payment> _payments = [];
  bool _loading = true;
  int? _currentUserId;
  List<Map<String, dynamic>> _financeRequests = [];
  bool _financeLoading = true;

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
    if (columns == 3) return 0.92;
    if (columns == 2) return 0.98;
    return 1.16;
  }

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _loadFinanceRequests();
  }

  Future<void> _loadFinanceRequests() async {
    try {
      final data = await ApiService.getFinanceRequests();
      if (mounted) {
        setState(() {
          _financeRequests = data.cast<Map<String, dynamic>>();
          _financeRequests.sort((a, b) {
            final aDate = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          _financeLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _financeLoading = false);
    }
  }

  Future<void> _loadPayments() async {
    try {
      final user = await SessionService.getUser();
      _currentUserId = user?.id;
      final data = await ApiService.getPayments();
      if (mounted) {
        setState(() {
          _payments = data
              .map((e) => Payment.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Finance-request based metrics ────────────────────────────────

  double get _portfolioValue => _financeRequests
      .where((r) => r['status'] == 'approved')
      .fold<double>(0, (sum, r) => sum + (r['amount'] as num? ?? 0).toDouble());

  double _financeAmountInWindow(DateTime from, DateTime to) {
    return _financeRequests
        .where((r) => r['status'] == 'approved')
        .where((r) {
          final d = DateTime.tryParse(r['createdAt']?.toString() ?? '');
          if (d == null) return false;
          return !d.isBefore(from) && d.isBefore(to);
        })
        .fold<double>(0, (sum, r) => sum + (r['amount'] as num? ?? 0).toDouble());
  }

  double get _portfolioTrendPercent {
    final now = DateTime.now();
    final currentStart = now.subtract(const Duration(days: 30));
    final previousStart = now.subtract(const Duration(days: 60));
    final current = _financeAmountInWindow(currentStart, now);
    final previous = _financeAmountInWindow(previousStart, currentStart);
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  double get _repaymentRate {
    final approved = _financeRequests.where((r) => r['status'] == 'approved').length;
    final settled = _financeRequests
        .where((r) => r['status'] == 'approved' || r['status'] == 'rejected')
        .length;
    if (settled == 0) return 0;
    return (approved / settled) * 100;
  }

  int get _activeCreditCount =>
      _financeRequests.where((r) => r['status'] == 'approved').length;

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      currentIndex: _currentIndex,
      userRole: 'Banque',
      userId: _currentUserId,
      navItems: const [
        NavItem(icon: Icons.home_outlined, label: 'Home'),
        NavItem(icon: Icons.request_page_outlined, label: 'Requests'),
        NavItem(icon: Icons.chat_bubble_outline, label: 'Messages'),
        NavItem(icon: Icons.person_outline, label: 'Profile'),
      ],
      onTabSelected: (index) => setState(() => _currentIndex = index),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildFinanceRequestsTab(),
          const ConversationsScreen(),
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
            'BANK DASHBOARD',
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hello, ${widget.bankName}',
            style: TextStyle(
              fontSize: 28,
              color: _textColor,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Here is the status of your financial pipeline today.',
            style: TextStyle(color: _textLight, fontSize: 13),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _currentIndex = 1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.request_page_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'View Requests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: _gridColumns(context),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: _gridAspectRatio(context),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _metricSquareCard(
                title: 'Portfolio Value',
                value: _financeLoading ? '...' : '${_portfolioValue.toStringAsFixed(0)} MAD',
                accent: _primaryGreen,
                icon: Icons.account_balance_wallet_outlined,
              ),
              _metricSquareCard(
                title: 'Trend',
                value: _financeLoading
                    ? '...'
                    : '${_portfolioTrendPercent >= 0 ? '+' : ''}${_portfolioTrendPercent.toStringAsFixed(1)}%',
                accent: const Color(0xFF2E7D32),
                icon: Icons.trending_up,
              ),
              _metricSquareCard(
                title: 'Approval Rate',
                value: _financeLoading ? '...' : '${_repaymentRate.toStringAsFixed(1)}%',
                accent: const Color(0xFF2E7D32),
                icon: Icons.check_circle_outline,
              ),
              _metricSquareCard(
                title: 'Active Credit',
                value: _financeLoading ? '...' : '$_activeCreditCount',
                subtitle: 'Approved Requests',
                accent: const Color(0xFF2E7D32),
                icon: Icons.groups_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: _financeLoading
                ? [const Center(child: CircularProgressIndicator())]
                : _financeRequests.isEmpty
                    ? [const Center(child: Text('No activity yet'))]
                    : [
                        GridView.count(
                          crossAxisCount: _gridColumns(context),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: _gridAspectRatio(context),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: _financeRequests.take(6).map((req) {
                            final status = (req['status'] ?? 'pending').toString();
                            final amount = (req['amount'] as num? ?? 0).toDouble();
                            final statusColor = _requestStatusColor(status);
                            return _activityTile(
                              req['farmerName']?.toString() ?? 'Farmer',
                              req['title']?.toString() ?? '',
                              '${amount.toStringAsFixed(0)} MAD',
                              _requestStatusLabel(status),
                              statusColor,
                            );
                          }).toList(),
                        )
                      ],
          ),
        ],
      ),
    );
  }

  static const _purposeLabels = {
    'equipment': 'Equipment / Machinery',
    'seeds': 'Seeds & Inputs',
    'infrastructure': 'Infrastructure',
    'land': 'Land Purchase',
    'other': 'Other',
  };
  static const _purposeIcons = {
    'equipment': Icons.agriculture,
    'seeds': Icons.grass,
    'infrastructure': Icons.construction,
    'land': Icons.landscape,
    'other': Icons.more_horiz,
  };
  static const _purposeColors = {
    'equipment': Color(0xFF1565C0),
    'seeds': Color(0xFF2E7D32),
    'infrastructure': Color(0xFFE65100),
    'land': Color(0xFF6D4C41),
    'other': Color(0xFF6A1B9A),
  };

  Color _requestStatusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'reviewing':
        return const Color(0xFF1565C0);
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _requestStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'APPROVED';
      case 'reviewing':
        return 'REVIEWING';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'PENDING';
    }
  }

  void _openRequestDetail(Map<String, dynamic> req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final status = (req['status'] ?? 'pending').toString();
        final purpose = (req['purpose'] ?? 'other').toString();
        final purposeColor = _purposeColors[purpose] ?? _primaryGreen;
        final purposeIcon = _purposeIcons[purpose] ?? Icons.more_horiz;
        final amount = req['amount'];
        final amountStr =
            amount != null ? '${(amount as num).toStringAsFixed(0)} MAD' : '—';
        final farmerId = req['farmerId'];
        final farmerName = req['farmerName']?.toString() ?? 'Farmer';
        final farmerCity = req['farmerCity']?.toString() ?? '';
        final farmerPhone = req['farmerPhone']?.toString() ?? '';
        final dateStr = req['createdAt'] != null
            ? DateTime.tryParse(req['createdAt'].toString())
                    ?.toLocal()
                    .toString()
                    .split(' ')
                    .first ??
                ''
            : '';

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: purposeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(purposeIcon, color: purposeColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req['title']?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _textColor,
                            ),
                          ),
                          Text(
                            _purposeLabels[purpose] ?? purpose,
                            style: TextStyle(
                              fontSize: 12,
                              color: purposeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            _requestStatusColor(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _requestStatusLabel(status),
                        style: TextStyle(
                          color: _requestStatusColor(status),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Amount
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F9F3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined,
                          color: Color(0xFF1565C0), size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Requested Amount',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF757575)),
                          ),
                          Text(
                            amountStr,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Farmer info
                Text(
                  'FARMER DETAILS',
                  style: TextStyle(
                    color: _primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                _detailRow(Icons.person_outline, const Color(0xFF6A1B9A),
                    'Name', farmerName),
                if (farmerCity.isNotEmpty)
                  _detailRow(Icons.location_on_outlined, const Color(0xFFE65100),
                      'City', farmerCity),
                if (farmerPhone.isNotEmpty)
                  _detailRow(Icons.phone_outlined, const Color(0xFFAD1457),
                      'Phone', farmerPhone),
                if (dateStr.isNotEmpty)
                  _detailRow(Icons.calendar_today_outlined,
                      const Color(0xFF1565C0), 'Posted', dateStr),
                const SizedBox(height: 16),
                // Description
                Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    color: _primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  req['description']?.toString() ?? '',
                  style: TextStyle(
                      fontSize: 14, color: _textColor, height: 1.5),
                ),
                const SizedBox(height: 24),
                // Status update
                Text(
                  'UPDATE STATUS',
                  style: TextStyle(
                    color: _primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _statusActionBtn(
                        'Reviewing',
                        Icons.visibility_outlined,
                        const Color(0xFF1565C0),
                        status == 'reviewing',
                        () async {
                          final id = req['id'];
                          if (id == null) return;
                          await ApiService.updateFinanceRequest(
                            id is int ? id : int.parse(id.toString()),
                            {'status': 'reviewing'},
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          await _loadFinanceRequests();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statusActionBtn(
                        'Approve',
                        Icons.check_circle_outline,
                        const Color(0xFF2E7D32),
                        status == 'approved',
                        () async {
                          final id = req['id'];
                          if (id == null) return;
                          await ApiService.updateFinanceRequest(
                            id is int ? id : int.parse(id.toString()),
                            {'status': 'approved'},
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          await _loadFinanceRequests();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statusActionBtn(
                        'Reject',
                        Icons.cancel_outlined,
                        Colors.red,
                        status == 'rejected',
                        () async {
                          final id = req['id'];
                          if (id == null) return;
                          await ApiService.updateFinanceRequest(
                            id is int ? id : int.parse(id.toString()),
                            {'status': 'rejected'},
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          await _loadFinanceRequests();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Contact farmer button
                if (farmerId != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_currentUserId == null) return;
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              partnerId: farmerId is int
                                  ? farmerId
                                  : int.parse(farmerId.toString()),
                              partnerName: farmerName,
                              currentUserId: _currentUserId!,
                              currentUserName: widget.bankName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Contact Farmer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
      IconData icon, Color iconColor, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF757575))),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusActionBtn(
    String label,
    IconData icon,
    Color color,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? color : Colors.grey, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceRequestsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F3),
      body: _financeLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BANK DASHBOARD',
                          style: TextStyle(
                            color: _primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Finance Requests',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Review farmer loan requests. Tap a request to view details and contact the farmer.',
                          style: TextStyle(fontSize: 13, color: _textLight),
                        ),
                        const SizedBox(height: 16),
                        // Summary chips
                        Row(
                          children: [
                            _summaryChip(
                              '${_financeRequests.where((r) => r['status'] == 'pending').length}',
                              'Pending',
                              Colors.orange,
                              Icons.hourglass_empty,
                            ),
                            const SizedBox(width: 8),
                            _summaryChip(
                              '${_financeRequests.where((r) => r['status'] == 'reviewing').length}',
                              'Reviewing',
                              const Color(0xFF1565C0),
                              Icons.visibility_outlined,
                            ),
                            const SizedBox(width: 8),
                            _summaryChip(
                              '${_financeRequests.where((r) => r['status'] == 'approved').length}',
                              'Approved',
                              const Color(0xFF2E7D32),
                              Icons.check_circle_outline,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_financeRequests.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 48),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 64, color: _textLight),
                          const SizedBox(height: 12),
                          Text(
                            'No finance requests yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Farmers will post requests here when they need financing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: _textLight),
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
                        (ctx, i) {
                          final req = _financeRequests[i];
                          final status =
                              (req['status'] ?? 'pending').toString();
                          final purpose =
                              (req['purpose'] ?? 'other').toString();
                          final purposeColor =
                              _purposeColors[purpose] ?? _primaryGreen;
                          final purposeIcon =
                              _purposeIcons[purpose] ?? Icons.more_horiz;
                          final amount = req['amount'];
                          final amountStr = amount != null
                              ? '${(amount as num).toStringAsFixed(0)} MAD'
                              : '—';
                          final farmerName =
                              req['farmerName']?.toString() ?? 'Farmer';
                          final farmerCity =
                              req['farmerCity']?.toString() ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () => _openRequestDetail(req),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: purposeColor
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(purposeIcon,
                                              color: purposeColor, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                req['title']?.toString() ?? '',
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  color: _textColor,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                      Icons.person_outline,
                                                      size: 12,
                                                      color: Color(0xFF757575)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    farmerName,
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: _textLight),
                                                  ),
                                                  if (farmerCity.isNotEmpty)
                                                    Text(
                                                      ' • $farmerCity',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: _textLight),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: _requestStatusColor(status)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            _requestStatusLabel(status),
                                            style: TextStyle(
                                              color:
                                                  _requestStatusColor(status),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      req['description']?.toString() ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 13, color: _textLight),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.payments_outlined,
                                            size: 16,
                                            color: Color(0xFF1565C0)),
                                        const SizedBox(width: 6),
                                        Text(
                                          amountStr,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1565C0),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'Tap to review →',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _financeRequests.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _summaryChip(
      String count, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: _textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SharedProfileTab(
      fullName: widget.bankName,
      subtitle: 'BANK • ${widget.officialId}',
      primaryGreen: _primaryGreen,
      textColor: _textColor,
      textLight: _textLight,
      infoItems: [
        ProfileInfoItem(
          icon: Icons.account_balance_outlined,
          iconColor: const Color(0xFF1565C0),
          label: 'BANK NAME',
          value: widget.bankName,
        ),
        ProfileInfoItem(
          icon: Icons.badge_outlined,
          iconColor: const Color(0xFF6A1B9A),
          label: 'OFFICIAL ID',
          value: widget.officialId,
        ),
        ProfileInfoItem(
          icon: Icons.email_outlined,
          iconColor: const Color(0xFFE65100),
          label: 'EMAIL',
          value: widget.email,
        ),
        ProfileInfoItem(
          icon: Icons.phone_outlined,
          iconColor: const Color(0xFFAD1457),
          label: 'PHONE',
          value: widget.phone,
        ),
      ],
    );
  }

  Widget _metricSquareCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    String? subtitle,
  }) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF757575), fontSize: 12),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF757575), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _activityTile(
    String title,
    String subtitle,
    String amount,
    String status,
    Color amountColor,
  ) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                child: const Icon(Icons.upload_file, color: Color(0xFF5A5E5A), size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: amountColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A1D1A)),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF757575), fontSize: 12),
          ),
          const Spacer(),
          Text(amount, style: TextStyle(color: amountColor, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
