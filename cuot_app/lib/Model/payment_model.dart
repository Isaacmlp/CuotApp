class PaymentModel {
  final String id;
  final String creditId;
  final double amount;
  final DateTime date;
  final int installmentNumber;
  final String status; // 'paid', 'pending', 'late'
  final String? clientName;
  final String? concept;

  PaymentModel({
    required this.id,
    required this.creditId,
    required this.amount,
    required this.date,
    required this.installmentNumber,
    required this.status,
    this.clientName,
    this.concept,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'].toString(),
      creditId: json['credit_id'].toString(),
      amount: (json['amount'] ?? 0).toDouble(),
      date: DateTime.parse(json['date']),
      installmentNumber: json['installment_number'] ?? 0,
      status: json['status'] ?? 'pending',
      clientName: json['clientName'],
      concept: json['concept'],
    );
  }
}