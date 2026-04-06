import 'package:flutter/material.dart';

// Priority enum (duplicate here to avoid import issues on web)
enum ContactPriority {
  high(1, 'High', Color(0xFFDC143C), Icons.priority_high),
  medium(2, 'Medium', Color(0xFFFF9800), Icons.remove),
  low(3, 'Low', Color(0xFF00BFA5), Icons.arrow_downward);

  final int value;
  final String label;
  final Color color;
  final IconData icon;

  const ContactPriority(this.value, this.label, this.color, this.icon);

  static ContactPriority fromValue(int value) {
    return ContactPriority.values.firstWhere(
          (p) => p.value == value,
      orElse: () => ContactPriority.medium,
    );
  }
}

/// Main Priority Selector - Use in Add/Edit Contact screens
class PrioritySelector extends StatelessWidget {
  final int selectedPriority;
  final Function(int) onPriorityChanged;
  final bool enabled;

  const PrioritySelector({
    Key? key,
    required this.selectedPriority,
    required this.onPriorityChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Priority',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0A0E27),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Higher priority contacts are alerted first during emergencies',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: ContactPriority.values.map((priority) {
            final isSelected = priority.value == selectedPriority;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _PriorityCard(
                  priority: priority,
                  isSelected: isSelected,
                  enabled: enabled,
                  onTap: () {
                    if (enabled) {
                      onPriorityChanged(priority.value);
                    }
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final ContactPriority priority;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _PriorityCard({
    Key? key,
    required this.priority,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? priority.color.withOpacity(0.15) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? priority.color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                priority.icon,
                color: isSelected ? priority.color : Colors.grey[600],
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                priority.label,
                style: TextStyle(
                  color: isSelected ? priority.color : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Icon(Icons.check_circle, color: priority.color, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Priority Badge - Display in contact lists
class PriorityBadge extends StatelessWidget {
  final int priority;
  final bool compact;

  const PriorityBadge({
    Key? key,
    required this.priority,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priorityLevel = ContactPriority.fromValue(priority);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: priorityLevel.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: priorityLevel.color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(priorityLevel.icon, size: 14, color: priorityLevel.color),
            const SizedBox(width: 4),
            Text(
              priorityLevel.label,
              style: TextStyle(
                color: priorityLevel.color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Chip(
      avatar: Icon(priorityLevel.icon, size: 18, color: priorityLevel.color),
      label: Text(
        '${priorityLevel.label} Priority',
        style: TextStyle(color: priorityLevel.color, fontWeight: FontWeight.bold),
      ),
      backgroundColor: priorityLevel.color.withOpacity(0.15),
      side: BorderSide(color: priorityLevel.color.withOpacity(0.3)),
    );
  }
}

/// Priority Icon - For list avatars
class PriorityIcon extends StatelessWidget {
  final int priority;
  final double size;

  const PriorityIcon({
    Key? key,
    required this.priority,
    this.size = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priorityLevel = ContactPriority.fromValue(priority);
    return CircleAvatar(
      radius: size,
      backgroundColor: priorityLevel.color.withOpacity(0.2),
      child: Icon(
        priorityLevel.icon,
        color: priorityLevel.color,
        size: size * 0.7,
      ),
    );
  }
}