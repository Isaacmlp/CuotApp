import 'package:flutter/material.dart';

class CuotAppSocialButtonsRow extends StatelessWidget {
  const CuotAppSocialButtonsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Google login
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[800],
              side: BorderSide(
                color: Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            icon: const Icon(
              Icons.g_mobiledata,
              size: 28,
              color: Colors.red,
            ),
            label: const Text('Google'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Apple login
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[800],
              side: BorderSide(
                color: Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            icon: const Icon(
              Icons.apple,
              size: 22,
              color: Colors.black,
            ),
            label: const Text('Apple'),
          ),
        ),
      ],
    );
  }
}
