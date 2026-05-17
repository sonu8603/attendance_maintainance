
import 'package:flutter/material.dart';

class NavigationHelper{

  static void push(BuildContext context, Widget screen){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>screen));
  }

  // push replace screen

  static void pushReplace(BuildContext context, Widget screen){
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>screen));
  }

}