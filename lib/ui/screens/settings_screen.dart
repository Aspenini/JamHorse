import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/brand.dart';
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
  }

  Future<void> _setStreamQuality(String value) async {
    setState(() => _streamQuality = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('streamQuality', value);
  }

  Future<void> _exportDiagnostics() async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await exportDiagnostics();
    if (Platform.isMacOS) {
      // Reveal the file in Finder.
      await Process.run('open', ['-R', file.path]);
    }
    messenger.showSnackBar(
      SnackBar(content: Text('Diagnostics saved to ${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final capabilities = ref.watch(platformMediaBridgeProvider).capabilities;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: JamColors.ink,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
        children: [
          const Center(child: JamHorseBrand()),
          const SizedBox(height: 28),
          _Section(
            title: 'Servers',
            children: [
              RadioGroup<String>(
                groupValue: state.session?.profile.id,
                onChanged: (profileId) {
                  final profile = state.profiles
                      .where((entry) => entry.id == profileId)
                      .firstOrNull;
                  if (profile != null) _switchServer(profile);
                },
                child: Column(
                  children: [
                    for (final profile in state.profiles)
                      RadioListTile<String>(
                        value: profile.id,
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
                    .logout(),
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
                    DropdownMenuItem(value: 'Data saver', child: Text('Saver')),
                  ],
                  onChanged: (value) =>
                      _setStreamQuality(value ?? 'Original'),
                ),
              ),
              if (capabilities.equalizer)
                ListTile(
                  leading: const Icon(Icons.equalizer_rounded),
                  title: const Text('Equalizer'),
                  subtitle: const Text('Flat · 10 bands'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showEqualizer,
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
          const Text(
            'JamHorse 1.0.0 · GPLv3\nIndependent Jellyfin music client',
            textAlign: TextAlign.center,
            style: TextStyle(color: JamColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _switchServer(ServerProfile profile) async {
    final playing = ref.read(playbackCoordinatorProvider).currentSnapshot.playing;
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

  void _showEqualizer() {
    final values = List.filled(10, 0.0);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Equalizer',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: Row(
                    children: [
                      for (var index = 0; index < values.length; index++)
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Slider(
                              value: values[index],
                              min: -12,
                              max: 12,
                              onChanged: (value) {
                                setModalState(() => values[index] = value);
                                ref
                                    .read(platformMediaBridgeProvider)
                                    .applyEqualizer(values);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Text('60  120  250  500  1k  2k  4k  8k  12k  16k'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout({required bool forget}) async {
    await ref
        .read(appControllerProvider.notifier)
        .logout(forgetServer: forget);
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
          Card(
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
