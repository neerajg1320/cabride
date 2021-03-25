import 'package:cabrider/datamodels/address.dart';
import 'package:flutter/cupertino.dart';

class AppData extends ChangeNotifier {
  Address pickupAddress;
  Address destinationAddress;

  void updatePickupAddress(Address address) {
    pickupAddress = address;
    notifyListeners();
  }

  void updateDestinationAddress(Address address) {
    destinationAddress = address;
    notifyListeners();
  }
}