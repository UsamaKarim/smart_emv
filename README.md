# smart_emv

A modern, robust, and pure Dart EMV NFC Reader library for Flutter that supports reading credit, debit, and payment cards on **Android & iOS** using raw ISO 7816 / APDU commands.

This package is a complete pure Dart migration and enhancement of the original [emv_nfc_reader](https://pub.dev/packages/emv_nfc_reader) library by abidiahmedcom. By porting all high-level parsing, GPO templates, recursive BER-TLV decoders, and AFL scanners directly to pure Dart, this library provides a single, testable, and cross-platform codebase that works identically on both major mobile operating systems.

## Features

* **Cross-Platform Support**: Read EMV cards on both Android and iOS devices.
* **Pure Dart EMV Parser**: Complete Tag-Length-Value (BER-TLV) recursive parsing, Processing Options (PDOL) building, and AFL records loop directly in Dart.
* **Strongly-Typed Models**: Returns a rich, typed `EmvCard` model (with backward-compatible `toMap()` helper).
* **Robust Card Network Compatibility**: Supported out-of-the-box: Visa, Mastercard, American Express, Discover, JCB, UnionPay, Electron, Maestro, and Cirrus.
* **Transaction Logs Extraction**: Reads and parses historical transaction lists directly from the card log files when supported.
* **Highly Testable**: Core EMV layer has zero external hardware/plugin dependencies. Easily mock the transceiver layer to run unit tests offline.
* **Configurable Terminal Settings**: Customize default terminal capabilities, country codes, currency, and networks.

---

## Installation

Add `smart_emv` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  smart_emv: ^0.0.1
```

---

## Platform Setup

### Android Setup

Add the NFC permission to your `AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

### iOS Setup

1. Add the NFC usage description in your `ios/Runner/Info.plist`:

```xml
<key>NFCReaderUsageDescription</key>
<string>We require NFC access to securely scan and read EMV payment cards.</string>
```

2. Register the ISO 7816 Application Identifiers (AIDs) in your `ios/Runner/Info.plist`. iOS requires AIDs to be explicitly declared before communicating:

```xml
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>325041592E5359532E4444463031</string> <!-- PPSE -->
    <string>A0000000031010</string> <!-- Visa -->
    <string>A0000000032010</string> <!-- Visa Electron -->
    <string>A0000000032020</string> <!-- V PAY -->
    <string>A0000000980840</string> <!-- Visa US Common Debit -->
    <string>A0000000041010</string> <!-- Mastercard -->
    <string>A0000000043060</string> <!-- Maestro -->
    <string>A0000000046000</string> <!-- Cirrus -->
    <string>A0000000042203</string> <!-- Mastercard US Common Debit -->
    <string>A000000025010801</string> <!-- Amex -->
    <string>A0000001523010</string> <!-- Discover -->
    <string>A0000001524010</string> <!-- Discover Common Debit -->
    <string>A0000000651010</string> <!-- JCB -->
    <string>A000000333010101</string> <!-- UnionPay -->
    <string>A0000002771010</string> <!-- Interac -->
    <string>A0000005241010</string> <!-- RuPay -->
    <string>A00000038410</string> <!-- Eftpos -->
</array>
```

3. Enable the NFC Tag Reading capability in Xcode for your runner target. This creates or updates your target's `.entitlements` file containing:

```xml
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>TAG</string>
</array>
```

---

## Quick Start Example

```dart
import 'package:smart_emv/smart_emv.dart';

final _smartEmv = SmartEmv(
  config: const SmartEmvConfig(
    enableLogging: true, // Output APDU logs in debug console
  ),
);

Future<void> scanCard() async {
  // 1. Check NFC status with full detail
  final NfcStatus status = await _smartEmv.getNfcStatus();

  switch (status) {
    case NfcStatus.notSupported:
      print("This device does not have NFC hardware.");
      return;
    case NfcStatus.disabled:
      // Prompt the user to enable NFC.
      // On Android you can open NFC settings using a package like
      // `app_settings` or `url_launcher`:
      //   await launchUrl(Uri.parse('android.settings.NFC_SETTINGS'))
      print("NFC is turned off. Please enable it in Settings.");
      return;
    case NfcStatus.available:
      break; // Ready to scan
  }

  try {
    // 2. Poll and read card details
    final EmvCard card = await _smartEmv.readCard();

    print("Card Number: \${card.pan}");
    print("Expiry Date: \${card.expiry}");
    print("Holder Name: \${card.cardholderName}");
    print("Card Brand:  \${card.label}");

    // Print transaction log if extracted
    if (card.transactions != null) {
      for (var tx in card.transactions!) {
        print("Tx: \${tx.date} - \${tx.amount} \${tx.currency}");
      }
    }
  } on SmartEmvException catch (e) {
    switch (e.code) {
      case SmartEmvErrorCode.timeout:
        print("Scan timed out. Try holding the card still.");
      case SmartEmvErrorCode.userCancelled:
        print("Scan cancelled.");
      default:
        print("Failed to read card: \${e.message} (\${e.code})");
    }
  }
}
```

---

## NFC Status

Use `getNfcStatus()` to get a typed `NfcStatus` enum before scanning. This lets you
distinguish between a device with no NFC hardware and one where NFC is simply toggled off:

| `NfcStatus` | Meaning | Recommended action |
|---|---|---|
| `available` | Hardware present and enabled | Proceed with `readCard()` |
| `disabled` | Hardware present, NFC turned off | Prompt user to open NFC settings |
| `notSupported` | No NFC hardware on this device | Show permanent error message |

> **Tip (Android):** When `NfcStatus.disabled`, you can open the Android NFC settings screen
> using [`app_settings`](https://pub.dev/packages/app_settings) or
> [`url_launcher`](https://pub.dev/packages/url_launcher) from your app:
> ```dart
> // Using url_launcher:
> await launchUrl(Uri.parse('android.settings.NFC_SETTINGS'));
>
> // Using app_settings:
> await AppSettings.openNfcSettings();
> ```
> iOS does not expose an NFC on/off toggle, so `NfcStatus.disabled` is never returned on iOS.

---

## Advanced Configuration

### Android Performance Optimization

`SmartEmvConfig.androidReaderModeFlags` passes flags to Android's `NfcAdapter.enableReaderMode`.
The default value (`0x80 | 0x100`) gives approximately **500ms faster** tag detection by
skipping automatic NDEF discovery, and suppresses the system beep/vibration so you can
implement your own audio/haptic feedback.

```dart
final smartEmv = SmartEmv(
  config: const SmartEmvConfig(
    // FLAG_READER_SKIP_NDEF_CHECK  — faster detection (~500ms gain)
    // FLAG_READER_NO_PLATFORM_SOUNDS — silent; handle beep/haptic yourself
    androidReaderModeFlags: 0x80 | 0x100, // default

    // Or restore Android platform defaults (NDEF check + system sounds):
    // androidReaderModeFlags: 0,
  ),
);
```

This field has no effect on iOS.

---

## Data Fields

The returned `EmvCard` model contains the following strongly-typed fields:

| Field Name | Type | EMV Tag / Origin | Description |
| :--- | :--- | :--- | :--- |
| `pan` | `String?` | `0x5A` or `0x57` | Primary Account Number formatted with spaces (e.g. `"4111 1111 1111 1111"`). |
| `expiry` | `String?` | `0x5F24` or `0x57` | Expiry date formatted as `MM/YY`. |
| `cardholderName` | `String?` | `0x5F20` or `0x56` | Full cardholder name from Tag 5F20 or Track 1 data. |
| `preferredName` | `String?` | `0x9F12` | Application preferred name if different from label. |
| `label` | `String?` | `0x50` | Card application label (e.g. `"VISA DEBIT"`, `"MASTERCARD"`). Defaults to selected AID name. |
| `iban` | `String?` | `0x5F53` | International Bank Account Number if present on card. |
| `bic` | `String?` | `0x5F54` | Bank Identifier Code (BIC/SWIFT) if present on card. |
| `language` | `String?` | `0x5F2D` | Preferred language code (ISO 639-1 two-letter code, e.g. `"en"`). |
| `countryCode` | `String?` | `0x5F28` | Issuer country numeric code (ISO 3166-1). |
| `currencyCode` | `String?` | `0x5F42` | Application currency numeric code (ISO 4217). |
| `atc` | `int?` | `0x9F36` | Application Transaction Counter — total number of transactions on this card. |
| `pinTriesRemaining` | `int?` | `0x9F17` | Remaining offline PIN validation attempts before the card locks. |
| `lastOnlineAtc` | `int?` | `0x9F13` | ATC value at the time of the last online transaction. |
| `panSequenceNumber` | `String?` | `0x5F34` | PAN sequence number differentiating multiple cards with the same PAN. |
| `formFactor` | `String?` | `0x9F6E` | Third-party form factor indicator (e.g. phone, wearable). |
| `issuerData` | `String?` | `0x9F10` | Issuer Application Data (proprietary hex). |
| `offlineBalance` | `String?` | `0x9F5D` | Available offline spending amount if supported by card. |
| `applicationDefaultAction` | `String?` | `0x9F52` | Application Default Action (ADA) settings hex. |
| `cardTransactionQualifiers` | `String?` | `0x9F6C` | Card Transaction Qualifiers (CTQ) byte flags. |
| `aid` | `String?` | PPSE / fallback | The exact AID hex string that was successfully selected to read this card. |
| `transactions` | `List<EmvTransaction>?` | Tags `0x9F4D` + `0x9F4F` | List of historical transaction records from the card log file. |
| `rawTags` | `Map<String, String>` | All parsed tags | Raw hex dictionary of every TLV tag found (e.g. `{"9F36": "0015"}`). Useful for advanced access to tags not mapped above. |

---

## Advanced Usage

### 1. Custom Terminal Configurations
Simulate custom POS terminal tags during dynamic PDOL processing.

```dart
final customTerminal = const TerminalConfig(
  countryCode: '0250',                 // France country BCD
  currencyCode: '0978',                // EUR currency BCD
  terminalCapabilities: 'E0A000',
  terminalType: '22',
  transactionQualifiers: 'F620C000',
  additionalTerminalCapabilities: '8E00B05005',
  interfaceDeviceSerialNumber: '3031323334353637',
);

final _smartEmv = SmartEmv(
  config: SmartEmvConfig(
    terminalConfig: customTerminal,
  ),
);
```

### 2. Injecting a Custom Transceiver
Inject a custom mock or stateful transceiver layer for custom setups or testing.

```dart
class MyCustomTransceiver implements NfcTransceiver {
  @override
  Future<Uint8List> transceive(Uint8List command) async {
    // Write custom transceive logic...
  }

  @override
  Future<void> close() async {
    // Release custom resources...
  }
}

final _smartEmv = SmartEmv(
  config: SmartEmvConfig(
    customTransceiver: MyCustomTransceiver(),
  ),
);
```

---

## Limitations

* **Simulators & Emulators**: NFC reading is a physical-hardware operation. Neither the iOS Simulator nor the Android Emulator support NFC scanning. Physical devices are strictly required for testing.
* **Apple Pay & Google Pay virtual cards**: Tokenized virtual credit cards on smartphones generate one-time-use dynamic keys and restrict sharing of the full primary details (such as the actual cardholder name) over the raw NFC interface for data safety.
* **Cards with Locked Transaction logs**: Some banking institutions lock access to transaction history logs (tags `9F4D`/`9F4F`). The parser will gracefully skip historical transaction reading if these tags are empty or locked by the card chip.

---

## Attribution

This package is a pure Dart fork and enhancement of the original Android-only native Kotlin plugin `emv_nfc_reader` created by [abidiahmedcom](https://github.com/abidiahmedcom/emv_nfc_reader). We sincerely credit their excellent initial native Kotlin card reading research and parser logic which served as the blueprint for this cross-platform Dart implementation.

## License

This project is licensed under the MIT License.
