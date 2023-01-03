// Import necessary libraries

// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

// Class to provide local authentication service

class LocalAuthApi{

  // Instance of the LocalAuthentication class
  static final LocalAuthentication auth = LocalAuthentication();
  
  // check if biometrics can be used to authenticate
  static Future<bool> hasBiometrics() async{
    try {
      return await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      return false;
    }
  }

  // Future boolean to authenticate
  static Future<bool> try_authenticate() async{
    
    // Check if user can authenticate using biometrics
    final isAvailable = await hasBiometrics();

    // Check for user authentication when this function is called
    // Return true on successful authentication, false if not
    try{return await auth.authenticateWithBiometrics(
      localizedReason: 'Scan to authenticate',
      useErrorDialogs: true,
      stickyAuth: true
      );} on PlatformException catch(e){
        return false;
      }
  }
}