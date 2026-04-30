import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/locale_controller.dart';
import '../../services/session_service.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Data model for one info tile
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class ProfileInfoItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const ProfileInfoItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Shared profile tab â€” used by every role
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class SharedProfileTab extends StatefulWidget {
  final String fullName;
  final String subtitle;
  final Color primaryGreen;
  final Color textColor;
  final Color textLight;
  final List<ProfileInfoItem> infoItems;
  /// Optional content placed between Settings and the Sign Out button.
  final Widget? extraContent;

  const SharedProfileTab({
    super.key,
    required this.fullName,
    required this.subtitle,
    required this.primaryGreen,
    required this.textColor,
    required this.textLight,
    required this.infoItems,
    this.extraContent,
  });

  @override
  State<SharedProfileTab> createState() => _SharedProfileTabState();
}

class _SharedProfileTabState extends State<SharedProfileTab> {
  // â”€â”€ state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  File? _image;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _currentLanguage = 'English';
  int _starRating = 0;

  static const List<Map<String, String>> _languages = [
    {'code': 'en', 'label': 'English',  'native': 'English',  'color': 'blue'},
    {'code': 'fr', 'label': 'Francais', 'native': 'Francais', 'color': 'indigo'},
    {'code': 'ar', 'label': 'Arabiya',  'native': 'Arabic',   'color': 'teal'},
    {'code': 'es', 'label': 'Espanol',  'native': 'Espanol',  'color': 'orange'},
  ];

  static Color _langColor(String colorKey) {
    switch (colorKey) {
      case 'indigo': return const Color(0xFF3949AB);
      case 'teal':   return const Color(0xFF00796B);
      case 'orange': return const Color(0xFFE65100);
      default:       return const Color(0xFF1565C0);
    }
  }

  // â”€â”€ theme helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Color get _green => widget.primaryGreen;
  Color get _text => widget.textColor;
  Color get _light => widget.textLight;

  // â”€â”€ init â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  String get _imageKey => 'profile_image_${widget.fullName}';

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedImage = prefs.getString(_imageKey);
    Uint8List? bytes;
    if (savedImage != null) {
      try { bytes = base64Decode(savedImage); } catch (_) {}
    }
    // If not in prefs, try loading from the DB (persisted profileImage)
    if (bytes == null) {
      try {
        final user = await SessionService.getUser();
        final dbImage = user?.profileImage;
        if (dbImage != null && dbImage.isNotEmpty) {
          bytes = base64Decode(dbImage);
          // Cache it locally so we don't hit the DB every time
          await prefs.setString(_imageKey, dbImage);
        }
      } catch (_) {}
    }
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _currentLanguage = prefs.getString('preferred_language') ?? 'English';
      _starRating = prefs.getInt('app_rating') ?? 0;
      if (bytes != null) _imageBytes = bytes;
    });
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // AVATAR
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Future<void> _pickImage() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              Text('Change Profile Photo',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _text)),
              const SizedBox(height: 20),
              _sheetOption(
                  icon: Icons.photo_library_outlined,
                  color: const Color(0xFF1565C0),
                  label: 'Choose from Gallery',
                  onTap: () => Navigator.pop(context, ImageSource.gallery)),
              const SizedBox(height: 12),
              _sheetOption(
                  icon: Icons.camera_alt_outlined,
                  color: const Color(0xFF00695C),
                  label: 'Take a Photo',
                  onTap: () => Navigator.pop(context, ImageSource.camera)),
            ],
          ),
        ),
      ),
    );
    if (src == null) return;
    final picked = await _picker.pickImage(source: src, imageQuality: 80);
    if (picked != null && mounted) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final encoded = base64Encode(bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_imageKey, encoded);
        // Persist to DB
        try {
          final user = await SessionService.getUser();
          if (user?.id != null) {
            await ApiService.updateUser(user!.id!, {'profileImage': encoded});
            await SessionService.saveSession(user.copyWith(profileImage: encoded));
          }
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _imageBytes = bytes;
          _image = null;
        });
      } else {
        final bytes = await picked.readAsBytes();
        final encoded = base64Encode(bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_imageKey, encoded);
        // Persist to DB
        try {
          final user = await SessionService.getUser();
          if (user?.id != null) {
            await ApiService.updateUser(user!.id!, {'profileImage': encoded});
            await SessionService.saveSession(user.copyWith(profileImage: encoded));
          }
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _image = File(picked.path);
          _imageBytes = bytes;
        });
      }
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // NOTIFICATIONS TOGGLE
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    if (mounted) setState(() => _notificationsEnabled = value);
    _toast(value ? 'Notifications enabled' : 'Notifications disabled');
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SECURITY & PRIVACY
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  void _openSecurity() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 20),
              Text('Security & Privacy',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _text)),
              const SizedBox(height: 20),
              // Change Password
              _sheetOption(
                icon: Icons.lock_outline,
                color: const Color(0xFF1565C0),
                label: 'Change Password',
                onTap: () {
                  Navigator.pop(ctx);
                  _showChangePassword();
                },
              ),
              const SizedBox(height: 12),
              // Biometric Login toggle tile
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withValues(alpha: 0.12),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.fingerprint,
                        color: Color(0xFF6A1B9A), size: 22),
                  ),
                  title: Text('Biometric Login',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _text)),
                  subtitle: Text(
                      _biometricEnabled ? 'Enabled' : 'Disabled',
                      style: TextStyle(fontSize: 12, color: _light)),
                  value: _biometricEnabled,
                  activeColor: _green,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('biometric_enabled', val);
                    setModal(() => _biometricEnabled = val);
                    if (mounted) setState(() => _biometricEnabled = val);
                    _toast(val
                        ? 'Biometric login enabled'
                        : 'Biometric login disabled');
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Privacy Settings
              _sheetOption(
                icon: Icons.privacy_tip_outlined,
                color: const Color(0xFF00695C),
                label: 'Privacy Settings',
                onTap: () {
                  Navigator.pop(ctx);
                  _showPrivacySheet();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ Change Password â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;
    bool saving = false;
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Icon(Icons.lock_outline, color: _green, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Change Password',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _text)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pwField(
                  controller: currentCtrl,
                  label: 'Current Password',
                  show: showCurrent,
                  toggle: () => setDlg(() => showCurrent = !showCurrent),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _pwField(
                  controller: newCtrl,
                  label: 'New Password',
                  show: showNew,
                  toggle: () => setDlg(() => showNew = !showNew),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 4) return 'Min 4 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _pwField(
                  controller: confirmCtrl,
                  label: 'Confirm New Password',
                  show: showConfirm,
                  toggle: () => setDlg(() => showConfirm = !showConfirm),
                  validator: (v) => v != newCtrl.text
                      ? 'Passwords do not match'
                      : null,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setDlg(() => saving = true);
                            try {
                              final user = await SessionService.getUser();
                              if (user == null || user.id == null) {
                                _toast('Session expired. Please login again.');
                                setDlg(() => saving = false);
                                return;
                              }
                              // Fetch stored password from API to validate
                              final stored = await ApiService.getUserById(user.id!);
                              final storedPw = stored['password']?.toString() ?? '';
                              if (currentCtrl.text.trim() != storedPw) {
                                setDlg(() => saving = false);
                                _toast('Current password is incorrect');
                                return;
                              }
                              await ApiService.updateUser(
                                  user.id!, {'password': newCtrl.text.trim()});
                              if (ctx.mounted) Navigator.pop(ctx);
                              _toast('Password updated successfully âœ“');
                            } catch (_) {
                              setDlg(() => saving = false);
                              _toast('Failed to update password');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).then((_) {
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    });
  }

  Widget _pwField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _light, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF4F6F4),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _green, width: 1.5)),
        suffixIcon: IconButton(
          icon:
              Icon(show ? Icons.visibility_off : Icons.visibility, size: 20),
          color: _light,
          onPressed: toggle,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // â”€â”€â”€ Privacy Settings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showPrivacySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child:
                        Icon(Icons.privacy_tip_outlined, color: _green),
                  ),
                  const SizedBox(width: 12),
                  Text('Privacy Settings',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _text)),
                ],
              ),
              const SizedBox(height: 24),
              _privacySection('Data Collection',
                  'AgriFlow collects only the information needed to operate the platform: your name, email, phone, location, and activity within the app.'),
              _privacySection('Data Sharing',
                  'Your data is never sold to third parties. It may be shared with connected buyers, transporters, or banks only as part of a transaction you initiate.'),
              _privacySection('Data Retention',
                  'Your account data is retained as long as your account is active. You may request deletion at any time via Contact Support.'),
              _privacySection('Your Rights',
                  'You have the right to access, correct, or delete your personal data. Contact support to exercise these rights.'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text('Got it',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacySection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _green)),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(
                  fontSize: 13, color: _light, height: 1.6)),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // LANGUAGE
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  void _openLanguage() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0277BD).withValues(alpha: 0.12),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.language_outlined,
                        color: Color(0xFF0277BD)),
                  ),
                  const SizedBox(width: 12),
                  Text('Select Language',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _text)),
                ],
              ),
              const SizedBox(height: 20),
              ..._languages.map((lang) {
                final selected = lang['label'] == _currentLanguage;
                return GestureDetector(
                  onTap: () async {
                    await LocaleController.setLocale(
                        lang['code']!, lang['label']!);
                    setModal(() {});
                    if (mounted)
                      setState(() => _currentLanguage = lang['label']!);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _toast('Language changed to ${lang['label']}');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? _green.withValues(alpha: 0.08)
                          : const Color(0xFFF4F6F4),
                      borderRadius: BorderRadius.circular(16),
                      border: selected
                          ? Border.all(color: _green, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _langColor(lang['color']!)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            lang['code']!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: _langColor(lang['color']!),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(lang['label']!,
                              style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  fontSize: 15,
                                  color: selected ? _green : _text)),
                        ),
                        if (selected)
                          Icon(Icons.check_circle, color: _green, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // HELP & SUPPORT
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  void _openHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _sheetHandle()),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withValues(alpha: 0.12),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.help_outline,
                      color: Color(0xFF00695C)),
                ),
                const SizedBox(width: 12),
                Text('Help & Support',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _text)),
              ],
            ),
            const SizedBox(height: 20),
            _sheetOption(
              icon: Icons.menu_book_outlined,
              color: const Color(0xFF283593),
              label: 'User Guide',
              onTap: () {
                Navigator.pop(ctx);
                _showUserGuide();
              },
            ),
            const SizedBox(height: 12),
            _sheetOption(
              icon: Icons.contact_support_outlined,
              color: const Color(0xFF00695C),
              label: 'Contact Support',
              onTap: () {
                Navigator.pop(ctx);
                _showContactSupport(isReport: false);
              },
            ),
            const SizedBox(height: 12),
            _sheetOption(
              icon: Icons.bug_report_outlined,
              color: const Color(0xFFB71C1C),
              label: 'Report a Bug',
              onTap: () {
                Navigator.pop(ctx);
                _showContactSupport(isReport: true);
              },
            ),
            const SizedBox(height: 12),
            _sheetOption(
              icon: Icons.star_outline,
              color: const Color(0xFFF9A825),
              label: 'Rate the App',
              trailing: _starRating > 0
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        _starRating,
                        (_) => const Icon(Icons.star,
                            color: Color(0xFFF9A825), size: 14),
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                _showRateApp();
              },
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ User Guide â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showUserGuide() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: const Color(0xFF283593).withValues(alpha: 0.12),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.menu_book_outlined,
                        color: Color(0xFF283593)),
                  ),
                  const SizedBox(width: 12),
                  Text('User Guide',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _text)),
                ],
              ),
              const SizedBox(height: 24),
              _guideSection('Getting Started',
                  'Welcome to AgriFlow! After logging in, you land on your role-specific dashboard. Each role has its own features and navigation tabs.'),
              _guideSection('Marketplace',
                  'Browse and purchase fresh agricultural products directly from farmers. Use filters to find what you need by category, location, or price.'),
              _guideSection('Orders & Shipments',
                  'Track your orders in real time. Buyers can see order status; transporters can update shipment progress step by step.'),
              _guideSection('Messages',
                  'Use the built-in chat to communicate directly with farmers, buyers, or transporters. All conversations are saved.'),
              _guideSection('Payments',
                  'Payments are managed through the escrow system. Funds are held securely and released upon delivery confirmation.'),
              _guideSection('Profile & Settings',
                  'Update your profile picture, change your password, switch languages, and manage notification preferences from this screen.'),
              _guideSection('Need More Help?',
                  'Use "Contact Support" to reach our team. We respond within 24 hours on business days.'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _green)),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(
                  fontSize: 13, color: _light, height: 1.6)),
        ],
      ),
    );
  }

  // â”€â”€â”€ Contact Support / Report Bug â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showContactSupport({required bool isReport}) {
    final msgCtrl = TextEditingController();
    final subjectCtrl = TextEditingController(
        text: isReport ? 'Bug Report' : 'Support Request');
    bool sending = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 40),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _sheetHandle()),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: (isReport
                                  ? const Color(0xFFB71C1C)
                                  : const Color(0xFF00695C))
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle),
                      child: Icon(
                          isReport
                              ? Icons.bug_report_outlined
                              : Icons.contact_support_outlined,
                          color: isReport
                              ? const Color(0xFFB71C1C)
                              : const Color(0xFF00695C)),
                    ),
                    const SizedBox(width: 12),
                    Text(isReport ? 'Report a Bug' : 'Contact Support',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _text)),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: subjectCtrl,
                  decoration: _inputDecor('Subject'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: msgCtrl,
                  maxLines: 4,
                  decoration: _inputDecor(
                      isReport
                          ? 'Describe the bug in detailâ€¦'
                          : 'How can we help you?'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: sending
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModal(() => sending = true);
                            try {
                              final user = await SessionService.getUser();
                              await ApiService.createSupportTicket({
                                'type': isReport ? 'bug' : 'support',
                                'subject': subjectCtrl.text.trim(),
                                'message': msgCtrl.text.trim(),
                                'userId': user?.id,
                                'userEmail': user?.email ?? '',
                                'status': 'open',
                                'createdAt':
                                    DateTime.now().toIso8601String(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              _toast(isReport
                                  ? 'Bug report submitted. Thank you!'
                                  : 'Message sent. We\'ll respond soon!');
                            } catch (_) {
                              setModal(() => sending = false);
                              _toast('Failed to send. Try again later.');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(isReport ? 'Submit Report' : 'Send Message',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      msgCtrl.dispose();
      subjectCtrl.dispose();
    });
  }

  // â”€â”€â”€ Rate the App â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showRateApp() {
    int tempRating = _starRating;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF9A825).withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: const Icon(Icons.star_outline,
                    color: Color(0xFFF9A825), size: 32),
              ),
              const SizedBox(height: 12),
              Text('Rate AgriFlow',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _text),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('How would you rate your experience?',
                  style: TextStyle(fontSize: 13, color: _light),
                  textAlign: TextAlign.center),
            ],
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < tempRating;
              return GestureDetector(
                onTap: () => setDlg(() => tempRating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled
                        ? const Color(0xFFF9A825)
                        : Colors.grey.shade300,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Later',
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: tempRating == 0
                        ? null
                        : () async {
                            final prefs =
                                await SharedPreferences.getInstance();
                            await prefs.setInt('app_rating', tempRating);
                            if (mounted)
                              setState(() => _starRating = tempRating);
                            if (ctx.mounted) Navigator.pop(ctx);
                            final labels = [
                              '',
                              'Thanks for the feedback!',
                              'Thanks for the feedback!',
                              'Thanks! We\'ll improve.',
                              'Great! Glad you like it.',
                              'Amazing! You made our day! ðŸŒŸ'
                            ];
                            _toast(labels[tempRating]);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9A825),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text('Submit',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // LOGOUT
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.logout,
                  color: Color(0xFFD32F2F), size: 28),
            ),
            const SizedBox(height: 12),
            const Text('Sign Out',
                style:
                    TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('Sign Out',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await SessionService.clearSession();
      Navigator.of(context).pushNamedAndRemoveUntil('/intro', (_) => false);
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // BUILD
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // â”€â”€ Avatar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: _green, width: 2.5),
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 110,
                          height: 110,
                          child: _imageBytes != null
                              ? Image.memory(
                                  _imageBytes!,
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  key: ValueKey(_imageBytes!.length),
                                )
                              : _image != null
                                  ? Image.file(
                                      _image!,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                      key: ValueKey(_image!.path),
                                    )
                                  : Container(
                                      color:
                                          _green.withValues(alpha: 0.15),
                                      child: Icon(
                                        Icons.person,
                                        size: 55,
                                        color: _green,
                                      ),
                                    ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _green,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.fullName.isNotEmpty ? widget.fullName : 'User',
                  style: TextStyle(
                      fontSize: 24,
                      color: _text,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(widget.subtitle,
                    style: TextStyle(
                        color: _light,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // â”€â”€ Account Information â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Text('Account Information',
              style: TextStyle(
                  fontSize: 17,
                  color: _text,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...widget.infoItems.map(_infoTile),
          const SizedBox(height: 32),

          // â”€â”€ Settings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Text('Settings',
              style: TextStyle(
                  fontSize: 17,
                  color: _text,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                // Notifications
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      _settingsIcon(Icons.notifications_outlined,
                          const Color(0xFFE65100),
                          bg: const Color(0xFFFFF3E0)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Text('Notifications',
                              style: TextStyle(
                                  color: _text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700))),
                      Switch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeColor: _green,
                      ),
                    ],
                  ),
                ),
                _divider(),
                _settingsTile(
                  Icons.security_outlined,
                  const Color(0xFF6A1B9A),
                  'Security & Privacy',
                  bg: const Color(0xFFF3E5F5),
                  onTap: _openSecurity,
                ),
                _divider(),
                _settingsTile(
                  Icons.language_outlined,
                  const Color(0xFF0277BD),
                  'Language',
                  bg: const Color(0xFFE1F5FE),
                  trailing: _currentLanguage,
                  onTap: _openLanguage,
                ),
                _divider(),
                _settingsTile(
                  Icons.help_outline,
                  const Color(0xFF00695C),
                  'Help & Support',
                  bg: const Color(0xFFE0F2F1),
                  onTap: _openHelp,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // -- Extra content (role-specific, placed before sign-out) --
          if (widget.extraContent != null) ...[
            widget.extraContent!,
            const SizedBox(height: 40),
          ],

          // â”€â”€ Sign-out button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('SIGN OUT',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor:
                    const Color(0xFFD32F2F).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // UI HELPERS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _infoTile(ProfileInfoItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: TextStyle(
                        color: item.iconColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0)),
                const SizedBox(height: 6),
                Text(item.value.isNotEmpty ? item.value : 'N/A',
                    style: TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(
    IconData icon,
    Color color,
    String label, {
    Color? bg,
    String? trailing,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            _settingsIcon(icon, color, bg: bg),
            const SizedBox(width: 16),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700))),
            if (trailingWidget != null) trailingWidget,
            if (trailing != null)
              Text(trailing,
                  style: TextStyle(
                      color: _light,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                color: _light.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _settingsIcon(IconData icon, Color color, {Color? bg}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _sheetHandle() => Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2)),
      );

  Widget _divider() =>
      const Divider(height: 1, indent: 60, endIndent: 20);

  Widget _sheetOption({
    required IconData icon,
    required Color color,
    required String label,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _text)),
            ),
            if (trailing != null) trailing,
            Icon(Icons.chevron_right,
                color: _light.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _light, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF4F6F4),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _green, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _green,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

