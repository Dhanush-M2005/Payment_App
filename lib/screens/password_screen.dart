import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  String _enteredPin = "";
  String? _tempPin; // For confirming PIN during setup
  bool _isSettingUp = false;
  String _promptText = "";
  bool _isLoading = true;
  String _errorText = "";

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('app_pin');

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (savedPin == null) {
            _isSettingUp = true;
            _promptText = "Set SafeUPI PIN";
          } else {
            _isSettingUp = false;
            _promptText = "Enter SafeUPI PIN";
          }
        });
      }
    } on PlatformException catch (_) {
      // Fallback for restart scenario
      if (mounted) {
        setState(() {
          _isLoading = false;
          _promptText = "Error: Restart App";
        });
      }
    }
  }

  void _onKeyTap(String value) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += value;
        _errorText = "";
      });
      if (_enteredPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorText = "";
      });
    }
  }

  Future<void> _handlePinComplete() async {
    // Small delay for visual feedback of the 4th dot filling
    await Future.delayed(const Duration(milliseconds: 200));

    final prefs = await SharedPreferences.getInstance();

    if (_isSettingUp) {
      if (_tempPin == null) {
        // First entry of new PIN
        setState(() {
          _tempPin = _enteredPin;
          _enteredPin = "";
          _promptText = "Confirm SafeUPI PIN";
        });
      } else {
        // Confirmation entry
        if (_enteredPin == _tempPin) {
          await prefs.setString('app_pin', _enteredPin);
          if (mounted) _navigateToHome();
        } else {
          // Mismatch
          setState(() {
            _errorText = "PINs do not match. Try again.";
            _tempPin = null;
            _enteredPin = "";
            _promptText = "Set SafeUPI PIN";
          });
        }
      }
    } else {
      // Login check
      final savedPin = prefs.getString('app_pin');
      if (_enteredPin == savedPin) {
        _navigateToHome();
      } else {
        setState(() {
          _errorText = "Incorrect PIN";
          _enteredPin = "";
          // Haptic feedback could be added here
        });
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isFilled = index < _enteredPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isFilled
                ? Colors.black87
                : Colors.transparent, // Filled is dark
            border: Border.all(color: Colors.black87, width: 2), // Ring is dark
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildKeypadButton(
    String label, {
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          height: 80,
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: Colors.black87, size: 28)
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // Light background
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Logo
            const Icon(
              Icons.shield_outlined,
              color: Colors.blue,
              size: 48,
            ).animate().scale(duration: 400.ms),

            const SizedBox(height: 24),

            // Title
            Text(
              _promptText,
              style: const TextStyle(
                color: Colors.black87, // Dark text
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle / Error
            if (_errorText.isNotEmpty)
              Text(
                _errorText,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ).animate().shake()
            else
              const Text(
                "Keep your payments safe",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),

            const SizedBox(height: 48),

            // PIN Dots
            _buildPinDots(),

            const Spacer(),

            // Numeric Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildKeypadButton("1", onTap: () => _onKeyTap("1")),
                      _buildKeypadButton("2", onTap: () => _onKeyTap("2")),
                      _buildKeypadButton("3", onTap: () => _onKeyTap("3")),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildKeypadButton("4", onTap: () => _onKeyTap("4")),
                      _buildKeypadButton("5", onTap: () => _onKeyTap("5")),
                      _buildKeypadButton("6", onTap: () => _onKeyTap("6")),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildKeypadButton("7", onTap: () => _onKeyTap("7")),
                      _buildKeypadButton("8", onTap: () => _onKeyTap("8")),
                      _buildKeypadButton("9", onTap: () => _onKeyTap("9")),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Empty space for layout balance
                      const Expanded(child: SizedBox()),
                      _buildKeypadButton("0", onTap: () => _onKeyTap("0")),
                      _buildKeypadButton(
                        "",
                        onTap: _onBackspace,
                        icon: Icons.backspace_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
