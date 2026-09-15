import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';

LibraryItem testTrack(
  String id, {
  String? name,
  bool favorite = false,
  Duration duration = const Duration(minutes: 3, seconds: 21),
}) {
  return LibraryItem(
    id: id,
    profileId: 'profile',
    serverId: 'server',
    type: LibraryItemType.track,
    name: name ?? 'Track $id',
    subtitle: 'The Band',
    artists: const ['The Band'],
    albumId: 'album',
    albumName: 'The Album',
    duration: duration,
    isFavorite: favorite,
  );
}

/// Records transport calls; the snapshot is served synchronously through
/// [currentSnapshot] so widget tests need no stream timing.
class FakePlaybackCoordinator implements PlaybackCoordinator {
  FakePlaybackCoordinator([this.snapshot = const PlaybackSnapshot()]);

  PlaybackSnapshot snapshot;
  final calls = <String>[];

  @override
  Stream<PlaybackSnapshot> get snapshots => const Stream.empty();

  @override
  PlaybackSnapshot get currentSnapshot => snapshot;

  @override
  int? get audioSessionId => null;

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> skipNext() async => calls.add('next');

  @override
  Future<void> skipPrevious() async => calls.add('previous');

  @override
  Future<void> setShuffle(bool enabled) async => calls.add('shuffle:$enabled');

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class FakeMediaBridge implements PlatformMediaBridge {
  @override
  PlatformCapabilities get capabilities => const PlatformCapabilities(
    googleCast: false,
    airPlay: false,
    equalizer: false,
    automotive: false,
    desktopMediaKeys: false,
  );

  @override
  Stream<PlatformCapabilities> get capabilityChanges => const Stream.empty();

  @override
  Stream<List<CastTarget>> get castTargets => const Stream.empty();

  @override
  RemotePlaybackState get remoteSession => const RemotePlaybackState();

  @override
  Stream<RemotePlaybackState> get remoteSessionChanges => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class FakeAppController extends AppController {
  FakeAppController(this.initial);

  final AppState initial;
  final favorited = <String>[];

  @override
  AppState build() => initial;

  @override
  Future<void> toggleFavorite(LibraryItem item) async => favorited.add(item.id);
}

/// Pumps [child] inside the app theme with every platform service faked.
Future<FakePlaybackCoordinator> pumpWithFakes(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1240, 800),
  PlaybackSnapshot snapshot = const PlaybackSnapshot(),
  List<LibraryItem> library = const [],
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final coordinator = FakePlaybackCoordinator(snapshot);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playbackCoordinatorProvider.overrideWithValue(coordinator),
        platformMediaBridgeProvider.overrideWithValue(FakeMediaBridge()),
        appControllerProvider.overrideWith(
          () => FakeAppController(
            AppState(initializing: false, library: library),
          ),
        ),
        downloadedItemIdsProvider.overrideWithValue(const {}),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildJamHorseTheme(),
        home: Scaffold(backgroundColor: JamColors.ink, body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return coordinator;
}
