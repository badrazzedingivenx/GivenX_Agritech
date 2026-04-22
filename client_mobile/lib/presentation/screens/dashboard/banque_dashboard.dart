import 'package:flutter/material.dart';

import '../../../models/payment.dart';
import '../../../services/api_service.dart';
import '../../widgets/dashboard_scaffold.dart';

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
  }

  Future<void> _loadPayments() async {
    try {
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

  double get _totalPortfolio =>
      _payments.fold<double>(0, (sum, p) => sum + p.amount);

  int get _activeCount => _payments
      .where((p) =>
          p.status != PaymentStatus.released && p.status != PaymentStatus.failed)
      .length;

  int get _releasedCount =>
      _payments.where((p) => p.status == PaymentStatus.released).length;

  int get _failedCount =>
      _payments.where((p) => p.status == PaymentStatus.failed).length;

  int get _refundedCount =>
      _payments.where((p) => p.status == PaymentStatus.refunded).length;

  int get _settledCount => _releasedCount + _failedCount + _refundedCount;

  double get _repaymentRate {
    if (_settledCount == 0) return 0;
    return (_releasedCount / _settledCount) * 100;
  }

  double get _nplRatio {
    if (_settledCount == 0) return 0;
    return (_failedCount / _settledCount) * 100;
  }

  double get _liquidityRatio {
    if (_totalPortfolio == 0) return 0;
    return (_releasedTotal / _totalPortfolio) * 100;
  }

  double _sumAmountInWindow(DateTime from, DateTime to) {
    return _payments
        .where((p) => !p.createdAt.isBefore(from) && p.createdAt.isBefore(to))
        .fold<double>(0, (sum, p) => sum + p.amount);
  }

  double get _portfolioTrendPercent {
    final now = DateTime.now();
    final currentStart = now.subtract(const Duration(days: 30));
    final previousStart = now.subtract(const Duration(days: 60));
    final current = _sumAmountInWindow(currentStart, now);
    final previous = _sumAmountInWindow(previousStart, currentStart);
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  String get _riskGrade {
    final npl = _nplRatio;
    if (npl <= 2) return 'AAA';
    if (npl <= 5) return 'AA';
    if (npl <= 8) return 'A';
    return 'BBB';
  }

  int get _stabilityDots {
    if (_repaymentRate >= 90) return 4;
    if (_repaymentRate >= 75) return 3;
    if (_repaymentRate >= 60) return 2;
    return 1;
  }

  String get _nplInsight {
    if (_nplRatio <= 2) return 'Within target';
    if (_nplRatio <= 5) return 'Watch closely';
    return 'Above target';
  }

  double get _releasedTotal => _payments
      .where((p) => p.status == PaymentStatus.released)
      .fold<double>(0, (sum, p) => sum + p.amount);

  double get _heldTotal => _payments
      .where((p) => p.status == PaymentStatus.held)
      .fold<double>(0, (sum, p) => sum + p.amount);

  String _paymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.online:
        return 'Online';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cashOnDelivery:
        return 'Cash On Delivery';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      currentIndex: _currentIndex,
      navItems: const [
        NavItem(icon: Icons.home_outlined, label: 'Home'),
        NavItem(icon: Icons.credit_card_outlined, label: 'Loans'),
        NavItem(icon: Icons.bar_chart_outlined, label: 'Analytics'),
        NavItem(icon: Icons.person_outline, label: 'Profile'),
      ],
      onTabSelected: (index) => setState(() => _currentIndex = index),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildLoansTab(),
          _buildAnalyticsTab(),
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
          const SizedBox(height: 18),
          Row(
            children: [
              widget.logoPath.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(widget.logoPath, height: 60),
                    )
                  : const Icon(
                      Icons.account_balance,
                      size: 60,
                      color: Colors.green,
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.bankName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Text(
                      'ID: ${widget.officialId}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                value: _loading ? '...' : '${_totalPortfolio.toStringAsFixed(0)} MAD',
                accent: _primaryGreen,
                icon: Icons.account_balance_wallet_outlined,
              ),
              _metricSquareCard(
                title: 'Trend',
                value: _loading
                    ? '...'
                    : '${_portfolioTrendPercent >= 0 ? '+' : ''}${_portfolioTrendPercent.toStringAsFixed(1)}%',
                accent: const Color(0xFF2E7D32),
                icon: Icons.trending_up,
              ),
              _metricSquareCard(
                title: 'Repayment Rate',
                value: _loading ? '...' : '${_repaymentRate.toStringAsFixed(1)}%',
                accent: const Color(0xFF2E7D32),
                icon: Icons.check_circle_outline,
              ),
              _metricSquareCard(
                title: 'Active Credit',
                value: _loading ? '...' : '$_activeCount',
                subtitle: 'Farmers & Exporters',
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
            children: _loading
                ? [const Center(child: CircularProgressIndicator())]
                : _payments.isEmpty
                    ? [const Center(child: Text('No activity yet'))]
                    : [
                        GridView.count(
                          crossAxisCount: _gridColumns(context),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: _gridAspectRatio(context),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: _payments.take(6).map((p) {
                            final isReleased = p.status == PaymentStatus.released;
                            return _activityTile(
                              'Order #${p.orderId}',
                              '${p.method == PaymentMethod.bankTransfer ? 'Bank Transfer' : 'Online'} - ${p.status.label}',
                              '${isReleased ? '+' : '-'}${p.amount.toStringAsFixed(0)} MAD',
                              p.status.label.toUpperCase(),
                              isReleased ? Colors.green : Colors.orange,
                            );
                          }).toList(),
                        )
                      ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoansTab() {
    final openCredits = _payments
        .where((p) =>
            p.status != PaymentStatus.released && p.status != PaymentStatus.failed)
        .toList();

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
            'Here are your open credit operations and pending releases.',
            style: TextStyle(color: _textLight, fontSize: 13),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (openCredits.isEmpty)
            const Center(child: Text('No activity yet'))
          else
            GridView.count(
              crossAxisCount: _gridColumns(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: _gridAspectRatio(context),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: openCredits.map((p) => _activityTile(
                    'Order #${p.orderId}',
                    '${_paymentMethodLabel(p.method)} - ${p.status.label}',
                    '${p.amount.toStringAsFixed(0)} MAD',
                    p.status.label.toUpperCase(),
                    Colors.orange,
                  )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
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
            'Performance and risk indicators.',
            style: TextStyle(color: _textLight, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NPL Ratio',
                          style: TextStyle(fontSize: 14, color: Colors.red),
                        ),
                        Text(
                          _loading ? '...' : '${_nplRatio.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          _loading ? '' : _nplInsight,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Risk Grade',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              _loading ? '...' : _riskGrade,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Stability',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                4,
                                (index) => Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: index < _stabilityDots
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Deposits',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Text(
                    _loading ? '...' : '${_releasedTotal.toStringAsFixed(0)} MAD',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'In Escrow',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Text(
                    _loading ? '...' : '${_heldTotal.toStringAsFixed(0)} MAD',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Liquidity Ratio',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Text(
                    _loading ? '...' : '${_liquidityRatio.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
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
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank: ${widget.bankName}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Official ID: ${widget.officialId}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('Email: ${widget.email}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('Phone: ${widget.phone}', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
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
