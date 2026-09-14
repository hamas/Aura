import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AuraScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;

  const AuraScaffold({
    super.key,
    required this.body,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: appBar,
      body: body,
    );
  }
}
