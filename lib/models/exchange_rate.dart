/// Exchange rates response model (Frankfurter API)
class ExchangeRates {
  final String base;
  final String date;
  final Map<String, double> rates;

  ExchangeRates({required this.base, required this.date, required this.rates});

  factory ExchangeRates.fromJson(Map<String, dynamic> json) {
    final rawRates = (json['rates'] as Map<String, dynamic>);
    final parsedRates = rawRates.map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );

    return ExchangeRates(
      base: (json['base'] ?? 'EUR').toString(),
      date: (json['date'] ?? '').toString(),
      rates: parsedRates,
    );
  }
}
