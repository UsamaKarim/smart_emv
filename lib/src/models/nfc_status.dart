/// Represents the three possible NFC hardware states on a device.
///
/// Use [SmartEmv.getNfcStatus] to retrieve the current state before
/// initiating a card scan. This enum provides more context than a plain
/// [bool], enabling the calling application to distinguish between a device
/// with no NFC hardware and one where NFC is simply toggled off.
///
/// ### Typical usage
/// ```dart
/// final status = await smartEmv.getNfcStatus();
/// switch (status) {
///   case NfcStatus.available:
///     final card = await smartEmv.readCard();
///   case NfcStatus.disabled:
///     // Prompt user to enable NFC in Settings.
///     // On Android you can open settings via:
///     //   await app_settings.AppSettings.openNfcSettings()
///     // or:
///     //   await url_launcher.launchUrl(Uri.parse('android.settings.NFC_SETTINGS'))
///   case NfcStatus.notSupported:
///     // Show a permanent "NFC not supported" message.
/// }
/// ```
enum NfcStatus {
  /// NFC hardware is present and enabled — ready to initiate a scan.
  available,

  /// NFC hardware is present on the device but is currently turned off in
  /// system settings. The user can enable it without any hardware changes.
  ///
  /// **Android**: Direct the user to open NFC settings.
  /// **iOS**: This state is not reachable — iOS NFC is always managed by the
  /// system and does not expose an on/off toggle to the user.
  disabled,

  /// The device does not have NFC hardware. Scanning is permanently unavailable.
  notSupported,
}
