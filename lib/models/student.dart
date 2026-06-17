/// Student model - stored locally
class Student {
  final String id;
  final String name;
  final String imagePath;

  Student({
    required this.id,
    required this.name,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as String,
        name: json['name'] as String,
        imagePath: json['imagePath'] as String,
      );
}
