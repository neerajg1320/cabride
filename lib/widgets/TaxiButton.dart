import 'package:flutter/material.dart';

class TaxiButton extends StatelessWidget {
  // const TaxiButton({
  //   Key key,
  // }) : super(key: key);

  final String title;
  final Color color;
  final Function onPressed;

  TaxiButton({this.title, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: onPressed,
      shape: new RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(20)),
      color: color,
      textColor: Colors.white,
      child: Container(
        height: 50,
        child: Center(
          child: Text(
            title,
            style: TextStyle(fontSize: 18, fontFamily: 'Brand-Bold'),
          ),
        ),
      ),
    );
  }
}