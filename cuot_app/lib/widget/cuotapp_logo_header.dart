import 'package:flutter/material.dart';

class CuotAppLogoHeader extends StatelessWidget {
  const CuotAppLogoHeader({
    super.key,
    required this.lightGreen,
    required this.primaryGreen,
  });

  final Color lightGreen;
  final Color primaryGreen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: lightGreen.withOpacity(0.6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Text("C",
            style: TextStyle(
              fontSize: 52,
              color: Colors.white,
            ),),
          
           /*const Icon(
            Icons.savings_rounded,
            size: 52,
            color: Colors.white,
          ),*/
        ),
        const SizedBox(height: 16),
        Text(
          'CuotApp',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryGreen,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Administra tus cuotas de forma simple',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
        ),
      ],
    );
  }
}
