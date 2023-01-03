import 'package:co2_emission_final/auth_page.dart';
import 'package:co2_emission_final/register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(
    MaterialApp(
      home: prefs.containsKey('name') == true? AuthPage()
        :RegisterPage()
    )
  );
}