import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user.dart';
import '../../../viewmodels/admin_users_viewmodel.dart';

/// Admin user validation: approve / reject (block) accounts and filter by
/// status. Reachable from the admin dashboard.
class AdminUsersScreen extends StatelessWidget {
  static const routeName = '/admin/users';
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminUsersViewModel>(
      create: (_) => AdminUsersViewModel()..load(),
      child: const _AdminUsersContent(),
    );
  }
}

class _AdminUsersContent extends StatelessWidget {
  const _AdminUsersContent();

  static const Color _primaryGreen = Color(0xFF23763D);
  static const Color _textColor = Color(0xFF1A1D1A);
  static const Color _textLight = Color(0xFF757575);
  static const Color _bg = Color(0xFFF4F9F3);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminUsersViewModel>();
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _textColor,
        title: const Text('User Validation',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? _errorView(vm)
              : RefreshIndicator(
                  onRefresh: vm.load,
                  child: CustomScrollView(slivers: [
                    SliverToBoxAdapter(child: _filters(context, vm)),
                    if (vm.users.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text('No users in this category',
                              style: TextStyle(color: _textLight)),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _userTile(context, vm, vm.users[i]),
                            ),
                            childCount: vm.users.length,
                          ),
                        ),
                      ),
                  ]),
                ),
    );
  }

  Widget _errorView(AdminUsersViewModel vm) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(vm.error!, style: const TextStyle(color: _textLight)),
          const SizedBox(height: 12),
          TextButton(onPressed: vm.load, child: const Text('Retry')),
        ]),
      );

  Widget _filters(BuildContext context, AdminUsersViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${vm.totalCount} registered accounts',
            style: const TextStyle(fontSize: 13, color: _textLight)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chip(context, vm, null, 'All', vm.totalCount),
            const SizedBox(width: 8),
            _chip(context, vm, UserStatus.pending, 'Pending',
                vm.countFor(UserStatus.pending)),
            const SizedBox(width: 8),
            _chip(context, vm, UserStatus.active, 'Active',
                vm.countFor(UserStatus.active)),
            const SizedBox(width: 8),
            _chip(context, vm, UserStatus.blocked, 'Blocked',
                vm.countFor(UserStatus.blocked)),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(BuildContext context, AdminUsersViewModel vm,
      UserStatus? status, String label, int count) {
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

  Widget _userTile(
      BuildContext context, AdminUsersViewModel vm, User user) {
    final roleColor = _roleColor(user.role);
    final isUpdating = user.id != null && vm.updating.contains(user.id);
    return Container(
      padding: const EdgeInsets.all(14),
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
          CircleAvatar(
            radius: 22,
            backgroundColor: roleColor.withValues(alpha: 0.12),
            child: Text(
              user.fullName.isNotEmpty
                  ? user.fullName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: roleColor, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName.isNotEmpty ? user.fullName : user.email,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _textColor)),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: const TextStyle(fontSize: 12, color: _textLight),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
          ),
          _statusBadge(user.status),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text(user.role.name.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: roleColor)),
          ),
          if (user.city.isNotEmpty) ...[
            const SizedBox(width: 8),
            Icon(Icons.location_on_outlined, size: 13, color: _textLight),
            const SizedBox(width: 2),
            Text(user.city,
                style: const TextStyle(fontSize: 11, color: _textLight)),
          ],
        ]),
        if (user.status != UserStatus.active ||
            user.role != UserRole.admin) ...[
          const SizedBox(height: 12),
          if (isUpdating)
            const Center(
                child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Row(children: [
              if (user.status != UserStatus.active)
                Expanded(
                  child: _actionButton(
                    label: 'Approve',
                    icon: Icons.check_circle_outline,
                    color: _primaryGreen,
                    onTap: () => _act(context, vm, user, approve: true),
                  ),
                ),
              if (user.status != UserStatus.active &&
                  user.status != UserStatus.blocked)
                const SizedBox(width: 10),
              if (user.status != UserStatus.blocked)
                Expanded(
                  child: _actionButton(
                    label: 'Reject',
                    icon: Icons.block,
                    color: Colors.red,
                    onTap: () => _act(context, vm, user, approve: false),
                  ),
                ),
            ]),
        ],
      ]),
    );
  }

  Future<void> _act(BuildContext context, AdminUsersViewModel vm, User user,
      {required bool approve}) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = approve ? await vm.approve(user) : await vm.reject(user);
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? (approve
              ? '${user.fullName} approved'
              : '${user.fullName} blocked')
          : 'Update failed. Try again.'),
      backgroundColor: ok ? _primaryGreen : Colors.red,
    ));
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _statusBadge(UserStatus status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10)),
      child: Text(status.label.toUpperCase(),
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }

  static Color _statusColor(UserStatus status) {
    switch (status) {
      case UserStatus.pending:
        return const Color(0xFFE65100);
      case UserStatus.active:
        return const Color(0xFF2E7D32);
      case UserStatus.blocked:
        return Colors.red;
    }
  }

  static Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return const Color(0xFF2E7D32);
      case UserRole.buyer:
        return const Color(0xFF1565C0);
      case UserRole.transporter:
        return const Color(0xFFE65100);
      case UserRole.bank:
        return const Color(0xFF6A1B9A);
      case UserRole.admin:
        return Colors.red;
    }
  }
}
