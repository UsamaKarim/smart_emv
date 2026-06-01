import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'emv_transaction.dart';

/// Strongly-typed EMV payment card data model.
class EmvCard {
  /// Primary Account Number (formatted with spaces).
  final String? pan;

  /// Expiry date formatted as MM/YY.
  final String? expiry;

  /// Full cardholder name parsed from track data or designated EMV tags.
  final String? cardholderName;

  /// Cardholder preferred name if present.
  final String? preferredName;

  /// Card application label (e.g. "VISA DEBIT" or "MASTERCARD").
  final String? label;

  /// Card's IBAN (International Bank Account Number) if available.
  final String? iban;

  /// Card's BIC (Bank Identifier Code) if available.
  final String? bic;

  /// Language preference of the card (typically ISO 2-letter code).
  final String? language;

  /// Issuer country code.
  final String? countryCode;

  /// Currency code of the card application.
  final String? currencyCode;

  /// Application Transaction Counter (ATC) showing transaction count.
  final int? atc;

  /// PIN tries remaining count.
  final int? pinTriesRemaining;

  /// Last Online ATC if present.
  final int? lastOnlineAtc;

  /// Primary Account Number (PAN) sequence number.
  final String? panSequenceNumber;

  /// Form Factor of the card indicator.
  final String? formFactor;

  /// Issuer Application Data (proprietary data).
  final String? issuerData;

  /// Available Offline Spending Amount.
  final String? offlineBalance;

  /// Application Default Action (ADA) settings.
  final String? applicationDefaultAction;

  /// Card Transaction Qualifiers.
  final String? cardTransactionQualifiers;

  /// List of historical transaction records extracted from the card log.
  final List<EmvTransaction>? transactions;

  /// The AID (Application Identifier) that was successfully selected to read this card.
  final String? aid;

  /// Dictionary containing all raw tags parsed in hex for advanced users.
  final Map<String, String> rawTags;

  /// Creates an [EmvCard] instance holding parsed card metadata.
  const EmvCard({
    this.pan,
    this.expiry,
    this.cardholderName,
    this.preferredName,
    this.label,
    this.iban,
    this.bic,
    this.language,
    this.countryCode,
    this.currencyCode,
    this.atc,
    this.pinTriesRemaining,
    this.lastOnlineAtc,
    this.panSequenceNumber,
    this.formFactor,
    this.issuerData,
    this.offlineBalance,
    this.applicationDefaultAction,
    this.cardTransactionQualifiers,
    this.transactions,
    this.aid,
    this.rawTags = const {},
  });

  /// Converts the typed card data model back to a flat string map for backward compatibility.
  Map<String, String> toMap() {
    final map = <String, String>{};
    if (pan != null) map['pan'] = pan!;
    if (expiry != null) map['expiry'] = expiry!;
    if (cardholderName != null) map['cardholder'] = cardholderName!;
    if (preferredName != null) map['preferredName'] = preferredName!;
    if (label != null) map['label'] = label!;
    if (iban != null) map['iban'] = iban!;
    if (bic != null) map['bic'] = bic!;
    if (language != null) map['language'] = language!;
    if (countryCode != null) map['country'] = countryCode!;
    if (currencyCode != null) map['currencyCode'] = currencyCode!;
    if (atc != null) map['atc'] = atc.toString();
    if (pinTriesRemaining != null) map['pinTry'] = pinTriesRemaining.toString();
    if (lastOnlineAtc != null) map['lastOnlineAtc'] = lastOnlineAtc.toString();
    if (panSequenceNumber != null) {
      map['panSequenceNumber'] = panSequenceNumber!;
    }
    if (formFactor != null) map['formFactor'] = formFactor!;
    if (issuerData != null) map['issuerData'] = issuerData!;
    if (offlineBalance != null) map['offlineBalance'] = offlineBalance!;
    if (applicationDefaultAction != null) {
      map['applicationDefaultAction'] = applicationDefaultAction!;
    }
    if (cardTransactionQualifiers != null) {
      map['cardTransactionQualifiers'] = cardTransactionQualifiers!;
    }

    if (transactions != null && transactions!.isNotEmpty) {
      map['transactions'] = transactions!.map((tx) => tx.toString()).join('|');
    }
    if (aid != null) map['aid'] = aid!;

    // Include raw tags in the map prefixed with 'tag_'
    rawTags.forEach((k, v) {
      map['tag_$k'] = v;
    });

    return map;
  }

  /// Creates a copy of this [EmvCard] with the given fields replaced by the new values.
  EmvCard copyWith({
    String? pan,
    String? expiry,
    String? cardholderName,
    String? preferredName,
    String? label,
    String? iban,
    String? bic,
    String? language,
    String? countryCode,
    String? currencyCode,
    int? atc,
    int? pinTriesRemaining,
    int? lastOnlineAtc,
    String? panSequenceNumber,
    String? formFactor,
    String? issuerData,
    String? offlineBalance,
    String? applicationDefaultAction,
    String? cardTransactionQualifiers,
    List<EmvTransaction>? transactions,
    String? aid,
    Map<String, String>? rawTags,
  }) {
    return EmvCard(
      pan: pan ?? this.pan,
      expiry: expiry ?? this.expiry,
      cardholderName: cardholderName ?? this.cardholderName,
      preferredName: preferredName ?? this.preferredName,
      label: label ?? this.label,
      iban: iban ?? this.iban,
      bic: bic ?? this.bic,
      language: language ?? this.language,
      countryCode: countryCode ?? this.countryCode,
      currencyCode: currencyCode ?? this.currencyCode,
      atc: atc ?? this.atc,
      pinTriesRemaining: pinTriesRemaining ?? this.pinTriesRemaining,
      lastOnlineAtc: lastOnlineAtc ?? this.lastOnlineAtc,
      panSequenceNumber: panSequenceNumber ?? this.panSequenceNumber,
      formFactor: formFactor ?? this.formFactor,
      issuerData: issuerData ?? this.issuerData,
      offlineBalance: offlineBalance ?? this.offlineBalance,
      applicationDefaultAction:
          applicationDefaultAction ?? this.applicationDefaultAction,
      cardTransactionQualifiers:
          cardTransactionQualifiers ?? this.cardTransactionQualifiers,
      transactions: transactions ?? this.transactions,
      aid: aid ?? this.aid,
      rawTags: rawTags ?? this.rawTags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmvCard &&
        other.pan == pan &&
        other.expiry == expiry &&
        other.cardholderName == cardholderName &&
        other.preferredName == preferredName &&
        other.label == label &&
        other.iban == iban &&
        other.bic == bic &&
        other.language == language &&
        other.countryCode == countryCode &&
        other.currencyCode == currencyCode &&
        other.atc == atc &&
        other.pinTriesRemaining == pinTriesRemaining &&
        other.lastOnlineAtc == lastOnlineAtc &&
        other.panSequenceNumber == panSequenceNumber &&
        other.formFactor == formFactor &&
        other.issuerData == issuerData &&
        other.offlineBalance == offlineBalance &&
        other.applicationDefaultAction == applicationDefaultAction &&
        other.cardTransactionQualifiers == cardTransactionQualifiers &&
        other.aid == aid &&
        // Deep list equality for transactions (requires EmvTransaction.==)
        listEquals(other.transactions, transactions) &&
        // Deep map equality for rawTags
        mapEquals(other.rawTags, rawTags);
  }

  @override
  int get hashCode {
    return Object.hashAll([
      pan,
      expiry,
      cardholderName,
      preferredName,
      label,
      iban,
      bic,
      language,
      countryCode,
      currencyCode,
      atc,
      pinTriesRemaining,
      lastOnlineAtc,
      panSequenceNumber,
      formFactor,
      issuerData,
      offlineBalance,
      applicationDefaultAction,
      cardTransactionQualifiers,
      aid,
      transactions?.length,
      rawTags.length,
    ]);
  }

  @override
  String toString() {
    return 'EmvCard(label: $label, pan: $pan, expiry: $expiry, cardholder: $cardholderName, aid: $aid)';
  }
}
