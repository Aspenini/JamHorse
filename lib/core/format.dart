/// `m:ss` (or `h:mm:ss` past an hour) for track positions and lengths.
/// Negative values clamp to zero.
String formatDuration(Duration value) {
  final safe = value.isNegative ? Duration.zero : value;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60);
  final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
  }
  return '$minutes:$seconds';
}

/// Spotify's collection summary, e.g. "1 hr 12 min" or "38 min".
String formatTotalDuration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  if (hours == 0) return '$minutes min';
  return '$hours hr $minutes min';
}
