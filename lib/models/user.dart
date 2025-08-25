class User {
  final String id;
  final String username;
  final String? password;
  final String fullName;
  final String role; // 'admin' or 'driver' or 'manager'

  User({
    required this.id,
    required this.username,
    this.password,
    required this.fullName,
    required this.role,
  });
}
