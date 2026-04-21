import 'package:flutter/material.dart';

class ToggleMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  const ToggleMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.initialValue,
    this.onChanged,
  });

  @override
  State<ToggleMenuItem> createState() => _ToggleMenuItemState();
}

class _ToggleMenuItemState extends State<ToggleMenuItem> {
  late bool _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color.fromARGB(255, 0, 57, 104);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(widget.icon, color: primaryBlue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Switch.adaptive(
            value: _currentValue,
            // ignore: deprecated_member_use
            activeColor: primaryBlue,
            onChanged: (value) {
              setState(() => _currentValue = value);
              if (widget.onChanged != null) widget.onChanged!(value);
            },
          ),
        ],
      ),
    );
  }
}
