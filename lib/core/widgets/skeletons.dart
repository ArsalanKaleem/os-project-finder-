import 'package:flutter/material.dart';

/// Gently pulsing placeholder block — the building brick of loading states.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    lowerBound: 0.35,
    upperBound: 0.9,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Card-shaped skeleton matching [RepoCard] / [IssueCard] proportions.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 150});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              SkeletonBox(width: 36, height: 36, radius: 18),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(width: double.infinity, height: 16)),
            ]),
            const SizedBox(height: 16),
            const SkeletonBox(),
            const SizedBox(height: 8),
            const SkeletonBox(width: 220),
            const Spacer(),
            Row(children: const [
              SkeletonBox(width: 60, height: 12),
              SizedBox(width: 12),
              SkeletonBox(width: 60, height: 12),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Grid/list of skeleton cards used while first page loads.
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 170,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }
}
