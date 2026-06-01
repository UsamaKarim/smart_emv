/// Shared utility for detecting NFC transport-level errors that indicate
/// the physical card connection was lost or interrupted. Centralises the
/// detection logic to avoid duplicating the same string-matching heuristic
/// across [EmvProcessor], [AflReader], and [TransactionParser].
class NfcErrorUtils {
  /// Returns true when [error] represents a physical NFC tag loss or an
  /// unrecoverable connection failure that should abort the entire EMV session,
  /// rather than a recoverable application-level response (e.g. file not found).
  ///
  /// Detection is heuristic: it inspects the error message for well-known
  /// keywords produced by [flutter_nfc_kit] and the underlying platform NFC
  /// drivers on Android and iOS.
  static bool isTagLost(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('lost') ||
        msg.contains('closed') ||
        msg.contains('disconnect') ||
        msg.contains('broken') ||
        msg.contains('pipe') ||
        msg.contains('timeout') ||
        msg.contains('cancel') ||
        msg.contains('connection') ||
        msg.contains('communication') ||
        msg.contains('500');
  }
}
