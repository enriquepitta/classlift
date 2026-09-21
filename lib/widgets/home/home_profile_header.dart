import 'package:flutter/material.dart';
import 'package:classlift/utils/classlift_colors.dart';

class HomeProfileHeader extends StatelessWidget {
  const HomeProfileHeader({
    super.key,
    this.displayName,
    this.email,
    required this.subtitle,
    required this.signingOut,
    required this.onSignOut,
  });

  final String? displayName;
  final String? email;
  final String subtitle;
  final bool signingOut;
  final Future<void> Function() onSignOut;

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
              const Text('Mi cuenta',
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
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (email?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(email!,
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
    return Container(
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
                        color: ClassliftColors.White,
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: ClassliftColors.homeGreetingSubtitle,
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
                  foregroundColor: ClassliftColors.White,
                  minimumSize: const Size(48, 48),
                ),
                icon: signingOut
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: ClassliftColors.White))
                    : const Icon(Icons.account_circle_outlined, size: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
