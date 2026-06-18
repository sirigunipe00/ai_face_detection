// /// Student model - stored locally
// class Student {
//   final String id;
//   final String name;
//   final String imagePath;

//   Student({
//     required this.id,
//     required this.name,
//     required this.imagePath,
//   });

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'name': name,
//         'imagePath': imagePath,
//       };

//   factory Student.fromJson(Map<String, dynamic> json) => Student(
//         id: json['id'] as String,
//         name: json['name'] as String,
//         imagePath: json['imagePath'] as String,
//       );
// }



/// Student model - stored locally
class Student {
  final String id;
  final String name;
  final String imagePath;
  final List<double> embedding;
  final String createdAt;

  Student({
    required this.id,
    required this.name,
    required this.imagePath,
    this.embedding = const [],
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'embedding': embedding,
        'createdAt': createdAt,
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as String,
        name: json['name'] as String,
        imagePath: json['imagePath'] as String,
        // Older saved records won't have these keys - default safely.
        embedding: (json['embedding'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            const [],
        createdAt: json['createdAt'] as String? ??
            DateTime.now().toIso8601String(),
      );
}