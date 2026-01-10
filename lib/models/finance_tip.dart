/// Finance tip model (AdviceSlip API)
class FinanceTip {
  final int id;
  final String content;

  FinanceTip({required this.id, required this.content});

  factory FinanceTip.fromJson(Map<String, dynamic> json) {
    return FinanceTip(id: json['id'] as int, content: json['advice'] as String);
  }
}
