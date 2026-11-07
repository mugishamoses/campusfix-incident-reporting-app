import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../logic/auth_providers.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xl, vertical: AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: AppColors.primarySoft, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpace.l),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpace.xs),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            if (action != null) ...[
              const SizedBox(height: AppSpace.l),
              action!,
            ],
          ],
        ),
      );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: "Couldn't load this",
        message: errorMessage(error),
        action: onRetry == null
            ? null
            : OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
      );
}

/// Pulsing placeholder shaped like an IncidentCard.
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(6)),
        );
    return FadeTransition(
      opacity: Tween(begin: .45, end: 1.0).animate(_c),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.m),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Row(
          children: [
            bar(68, 68),
            const SizedBox(width: AppSpace.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(140, 14),
                  const SizedBox(height: 8),
                  bar(90, 11),
                  const SizedBox(height: 12),
                  bar(70, 11),
                ],
              ),
            ),
            bar(72, 24),
          ],
        ),
      ),
    );
  }
}

/// One place that decides how loading / error / data look for a list.
class AsyncSliverList<T> extends StatelessWidget {
  const AsyncSliverList({
    super.key,
    required this.value,
    required this.itemBuilder,
    required this.empty,
    this.limit,
    this.onRetry,
  });

  final AsyncValue<List<T>> value;
  final Widget Function(T item) itemBuilder;
  final Widget empty;
  final int? limit;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    Widget list(int count, Widget Function(int) build) => SliverPadding(
          padding: AppSpace.page,
          sliver: SliverList.separated(
            itemCount: count,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpace.m),
            itemBuilder: (_, i) => build(i),
          ),
        );

    return switch (value) {
      AsyncData(:final value) when value.isEmpty =>
        SliverToBoxAdapter(child: empty),
      AsyncData(:final value) => list(
          limit == null ? value.length : value.length.clamp(0, limit!),
          (i) => itemBuilder(value[i])),
      AsyncError(:final error) => SliverToBoxAdapter(
          child: ErrorState(error: error, onRetry: onRetry)),
      _ => list(3, (_) => const SkeletonCard()),
    };
  }
}
