import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final String area;
  final String status;
  final double progress;

  const ProjectCard({
    super.key,
    required this.title,
    required this.area,
    required this.status,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDone = progress >= 1.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(area, style: const TextStyle(fontSize: 12)),
                  backgroundColor: colorScheme.secondaryContainer,
                  labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
                  padding: EdgeInsets.zero,
                ),
                Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color: isDone ? Colors.green : colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              color: isDone ? Colors.green : colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }
}
