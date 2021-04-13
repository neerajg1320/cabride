import 'package:cabrider/datamodels/appuser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final String serverKey = 'key=AAAA4AEzLqQ:APA91bGDZXfx6zQqp2-ZUjHgmZH3HJNwv3qbN_uKPrdH43-3qBt10ep3VfS72DDtIOEaQJG7y3iIgIOb_Ed-5OiNILyPhI6lPnIn1ZONv-4jvbIcfk3dnfV-u1VLHmLPbBe1CdJ-Cj_A';
final String mapKey = "AIzaSyBriaQcD5BVaIoZGg3-sdqZr58MjCsTNhg";
final String geoCodingApiKey = "AIzaSyDyGkF3_aKHfo5KUTP4Pm6lsuXMPK1HwTU";

final CameraPosition googlePlexPosition = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);

AppUser currentUserInfo;
User currentFirebaseUser;