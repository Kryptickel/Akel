import 'package:flutter/material.dart';

/// Reusable empty state widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final Color? iconColor;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onActionPressed,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: iconColor ?? Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 32),

            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add),
                label: Text(
                  actionText!,
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pre-configured empty states

class EmptyContactsState extends StatelessWidget {
  final VoidCallback? onAddContact;

  const EmptyContactsState({Key? key, this.onAddContact}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.contact_phone_outlined,
      title: 'No Emergency Contacts',
      message: 'Add your trusted contacts who will receive alerts when you trigger the panic button.\n\n'
          'We recommend adding at least 2-3 contacts for better safety.',
      actionText: 'Add First Contact',
      onActionPressed: onAddContact,
      iconColor: Theme.of(context).primaryColor,
    );
  }
}

class EmptyHistoryState extends StatelessWidget {
  const EmptyHistoryState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.history_outlined,
      title: 'No Panic History',
      message: 'Your panic button alerts will appear here.\n\n'
          'This helps you track when and where you\'ve sent emergency alerts.',
      iconColor: Colors.orange,
    );
  }
}

class EmptyTemplatesState extends StatelessWidget {
  final VoidCallback? onAddTemplate;

  const EmptyTemplatesState({Key? key, this.onAddTemplate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.message_outlined,
      title: 'No Message Templates',
      message: 'Create custom emergency messages for different situations.\n\n'
          'Templates make it faster to send the right message during an emergency.',
      actionText: 'Create Template',
      onActionPressed: onAddTemplate,
      iconColor: Colors.blue,
    );
  }
}

