import 'package:cabrider/brand_colors.dart';
import 'package:cabrider/screens/mainpage.dart';
import 'package:cabrider/screens/registrationpage.dart';
import 'package:cabrider/widgets/ProgressDialog.dart';
import 'package:cabrider/widgets/TaxiButton.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  static const String id = 'login';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  void showSnackBar(String title) {
    final snackbar = SnackBar(
        content: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        )
    );
    scaffoldKey.currentState.showSnackBar(snackbar);
  }

  var emailController = TextEditingController(text: 'neeraj@abc.com');

  var passwordController = TextEditingController(text: 'password');

  void loginUser() async {
    showDialog(
      barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => ProgressDialog('Login in progress'),
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text,
          password:passwordController.text
      );

      Navigator.pop(context);

      // Verify user information from the users table
      final userId = userCredential.user.uid;
      DatabaseReference dbref = FirebaseDatabase.instance.reference().child('users/${userId}');
      dbref.once().then((DataSnapshot snapshot) {
        if (snapshot.value != null) {
          print('Login Successful:');
          print(snapshot.value);

          // Take the user to main page
          Navigator.pushNamedAndRemoveUntil(context, MainPage.id, (route) => false);
        } else {
          print('User Information not found');
        }
      });


    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);

      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(
                  height: 70,
                ),
                Image(
                  image: AssetImage('images/logo.png'),
                  alignment: Alignment.center,
                  height: 100,
                  width: 100,
                ),
                SizedBox(
                  height: 40,
                ),
                Text(
                  'Sign in as a Rider',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontFamily: 'Brand-Bold'),
                ),
                Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: TextStyle(
                              fontSize: 14.0,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 10.0,
                            )),
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              fontSize: 14.0,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 10.0,
                            )),
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      TaxiButton(
                        title: 'LOGIN',
                        color: BrandColors.colorGreen,
                        onPressed: () async {
                          // Check Network Connectivity
                          var connectivityResult = await Connectivity().checkConnectivity();

                          // NG: 2021-03-24 5:41pm
                          // The following check has to be corrected
                          if (connectivityResult != ConnectivityResult.mobile
                              && connectivityResult != ConnectivityResult.wifi) {
                            showSnackBar('No Internet Connectivity');
                          }

                          // Data Validation
                          if (!emailController.text.contains('@')) {
                            showSnackBar('Please provide a valid email');
                            return;
                          }
                          if (passwordController.text.length < 6) {
                            showSnackBar('Please provide a valid password');
                            return;
                          }

                          loginUser();
                        },
                      )
                    ],
                  ),
                ),
                FlatButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, RegistrationPage.id, (route) => false);
                    },
                    child: Text("Don't have an account, sign up here")
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}


