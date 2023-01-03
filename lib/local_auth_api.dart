import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthApi{
  static final LocalAuthentication auth = LocalAuthentication();
  
  static Future<bool> hasBiometrics() async{
    try {
      return await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      return false;
    }
  }

  static Future<bool> try_authenticate() async{

    final isAvailable = await hasBiometrics();
    try{return await auth.authenticateWithBiometrics(
      localizedReason: 'Scan to authenticate',
      useErrorDialogs: true,
      stickyAuth: true
      );} on PlatformException catch(e){
        return false;
      }
  }
}