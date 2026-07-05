import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/core/artwork_cache.dart';
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/platform/window_decorations.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/brand.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _wifiOnly = false;
  var _streamQuality = 'Original';
  // 0 means unlimited.
  var _storageLimitGb = 10;
  String? _downloadsPath;
  String _version = '…';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() {
        _wifiOnly = prefs.getBool('wifiOnlyDownloads') ?? false;
        _storageLimitGb = prefs.getInt('downloadStorageLimitGb') ?? 10;
        _streamQuality = prefs.getString('streamQuality') ?? 'Original';
      });
    });
    getApplicationSupportDirectory().then((dir) {
      if (!mounted) return;
      setState(() => _downloadsPath = '${dir.path}/downloads');
    });
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  Future<void> _revealDownloads() async {
    final path = _downloadsPath;
    if (path == null) return;
    final dir = Directory(path);
    if (!await dir.exists()) await dir.create(recursive: true);
    if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  }

  Future<void> _clearArtworkCache() async {
    final messenger = ScaffoldMessenger.of(context);
    await ArtworkCache.clear();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Artwork cache cleared. Images reload on next view.'),
      ),
    );
  }

  Future<void> _setWifiOnly(bool value) async {
    setState(() => _wifiOnly = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wifiOnlyDownloads', value);
  }

  Future<void> _setStorageLimit(int gigabytes) async {
    setState(() => _storageLimitGb = gigabytes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('downloadStorageLimitGb', gigabytes);
    await ref.read(downloadManagerProvider).enforceStorageLimit();
  }

  Future<void> _setStreamQuality(String value) async {
    setState(() => _streamQuality = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('streamQuality', value);
  }

  Future<void> _exportDiagnostics() async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await exportDiagnostics();
    if (Platform.isAndroid || Platform.isIOS) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'JamHorse diagnostics'),
      );
      return;
    }
    final destination = await getSaveLocation(
      suggestedName: file.uri.pathSegments.last,
    );
    if (destination == null) return;
    await file.copy(destination.path);
    if (!mounted) return;
    if (Platform.isMacOS) {
      await Process.run('open', ['-R', destination.path]);
    }
    messenger.showSnackBar(
      SnackBar(content: Text('Diagnostics saved to ${destination.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final bridge = ref.watch(platformMediaBridgeProvider);
    final capabilities =
        ref.watch(platformCapabilitiesProvider).value ?? bridge.capabilities;
    final windowDecoration = ref.watch(windowDecorationProvider);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 120),
            children: [
              Row(
                children: [
                  const JamHorseBrand(height: 64),
                  const SizedBox(width: 20),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
              const SizedBox(height: 34),
              _Section(
                title: 'Servers',
                children: [
                  RadioGroup<String>(
                    groupValue: state.session?.profile.profileId,
                    onChanged: (profileId) {
                      final profile = state.profiles
                          .where((entry) => entry.profileId == profileId)
                          .firstOrNull;
                      if (profile != null) _switchServer(profile);
                    },
                    child: Column(
                      children: [
                        for (final profile in state.profiles)
                          RadioListTile<String>(
                            value: profile.profileId,
                            title: Text(profile.name),
                            subtitle: Text(
                              '${profile.username} · '
                              'Jellyfin ${profile.serverVersion}\n'
                              '${profile.baseUrl}',
                            ),
                            secondary: const Icon(Icons.dns_rounded),
                          ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline_rounded),
                    title: const Text('Add another server'),
                    onTap: () => ref
                        .read(appControllerProvider.notifier)
                        .logout(preserveCredential: true),
                  ),
                ],
              ),
              if (supportsWindowDecorations)
                _Section(
                  title: 'Appearance',
                  children: [
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.web_asset_rounded),
                      title: const Text('Custom window controls'),
                      subtitle: Text(
                        windowDecoration == WindowDecorationMode.custom
                            ? 'Spotify-style title bar'
                            : 'System-native title bar',
                      ),
                      value: windowDecoration == WindowDecorationMode.custom,
                      onChanged: (enabled) => ref
                          .read(windowDecorationProvider.notifier)
                          .setMode(
                            enabled
                                ? WindowDecorationMode.custom
                                : WindowDecorationMode.native,
                          ),
                    ),
                  ],
                ),
              _Section(
                title: 'Playback',
                children: [
                  ListTile(
                    leading: const Icon(Icons.high_quality_rounded),
                    title: const Text('Streaming quality'),
                    subtitle: Text(_streamQuality),
                    trailing: DropdownButton<String>(
                      value: _streamQuality,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: 'Original',
                          child: Text('Original'),
                        ),
                        DropdownMenuItem(value: 'High', child: Text('High')),
                        DropdownMenuItem(
                          value: 'Data saver',
                          child: Text('Saver'),
                        ),
                      ],
                      onChanged: (value) =>
                          _setStreamQuality(value ?? 'Original'),
                    ),
                  ),
                  if (capabilities.equalizer)
                    ListTile(
                      leading: const Icon(Icons.equalizer_rounded),
                      title: const Text('Equalizer'),
                      subtitle: const Text('Open system audio effects'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        try {
                          await bridge.showEqualizer(
                            audioSessionId: ref
                                .read(playbackCoordinatorProvider)
                                .audioSessionId,
                          );
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$error')));
                        }
                      },
                    ),
                ],
              ),
              _Section(
                title: 'Downloads',
                children: [
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.wifi_rounded),
                    title: const Text('Download on Wi-Fi only'),
                    value: _wifiOnly,
                    onChanged: _setWifiOnly,
                  ),
                  ListTile(
                    leading: const Icon(Icons.storage_rounded),
                    title: const Text('Storage limit'),
                    subtitle: Text(
                      _storageLimitGb == 0
                          ? 'Unlimited'
                          : '$_storageLimitGb GB · remove least recently '
                                'played first',
                    ),
                    trailing: DropdownButton<int>(
                      value: _storageLimitGb,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Unlimited')),
                        DropdownMenuItem(value: 5, child: Text('5 GB')),
                        DropdownMenuItem(value: 10, child: Text('10 GB')),
                        DropdownMenuItem(value: 20, child: Text('20 GB')),
                        DropdownMenuItem(value: 50, child: Text('50 GB')),
                      ],
                      onChanged: (value) =>
                          _setStorageLimit(value ?? _storageLimitGb),
                    ),
                  ),
                  if (Platform.isMacOS ||
                      Platform.isWindows ||
                      Platform.isLinux)
                    ListTile(
                      leading: const Icon(Icons.folder_open_rounded),
                      title: const Text('Downloads folder'),
                      subtitle: Text(
                        _downloadsPath ?? 'Locating…',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.open_in_new_rounded),
                      onTap: _revealDownloads,
                    ),
                ],
              ),
              _Section(
                title: 'Integrations',
                children: [
                  _CapabilityTile(
                    title: 'Google Cast',
                    enabled: capabilities.googleCast,
                  ),
                  _CapabilityTile(
                    title: 'AirPlay',
                    enabled: capabilities.airPlay,
                  ),
                  _CapabilityTile(
                    title: 'Automotive controls',
                    enabled: capabilities.automotive,
                  ),
                  _CapabilityTile(
                    title: 'Desktop media keys',
                    enabled: capabilities.desktopMediaKeys,
                  ),
                ],
              ),
              _Section(
                title: 'Privacy & diagnostics',
                children: [
                  const ListTile(
                    leading: Icon(Icons.shield_outlined),
                    title: Text('No analytics'),
                    subtitle: Text(
                      'JamHorse sends playback data only to your Jellyfin server.',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Export redacted diagnostics'),
                    trailing: const Icon(Icons.ios_share_rounded),
                    onTap: _exportDiagnostics,
                  ),
                  ListTile(
                    leading: const Icon(Icons.gavel_rounded),
                    title: const Text('Open-source licenses'),
                    subtitle: const Text(
                      'JamHorse GPLv3 and dependency notices',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'JamHorse',
                      applicationVersion: _version,
                      applicationLegalese:
                          'Copyright © 2026 JamHorse contributors\nGPLv3',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_rounded),
                    title: const Text('Clear artwork cache'),
                    subtitle: const Text(
                      'Cached covers make browsing instant and work offline; '
                      'clear to free space or fix stale images.',
                    ),
                    onTap: _clearArtworkCache,
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _logout(forget: false),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _logout(forget: true),
                child: const Text('Forget this server'),
              ),
              const SizedBox(height: 20),
              Text(
                'JamHorse $_version · GPLv3\nIndependent Jellyfin music client',
                textAlign: TextAlign.center,
                style: TextStyle(color: JamColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _switchServer(ServerProfile profile) async {
    final playing = ref
        .read(playbackCoordinatorProvider)
        .currentSnapshot
        .playing;
    if (playing) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Switch servers?'),
          content: const Text('Current playback will stop.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Switch'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    await ref.read(appControllerProvider.notifier).switchProfile(profile);
  }

  Future<void> _logout({required bool forget}) async {
    await ref.read(appControllerProvider.notifier).logout(forgetServer: forget);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: JamColors.accentBright,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1.3,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: JamColors.soft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _CapabilityTile extends StatelessWidget {
  const _CapabilityTile({required this.title, required this.enabled});

  final String title;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        enabled ? Icons.check_circle_rounded : Icons.remove_circle_outline,
        color: enabled ? const Color(0xFF5FD49A) : JamColors.muted,
      ),
      title: Text(title),
      subtitle: Text(enabled ? 'Available on this device' : 'Not supported'),
    );
  }
}
