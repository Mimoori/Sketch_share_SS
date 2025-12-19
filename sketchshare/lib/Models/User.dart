// class User {
//   final int id;
//   final String name;
//   final String surname;
//   final String nickname;
//   final String avatar;

//   User({
//     required this.id,
//     required this.name,
//     required this.surname,
//     required this.nickname,
//     required this.avatar,
//   });

//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       id: json['id'] ?? 0,
//       name: json['name'] ?? '',
//       surname: json['surname'] ?? '',
//       nickname: json['nickname'] ?? 'User',
//       avatar: json['avatar'] ?? '',
//     );
//   }

//   String get fullName => '$name $surname'.trim();
// }