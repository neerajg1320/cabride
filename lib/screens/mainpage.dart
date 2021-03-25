import 'dart:async';
import 'dart:io';

import 'package:cabrider/brand_colors.dart';
import 'package:cabrider/datamodels/directiondetails.dart';
import 'package:cabrider/dataprovider/appdata.dart';
import 'package:cabrider/globalvariable.dart';
import 'package:cabrider/helpers/helpermethods.dart';
import 'package:cabrider/screens/searchpage.dart';
import 'package:cabrider/styles/styles.dart';
import 'package:cabrider/widgets/BrandDivider.dart';
import 'package:cabrider/widgets/ProgressDialog.dart';
import 'package:cabrider/widgets/TaxiButton.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  static const String id = 'mainpage';

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  double searchSheetHeight = (Platform.isIOS) ? 300: 275;
  double rideDetailsSheetHeight = 0;

  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;
  double mapBottomPadding = 0;

  List<LatLng> polylineCoordinates = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _Markers = {};
  Set<Circle> _Circles = {};

  var geoLocator = Geolocator();
  Position currentPosition;
  DirectionDetails tripDirectionDetails;

  bool drawerCanOpen = true;

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
    
    String address = await HelperMethods.findCoordinateAddress(position, context) ;
    print(address);
  }

  void showRideDetailSheet() async {
    await getDirection();

    setState(() {
      searchSheetHeight = 0;
      rideDetailsSheetHeight = (Platform.isIOS) ? 235 : 260;
      mapBottomPadding = (Platform.isAndroid) ? 240 : 230;
      drawerCanOpen = false;
    });
  }


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
              initialCameraPosition: googlePlexPosition,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              polylines: _polylines,
              markers: _Markers,
              circles: _Circles,

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
                  if (drawerCanOpen) {
                    scaffoldKey.currentState.openDrawer();
                  } else {
                    resetApp();
                  }

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
                    child: Icon(
                        drawerCanOpen ? Icons.menu : Icons.arrow_back,
                        color: Colors.black87
                    ),
                  ),
                ),
              ),
            ),

           // Search Sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSize(
                vsync: this,
                duration: new Duration(milliseconds: 150),
                curve: Curves.easeIn,
                child: Container(
                    height: searchSheetHeight,
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
                            onTap: () async {
                              var response = await Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => SearchPage()
                              ));

                              if (response == 'getDirection') {
                                showRideDetailSheet();
                              }

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
              ),
            ),

            // Ride Details Sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSize(
                vsync: this,
                duration: new Duration(milliseconds: 150),
                curve: Curves.easeIn,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
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
                  height: rideDetailsSheetHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18.0),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: BrandColors.colorAccent1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Image.asset('images/taxi.png', height: 70, width: 70),
                                SizedBox(width: 16),
                                Column(
                                  children: [
                                    Text('Taxi', style: TextStyle(fontSize: 18, fontFamily: 'Brand-Bold')),
                                    Text(tripDirectionDetails != null ? tripDirectionDetails.distanceText : '?Km',
                                        style: TextStyle(fontSize: 16, color: BrandColors.colorTextLight)
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(tripDirectionDetails != null ? '\$${HelperMethods.estimateFares(tripDirectionDetails) }': '?Km',
                                    style: TextStyle(fontSize: 18, fontFamily: 'Brand-Bold')
                                ),

                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 22,),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Icon(FontAwesomeIcons.moneyBill, size: 18, color: BrandColors.colorTextLight,),
                              SizedBox(width: 16),
                              Text('Cash'),
                              SizedBox(width: 5),
                              Icon(Icons.keyboard_arrow_down, color: BrandColors.colorTextLight, size: 16),

                            ],
                          ),
                        ),
                        SizedBox(height: 22,),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TaxiButton(
                            title: 'REQUEST CAR',
                            color: BrandColors.colorGreen,
                            onPressed: () {


                            },
                          ),
                        )

                      ],
                    ),
                  )
                ),
              ),
            )
          ],
        )
    );
  }

  Future<void> getDirection() async {
    var pickup = Provider.of<AppData>(context, listen: false).pickupAddress;
    var destination = Provider.of<AppData>(context, listen: false).destinationAddress;

    var pickupLatLng = LatLng(pickup.latitude, pickup.longitude);
    var destinationLatLng = LatLng(destination.latitude, destination.longitude);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => ProgressDialog('Please wait')
    );
    var thisDetails = await HelperMethods.getDirectionDetails(pickupLatLng, destinationLatLng);

    setState(() {
      tripDirectionDetails = thisDetails;
    });

    Navigator.pop(context);

    // print(thisDetails.encodedPoints);
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> results = polylinePoints.decodePolyline(thisDetails.encodedPoints);

    polylineCoordinates.clear();
    if (results.isNotEmpty) {
      results.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    _polylines.clear();

    setState(() {
      Polyline polyline = Polyline(
        polylineId: PolylineId('polyid'),
        color: Color.fromARGB(255, 95, 109, 237),
        points: polylineCoordinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      _polylines.add(polyline);
    });

    LatLngBounds bounds;
    if (pickupLatLng.latitude > destinationLatLng.latitude && pickupLatLng.longitude > destinationLatLng.longitude) {
      bounds = LatLngBounds(
          southwest: destinationLatLng,
          northeast: pickupLatLng
      );
    } else if (pickupLatLng.longitude > destinationLatLng.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(pickupLatLng.latitude, destinationLatLng.longitude),
          northeast: LatLng(destinationLatLng.latitude, pickupLatLng.longitude)
      );
    } else if(pickupLatLng.latitude > destinationLatLng.latitude) {
      bounds = LatLngBounds(
          southwest: LatLng(destinationLatLng.latitude, pickupLatLng.longitude),
          northeast: LatLng(pickupLatLng.latitude, destinationLatLng.longitude)
      );
    } else {
      bounds = LatLngBounds(
          southwest: pickupLatLng,
          northeast: destinationLatLng
      );
    }

    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));

    Marker pickupMarker = Marker(
      markerId: MarkerId('pickup'),
      position: pickupLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: pickup.placeName, snippet: 'My Location')
    );
    Marker destinationMarker = Marker(
        markerId: MarkerId('destination'),
        position: destinationLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: destination.placeName, snippet: 'Destination')
    );

    setState(() {
      _Markers.add(pickupMarker);
      _Markers.add(destinationMarker);
    });

    Circle pickupCirle = Circle(
      circleId: CircleId('pickup'),
      strokeColor: Colors.green,
      strokeWidth: 3,
      radius: 12,
      center: pickupLatLng,
      fillColor: BrandColors.colorGreen,
    );

    Circle destinationCirle = Circle(
      circleId: CircleId('destination'),
      strokeColor: Colors.green,
      strokeWidth: 3,
      radius: 12,
      center: destinationLatLng,
      fillColor: BrandColors.colorAccentPurple,
    );

    setState(() {
      _Circles.add(pickupCirle);
      _Circles.add(destinationCirle);
    });
  }

  resetApp() {
    setState(() {
      polylineCoordinates.clear();
      _polylines.clear();
      _Markers.clear();
      _Circles.clear();
      rideDetailsSheetHeight = 0;
      searchSheetHeight = (Platform.isIOS) ? 300: 275;
      mapBottomPadding = (Platform.isAndroid) ? 240 : 230;
      drawerCanOpen = true;
    });

    setupPositionLocator();
  }
}
