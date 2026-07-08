import 'user_model.dart';

class ItemModel {
  final int id;
  final int userId;
  final String type; // 'lost' or 'found'
  final String? imagePath;
  final String name;
  final String category;
  final String location;
  final DateTime date;
  final String description;
  final String status; // 'lost', 'found', 'security', 'lab_assistant', 'returned'
  final String? verificationQuestion;
  final String? custodianType; // 'security', 'lab_assistant'
  final String? custodianName;
  final DateTime createdAt;
  final UserModel? user;

  ItemModel({
    required this.id,
    required this.userId,
    required this.type,
    this.imagePath,
    required this.name,
    required this.category,
    required this.location,
    required this.date,
    required this.description,
    required this.status,
    this.verificationQuestion,
    this.custodianType,
    this.custodianName,
    required this.createdAt,
    this.user,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      imagePath: json['image_path'],
      name: json['name'],
      category: json['category'],
      location: json['location'],
      date: DateTime.parse(json['date']),
      description: json['description'],
      status: json['status'],
      verificationQuestion: json['verification_question'],
      custodianType: json['custodian_type'],
      custodianName: json['custodian_name'],
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
