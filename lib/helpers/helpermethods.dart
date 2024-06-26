import 'dart:convert';
import 'dart:math';

import 'package:cabrider/datamodels/address.dart';
import 'package:cabrider/datamodels/appuser.dart';
import 'package:cabrider/datamodels/directiondetails.dart';
import 'package:cabrider/dataprovider/appdata.dart';
import 'package:cabrider/globalvariable.dart';
import 'package:cabrider/helpers/requesthelper.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class HelperMethods {
  static void getCurrentUserInfo() async {
    User currentFirebaseUser = FirebaseAuth.instance.currentUser;
    String userId = currentFirebaseUser.uid;
    // String userId = 'zIRMfZ2CsaPAfEjK9JUjaRIjTQB3';

    DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users/$userId');
    userRef.once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        currentUserInfo = AppUser.fromSnapshot(snapshot);

        print('User Details:');
        print(currentUserInfo);
      }
    });
  }

  static Future<String> findCoordinateAddress(Position position, context) async {
    String placeAddress = '';

    // NG: 2021-03-25 , code repetition
    // This is used in internet connectivity checks in the Register and Login
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.mobile &&
        connectivityResult != ConnectivityResult.wifi) {
      return placeAddress;
    }

    String url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${geoCodingApiKey}';

    var response = await RequestHelper.getRequest(url);
    if (response != 'failed') {
      placeAddress = response['results'][0]['formatted_address'];
      Address pickupAddress = new Address(
        latitude: position.latitude,
        longitude: position.longitude,
        placeName: placeAddress,
      );

      Provider.of<AppData>(context, listen: false).updatePickupAddress(pickupAddress);
    }

    return placeAddress;
  }

  static Future<DirectionDetails> getDirectionDetails(LatLng startPosition, LatLng endPosition) async {
    String directionMode = 'driving';
    String url = "https://maps.googleapis.com/maps/api/directions/json?origin=${startPosition.latitude},${startPosition.longitude}&destination=${endPosition.latitude},${endPosition.longitude}&mode=$directionMode&key=$geoCodingApiKey";

    var response = await RequestHelper.getRequest(url);

    if (response == 'failed') {
      return null;
    }

    DirectionDetails directionDetails = DirectionDetails(
      distanceText: response['routes'][0]['legs'][0]['distance']['text'],
      distanceValue: response['routes'][0]['legs'][0]['distance']['value'],
      durationText: response['routes'][0]['legs'][0]['duration']['text'],
      durationValue: response['routes'][0]['legs'][0]['duration']['value'],
      encodedPoints: response['routes'][0]['overview_polyline']['points']
    );

    return directionDetails;
  }

  static int estimateFares(DirectionDetails details) {
    double perKm = 0.3;
    double perMin = 0.2;
    double baseFare = 3;

    double distanceFare = (details. distanceValue/1000) * perKm;
    double timeFare = (details.durationValue/60) * perMin;

    double totalFare = baseFare + distanceFare + timeFare;

    return totalFare.truncate();
  }

  static double generateRandomNumber(int max) {
    var randomGenerator = Random();
    int radInt = randomGenerator.nextInt(max);
    return radInt.toDouble();
  }

  static void sendNotification(String token, context, rideId) async {
    var destination = Provider.of<AppData>(context, listen: false).destinationAddress;
    Map<String, String> headerMap = {
      'Content-Type': 'application/json',
      'Authorization': serverKey,
    };

    Map notificationMap = {
      'title': 'NEW TRIP REQUEST',
      'body': 'Destination, ${destination.placeName}'
    };

    Map dataMap = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': 1,
      'status': 'done',
      'ride_id': rideId,
    };

    Map bodyMap = {
      'notification': notificationMap,
      'data': dataMap,
      'priority': 'high',
      'to': token,
    };

    var response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: headerMap,
      body: jsonEncode(bodyMap),
    );

    print('Response Body: ${response.body}');
  }
}