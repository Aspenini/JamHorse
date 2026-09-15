import 'package:flutter/material.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/ui/layout.dart';

/// Spotify's album/playlist/artist page frame: an artwork-tinted header
/// that fades into the action row, followed by the page's content.
class DetailPage extends StatelessWidget {
  const DetailPage({
    required this.title,
    required this.typeLabel,
    required this.artwork,
    required this.metadata,
    required this.actions,
    required this.slivers,
    required this.tint,
    super.key,
    this.appBarActions = const [],
  });

  final String title;
  final String typeLabel;
  final Widget artwork;
  final Widget metadata;
  final Widget actions;
  final List<Widget> slivers;
  final Color tint;
  final List<Widget> appBarActions;

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktopLayout(context);
    final fade = Color.lerp(tint, JamColors.elevated, 0.7)!;
    const duration = Duration(milliseconds: 500);
    return Scaffold(
      backgroundColor: JamColors.elevated,
      body: CustomScrollView(
        slivers: [
          if (!desktop)
            SliverAppBar(
              pinned: true,
              backgroundColor: Color.lerp(tint, Colors.black, 0.4),
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: appBarActions,
            ),
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: duration,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [tint, fade],
                ),
              ),
              padding: desktop
                  ? const EdgeInsets.fromLTRB(24, 48, 24, 24)
                  : const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: desktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _Shadowed(size: 220, child: artwork),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                typeLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      fontSize: title.length > 28 ? 44 : 72,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              metadata,
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: _Shadowed(size: 232, child: artwork)),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        metadata,
                      ],
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: duration,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [fade, JamColors.elevated],
                ),
              ),
              padding: desktop
                  ? const EdgeInsets.fromLTRB(24, 20, 24, 12)
                  : const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: actions,
            ),
          ),
          ...slivers,
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

class _Shadowed extends StatelessWidget {
  const _Shadowed({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Play, shuffle, and utility buttons. Desktop leads with play; phones put
/// utilities on the left and shuffle and play on the right.
class DetailActionRow extends StatelessWidget {
  const DetailActionRow({
    required this.play,
    super.key,
    this.shuffle,
    this.utilities = const [],
    this.trailing = const [],
  });

  final Widget play;
  final Widget? shuffle;
  final List<Widget> utilities;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    if (isDesktopLayout(context)) {
      return Row(
        children: [
          play,
          const SizedBox(width: 20),
          if (shuffle case final shuffle?) ...[
            shuffle,
            const SizedBox(width: 4),
          ],
          ...utilities,
          const Spacer(),
          ...trailing,
        ],
      );
    }
    return Row(
      children: [
        ...utilities,
        const Spacer(),
        ...trailing,
        ?shuffle,
        const SizedBox(width: 8),
        play,
      ],
    );
  }
}

/// A section title inside a detail page's scroll view.
class SliverSectionHeading extends StatelessWidget {
  const SliverSectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktopLayout(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(desktop ? 24 : 16, 24, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
