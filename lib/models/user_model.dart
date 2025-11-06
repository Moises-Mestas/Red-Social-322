class UserModel {
  final String id;
  final String name;
  final String email;
  final String image;
  final String username;
  final String searchKey;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
    required this.username,
    required this.searchKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Name': name,
      'Email': email,
      'Image': image,
      'username': username,
      'SearchKey': searchKey,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['Id'] ?? '',
      name: map['Name'] ?? '',
      email: map['Email'] ?? '',
      image: map['Image'] ?? '',
      username: map['username'] ?? '',
      searchKey: map['SearchKey'] ?? '',
    );
  }
}
