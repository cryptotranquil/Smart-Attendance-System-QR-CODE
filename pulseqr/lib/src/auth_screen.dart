import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard_screen.dart';
import 'pulse_qr_theme.dart';

const _faculties = <String>[
  'Faculty of Computing & Information Systems (BS CS)',
  'Faculty of Business & Management Sciences',
  'Faculty of Natural Sciences & Mathematics',
  'Faculty of Engineering',
  'Faculty of Health Sciences',
  'Faculty of Education',
  'Faculty of Law',
  'Faculty of Social Sciences',
];

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class PulseQrAuthScreen extends StatefulWidget {
  const PulseQrAuthScreen({super.key, required this.connected});

  /// true when SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY were provided and
  /// the client initialized successfully.
  final bool connected;

  @override
  State<PulseQrAuthScreen> createState() => _PulseQrAuthScreenState();
}

class _PulseQrAuthScreenState extends State<PulseQrAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCreateMode = true;
  String _role = 'student';
  String _department = _faculties.first;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _busy = false;
  String? _error;
  String? _notice;

  bool get _isStudent => _role == 'student';
  String get _roleLabel => _isStudent ? 'Student' : 'Lecturer';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _fullNameController.dispose();
    _regNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() => setState(() {});

  void _setMode(bool create) {
    setState(() {
      _isCreateMode = create;
      _error = null;
      _notice = null;
    });
  }

  void _setRole(String role) {
    setState(() {
      _role = role;
      _error = null;
    });
  }

  int get _passwordScore {
    final p = _passwordController.text;
    var score = 0;
    if (p.length >= 8) score++;
    if (p.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p) && RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score;
  }

  String get _passwordStrength {
    final score = _passwordScore;
    if (score <= 1) return 'Weak';
    if (score == 2) return 'Fair';
    if (score == 3) return 'Medium';
    return 'Strong';
  }

  // ---------------------------------------------------------------- validators

  String? _signInIdValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your school email';
    if (widget.connected && !_emailPattern.hasMatch(text)) {
      return 'Use the email linked to your school account';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your university email';
    if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  String? _requiredValidator(String? value, String field) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter $field';
    return null;
  }

  String? _fullNameValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your full legal name';
    if (text.length < 3) return 'Name looks too short';
    return null;
  }

  String? _passwordValidator(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Choose a password';
    if (text.length < 12) return 'Use at least 12 characters';
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if ((value ?? '') != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // ------------------------------------------------------------------ actions

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_isCreateMode) {
      await _submitCreate();
    } else {
      await _submitSignIn();
    }
  }

  Future<void> _submitSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!widget.connected) {
      _openDashboard(role: _role);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final result = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) {
        setState(() => _error = 'Sign-in failed. Check your credentials.');
        return;
      }

      final profile = await supabase
          .from('profiles')
          .select('role, active, full_name, school_id')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      final isActive = profile != null && (profile['active'] as bool? ?? false);
      if (!isActive) {
        await supabase.auth.signOut();
        setState(() {
          _error =
              'No active school profile for this account. Contact the Registrar to claim your roster entry.';
        });
        return;
      }

      if (!mounted) return;
      _openDashboard(
        role: profile['role'] as String? ?? _role,
        userName: profile['full_name'] as String?,
        schoolId: profile['school_id'] as String?,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Sign-in failed. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitCreate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();
    final schoolId = _regNumberController.text.trim();

    if (!widget.connected) {
      _openDashboard(role: _role, userName: fullName.isEmpty ? null : fullName, schoolId: schoolId.isEmpty ? null : schoolId);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final result = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'school_id': schoolId, 'role': _role},
      );

      if (result.user == null) {
        setState(() => _error = 'Could not create the account. Try again.');
        return;
      }

      // The handle_new_user trigger claims a matching registrar-roster profile.
      if (result.session != null) {
        final profile = await supabase
            .from('profiles')
            .select('role, active, full_name, school_id')
            .eq('auth_user_id', result.user!.id)
            .maybeSingle();

        if (profile != null && (profile['active'] as bool? ?? false)) {
          if (!mounted) return;
          _openDashboard(
            role: profile['role'] as String? ?? _role,
            userName: profile['full_name'] as String? ?? fullName,
            schoolId: profile['school_id'] as String? ?? schoolId,
          );
          return;
        }

        await supabase.auth.signOut();
        setState(() {
          _notice =
              'Account created, but this email is not on the official Registrar Roster. Contact Registrar Admissions to get your entry added.';
        });
        return;
      }

      setState(() {
        _notice =
            'Account created. Verify the link sent to $email, then sign in. Your roster entry activates automatically when the email matches.';
        _isCreateMode = false;
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not create the account. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openDashboard({required String role, String? userName, String? schoolId}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          role: role,
          userName: userName,
          schoolId: schoolId,
          connected: widget.connected,
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailPattern.hasMatch(email)) {
      setState(() => _error = 'Enter your school email above first, then tap Forgot password.');
      return;
    }
    if (!widget.connected) {
      setState(() => _notice = 'Preview mode: no email was sent.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        setState(() => _notice = 'If $email is registered, a password reset link is on its way.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not send the reset email. Try again.');
    }
  }

  void _showInfoDialog(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PulseQrColors.containerLowest,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text(body, style: const TextStyle(fontSize: 13, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMetaStrip(),
                            const SizedBox(height: 12),
                            _buildCard(),
                            const SizedBox(height: 20),
                            _buildHelpText(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const _FooterBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaStrip() {
    final wide = MediaQuery.sizeOf(context).width >= 560;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: PulseQrColors.containerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  children: [
                    _PulseDot(),
                    SizedBox(width: 6),
                    Text(
                      'TLS STRICT V1.3',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: PulseQrColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (wide) ...[
                const SizedBox(width: 10),
                const Text('|', style: TextStyle(color: PulseQrColors.outlineVariant)),
                const SizedBox(width: 10),
                const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 13, color: PulseQrColors.onSurfaceVariant),
                    SizedBox(width: 4),
                    Text(
                      'ZKP Identity Layer Active',
                      style: TextStyle(fontSize: 11.5, color: PulseQrColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ],
          ),
          InkWell(
            onTap: () => _showInfoDialog(
              'Registrar Desk',
              'Registrar Admissions\nEmail: admissions@univ.edu\nPhone: +265 1 770 000\nRoom 04, Registry Block\n\nBring your smartcard and a valid ID. Roster entries are provisioned by the school before accounts can be claimed.',
            ),
            child: const Row(
              children: [
                Icon(Icons.contact_support_outlined, size: 14, color: PulseQrColors.onSurfaceVariant),
                SizedBox(width: 4),
                Text(
                  'Registrar Desk',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: PulseQrColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: PulseQrColors.containerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PulseQrColors.hairline),
          boxShadow: const [
            BoxShadow(color: PulseQrColors.shadow, blurRadius: 36, offset: Offset(0, 14)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AccentLine(),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildModeSwitcher(),
                  const SizedBox(height: 20),
                  const Text(
                    'Establish Institutional Identity',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: PulseQrColors.onSurface),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Synchronize dynamic cryptographic signatures for anti-spoof biometric and location-anchored attendance.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: PulseQrColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  _microLabel('Institutional Role'),
                  _buildRoleSegmentedControl(),
                  const SizedBox(height: 18),
                  Form(
                    key: _formKey,
                    child: _isCreateMode ? _buildCreateForm() : _buildSignInForm(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _Banner(message: _error!, isError: true),
                  ],
                  if (_notice != null) ...[
                    const SizedBox(height: 12),
                    _Banner(message: _notice!, isError: false),
                  ],
                  const SizedBox(height: 16),
                  _buildCtaButton(),
                  const SizedBox(height: 10),
                  if (!_isCreateMode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ",
                            style: TextStyle(fontSize: 12.5, color: PulseQrColors.onSurfaceVariant)),
                        InkWell(
                          onTap: () => _setMode(true),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: PulseQrColors.onSurface, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'Admin accounts are provisioned by the school.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.5, color: PulseQrColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: PulseQrColors.hairline),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.fingerprint, size: 15, color: PulseQrColors.onSurfaceVariant),
                      SizedBox(width: 6),
                      Text(
                        'ECDSA p-256 Curve Cryptography',
                        style: TextStyle(fontSize: 10.5, color: PulseQrColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (MediaQuery.sizeOf(context).width >= 540)
                    const Text(
                      'NODE_HASH: 0x98f4...b2a1',
                      style: TextStyle(fontSize: 10.5, color: PulseQrColors.onSurfaceVariant, fontFamily: 'monospace'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitcher() {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: PulseQrColors.containerLow,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              _ModePill(label: 'Create Account', active: _isCreateMode, onTap: () => _setMode(true)),
              _ModePill(label: 'Sign In', active: !_isCreateMode, onTap: () => _setMode(false)),
            ],
          ),
        ),
        if (wide)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: PulseQrColors.containerLow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Icon(
                  widget.connected ? Icons.verified_user_outlined : Icons.visibility_outlined,
                  size: 13,
                  color: PulseQrColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.connected ? 'Roster Verification Engine' : 'UI Preview · Not Connected',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PulseQrColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRoleSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PulseQrColors.containerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _RoleSegment(
            label: 'Student',
            icon: Icons.school_outlined,
            active: _isStudent,
            onTap: () => _setRole('student'),
          ),
          _RoleSegment(
            label: 'Lecturer / Faculty',
            icon: Icons.co_present_outlined,
            active: !_isStudent,
            onTap: () => _setRole('lecturer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('Full Legal Name'),
        TextFormField(
          controller: _fullNameController,
          textCapitalization: TextCapitalization.words,
          decoration: _fieldDecoration(
            hint: 'e.g. Tadala Chirwa',
            suffix: const Icon(Icons.badge_outlined, size: 18, color: PulseQrColors.onSurfaceVariant),
          ),
          validator: _fullNameValidator,
        ),
        const SizedBox(height: 14),
        if (narrow) ...[
          _fieldLabel('Registration Number'),
          TextFormField(
            controller: _regNumberController,
            textCapitalization: TextCapitalization.characters,
            decoration: _fieldDecoration(
              hint: 'REG-2024-8921',
              suffix: const Icon(Icons.credit_card_outlined, size: 18, color: PulseQrColors.onSurfaceVariant),
            ),
            validator: (v) => _requiredValidator(v, 'your registration number'),
          ),
          const SizedBox(height: 14),
          _fieldLabel('University Email'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: _fieldDecoration(
              hint: 'tadala@student.univ.edu',
              suffix: const Icon(Icons.alternate_email, size: 18, color: PulseQrColors.onSurfaceVariant),
            ),
            validator: _emailValidator,
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fieldLabel('Registration Number'),
                    TextFormField(
                      controller: _regNumberController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _fieldDecoration(
                        hint: 'REG-2024-8921',
                        suffix: const Icon(Icons.credit_card_outlined, size: 18, color: PulseQrColors.onSurfaceVariant),
                      ),
                      validator: (v) => _requiredValidator(v, 'your registration number'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fieldLabel('University Email'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: _fieldDecoration(
                        hint: 'tadala@student.univ.edu',
                        suffix: const Icon(Icons.alternate_email, size: 18, color: PulseQrColors.onSurfaceVariant),
                      ),
                      validator: _emailValidator,
                    ),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),
        _fieldLabel('Academic Department & Track'),
        DropdownButtonFormField<String>(
          initialValue: _department,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: PulseQrColors.onSurfaceVariant),
          decoration: _fieldDecoration(),
          items: [
            for (final faculty in _faculties)
              DropdownMenuItem(
                value: faculty,
                child: Text(faculty, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _department = value);
          },
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PulseQrColors.containerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 17, color: PulseQrColors.onSurfaceVariant),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Institutional Ledger Pre-Check',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PulseQrColors.onSurface),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your Registration Number will be dynamically validated against the official Term Registrar Roster. Ensure exact syntax as issued on your smartcard.',
                      style: TextStyle(fontSize: 11.5, height: 1.4, color: PulseQrColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (narrow) ...[
          _passwordFields(),
        ] else
          _passwordFieldsRow(),
        const SizedBox(height: 8),
        _buildStrengthMeter(),
      ],
    );
  }

  Widget _passwordFieldsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _passwordField(isConfirm: false)),
        const SizedBox(width: 12),
        Expanded(child: _passwordField(isConfirm: true)),
      ],
    );
  }

  Widget _passwordFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _passwordField(isConfirm: false),
        const SizedBox(height: 14),
        _passwordField(isConfirm: true),
      ],
    );
  }

  Widget _passwordField({required bool isConfirm}) {
    final obscure = isConfirm ? _obscureConfirm : _obscurePassword;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(isConfirm ? 'Confirm Password' : 'Password', note: isConfirm ? 'Match required' : 'Min. 12 chars'),
        TextFormField(
          controller: isConfirm ? _confirmPasswordController : _passwordController,
          obscureText: obscure,
          decoration: _fieldDecoration(
            hint: '••••••••••••',
            suffix: IconButton(
              tooltip: obscure ? 'Show password' : 'Hide password',
              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: PulseQrColors.onSurfaceVariant),
              onPressed: () => setState(() {
                if (isConfirm) {
                  _obscureConfirm = !_obscureConfirm;
                } else {
                  _obscurePassword = !_obscurePassword;
                }
              }),
            ),
          ),
          validator: isConfirm ? _confirmPasswordValidator : _passwordValidator,
        ),
      ],
    );
  }

  Widget _buildStrengthMeter() {
    final score = _passwordScore;
    return Row(
      children: [
        const Text('Strength: ', style: TextStyle(fontSize: 11, color: PulseQrColors.onSurfaceVariant)),
        Text(
          _passwordStrength,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PulseQrColors.onSurface),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i < score ? PulseQrColors.ink : PulseQrColors.containerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PulseQrColors.containerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: PulseQrColors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isStudent
                      ? 'Check in with rotating QR, submit excuse waivers, and view timetable compliance.'
                      : 'Launch real-time attendance sessions, enforce the campus geofence, and review attendance logs.',
                  style: const TextStyle(fontSize: 11.5, height: 1.4, color: PulseQrColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _fieldLabel('School Email'),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: PulseQrColors.container,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _isStudent ? '@student.edu' : '@univ.edu',
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: PulseQrColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: _fieldDecoration(
            hint: _isStudent ? 'tadala@student.univ.edu' : 'l.phiri@univ.edu',
            prefix: const Icon(Icons.badge_outlined, size: 18, color: PulseQrColors.onSurfaceVariant),
          ),
          validator: _signInIdValidator,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _fieldLabel('Password'),
            InkWell(
              onTap: _busy ? null : _sendPasswordReset,
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PulseQrColors.onSurfaceVariant, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: _fieldDecoration(
            hint: '••••••••••••',
            prefix: const Icon(Icons.lock_outline, size: 18, color: PulseQrColors.onSurfaceVariant),
            suffix: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: PulseQrColors.onSurfaceVariant),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
        ),
      ],
    );
  }

  Widget _buildCtaButton() {
    final label = _isCreateMode ? 'Create $_roleLabel Account' : 'Sign In as $_roleLabel';
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: PulseQrColors.ink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _busy ? null : _submit,
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, size: 17),
                ],
              ),
      ),
    );
  }

  Widget _buildHelpText() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          runSpacing: 4,
          children: [
            const Text(
              'Need assistance registering or index unverified? ',
              style: TextStyle(fontSize: 12, color: PulseQrColors.onSurfaceVariant),
            ),
            InkWell(
              onTap: () => _showInfoDialog(
                'Registrar Admissions',
                'Email: admissions@univ.edu\nPhone: +265 1 770 000\nRoom 04, Registry Block\n\nBring your smartcard and a valid ID.',
              ),
              child: const Text(
                'Contact Registrar Admissions',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PulseQrColors.onSurface, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'ACADEMIC YEAR 2026–2027 · PULSEQR CRYPTOGRAPHIC VERIFICATION PROTOCOL',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 8.5, letterSpacing: 1.1, color: PulseQrColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _microLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: PulseQrColors.onSurfaceVariant),
        ),
      );

  Widget _fieldLabel(String text, {String? note}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: PulseQrColors.onSurface)),
          if (note != null)
            Text(note, style: const TextStyle(fontSize: 10, color: PulseQrColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hint, Widget? suffix, Widget? prefix}) {
    const radius = 14.0;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0x80575E70)),
      filled: true,
      fillColor: PulseQrColors.containerLow,
      prefixIcon: prefix,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(Colors.transparent, 0),
      enabledBorder: border(Colors.transparent, 0),
      focusedBorder: border(PulseQrColors.ink, 1.4),
      errorBorder: border(PulseQrColors.error, 1.0),
      focusedErrorBorder: border(PulseQrColors.error, 1.4),
      errorStyle: const TextStyle(fontSize: 10.5, color: PulseQrColors.error),
    );
  }
}

// ---------------------------------------------------------------- components

class _ModePill extends StatelessWidget {
  const _ModePill({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? PulseQrColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : PulseQrColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RoleSegment extends StatelessWidget {
  const _RoleSegment({required this.label, required this.icon, required this.active, required this.onTap});

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? PulseQrColors.containerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? const [BoxShadow(color: Color(0x1A151C27), blurRadius: 8, offset: Offset(0, 2))]
                : const [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? PulseQrColors.ink : PulseQrColors.onSurfaceVariant),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active ? PulseQrColors.ink : PulseQrColors.onSurfaceVariant,
                  ),
                ),
              ),
              if (active) ...[
                const SizedBox(width: 6),
                Container(width: 5, height: 5, decoration: const BoxDecoration(color: PulseQrColors.ink, shape: BoxShape.circle)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final bg = isError ? PulseQrColors.errorContainer : PulseQrColors.container;
    final fg = isError ? PulseQrColors.onErrorContainer : PulseQrColors.onSurface;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(fontSize: 12, height: 1.4, color: fg))),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(color: PulseQrColors.ink, shape: BoxShape.circle),
    );
  }
}

class _AccentLine extends StatelessWidget {
  const _AccentLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x00000000), Color(0x403C3C3C), Color(0x00000000)],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: PulseQrColors.surface,
        border: Border(bottom: BorderSide(color: PulseQrColors.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: PulseQrColors.ink, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.qr_code_2, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 9),
          const Text(
            'PulseQR',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: PulseQrColors.onSurface),
          ),
          const SizedBox(width: 10),
          const SizedBox(height: 16, child: VerticalDivider(width: 1, thickness: 1, color: PulseQrColors.outlineVariant)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: PulseQrColors.containerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'PROD V2.4',
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: PulseQrColors.onSurfaceVariant),
            ),
          ),
          const Spacer(),
          if (wide) ...[
            const Row(
              children: [
                Icon(Icons.terminal, size: 15, color: PulseQrColors.onSurfaceVariant),
                SizedBox(width: 5),
                Text('System Docs', style: TextStyle(fontSize: 12, color: PulseQrColors.onSurfaceVariant)),
              ],
            ),
            const SizedBox(width: 14),
            const SizedBox(height: 16, child: VerticalDivider(width: 1, thickness: 1, color: PulseQrColors.outlineVariant)),
            const SizedBox(width: 14),
            const Row(
              children: [
                Icon(Icons.sensors, size: 15, color: PulseQrColors.onSurfaceVariant),
                SizedBox(width: 5),
                Text('Telemetry', style: TextStyle(fontSize: 12, color: PulseQrColors.onSurfaceVariant)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FooterBar extends StatelessWidget {
  const _FooterBar();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: PulseQrColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '© 2026 PulseQR Cryptographic Verification Protocol. All rights reserved.',
              style: const TextStyle(fontSize: 10.5, color: Color(0xCC4C4546)),
            ),
          ),
          if (wide) ...[
            const _FooterLink(label: 'Security Policy'),
            const SizedBox(width: 18),
            const _FooterLink(label: 'Zero-Knowledge Attestation'),
            const SizedBox(width: 18),
            const _FooterLink(label: 'API Spec'),
          ],
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: PulseQrColors.containerLowest,
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: const Text(
            'Published with the production release of the PulseQR verification protocol. Contact your system administrator for the current document.',
            style: TextStyle(fontSize: 13, height: 1.45),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10.5, color: PulseQrColors.onSurfaceVariant, decoration: TextDecoration.underline),
      ),
    );
  }
}
