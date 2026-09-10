class ProtectedBrand {
  const ProtectedBrand({required this.name, required this.officialDomain});

  final String name;
  final String officialDomain;
}

class QrDestinationAnalysis {
  const QrDestinationAnalysis({
    required this.isValid,
    required this.usesHttps,
    required this.host,
    required this.isIpAddress,
    required this.usesPunycode,
    this.invalidReason,
  });

  final bool isValid;
  final bool usesHttps;
  final String host;
  final bool isIpAddress;
  final bool usesPunycode;
  final String? invalidReason;
}

abstract final class QrAnalysisService {
  static QrDestinationAnalysis analyseDestination(String rawValue) {
    final value = rawValue.trim();

    if (value.isEmpty) {
      return const QrDestinationAnalysis(
        isValid: false,
        usesHttps: false,
        host: '',
        isIpAddress: false,
        usesPunycode: false,
        invalidReason: 'The QR code does not contain a destination.',
      );
    }

    if (value.contains(RegExp(r'\s'))) {
      return const QrDestinationAnalysis(
        isValid: false,
        usesHttps: false,
        host: '',
        isIpAddress: false,
        usesPunycode: false,
        invalidReason: 'The destination contains invalid spaces.',
      );
    }

    final uri = Uri.tryParse(value);
    final scheme = uri?.scheme.toLowerCase() ?? '';

    if (uri == null || (scheme != 'http' && scheme != 'https')) {
      return const QrDestinationAnalysis(
        isValid: false,
        usesHttps: false,
        host: '',
        isIpAddress: false,
        usesPunycode: false,
        invalidReason:
            'Only HTTP and HTTPS website destinations are supported.',
      );
    }

    final host = _normalizeHost(uri.host);
    final isIpAddress = _isIpAddress(host);
    final validHost = isIpAddress || _isValidPublicDomain(host);

    if (!validHost) {
      return QrDestinationAnalysis(
        isValid: false,
        usesHttps: scheme == 'https',
        host: host,
        isIpAddress: false,
        usesPunycode: false,
        invalidReason: 'The QR code does not contain a valid public website.',
      );
    }

    return QrDestinationAnalysis(
      isValid: true,
      usesHttps: scheme == 'https',
      host: host,
      isIpAddress: isIpAddress,
      usesPunycode: host.split('.').any((label) => label.startsWith('xn--')),
    );
  }

  static String? findImpersonatedBrand(
    String host,
    List<ProtectedBrand> brands,
  ) {
    final normalizedHost = _normalizeHost(host);
    final hostLabels = normalizedHost.split('.');

    for (final brand in brands) {
      final officialHost = _normalizeHost(brand.officialDomain);
      if (officialHost.isEmpty ||
          normalizedHost == officialHost ||
          normalizedHost.endsWith('.$officialHost')) {
        continue;
      }

      final tokens = _brandTokens(brand.name);
      for (final token in tokens) {
        for (final label in hostLabels) {
          final normalizedLabel = _lettersAndNumbers(label);
          if (normalizedLabel.contains(token) ||
              _isVisuallySimilar(normalizedLabel, token)) {
            return brand.name;
          }
        }
      }
    }

    return null;
  }

  static String domainExtension(String host) {
    if (!host.contains('.')) {
      return '';
    }
    return '.${host.split('.').last.toLowerCase()}';
  }

  static bool _isValidPublicDomain(String host) {
    if (host.isEmpty ||
        host.startsWith('.') ||
        host.endsWith('.') ||
        !host.contains('.')) {
      return false;
    }

    final labels = host.split('.');
    final labelPattern = RegExp(r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$');

    if (labels.any((label) => !labelPattern.hasMatch(label))) {
      return false;
    }

    final suffix = labels.last;
    return RegExp(r'^[a-z]{2,63}$').hasMatch(suffix) ||
        suffix.startsWith('xn--');
  }

  static bool _isIpAddress(String host) {
    final ipv4 = RegExp(
      r'^(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})'
      r'(?:\.(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})){3}$',
    );
    return ipv4.hasMatch(host) || host.contains(':');
  }

  static Set<String> _brandTokens(String name) {
    const ignoredWords = {
      'bank',
      'berhad',
      'company',
      'group',
      'limited',
      'malaysia',
      'merchant',
      'official',
      'services',
      'verified',
    };

    final tokens = name
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .map(_lettersAndNumbers)
        .where((token) => token.length >= 4 && !ignoredWords.contains(token))
        .toSet();

    final compactName = _lettersAndNumbers(name);
    if (compactName.length >= 4) {
      tokens.add(compactName);
    }

    return tokens;
  }

  static bool _isVisuallySimilar(String candidate, String token) {
    if (candidate.length < 4 || token.length < 4) {
      return false;
    }

    final allowedDistance = token.length >= 9 ? 2 : 1;
    return (candidate.length - token.length).abs() <= allowedDistance &&
        _levenshtein(candidate, token) <= allowedDistance;
  }

  static int _levenshtein(String left, String right) {
    if (left == right) return 0;
    if (left.isEmpty) return right.length;
    if (right.isEmpty) return left.length;

    var previous = List<int>.generate(right.length + 1, (index) => index);

    for (var leftIndex = 1; leftIndex <= left.length; leftIndex++) {
      final current = List<int>.filled(right.length + 1, 0);
      current[0] = leftIndex;

      for (var rightIndex = 1; rightIndex <= right.length; rightIndex++) {
        final substitutionCost =
            left.codeUnitAt(leftIndex - 1) == right.codeUnitAt(rightIndex - 1)
            ? 0
            : 1;

        final deletion = previous[rightIndex] + 1;
        final insertion = current[rightIndex - 1] + 1;
        final substitution = previous[rightIndex - 1] + substitutionCost;

        current[rightIndex] = _minimum(deletion, insertion, substitution);
      }

      previous = current;
    }

    return previous.last;
  }

  static int _minimum(int first, int second, int third) {
    var result = first < second ? first : second;
    if (third < result) result = third;
    return result;
  }

  static String _normalizeHost(String value) {
    var host = value.trim().toLowerCase();

    final uri = Uri.tryParse(host.contains('://') ? host : 'https://$host');
    if (uri != null && uri.host.isNotEmpty) {
      host = uri.host.toLowerCase();
    }

    if (host.startsWith('www.')) {
      host = host.substring(4);
    }

    return host.endsWith('.') ? host.substring(0, host.length - 1) : host;
  }

  static String _lettersAndNumbers(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
