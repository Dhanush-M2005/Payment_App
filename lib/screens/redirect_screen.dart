import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RedirectScreen extends StatefulWidget {
  const RedirectScreen({super.key});

  @override
  State<RedirectScreen> createState() => _RedirectScreenState();
}

class _RedirectScreenState extends State<RedirectScreen> {
  String status = "Redirecting to UPI app...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirect();
    });
  }

  Future<void> _redirect() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final String upiUriString = args['upiUri'];
    final Uri upiUri = Uri.parse(upiUriString);

    await Future.delayed(const Duration(seconds: 1));

    try {
      if (await canLaunchUrl(upiUri)) {
        bool launched = await launchUrl(
          upiUri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          // Fallback to default mode
          launched = await launchUrl(upiUri, mode: LaunchMode.platformDefault);
        }

        if (mounted) {
          setState(
            () =>
                status = launched ? "Opened UPI app" : "Failed to open UPI app",
          );
        }
      } else {
        if (mounted) {
          setState(() => status = "No UPI app found");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No UPI app found to handle this request"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => status = "Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(status),
            const SizedBox(height: 20),
            const Text(
              "We do not process payments. Only secure redirection.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
