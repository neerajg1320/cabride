import 'package:cabrider/datamodels/address.dart';
import 'package:cabrider/dataprovider/appdata.dart';
import 'package:cabrider/helpers/requesthelper.dart';
import 'package:connectivity/connectivity.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class HelperMethods {
  static Future<String> findCoordinaeAddress(Position position, context) async {
    String placeAddress = '';

    // NG: 2021-03-25 , code repetition
    // This is used in internet connectivity checks in the Register and Login
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.mobile &&
        connectivityResult != ConnectivityResult.wifi) {
      return placeAddress;
    }

    String url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=AIzaSyDyGkF3_aKHfo5KUTP4Pm6lsuXMPK1HwTU';

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
}