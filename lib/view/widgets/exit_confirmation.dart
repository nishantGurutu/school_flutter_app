import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExitConfirmation extends StatefulWidget {
  final Widget child;

  const ExitConfirmation({super.key, required this.child});

  @override
  State<ExitConfirmation> createState() => _ExitConfirmationState();
}

class _ExitConfirmationState extends State<ExitConfirmation> {
  bool _showingDialog = false;

  Future<void> _handleBack(bool didPop, Object? result) async {
    if (didPop || _showingDialog) return;

    final navigator = Navigator.of(context);
    // Close local history entries, such as an open drawer, before exiting.
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    _showingDialog = true;
    try {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Close app?'),
          content: const Text('Are you sure you want to close the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (shouldExit == true && mounted) {
        await SystemNavigator.pop();
      }
    } finally {
      _showingDialog = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !(ModalRoute.of(context)?.isFirst ?? true),
      onPopInvokedWithResult: _handleBack,
      child: widget.child,
    );
  }
}
