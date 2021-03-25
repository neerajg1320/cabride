import 'dart:async';
import 'dart:io';

import 'package:cabrider/brand_colors.dart';
import 'package:cabrider/dataprovider/appdata.dart';
import 'package:cabrider/helpers/helpermethods.dart';
import 'package:cabrider/screens/searchpage.dart';
import 'package:cabrider/styles/styles.dart';
import 'package:cabrider/widgets/BrandDivider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  static const String id = 'mainpage';

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  double searchSheetHeight = 300;

  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;
  double mapBottomPadding = 0;
  var geoLocator = Geolocator();
  Position currentPosition;

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error(
            'Location permissions are denied');
      }
    }

    print("Calling getPosition");

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  void setupPositionLocator() async {
    // Position position = await Geolocator.getCurrentPosition(
    //     desiredAccuracy: LocationAccuracy.bestForNavigation
    // );
    Position position = await _determinePosition();
    currentPosition = position;
    
    LatLng pos = LatLng(position.latitude, position.longitude);
    CameraPosition cp = new CameraPosition(target: pos, zoom: 14);
    mapController.animateCamera(CameraUpdate.newCameraPosition(cp));
    
    String address = await HelperMethods.findCoordinaeAddress(position, context) ;
    print(address);
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        drawer: Container(
          width: 250,
          color: Colors.white,
          child: Drawer(
            child: ListView(
              padding: EdgeInsets.all(0),
              children: [
                Container(
                  color: Colors.white,
                  height: 160,
                  child: DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.white
                    ),
                    child: Row(
                      children: [
                        Image.asset('images/user_icon.png', height: 60, width: 60),
                        SizedBox(width: 15),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Neeraj', style: TextStyle(fontSize: 20, fontFamily: 'Brand-Bold')),
                            SizedBox(height: 5),
                            Text('View Profile'),
                          ],
                        )

                      ],
                    )

                  ),
                ),
                BrandDivider(),
                SizedBox(height: 10),
                ListTile(
                  leading: Icon(OMIcons.cardGiftcard),
                  title: Text('Free Rides', style:kDrawerItemStyle),
                ),
                ListTile(
                  leading: Icon(OMIcons.cardGiftcard),
                  title: Text('Payments', style:kDrawerItemStyle),
                ),
                ListTile(
                  leading: Icon(OMIcons.history),
                  title: Text('Ride History', style:kDrawerItemStyle),
                ),
                ListTile(
                  leading: Icon(OMIcons.cardGiftcard),
                  title: Text('Support', style:kDrawerItemStyle),
                ),
                ListTile(
                  leading: Icon(OMIcons.cardGiftcard),
                  title: Text('About', style:kDrawerItemStyle),
                ),
              ],
            )
          ),
        ),
        body: Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.only(bottom: mapBottomPadding),
              mapType: MapType.normal,
              myLocationButtonEnabled: true,
              initialCameraPosition: _kGooglePlex,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,

              onMapCreated: (GoogleMapController gmapController) {
                _controller.complete(gmapController);
                mapController = gmapController;
                setState(() {
                  mapBottomPadding = Platform.isAndroid ? 300 : 280;
                });

                setupPositionLocator();
              },

            ),
            // Menu Button
            Positioned(
              top: 44,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  scaffoldKey.currentState.openDrawer();

                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5.0,
                          spreadRadius: 0.5,
                          offset: Offset(
                            0.7,
                            0.7,
                          )

                        )
                      ]
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Icon(Icons.menu, color: Colors.black87),
                  ),
                ),
              ),
            ),
            // Search Sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15.0,
                            spreadRadius: 0.5,
                            offset: Offset(
                              0.7,
                              0.7,
                            )
                        )
                      ]
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 5,),
                        Text(
                          'Nice to see you',
                          style: TextStyle(fontSize: 10),
                        ),
                        Text(
                          'Where are you going',
                          style: TextStyle(fontSize: 18, fontFamily: 'Brand-Bold'),
                        ),
                        SizedBox(height: 20,),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) => SearchPage()
                            ));
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 5.0,
                                        spreadRadius: 0.5,
                                        offset: Offset(
                                          0.7,
                                          0.7,
                                        )

                                    )
                                  ]
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.search, color: Colors.blue),
                                    SizedBox(width: 10),
                                    Text('Search Destination'),
                                  ],
                                ),
                              )
                          ),
                        ),
                        SizedBox(height: 22,),
                        Row(
                          children: [
                            Icon(OMIcons.home, color: BrandColors.colorDimText),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add Home'),
                                SizedBox(height:3),
                                Text(
                                  'Your Residential Address',
                                  style: TextStyle(fontSize: 11, color: BrandColors.colorDimText),
                                ),

                              ],
                            )

                          ],
                        ),
                        SizedBox(height: 10,),
                        BrandDivider(),
                        SizedBox(height: 16,),
                        Row(
                          children: [
                            Icon(OMIcons.work, color: BrandColors.colorDimText),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add Work'),
                                SizedBox(height:3),
                                Text(
                                  'Your Office Address',
                                  style: TextStyle(fontSize: 11, color: BrandColors.colorDimText),
                                ),

                              ],
                            )

                          ],
                        ),
                      ],
                    ),
                  )
              ),
            )
          ],
        )
    );
  }
}
