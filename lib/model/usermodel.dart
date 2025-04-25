import 'package:firebase_database/firebase_database.dart';

class Usermodel {
  String? id;
  String? name;
  String? email;
  String? phone;

  Usermodel({
    this.id,
    this.name,
    this.email,
    this.phone,
  });

  Usermodel.fromSnapshot(DataSnapshot snapshot) {
    id = snapshot.key;
    final data = snapshot.value as Map;

    name = data["name"];
    email = data["email"];
    phone = data["phone"];
  }
}