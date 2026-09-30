enum PaymentRating {
  excellent,
  good,
  average,
  needsAttention,
  noHistory,
}

class PaymentRatingResult {
  final PaymentRating rating;
  final int score;
  final int totalPayments;
  final int onTimePayments;
  final int latePayments;
  final double onTimeRate;

  const PaymentRatingResult({
    required this.rating,
    required this.score,
    required this.totalPayments,
    required this.onTimePayments,
    required this.latePayments,
    required this.onTimeRate,
  });
}

/// Calculates a simple, explainable customer payment rating.
/// The rating is based on payment timing, not subjective/manual scoring.
PaymentRatingResult calculatePaymentRating({
  required int totalPayments,
  required int onTimePayments,
  required int latePayments,
}) {
  if (totalPayments <= 0) {
    return const PaymentRatingResult(
      rating: PaymentRating.noHistory,
      score: 0,
      totalPayments: 0,
      onTimePayments: 0,
      latePayments: 0,
      onTimeRate: 0,
    );
  }

  final safeTotal = totalPayments < 0 ? 0 : totalPayments;
  final safeOnTime = onTimePayments.clamp(0, safeTotal);
  final safeLate = latePayments.clamp(0, safeTotal - safeOnTime);
  final rate = safeTotal == 0 ? 0.0 : safeOnTime / safeTotal;
  final score = (rate * 100).round();

  final rating = rate >= .90
      ? PaymentRating.excellent
      : rate >= .75
          ? PaymentRating.good
          : rate >= .50
              ? PaymentRating.average
              : PaymentRating.needsAttention;

  return PaymentRatingResult(
    rating: rating,
    score: score,
    totalPayments: safeTotal,
    onTimePayments: safeOnTime,
    latePayments: safeLate,
    onTimeRate: rate,
  );
}
