import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/enum_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/enums.dart';
import '../../data/models/incident.dart';
import 'basics.dart';

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final IncidentStatus status;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Tag(status.label,
            key: ValueKey(status),
            color: status.color,
            background: status.background),
      );
}

class PriorityTag extends StatelessWidget {
  const PriorityTag(this.priority, {super.key});
  final IncidentPriority priority;

  @override
  Widget build(BuildContext context) => Tag('${priority.label} priority',
      icon: Icons.flag_rounded,
      color: priority.color,
      background: priority.color.withValues(alpha: .1));
}

/// Incident photo, or a category-tinted placeholder when there is none.
class IncidentImage extends StatelessWidget {
  const IncidentImage({
    super.key,
    required this.incident,
    this.size,
    this.radius = 12,
    this.iconSize = 28,
  });

  final Incident incident;
  final double? size;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final url = incident.photoUrl;
    final c = incident.category.color;
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: .18), c.withValues(alpha: .06)],
        ),
      ),
      child: Center(
          child: Icon(incident.category.icon, color: c, size: iconSize)),
    );
    Widget child;
    if (url == null) {
      child = placeholder;
    } else if (url.startsWith('http')) {
      // Disk-cached so feed thumbnails don't re-download on every scroll.
      child = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      );
    } else {
      child = Image.file(File(url),
          fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}

class IncidentCard extends StatelessWidget {
  const IncidentCard({super.key, required this.incident, required this.onTap});
  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '${incident.title}, ${incident.location}, ${incident.status.label}',
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpace.m),
        child: Row(
          children: [
            IncidentImage(incident: incident, size: 68),
            const SizedBox(width: AppSpace.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(incident.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall),
                      ),
                      if (incident.isHidden)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.visibility_off_rounded,
                              size: 16, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(incident.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall),
                  const SizedBox(height: 8),
                  MetaRow(Icons.calendar_today_outlined,
                      timeAgo(incident.createdAt)),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s),
            StatusPill(incident.status),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$value $label',
      excludeSemantics: true,
      child: PressScale(
        child: Material(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(AppRadius.card),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: .15),
                        shape: BoxShape.circle),
                    child: Icon(icon, size: 19, color: color),
                  ),
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: value.toDouble()),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => Text('${v.round()}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 22)),
                  ),
                  const SizedBox(height: 2),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final IncidentCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      excludeSemantics: true,
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 76,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: selected ? AppShadow.lifted : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, color: fg, size: 24),
                const SizedBox(height: 6),
                Text(category.label,
                    style: TextStyle(
                        color: selected ? Colors.white : AppColors.text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal 4-step progress: done ✓, current (ringed), future (grey).
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.current, required this.history});
  final IncidentStatus current;
  final List<StatusChange> history;

  @override
  Widget build(BuildContext context) {
    const steps = IncidentStatus.values;
    final reachedAt = {for (final h in history) h.to: h.at};
    Widget node(IncidentStatus s) {
      final done = s.index < current.index ||
          (s == IncidentStatus.resolved && current == s);
      final isCurrent = s == current && !done;
      final active = done || isCurrent;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.primary : AppColors.border,
          border: isCurrent
              ? Border.all(color: AppColors.primarySoft, width: 4)
              : null,
          boxShadow: isCurrent ? AppShadow.lifted : null,
        ),
        child: Icon(done ? Icons.check_rounded : s.icon,
            size: 16, color: active ? Colors.white : AppColors.textMuted),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in steps)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: s == steps.first
                          ? const SizedBox()
                          : _Line(on: s.index <= current.index),
                    ),
                    node(s),
                    Expanded(
                      child: s == steps.last
                          ? const SizedBox()
                          : _Line(on: s.index < current.index),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(s.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: s.index <= current.index
                          ? AppColors.text
                          : AppColors.textMuted,
                    )),
                const SizedBox(height: 2),
                Text(
                  reachedAt[s] != null ? shortDate(reachedAt[s]!) : '—',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 3,
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
