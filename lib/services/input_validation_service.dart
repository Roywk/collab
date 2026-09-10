abstract final class InputValidationService {
  static String? validateBusinessName(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'Business name is required.';
    }

    if (input.length < 3) {
      return 'Enter at least three characters.';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return null;
    }

    final emailPattern = RegExp(
      r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@"
      r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
      r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
    );

    return emailPattern.hasMatch(input) ? null : 'Enter a valid email address.';
  }

  static String? validatePhone(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return null;
    }

    if (!RegExp(r'^\+?[0-9\s()-]+$').hasMatch(input)) {
      return 'Enter a valid telephone number.';
    }

    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 7 && digits.length <= 15
        ? null
        : 'Telephone number must contain 7 to 15 digits.';
  }

  static String? validateWebUrl(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return null;
    }

    if (input.contains(RegExp(r'\s'))) {
      return 'Enter a valid URL without spaces.';
    }

    final uri = Uri.tryParse(input);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        !_isValidPublicHost(uri.host)) {
      return 'Enter a complete HTTP or HTTPS URL.';
    }

    return null;
  }

  static String? validateSearch(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'Enter a business name, phone, email or URL.';
    }

    if (input.length < 3) {
      return 'Enter at least three characters.';
    }

    if (input.contains('@')) {
      return validateEmail(input);
    }

    if (RegExp(r'^[+0-9\s()-]+$').hasMatch(input)) {
      return validatePhone(input);
    }

    if (input.contains('://')) {
      return validateWebUrl(input);
    }

    if (RegExp(r'^[A-Za-z0-9.-]+\.[A-Za-z]{2,}([/?#].*)?$').hasMatch(input)) {
      return validateWebUrl('https://$input');
    }

    return null;
  }

  static bool _isValidPublicHost(String host) {
    final normalized = host.toLowerCase();
    if (normalized.isEmpty ||
        normalized.startsWith('.') ||
        normalized.endsWith('.') ||
        !normalized.contains('.')) {
      return false;
    }

    final labels = normalized.split('.');
    final labelPattern = RegExp(r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$');

    if (labels.any((label) => !labelPattern.hasMatch(label))) {
      return false;
    }

    final suffix = labels.last;
    return RegExp(r'^[a-z]{2,63}$').hasMatch(suffix) ||
        suffix.startsWith('xn--');
  }
}
