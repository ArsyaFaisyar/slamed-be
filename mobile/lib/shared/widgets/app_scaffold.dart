import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

/// Scaffold standar: gradasi navy menutup seluruh layar (termasuk area app bar).
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.floatingActionButton,
    this.bottomBar,
    this.actions,
  });

  final String? title;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomBar;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: title == null ? null : AppBar(title: Text(title!), actions: actions),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomBar,
        body: body,
      ),
    );
  }
}