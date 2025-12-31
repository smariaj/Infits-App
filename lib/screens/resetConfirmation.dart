import 'package:flutter/material.dart';

class ResetConfirmationScreen extends StatelessWidget {
  const ResetConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      height: 120,
                      width: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6F2F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mail_outline,
                        size: 55,
                        color: Color(0xFF9CC6C2),
                      ),
                    ),
                    Container(
                      height: 28,
                      width: 28,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  "Check your mail",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "We have sent password recovery instructions to\nyour email. Please check your inbox and follow\nthe link to reset your password.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 24),

                // Return to login
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2EA3F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Return to Login",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive the email? ",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        "Resend",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2EA3F2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
