import 'package:flutter/material.dart';

/// The JamHorse logo (horse-and-note mark with wordmark) rendered from the
/// master branding asset.
class JamHorseBrand extends StatelessWidget {
  const JamHorseBrand({super.key, this.height = 96});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'JamHorse',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height * 0.22),
        child: Image.asset(
          'assets/icons-output/web/icon-512.png',
          height: height,
          width: height,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class JamHorseMark extends StatelessWidget {
  const JamHorseMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return JamHorseBrand(height: size);
  }
}
