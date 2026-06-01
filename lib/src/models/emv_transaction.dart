/// Represents a historical transaction record read from the EMV card.
class EmvTransaction {
  /// Date of transaction (typically YY/MM/DD).
  final String? date;

  /// Time of transaction (typically HH:MM:SS).
  final String? time;

  /// Parsed formatted transaction amount.
  final String? amount;

  /// ISO numeric currency code (e.g. "0840" for USD).
  final String? currency;

  /// Hex string representing transaction type.
  final String? type;

  /// Raw record payload if it could not be formatted cleanly.
  final String? raw;

  /// Creates an [EmvTransaction] instance holding a historical card transaction record.
  const EmvTransaction({
    this.date,
    this.time,
    this.amount,
    this.currency,
    this.type,
    this.raw,
  });

  @override
  String toString() {
    if (date != null ||
        time != null ||
        amount != null ||
        currency != null ||
        type != null) {
      final buffer = StringBuffer();
      if (date != null) buffer.write('Date: $date');
      if (time != null) {
        buffer.write('${buffer.isEmpty ? '' : ', '}Time: $time');
      }
      if (amount != null) {
        buffer.write('${buffer.isEmpty ? '' : ', '}Amt: $amount');
      }
      if (currency != null) {
        buffer.write('${buffer.isEmpty ? '' : ', '}Cur: $currency');
      }
      if (type != null) {
        buffer.write('${buffer.isEmpty ? '' : ', '}Type: $type');
      }
      return buffer.toString();
    }
    if (raw != null && raw!.isNotEmpty) {
      return 'RAW:$raw';
    }
    return '';
  }

  /// Converts this transaction into a JSON-compatible map.
  /// Only non-null fields are included in the result.
  Map<String, String> toMap() {
    return {
      if (date != null) 'date': date!,
      if (time != null) 'time': time!,
      if (amount != null) 'amount': amount!,
      if (currency != null) 'currency': currency!,
      if (type != null) 'type': type!,
      if (raw != null) 'raw': raw!,
    };
  }

  /// Creates a copy of this [EmvTransaction] with the given fields replaced.
  EmvTransaction copyWith({
    String? date,
    String? time,
    String? amount,
    String? currency,
    String? type,
    String? raw,
  }) {
    return EmvTransaction(
      date: date ?? this.date,
      time: time ?? this.time,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      raw: raw ?? this.raw,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmvTransaction &&
        other.date == date &&
        other.time == time &&
        other.amount == amount &&
        other.currency == currency &&
        other.type == type &&
        other.raw == raw;
  }

  @override
  int get hashCode => Object.hashAll([date, time, amount, currency, type, raw]);
}
