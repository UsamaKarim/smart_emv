/// Configuration parameters representing the simulated payment terminal for PDOL generation.
class TerminalConfig {
  /// Terminal Country Code. Default: "0840" (United States Numeric ISO 3166-1).
  final String countryCode;

  /// Transaction Currency Code. Default: "0840" (USD Numeric ISO 4217).
  final String currencyCode;

  /// Terminal Capabilities representation. Default: "E0A000" (Standard contactless/chip capabilities).
  final String terminalCapabilities;

  /// Terminal Type identifier. Default: "22" (Financial Institution, Attended POS).
  final String terminalType;

  /// Terminal Transaction Qualifiers (TTQ) indicator. Default: "F620C000" (Standard contactless EMV qualifications).
  final String transactionQualifiers;

  /// Additional Terminal Capabilities description. Default: "8E00B05005".
  final String additionalTerminalCapabilities;

  /// Interface Device (IFD) Serial Number. Default: "3031323334353637" ("01234567" ASCII representation).
  final String interfaceDeviceSerialNumber;

  /// Creates a custom [TerminalConfig] with specified EMV terminal parameters.
  const TerminalConfig({
    required this.countryCode,
    required this.currencyCode,
    required this.terminalCapabilities,
    required this.terminalType,
    required this.transactionQualifiers,
    required this.additionalTerminalCapabilities,
    required this.interfaceDeviceSerialNumber,
  });

  /// Default configuration representing a standard USA terminal accepting USD transactions.
  const TerminalConfig.defaultConfig()
    : countryCode = '0840', // USA BCD
      currencyCode = '0840', // USD BCD
      terminalCapabilities = 'E0A000',
      terminalType = '22',
      transactionQualifiers = 'F620C000',
      additionalTerminalCapabilities = '8E00B05005',
      interfaceDeviceSerialNumber = '3031323334353637';
}
