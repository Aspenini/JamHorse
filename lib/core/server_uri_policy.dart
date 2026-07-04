import 'dart:io';

class ServerUriPolicy {
  const ServerUriPolicy._();

  static Uri normalize(String input) {
    final trimmed = input.trim();
    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final parsed = Uri.parse(withScheme);
    if (!parsed.hasScheme || parsed.host.isEmpty) {
      throw const FormatException('Enter a valid Jellyfin server address.');
    }
    if (parsed.scheme != 'https' && parsed.scheme != 'http') {
      throw const FormatException('Only HTTP and HTTPS servers are supported.');
    }
    if (parsed.userInfo.isNotEmpty || parsed.hasQuery || parsed.hasFragment) {
      throw const FormatException(
        'Server addresses cannot contain credentials, a query, or a fragment.',
      );
    }
    return parsed.replace(
      path: parsed.path == '/'
          ? ''
          : parsed.path.replaceFirst(RegExp(r'/$'), ''),
      query: null,
      fragment: null,
    );
  }

  static bool isPrivateHttp(Uri uri) {
    if (uri.scheme != 'http') return false;
    final host = uri.host.toLowerCase();
    if (host == 'localhost') return true;
    final address = InternetAddress.tryParse(host);
    if (address == null) return false;
    if (address.isLoopback || address.isLinkLocal) return true;
    if (address.type == InternetAddressType.IPv4) {
      final octets = address.rawAddress;
      return octets[0] == 10 ||
          (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) ||
          (octets[0] == 192 && octets[1] == 168);
    }
    final first = address.rawAddress.first;
    return first & 0xfe == 0xfc;
  }

  static void validate(Uri uri, {required bool allowPrivateHttp}) {
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      throw const FormatException(
        'Server addresses cannot contain credentials, a query, or a fragment.',
      );
    }
    if (uri.scheme == 'https') return;
    if (!allowPrivateHttp || !isPrivateHttp(uri)) {
      throw const FormatException(
        'Plain HTTP is allowed only for explicitly trusted private servers.',
      );
    }
  }
}
