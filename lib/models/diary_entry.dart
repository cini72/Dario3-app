import 'dart:convert';

class DiaryEntry {
  final String id;
  String title;
  String content;
  DateTime date;
  String? address;
  String? phone;
  String? email;
  List<String> imagePaths;
  List<String> videoPaths;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.address,
    this.phone,
    this.email,
    List<String>? imagePaths,
    List<String>? videoPaths,
  })  : imagePaths = imagePaths ?? [],
        videoPaths = videoPaths ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'address': address ?? '',
      'phone': phone ?? '',
      'email': email ?? '',
      'imagePaths': imagePaths,
      'videoPaths': videoPaths,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      imagePaths: List<String>.from(map['imagePaths'] ?? []),
      videoPaths: List<String>.from(map['videoPaths'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory DiaryEntry.fromJson(String source) =>
      DiaryEntry.fromMap(json.decode(source));

  String toShareableText() {
    final buffer = StringBuffer();
    if (title.isNotEmpty) buffer.writeln("=== $title ===");
    buffer.writeln("Data: ${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}\n");
    if (content.isNotEmpty) buffer.writeln(content);
    if (address != null && address!.isNotEmpty) {
      buffer.writeln("\nIndirizzo: $address");
    }
    if (phone != null && phone!.isNotEmpty) {
      buffer.writeln("Telefono: $phone");
    }
    if (email != null && email!.isNotEmpty) {
      buffer.writeln("Email: $email");
    }
    return buffer.toString();
  }
}
