/// Represents an EMV Application Identifier (AID) with an associated friendly network name.
class EmvAid {
  /// The hexadecimal string representation of the AID.
  final String hex;

  /// Friendly name of the payment network associated with this AID.
  final String name;

  /// Creates a new [EmvAid] instance with specific [hex] and [name].
  const EmvAid({required this.hex, required this.name});

  // Predefined AIDs for major global card networks

  /// PPSE (Proximity Payment System Environment) - Used to discover available contactless AIDs.
  static const ppse = EmvAid(hex: '325041592E5359532E4444463031', name: 'PPSE');

  /// Visa Credit/Debit (AID: A0000000031010)
  static const visa = EmvAid(hex: 'A0000000031010', name: 'Visa');

  /// Mastercard Credit/Debit (AID: A0000000041010)
  static const mastercard = EmvAid(hex: 'A0000000041010', name: 'Mastercard');

  /// Visa Electron (AID: A0000000032010)
  static const visaElectron = EmvAid(
    hex: 'A0000000032010',
    name: 'Visa Electron',
  );

  /// Maestro Debit (AID: A0000000043060)
  static const maestro = EmvAid(hex: 'A0000000043060', name: 'Maestro');

  /// American Express (AID: A000000025010801)
  static const amex = EmvAid(hex: 'A000000025010801', name: 'American Express');

  /// Discover Card (AID: A0000001523010)
  static const discover = EmvAid(hex: 'A0000001523010', name: 'Discover');

  /// JCB Network (AID: A0000000651010)
  static const jcb = EmvAid(hex: 'A0000000651010', name: 'JCB');

  /// UnionPay Network (AID: A000000333010101)
  static const unionPay = EmvAid(hex: 'A000000333010101', name: 'UnionPay');

  /// Mastercard Cirrus ATM Network (AID: A0000000046000)
  static const cirrus = EmvAid(hex: 'A0000000046000', name: 'Cirrus');

  /// Default list of fallback AIDs utilized when PPSE selection is unavailable or fails.
  static const List<EmvAid> defaultAids = [
    visa,
    mastercard,
    visaElectron,
    maestro,
    amex,
    discover,
    jcb,
    unionPay,
    cirrus,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmvAid && runtimeType == other.runtimeType && hex == other.hex;

  @override
  int get hashCode => hex.hashCode;

  @override
  String toString() => '$name ($hex)';
}
