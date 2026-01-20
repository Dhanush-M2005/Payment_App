import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
      });

      // Check if device supports biometrics
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        // Fallback for emulators or devices without biometrics
        if (mounted) _navigateToHome();
        return;
      }

      authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to authenticate',
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow pin/pattern fallback
        ),
      );
    } on PlatformException catch (_) {
      // Handle error, maybe show retry button
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
        if (authenticated) {
          _navigateToHome();
        }
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 80,
              color: Colors.blue,
            ).animate().fade(duration: 500.ms).scale(),
            const SizedBox(height: 20),
            Text(
              "Secure your payments",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
            const SizedBox(height: 50),
            InkWell(
                  onTap: _authenticate,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 1.seconds,
                ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _authenticate,
              child: const Text("Tap to authenticate"),
            ),
            if (!_isAuthenticating)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: TextButton(
                  onPressed: _navigateToHome,
                  child: const Text("(Mock) Skip Authentication"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
