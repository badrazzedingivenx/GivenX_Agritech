import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/finance_request.dart';
import '../../../viewmodels/admin_finance_viewmodel.dart';

/// Admin finance requests overview: lists every financing request with its
/// status, the requesting agriculteur and the assigned établissement de
/// financement. Read-only with a detail sheet.
class AdminFinanceScreen extends StatelessWidget {
  static const routeName = '/admin/finance';
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminFinanceViewModel>(
      create: (_) => AdminFinanceViewModel()..load(),
      child: const _AdminFinanceContent(),
    );
  }
}

class _AdminFinanceContent extends StatelessWidget {
  const _AdminFinanceContent();

  static const Color _primaryGreen = Color(0xFF23763D);
  static const Color _textColor = Color(0xFF1A1D1A);
  static const Color _textLight = Color(0xFF757575);
  static const Color _bg = Color(0xFFF4F9F3);

  static const _filterStatuses = ['pending', 'reviewing', 'approved', 'rejected'];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminFinanceViewModel>();
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _textColor,
        title: const Text('Finance Requests',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text(vm.error!, style: const TextStyle(color: _textLight)),
                  const SizedBox(height: 12),
                  TextButton(onPressed: vm.load, child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: vm.load,
                  child: CustomScrollView(slivers: [
                    SliverToBoxAdapter(child: _filters(vm)),
                    if (vm.requests.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child: Text('No finance requests in this category',
                                style: TextStyle(color: _textLight))),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _requestTile(context, vm, vm.requests[i]),
                            ),
                            childCount: vm.requests.length,
                          ),
                        ),
                      ),
                  ]),
                ),
    );
  }

  Widget _filters(AdminFinanceViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${vm.totalCount} financing requests',
            style: const TextStyle(fontSize: 13, color: _textLight)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chip(vm, null, 'All', vm.totalCount),
            for (final s in _filterStatuses) ...[
              const SizedBox(width: 8),
              _chip(vm, s, _capitalize(s), vm.countFor(s)),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _chip(
      AdminFinanceViewModel vm, String? status, String label, int count) {
    final selected = vm.statusFilter == status;
    return GestureDetector(
      onTap: () => vm.setFilter(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? _primaryGreen : Colors.grey.shade200),
        ),
        child: Text('$label ($count)',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _textColor)),
      ),
    );
  }

  Widget _requestTile(
      BuildContext context, AdminFinanceViewModel vm, FinanceRequest r) {
    final color = _statusColor(r.status);
    final bank = vm.bankNameFor(r);
    return GestureDetector(
      onTap: () => _showDetail(context, vm, r),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(r.title.isNotEmpty ? r.title : 'Finance request',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: _textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(r.status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.agriculture_outlined, size: 14, color: _textLight),
            const SizedBox(width: 4),
            Expanded(
                child: Text(
                    r.farmerName.isNotEmpty ? r.farmerName : 'Farmer #${r.farmerId}',
                    style: const TextStyle(fontSize: 12, color: _textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            Icon(Icons.account_balance_outlined, size: 14, color: _textLight),
            const SizedBox(width: 4),
            Text(bank ?? 'Unassigned',
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: bank == null ? FontStyle.italic : FontStyle.normal,
                    color: bank == null ? _textLight : _textColor)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.payments_outlined, size: 14, color: _primaryGreen),
            const SizedBox(width: 4),
            Text('${r.amount.toStringAsFixed(0)} MAD',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _primaryGreen,
                    fontSize: 13)),
            const Spacer(),
            Text(r.purpose,
                style: const TextStyle(fontSize: 11, color: _textLight)),
          ]),
        ]),
      ),
    );
  }

  void _showDetail(
      BuildContext context, AdminFinanceViewModel vm, FinanceRequest r) {
    final color = _statusColor(r.status);
    final bank = vm.bankNameFor(r);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(r.title.isNotEmpty ? r.title : 'Finance request',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textColor)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(r.status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ),
            const SizedBox(height: 20),
            _detailRow(Icons.payments_outlined, _primaryGreen, 'Amount',
                '${r.amount.toStringAsFixed(0)} MAD'),
            _detailRow(Icons.category_outlined, const Color(0xFFE65100),
                'Purpose', r.purpose),
            _detailRow(Icons.agriculture_outlined, const Color(0xFF2E7D32),
                'Requested by',
                r.farmerName.isNotEmpty ? r.farmerName : 'Farmer #${r.farmerId}'),
            if (r.farmerCity.isNotEmpty)
              _detailRow(Icons.location_on_outlined, const Color(0xFF6A1B9A),
                  'City', r.farmerCity),
            if (r.farmerPhone.isNotEmpty)
              _detailRow(Icons.phone_outlined, const Color(0xFFAD1457), 'Phone',
                  r.farmerPhone),
            _detailRow(Icons.account_balance_outlined, const Color(0xFF1565C0),
                'Assigned établissement', bank ?? 'Unassigned'),
            if (r.description.isNotEmpty)
              _detailRow(Icons.description_outlined, _textLight, 'Description',
                  r.description),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, Color iconColor, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textColor)),
          ]),
        ),
      ]),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return Colors.red;
      case 'reviewing':
        return const Color(0xFF1565C0);
      case 'pending':
      default:
        return const Color(0xFFE65100);
    }
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
