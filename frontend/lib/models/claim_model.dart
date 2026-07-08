import 'user_model.dart';
import 'item_model.dart';

class ClaimModel {
  final int id;
  final int itemId;
  final int claimantId;
  final String verificationAnswer;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final UserModel? claimant;
  final ItemModel? item;

  ClaimModel({
    required this.id,
    required this.itemId,
    required this.claimantId,
    required this.verificationAnswer,
    required this.status,
    required this.createdAt,
    this.claimant,
    this.item,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      id: json['id'],
      itemId: json['item_id'],
      claimantId: json['claimant_id'],
      verificationAnswer: json['verification_answer'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      claimant: json['claimant'] != null ? UserModel.fromJson(json['claimant']) : null,
      item: json['item'] != null ? ItemModel.fromJson(json['item']) : null,
    );
  }
}
