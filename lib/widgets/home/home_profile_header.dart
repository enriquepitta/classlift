import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:classlift/utils/classlift_colors.dart';

class HomeProfileHeader extends StatelessWidget {
  const HomeProfileHeader({
    super.key,
    this.displayName,
    this.email,
    this.photoUrl,
    required this.subtitle,
    required this.signingOut,
    required this.onSignOut,
  });

  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String subtitle;
  final bool signingOut;
  final Future<void> Function() onSignOut;

  bool get _hasPhoto => photoUrl?.trim().isNotEmpty == true;

  Widget _profileAvatar({required double radius}) {
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: ClassliftColors.calendarInk.withValues(alpha: 0.08),
      child: Icon(
        Icons.account_circle_outlined,
        size: radius * 1.45,
        color: ClassliftColors.calendarInk,
      ),
    );

    if (!_hasPhoto) return fallback;

    final diameter = radius * 2;
    return ClipOval(
      child: Image.network(
        photoUrl!.trim(),
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  Future<void> _openProfile(BuildContext context) async {
    final signOut = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: ClassliftColors.White,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _profileAvatar(radius: 34)),
              const SizedBox(height: 16),
              const Text('Mi cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ClassliftColors.PrimaryColor,
                  )),
              const SizedBox(height: 16),
              Text(
                  displayName?.trim().isNotEmpty == true
                      ? displayName!.trim()
                      : 'Tu cuenta de ClassLift',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (email?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(email!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ClassliftColors.black54)),
              ],
              const SizedBox(height: 20),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded,
                    color: ClassliftColors.educaRed),
                title: const Text('Cerrar sesión',
                    style: TextStyle(color: ClassliftColors.educaRed)),
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (signOut == true && context.mounted) await onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    final name = displayName?.trim() ?? '';
    final firstName = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      firstName.isEmpty ? '¡Hola!' : '¡Hola, $firstName!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ClassliftColors.calendarInk,
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: ClassliftColors.calendarMuted,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: signingOut ? 'Cerrando sesión' : 'Mi perfil',
                onPressed: signingOut ? null : () => _openProfile(context),
                style: IconButton.styleFrom(
                  foregroundColor: ClassliftColors.calendarInk,
                  minimumSize: const Size(48, 48),
                ),
                icon: signingOut
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: ClassliftColors.calendarInk))
                    : _profileAvatar(radius: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
