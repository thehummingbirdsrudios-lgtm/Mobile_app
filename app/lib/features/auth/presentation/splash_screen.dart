import 'package:flutter/material.dart';

import '../../../core/core.dart';

/// Protected startup screen shown while the session is being verified.
/// Deliberately shows NO business data — so another tenant's cache can never
/// flash on screen before identity is resolved.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: BrandMark(size: 88)),
    );
  }
}
