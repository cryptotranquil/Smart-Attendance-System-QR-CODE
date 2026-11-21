import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/auth_screen.dart';
import 'src/pulse_qr_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const projectUrl = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  var connected = projectUrl.isNotEmpty && publishableKey.isNotEmpty;
  if (connected) {
    try {
      await Supabase.initialize(url: projectUrl, publishableKey: publishableKey);
    } catch (e) {
      debugPrint('Supabase initialization failed, falling back to preview mode: $e');
      connected = false;
    }
  }

  runApp(PulseQrApp(connected: connected));
}

class PulseQrApp extends StatelessWidget {
  const PulseQrApp({super.key, required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Attendance System',
      debugShowCheckedModeBanner: false,
      theme: PulseQrTheme.data,
      home: PulseQrAuthScreen(connected: connected),
    );
  }
}
