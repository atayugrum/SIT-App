// File: lib/src/data/models/budget_suggestion_model.dart

class BudgetSuggestion {
  final double suggestedBudget;
  final String rationale;
  final int transactionCount;

  BudgetSuggestion({
    required this.suggestedBudget,
    required this.rationale,
    required this.transactionCount,
  });

  factory BudgetSuggestion.fromJson(Map<String, dynamic> json) {
    return BudgetSuggestion(
      suggestedBudget: (json['suggestedBudget'] as num).toDouble(),
      rationale: json['rationale'] as String,
      transactionCount: json['transactionCount'] as int,
    );
  }
}