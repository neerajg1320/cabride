import 'package:firebase_database/firebase_database.dart';

class AppUser {
  String fullName;
  String email;
  String phone;
  String id;

  AppUser({
    this.fullName,
    this.email,
    this.phone,
    this.id,
  });

  AppUser.fromSnapshot(DataSnapshot snapshot) {
    id = snapshot.key;
    phone = snapshot.value['phone'];
    email = snapshot.value['email'];
    fullName = snapshot.value['fullname'];
  }
}