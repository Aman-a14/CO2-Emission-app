// Import necessary libraries and files

import 'package:co2_emission_final/local_auth_api.dart';
import 'package:co2_emission_final/wrapper.dart';
import 'package:flutter/material.dart';

// Stateful widget to dynamically check authentication and route the user to the home page on successful authentication
class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {

  // Call auth() when the page initializes
  void initState(){
    auth();
    super.initState();
  }

  // Main build widget of the authentication page
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // App bar
      appBar: AppBar(),

      // Main body of the page- a container widget
      body: Container(

        // Elevated button which attempts to authenticate the user when it is pressed.
        // Used if the authenticate function fails when the page initializes
        child: ElevatedButton(
          onPressed: () async{

            // Call the try_authenticate() function from the LocalAuthApi class in the local_auth_api.dart file
            final isAuthenticated = await LocalAuthApi.try_authenticate();
            if(isAuthenticated){

              // On successful authentication, route the user to the home page
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HomePage())
              );
            }
          },
          child: const Text('Authenticate')),
      ),
    );
  }

  // Function to autnenticate the user.
  void auth() async{

    // Call the try_authenticate() function from the LocalAuthApi class in the local_auth_api.dart file
    final isAuthenticated = await LocalAuthApi.try_authenticate();
    if(isAuthenticated){

      // On successful authentication, route the user to the home page
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const HomePage())
      );
    }
  }
}