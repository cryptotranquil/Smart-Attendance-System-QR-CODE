import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const projectUrl = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  runApp(MyApp(connected: projectUrl.isNotEmpty && publishableKey.isNotEmpty));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.connected});
  final bool connected;

  @override
  Widget build(BuildContext context) {
    if (connected) {
      // Initialize Supabase here if needed
    }
    return MaterialApp(
      title: 'PulseQR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff9f9ff),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black, primary: Colors.black),
      ),
      home: connected ? const LiveSignInScreen() : const AuthPreviewScreen(),
    );
  }
}

class LiveSignInScreen extends StatefulWidget {
  const LiveSignInScreen({super.key});
  @override
  State<LiveSignInScreen> createState() => _LiveSignInScreenState();
}

class _LiveSignInScreenState extends State<LiveSignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _busy = false;
  String _selectedRole = 'Student';
  String? _error;

  Future<void> _signIn() async {
    if (_busy) return;
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      setState(() => _error = 'Enter your school email and password.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final result = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (result.user == null) {
        setState(() => _error = 'Sign-in failed.');
        return;
      }

      // Fetch profile from database
      final profile = await supabase
          .from('profiles')
          .select('role,active')
          .eq('auth_user_id', result.user!.id)
          .maybeSingle();

      final userRole = profile?['role'] as String?;
      final isActive = profile?['active'] as bool? ?? false;

      if (!isActive || userRole == null) {
        await supabase.auth.signOut();
        setState(() => _error = 'No active school profile. Contact your school admin.');
        return;
      }

      // Navigate to dashboard based on role
      if (mounted) {
        final roleName = switch (userRole) {
          'student' => 'Student',
          'lecturer' => 'Lecturer',
          'admin' => 'Admin',
          _ => 'Student',
        };
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(role: roleName),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Sign-in failed. Check your credentials.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showRegistrationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xfff9f9ff),
      builder: (context) => const RegistrationScreen(),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Establishing Institutional Identity',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your school credentials to access your dashboard.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Student'),
                              selected: _selectedRole == 'Student',
                              onSelected: (selected) {
                                setState(() => _selectedRole = 'Student');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Lecturer'),
                              selected: _selectedRole == 'Lecturer',
                              onSelected: (selected) {
                                setState(() => _selectedRole = 'Lecturer');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'School ID or Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : _signIn,
                        child: Text(_busy ? 'Please wait...' : 'Sign in'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          // Show forgot password dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Forgot Password'),
                              content: const Text('Enter your school email to receive a password reset link.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Forgot password?'),
                      ),
                      TextButton(
                        onPressed: _showRegistrationDialog,
                        child: const Text('Create an account'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Admin accounts are provisioned by the school.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
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

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController schoolIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _busy = false;
  String _selectedRole = 'Student';
  String _passwordStrength = 'weak';

  void _updatePasswordStrength(String value) {
    if (value.length < 6) {
      setState(() => _passwordStrength = 'weak');
    } else if (value.length < 10) {
      setState(() => _passwordStrength = 'medium');
    } else {
      setState(() => _passwordStrength = 'strong');
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);

    try {
      final supabase = Supabase.instance.client;

      // Create user in Supabase Auth
      final result = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (result.user == null) {
        throw Exception('Failed to create user');
      }

      // Create profile record
      // Note: The 'id' column is auto-generated (UUID), we use 'auth_user_id' to link to auth.users
      await supabase.from('profiles').insert({
        'auth_user_id': result.user!.id,
        'school_id': schoolIdController.text.trim(),
        'school_email': emailController.text.trim(),
        'full_name': fullNameController.text.trim(),
        'role': _selectedRole.toLowerCase(),
        'active': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Check your email for verification.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    schoolIdController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = _selectedRole == 'Student';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Establish Institutional Identity',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your account to access the PulseQR system.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Student'),
                  selected: isStudent,
                  onSelected: (selected) {
                    setState(() => _selectedRole = 'Student');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Lecturer'),
                  selected: !isStudent,
                  onSelected: (selected) {
                    setState(() => _selectedRole = 'Lecturer');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Legal Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter full name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: schoolIdController,
                  decoration: InputDecoration(
                    labelText: isStudent ? 'Student ID' : 'Staff ID',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.badge),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter ID' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'School Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter email';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _passwordStrength == 'weak'
                                ? Colors.red
                                : _passwordStrength == 'medium'
                                    ? Colors.orange
                                    : Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.check),
                      ],
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
                  onChanged: _updatePasswordStrength,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Strength: ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _passwordStrength,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _passwordStrength == 'weak'
                            ? Colors.red
                            : _passwordStrength == 'medium'
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (v) => (v != passwordController.text) ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _submitRegistration,
                    child: _busy
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Creating account...'),
                            ],
                          )
                        : const Text('Create Account'),
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

class AuthPreviewScreen extends StatefulWidget {
  const AuthPreviewScreen({super.key});
  @override
  State<AuthPreviewScreen> createState() => _AuthPreviewScreenState();
}

class _AuthPreviewScreenState extends State<AuthPreviewScreen> {
  String _step = 'Sign in';
  String _role = 'Student';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _goTo(String step) => setState(() => _step = step);

  Widget _buildField(String label, {bool secret = false, bool email = false, bool code = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        key: ValueKey('$_step/$label'),
        obscureText: secret,
        keyboardType: email ? TextInputType.emailAddress : (code ? TextInputType.number : null),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return 'Enter $label'.toLowerCase().replaceFirst('enter', 'Enter');
          if (email && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) return 'Enter a valid email address';
          if (code && !RegExp(r'^\d{6}$').hasMatch(text)) return 'Enter six digits';
          if (secret && _step == 'Set password' && text.length < 8) return 'Use at least 8 characters';
          return null;
        },
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_step == 'Sign in') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(role: _role)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _step == 'Sign in';
    final isSignUp = _step == 'Sign up';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.qr_code_2),
                            SizedBox(width: 8),
                            Text('PulseQR',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(_step,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(switch (_step) {
                          'Sign up' => 'Claim your school account using your student or staff ID.',
                          'Verify email' => 'In the live app, you\'ll receive a code by email. For this preview, enter any six digits.',
                          'Set password' => 'Choose a password for your school account.',
                          'Reset password' => 'Enter the school email linked to your account.',
                          _ => 'Use your school email to sign in. Your account determines your role in the live app.',
                        }),
                        const SizedBox(height: 20),
                        if (isSignIn) ...[
                          DropdownButtonFormField<String>(
                            initialValue: _role,
                            decoration: const InputDecoration(
                              labelText: 'Preview as',
                              border: OutlineInputBorder(),
                            ),
                            items: ['Student', 'Lecturer', 'Admin']
                                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                .toList(),
                            onChanged: (r) {
                              if (r != null) {
                                setState(() => _role = r);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (isSignUp) _buildField('Student or staff ID'),
                        if (isSignIn || isSignUp || _step == 'Reset password') _buildField('School email', email: true),
                        if (isSignIn || _step == 'Set password') _buildField('Password', secret: true),
                        if (_step == 'Verify email') _buildField('Verification code', code: true),
                        FilledButton(
                          onPressed: _submit,
                          child: Text(switch (_step) {
                            'Sign in' => 'Preview sign in',
                            'Sign up' => 'Continue',
                            'Verify email' => 'Verify code',
                            'Reset password' => 'Preview reset request',
                            _ => 'Set password',
                          }),
                        ),
                        if (isSignIn) ...[
                          TextButton(
                            onPressed: () => _goTo('Reset password'),
                            child: const Text('Forgot password?'),
                          ),
                          TextButton(
                            onPressed: () => _goTo('Sign up'),
                            child: const Text('Sign up as a student or lecturer'),
                          ),
                          const Text('Admin accounts are provisioned by the school.',
                              textAlign: TextAlign.center),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => DashboardScreen(role: _role, isPreview: true)),
                            ),
                            child: const Text('Explore preview without signing in'),
                          ),
                        ] else
                            TextButton(
                              onPressed: () => _goTo('Sign in'),
                              child: const Text('Back to sign in'),
                            ),
                        const SizedBox(height: 12),
                        const Text('Design preview · No accounts, emails, or passwords are sent or saved.',
                            textAlign: TextAlign.center),
                      ],
                    ),
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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.role, this.isPreview = false});
  final String role;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PulseQR', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (isPreview)
            IconButton(
              onPressed: () {
                // Sign out
              },
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome to the $role dashboard',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}