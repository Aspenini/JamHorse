import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';

/// Lists Cast receivers and AirPlay/system outputs and moves playback to
/// the chosen one.
Future<void> showOutputPicker(BuildContext context, WidgetRef ref) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final bridge = container.read(platformMediaBridgeProvider);
  final capabilities =
      container.read(platformCapabilitiesProvider).value ?? bridge.capabilities;
  final targets =
      container.read(castTargetsProvider).value ?? const <CastTarget>[];
  final messenger = ScaffoldMessenger.maybeOf(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text('Connect to a device'),
            subtitle: Text('Available outputs are detected on your network.'),
          ),
          if (capabilities.castConnected)
            ListTile(
              leading: const Icon(Icons.cast_connected_rounded),
              title: const Text('Stop casting'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final coordinator = container.read(playbackCoordinatorProvider);
                final position = bridge.remoteSession.position;
                await bridge.disconnectCast();
                await coordinator.seek(position);
                await coordinator.pause();
              },
            ),
          if (capabilities.airPlay)
            ListTile(
              leading: const Icon(Icons.airplay_rounded),
              title: const Text('AirPlay or system output'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await bridge.showOutputPicker();
              },
            ),
          for (final target in targets)
            ListTile(
              leading: const Icon(Icons.cast_rounded),
              title: Text(target.name),
              subtitle: target.model == null ? null : Text(target.model!),
              onTap: () async {
                final session = container.read(sessionProvider);
                if (session == null) return;
                Navigator.pop(sheetContext);
                final coordinator = container.read(playbackCoordinatorProvider);
                try {
                  await coordinator.pause();
                  await bridge.connectCastDevice(
                    target.id,
                    session,
                    coordinator.currentSnapshot,
                    container.read(jellyfinGatewayProvider),
                  );
                } catch (error) {
                  messenger?.showSnackBar(SnackBar(content: Text('$error')));
                }
              },
            ),
          if (!capabilities.airPlay && targets.isEmpty)
            const ListTile(title: Text('No devices found')),
        ],
      ),
    ),
  );
}
