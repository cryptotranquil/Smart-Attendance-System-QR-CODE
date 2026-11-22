import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_screens.dart';
import 'lecturer_screens.dart';
import 'student_screens.dart';
import 'theme.dart';
import 'widgets.dart';

/// Redesign page 1 — a calm front door: "Mark your attendance in seconds."
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.connected});

  final bool connected;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isCreate = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  String? _notice;
  String _previewRole = 'student';

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!widget.connected) {
      _enter(role: _previewRole);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final email = _idController.text.trim().toLowerCase();
      final password = _passwordController.text;

      if (_isCreate) {
        final result = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': _nameController.text.trim()},
        );
        if (result.user == null) {
          setState(() => _error = 'That did not work. Check the details and try again.');
          return;
        }
        if (result.session != null) {
          await _routeAfterLogin(supabase, result.user!.id);
          return;
        }
        setState(() => _notice = 'Account created. Verify your email, then sign in.');
        return;
      }

      final result = await supabase.auth.signInWithPassword(email: email, password: password);
      if (result.user == null) {
        setState(() => _error = _authMessage(null));
        return;
      }
      await _routeAfterLogin(supabase, result.user!.id);
    } on AuthException catch (e) {
      setState(() => _error = _authMessage(e));
    } catch (_) {
      setState(() => _error = 'Something went wrong. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Turn Supabase auth errors into something a human can act on,
  /// instead of one catch-all message that hides the real cause.
  String _authMessage(AuthException? e) {
    final status = e?.statusCode ?? '';
    final code = (e?.code ?? '').toLowerCase();
    final raw = (e?.message ?? '').toLowerCase();
    if (status == '429' || raw.contains('too many') || raw.contains('rate limit')) {
      return 'Too many tries in a short time. Wait a minute, then sign in.';
    }
    if (status == '500' || code.contains('unexpected_failure') || raw.contains('unexpected')) {
      return 'The sign-in service had a hiccup — your password is fine. Try again in a moment.';
    }
    if (e == null || raw.contains('invalid') || code.contains('invalid')) {
      return "That ID and password don't match. Check for typos — the demo emails look like name@pulseqr.demo.";
    }
    return "Couldn't sign you in. Check your connection and try again.";
  }

  Future<void> _routeAfterLogin(SupabaseClient supabase, String authUserId) async {
    final profile = await supabase
        .from('profiles')
        .select('role, active, full_name, school_id')
        .eq('auth_user_id', authUserId)
        .maybeSingle();

    final active = profile != null && (profile['active'] as bool? ?? false);
    if (!active) {
      await supabase.auth.signOut();
      setState(() => _error = 'Your ID is not active yet. See the Registrar to get signed up.');
      return;
    }
    if (!mounted) return;
    _enter(
      role: profile['role'] as String? ?? 'student',
      userName: profile['full_name'] as String?,
      schoolId: profile['school_id'] as String?,
    );
  }

  void _enter({required String role, String? userName, String? schoolId}) {
    if (!mounted) return;
    final page = switch (role) {
      'lecturer' => LecturerTodayScreen(connected: widget.connected, userName: userName, schoolId: schoolId),
      'admin' => AdminPeopleScreen(connected: widget.connected, userName: userName, schoolId: schoolId),
      _ => StudentHomeScreen(connected: widget.connected, userName: userName, schoolId: schoolId),
    };
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1040),
              padding: const EdgeInsets.all(20),
              child: wide
                  ? Row(
                      children: [
                        Expanded(child: _buildHero()),
                        const SizedBox(width: 40),
                        Expanded(child: _buildCard()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHero(),
                        const SizedBox(height: 20),
                        _buildCard(),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            LogoMark(size: 34),
            SizedBox(width: 10),
            Text('PulseQR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          ],
        ),
        const SizedBox(height: 36),
        const Text(
          'Mark your\nattendance in\nseconds.',
          style: TextStyle(fontSize: 40, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -1.2),
        ),
        const SizedBox(height: 16),
        const Text(
          'Scan the QR on your lecturer\'s screen, and you\'re checked in. Location is verified automatically.',
          style: TextStyle(fontSize: 14.5, height: 1.5, color: C.muted),
        ),
        const SizedBox(height: 28),
        const SectionLabel('Preview each role'),
        Wrap(
          spacing: 8,
          children: [
            for (final role in ['student', 'lecturer', 'admin'])
              ChoiceChip(
                label: Text(switch (role) {
                  'lecturer' => 'Lecturer',
                  'admin' => 'Admin',
                  _ => 'Student',
                }),
                selected: _previewRole == role,
                showCheckmark: false,
                selectedColor: C.brand,
                backgroundColor: C.card,
                side: const BorderSide(color: C.hairline),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _previewRole == role ? Colors.white : C.muted,
                ),
                onSelected: (_) => setState(() => _previewRole = role),
              ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'In the real app your account decides which screens you see.',
          style: TextStyle(fontSize: 11, color: C.faint),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(999)),
            child: Row(
              children: [
                for (final create in [false, true])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isCreate = create;
                        _error = null;
                        _notice = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _isCreate == create ? C.card : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: _isCreate == create
                              ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 1))]
                              : const [],
                        ),
                        child: Text(
                          create ? 'Create account' : 'Sign in',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: _isCreate == create ? C.ink : C.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isCreate) ...[
                  _label('Full name'),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _fieldDecoration(hint: 'Alex Taylor'),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                _label('Student or staff ID'),
                TextFormField(
                  controller: _idController,
                  autocorrect: false,
                  decoration: _fieldDecoration(hint: _isCreate ? 'STU-99042' : 'name@univ.edu or STU-99042'),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Enter your ID or email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _label('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: _fieldDecoration(
                    hint: '••••••••',
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: C.muted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your password';
                    if (_isCreate && v.length < 8) return 'Use at least 8 characters';
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _message(_error!, error: true),
                ],
                if (_notice != null) ...[
                  const SizedBox(height: 12),
                  _message(_notice!, error: false),
                ],
                const SizedBox(height: 16),
                PrimaryButton(
                  label: _busy ? 'One moment…' : (_isCreate ? 'Create account' : 'Sign in'),
                  icon: Icons.arrow_forward,
                  onPressed: _busy ? () {} : _submit,
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : _forgotPassword,
                    child: const Text('Forgot password?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: C.muted)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _idController.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Type your email above first, then tap Forgot password.');
      return;
    }
    if (widget.connected) {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    }
    if (mounted) {
      setState(() => _notice = widget.connected
          ? 'If $email is registered, a reset link is on its way.'
          : 'Preview mode — no email was sent.');
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.ink)),
      );

  InputDecoration _fieldDecoration({String? hint, Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: C.faint, fontSize: 13.5),
        filled: true,
        fillColor: C.bg,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(PulseTheme.radiusField), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PulseTheme.radiusField),
          borderSide: const BorderSide(color: C.accent, width: 1.4),
        ),
        errorStyle: const TextStyle(fontSize: 11, color: C.danger),
      );

  Widget _message(String text, {required bool error}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: error ? C.dangerSoft : C.successSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(error ? Icons.error_outline : Icons.check_circle_outline, size: 16, color: error ? C.danger : C.success),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: TextStyle(fontSize: 12, height: 1.4, color: error ? C.danger : C.success, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
