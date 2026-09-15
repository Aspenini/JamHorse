import 'package:flutter/material.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/hoverable.dart';

/// A responsive grid of [ArtworkCard]s, as a sliver.
class SliverArtworkGrid extends StatelessWidget {
  const SliverArtworkGrid({required this.items, super.key, this.cardSubtitle});

  final List<LibraryItem> items;
  final String Function(LibraryItem item)? cardSubtitle;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.crossAxisExtent / 190).floor().clamp(2, 8);
        final width = constraints.crossAxisExtent / columns;
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: width + ArtworkCard.extraHeight,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => ArtworkCard(
            item: items[index],
            width: width,
            subtitle: cardSubtitle?.call(items[index]),
          ),
        );
      },
    );
  }
}

/// A titled, horizontally scrolling shelf of [ArtworkCard]s.
class MediaRow extends StatelessWidget {
  const MediaRow({
    required this.title,
    required this.items,
    super.key,
    this.subtitle,
    this.onShowAll,
    this.cardWidth = 176,
    this.cardSubtitle,
  });

  final String title;
  final List<LibraryItem> items;
  final String? subtitle;
  final VoidCallback? onShowAll;
  final double cardWidth;
  final String Function(LibraryItem item)? cardSubtitle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinkText(
                        title,
                        onTap: onShowAll,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: JamColors.muted,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onShowAll != null)
                  TextButton(
                    onPressed: onShowAll,
                    child: const Text('Show all'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: cardWidth + ArtworkCard.extraHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) => ArtworkCard(
                item: items[index],
                width: cardWidth,
                subtitle: cardSubtitle?.call(items[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
