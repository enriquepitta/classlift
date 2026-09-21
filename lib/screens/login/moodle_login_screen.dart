import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_tasks_service.dart';

enum _MoodleProvider { poli, demo, custom }

class _MoodleProviderOption {
  final _MoodleProvider provider;
  final String title;
  final String subtitle;
  final String siteUrl;

  const _MoodleProviderOption({
    required this.provider,
    required this.title,
    required this.subtitle,
    required this.siteUrl,
  });
}

const _poliMoodleUrl = 'https://grado.pol.una.py';
const _demoMoodleUrl = 'https://school.moodledemo.net';
const _educaRed = ClassliftColors.educaRed;
const _educaDarkRed = ClassliftColors.educaDarkRed;
const _educaSoftBackground = ClassliftColors.educaSoftBackground;
const _educaBadge = ClassliftColors.educaBadge;

const _providerOptions = [
  _MoodleProviderOption(
    provider: _MoodleProvider.poli,
    title: 'Politécnica UNA',
    subtitle: 'grado.pol.una.py',
    siteUrl: _poliMoodleUrl,
  ),
  _MoodleProviderOption(
    provider: _MoodleProvider.demo,
    title: 'Moodle Demo',
    subtitle: 'school.moodledemo.net',
    siteUrl: _demoMoodleUrl,
  ),
];

class MoodleLoginScreen extends StatefulWidget {
  const MoodleLoginScreen({super.key});

  @override
  State<MoodleLoginScreen> createState() => _MoodleLoginScreenState();
}

class _MoodleLoginScreenState extends State<MoodleLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _customUrl = TextEditingController();
  final _scrollController = ScrollController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  _MoodleProvider _provider = _MoodleProvider.poli;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _scrollController.dispose();
    _username.dispose();
    _password.dispose();
    _customUrl.dispose();
    super.dispose();
  }

  String get _selectedSiteUrl {
    if (_provider == _MoodleProvider.custom) {
      return _normalizeMoodleUrl(_customUrl.text);
    }

    return _providerOptions
        .firstWhere((option) => option.provider == _provider)
        .siteUrl;
  }

  String _normalizeMoodleUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'https://') return trimmed;
    if (trimmed.startsWith('https://')) return trimmed;
    if (trimmed.startsWith('http://')) return trimmed;
    return 'https://$trimmed';
  }

  Future<void> _chooseProvider() async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<_MoodleProvider>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: ClassliftColors.White,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Elegí tu campus',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _educaDarkRed)),
              const SizedBox(height: 16),
              for (final option in _providerOptions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProviderTile(
                    title: option.title,
                    subtitle: option.subtitle,
                    selected: _provider == option.provider,
                    enabled: true,
                    onTap: () => Navigator.pop(context, option.provider),
                  ),
                ),
              _ProviderTile(
                title: 'Otro campus Moodle',
                subtitle: 'Conectá el campus de tu institución',
                selected: _provider == _MoodleProvider.custom,
                enabled: true,
                onTap: () => Navigator.pop(context, _MoodleProvider.custom),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selected == null || selected == _provider) return;
    setState(() {
      _provider = selected;
      _password.clear();
      _error = null;
    });
  }

  Future<void> _signIn() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = MoodleAuthService(siteUrl: _selectedSiteUrl);
      final session = await service.signIn(_username.text, _password.text);
      MoodleAuthService.instance.session = session;
      await MoodleTasksService.loadCurrentSession();
      if (!mounted) return;
      _password.clear();
      context.go('/home');
    } on MoodleAuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'No se pudo iniciar sesión. Intentá nuevamente.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: _educaSoftBackground,
          appBar: AppBar(
            title: const Text('Conectar campus',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            scrolledUnderElevation: 0,
            backgroundColor: _educaSoftBackground,
            foregroundColor: _educaDarkRed,
            elevation: 0,
          ),
          body: SafeArea(
            bottom: false,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _MoodleHeader(),
                              const SizedBox(height: 24),
                              _MoodleCard(
                                key: const ValueKey('campus-credentials'),
                                child: AutofillGroup(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildProviderCard(),
                                      const SizedBox(height: 20),
                                      _buildCredentialsCard(),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Usá la misma cuenta con la que entrás a tu campus.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: ClassliftColors.educaMuted),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                _ErrorMessage(message: _error!),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _BottomConnectBar(
                    loading: _loading,
                    onPressed: _loading ? null : _signIn,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard() {
    final custom = _provider == _MoodleProvider.custom;
    final option = custom
        ? null
        : _providerOptions.firstWhere((option) => option.provider == _provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Tu campus',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _educaDarkRed)),
        const SizedBox(height: 8),
        Material(
          color: _educaSoftBackground,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _loading ? null : _chooseProvider,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.school_outlined, color: _educaRed),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option?.title ?? 'Otro campus Moodle',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _educaDarkRed)),
                    Text(
                        option?.subtitle ?? 'Ingresá la dirección de tu campus',
                        style: const TextStyle(
                            fontSize: 11, color: ClassliftColors.educaMuted)),
                  ],
                )),
                const Icon(Icons.expand_more_rounded, color: _educaRed),
              ]),
            ),
          ),
        ),
        if (_provider == _MoodleProvider.custom) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _customUrl,
            enabled: !_loading,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _usernameFocus.requestFocus(),
            decoration: _inputDecoration(
              label: 'URL del campus',
              icon: Icons.link_rounded,
              hint: 'https://campus.universidad.edu',
            ),
            validator: (value) {
              if (_provider != _MoodleProvider.custom) return null;
              final normalized = _normalizeMoodleUrl(value ?? '');
              final uri = Uri.tryParse(normalized);
              if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
                return 'Ingresá una URL HTTPS válida.';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCredentialsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _username,
          focusNode: _usernameFocus,
          enabled: !_loading,
          autocorrect: false,
          enableSuggestions: false,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          autofillHints: const [AutofillHints.username],
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
          decoration: _inputDecoration(
            label: 'Usuario del campus',
            icon: Icons.person_outline_rounded,
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Ingresá tu usuario.'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _password,
          focusNode: _passwordFocus,
          enabled: !_loading,
          obscureText: _obscure,
          keyboardType: TextInputType.text,
          autocorrect: false,
          enableSuggestions: false,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _signIn(),
          decoration: _inputDecoration(
            label: 'Contraseña',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
              onPressed:
                  _loading ? null : () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            ),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Ingresá tu contraseña.' : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelStyle: const TextStyle(color: _educaDarkRed),
      prefixIconColor: _educaRed,
      suffixIconColor: _educaRed,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: ClassliftColors.White,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _educaRed.withValues(alpha: 0.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _educaRed.withValues(alpha: 0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _educaRed, width: 1.5),
      ),
    );
  }
}

class _MoodleHeader extends StatelessWidget {
  const _MoodleHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 0),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _educaBadge,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: _educaRed,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu campus, más cerca',
                  style: TextStyle(
                    color: _educaDarkRed,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Consultá tus tareas desde ClassLift.',
                  style: TextStyle(
                    color: ClassliftColors.educaMuted,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodleCard extends StatelessWidget {
  final Widget child;

  const _MoodleCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClassliftColors.White,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}

class _BottomConnectBar extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const _BottomConnectBar({
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _educaSoftBackground,
      ),
      // Scaffold follows the keyboard insets directly. Only animate the
      // button's breathing room, never the keyboard height itself.
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          keyboardOpen ? 8 : safeBottom + 12,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ClassliftColors.White,
                        ),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(loading ? 'Sincronizando...' : 'Conectar campus'),
                style: FilledButton.styleFrom(
                  backgroundColor: _educaRed,
                  foregroundColor: ClassliftColors.White,
                  disabledBackgroundColor: _educaRed.withValues(alpha: 0.58),
                  disabledForegroundColor: ClassliftColors.White,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ProviderTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? _educaSoftBackground
              : ClassliftColors.campusOptionBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _educaRed : _educaDarkRed.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color:
                  selected ? _educaRed : _educaDarkRed.withValues(alpha: 0.38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _educaDarkRed,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _educaDarkRed.withValues(alpha: 0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _educaRed.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: _educaDarkRed,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
