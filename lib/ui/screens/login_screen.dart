import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/core/server_uri_policy.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/brand.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            JamHorseMark(size: 72),
            SizedBox(height: 24),
            CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  var _allowPrivateHttp = false;
  var _obscurePassword = true;

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    ref.listen(appControllerProvider, (previous, next) {
      if (previous?.isAuthenticated == false && next.isAuthenticated) {
        context.go('/home');
      }
    });
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.75, -0.8),
            radius: 1.15,
            colors: [Color(0xFF16264D), JamColors.ink],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  color: const Color(0xE610141F),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(child: JamHorseBrand()),
                          const SizedBox(height: 36),
                          Text(
                            'Your music. Your server.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Connect to Jellyfin and take your library everywhere.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: JamColors.muted),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _serverController,
                            keyboardType: TextInputType.url,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Server address',
                              hintText: 'https://music.example.com',
                              prefixIcon: Icon(Icons.dns_rounded),
                            ),
                            validator: (value) {
                              try {
                                ServerUriPolicy.normalize(value ?? '');
                                return null;
                              } on FormatException catch (error) {
                                return error.message;
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _usernameController,
                            autofillHints: const [AutofillHints.username],
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your Jellyfin username.'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _connect(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            value: _allowPrivateHttp,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Allow private-network HTTP'),
                            subtitle: const Text(
                              'Only localhost, .local, and private IP addresses',
                            ),
                            onChanged: (value) =>
                                setState(() => _allowPrivateHttp = value),
                          ),
                          if (state.error != null) ...[
                            const SizedBox(height: 8),
                            _ErrorMessage(message: state.error!),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: state.connecting ? null : _connect,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: state.connecting
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Connect to Jellyfin'),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Credentials stay on this device. JamHorse never '
                            'uses analytics or third-party music services.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: JamColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    final normalized = ServerUriPolicy.normalize(_serverController.text);
    try {
      await ref
          .read(appControllerProvider.notifier)
          .login(
            serverUrl: normalized.toString(),
            username: _usernameController.text,
            password: _passwordController.text,
            allowPrivateHttp: _allowPrivateHttp,
          );
    } catch (_) {
      // The controller exposes a sanitized error in state.
    }
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
