// Import necessary libraries and files

import 'package:co2_emission_final/auth_page.dart';
import 'package:co2_emission_final/register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Main function which runs when the app is initialized
void main() async{

  // Ensure that all the widgets are initialized on the screen
  WidgetsFlutterBinding.ensureInitialized();

  // Wait for the Firebase application to initialize
  await Firebase.initializeApp();

  // Create instance of shared preferenes
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Run the app, and route to the Authentication page if the user is registered.
  // To check if the user is registered, it is checked whether the 'name' key of the shared preferences exists. This key is created when the user first registers.
  // If no such key is found, the user is redirected to the Register page.
  runApp(
    MaterialApp(
      home: prefs.containsKey('name') == true? const AuthPage()
        :RegisterPage()
    )
  );
}