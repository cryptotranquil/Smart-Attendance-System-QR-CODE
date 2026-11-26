import 'package:flutter/material.dart';

import 'theme.dart';

/// Shared building blocks for the redesign.

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: C.faint),
        ),
      );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(SmartAttendanceTheme.radiusCard),
          border: Border.all(color: C.hairline),
        ),
        padding: padding,
        child: child,
      );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.fg = C.muted, this.bg = C.bg, this.icon});

  final String text;
  final Color fg;
  final Color bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
            Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'Active':
        return const Pill('Active', fg: C.success, bg: C.successSoft, icon: Icons.check_circle);
      case 'Approved':
        return const Pill('Approved', fg: C.success, bg: C.successSoft, icon: Icons.check_circle);
      case 'Not signed up':
        return const Pill('Not signed up', fg: C.muted, bg: C.bg, icon: Icons.schedule);
      case 'Suspended':
        return const Pill('Suspended', fg: C.danger, bg: C.dangerSoft, icon: Icons.block);
      case 'With lecturer':
        return const Pill('With lecturer', fg: C.warn, bg: C.warnSoft, icon: Icons.hourglass_top);
      case 'Declined':
        return const Pill('Declined', fg: C.danger, bg: C.dangerSoft);
      default:
        return Pill(status);
    }
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.expand = true});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
        if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 16, color: Colors.white)],
      ],
    );
    return SizedBox(
      height: 48,
      width: expand ? double.infinity : null,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: C.brand,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SmartAttendanceTheme.radiusField)),
        ),
        onPressed: onPressed,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: child),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onPressed, this.icon, this.expand = false, this.danger = false});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool expand;
  final bool danger;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        width: expand ? double.infinity : null,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: danger ? C.danger : C.ink,
            side: BorderSide(color: danger ? const Color(0x66B42318) : C.hairline),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SmartAttendanceTheme.radiusField)),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 8)],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      );
}

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 30});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: C.brand, borderRadius: BorderRadius.circular(size * 0.28)),
        child: Icon(Icons.qr_code_2, color: Colors.white, size: size * 0.62),
      );
}

/// Top chrome shared by every role shell: brand + role nav + user + sign out.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.navItems,
    required this.currentIndex,
    required this.onSelect,
    required this.userName,
    required this.userMeta,
    required this.onSignOut,
  });

  final List<String> navItems;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final String userName;
  final String userMeta;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Container(
      decoration: const BoxDecoration(
        color: C.card,
        border: Border(bottom: BorderSide(color: C.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const LogoMark(size: 28),
          const SizedBox(width: 8),
          const Text('Smart Attendance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
          const SizedBox(width: 18),
          if (wide)
            for (var i = 0; i < navItems.length; i++)
              _NavTab(label: navItems[i], active: i == currentIndex, onTap: () => onSelect(i)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              Text(userMeta, style: const TextStyle(fontSize: 10.5, color: C.muted)),
            ],
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onSignOut,
            child: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: C.ink)),
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? C.infoSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: active ? C.accent : C.muted,
              ),
            ),
          ),
        ),
      );
}

/// A − stepper + + control used across the admin Rules screen.
class StepperRow extends StatelessWidget {
  const StepperRow({super.key, required this.title, this.subtitle, required this.value, required this.unit, required this.onChanged, this.min = 0, this.max = 999});

  final String title;
  final String? subtitle;
  final int value;
  final String unit;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(fontSize: 11, color: C.muted)),
                ],
              ),
            ),
            _RoundButton(icon: Icons.remove, onTap: value > min ? () => onChanged(value - 1) : null),
            SizedBox(
              width: 74,
              child: Text(
                '$value $unit',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            _RoundButton(icon: Icons.add, onTap: value < max ? () => onChanged(value + 1) : null),
          ],
        ),
      );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkResponse(
        onTap: onTap,
        radius: 20,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border.all(color: C.hairline),
            shape: BoxShape.circle,
            color: onTap == null ? C.bg : C.card,
          ),
          child: Icon(icon, size: 15, color: onTap == null ? C.faint : C.ink),
        ),
      );
}
