class UserModel {
  final int id;
  final String name;
  final String email;
  final String nim;
  final String batch;
  final String? phoneNumber;
  final bool isAdmin;
  final String? imagePath;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.nim,
    required this.batch,
    this.phoneNumber,
    this.isAdmin = false,
    this.imagePath,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      nim: json['nim'],
      batch: json['batch'],
      phoneNumber: json['phone_number'],
      isAdmin: json['is_admin'] == 1 || json['is_admin'] == true,
      imagePath: json['image_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'nim': nim,
      'batch': batch,
      'phone_number': phoneNumber,
      'is_admin': isAdmin ? 1 : 0,
      'image_path': imagePath,
    };
  }
}
