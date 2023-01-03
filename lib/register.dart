// Import necessary libraries and files

// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:co2_emission_final/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Stateful Widget for dynamically registering the user and routing them to the home page on successful registration
class RegisterPage extends StatefulWidget {
  RegisterPage({Key? key}) : super(key: key);

  // Instance of the FlutterBluetoothSerial class
  FlutterBluetoothSerial flutterBlue = FlutterBluetoothSerial.instance;

  // Variables for enabling bluetooth discovery and storing the user name & bluetooth address
  bool discover = true;
  String address = "";
  String name = "";

  // Instance of a text editing controller to get the data entered in the username input field
  final TextEditingController _controller = TextEditingController();

  // Placeholder error message
  String err = "";

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  // Call the discoverDevices() function when the page initializes
  void initState(){
    super.initState();
    discoverDevices(widget.flutterBlue);
  }

  // Main build widget of the page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with title 'Register'
      appBar: AppBar(
        title: const Text('Register'),
      ),

      // Main body of the page- a container widget
      body: Container(

        // Show a circular progress bar if the app is discovering the desired HC--05 bluetooth device
        // If the device is shown, the pairedDevice() widget is displayed
        child: (widget.discover)? Column(
          children: const [
            CircularProgressIndicator(),
            Text('Discovering devices...')
          ],
        ): pairedDevice(),
      ),
      
    );
  }

  // Function to discover all the bluetooth devices in the vicinity of the device, and connect with the desired HC-05 bluetooth device
  void discoverDevices(FlutterBluetoothSerial bluetoothInst) async{

    // Start bluetooth discovery
    await bluetoothInst.startDiscovery().listen((result) { 

      // Check if name of the bluetooth device is 'HC-05'
      if(result.device.name == 'HC-05'){

        // If the HC-05 device is found, set the discover variable to false, and obtain the bluetooth address of the HC-05
        setState(() {
          widget.discover = false;
          widget.address = result.device.address;
        });

        // Stop bluetooth discovery
        bluetoothInst.cancelDiscovery();

      }
    });
  }

  // Widget to get username from the user
  Widget pairedDevice(){

    final _formKey = GlobalKey<FormState>();

    // Form widget to get user data
    return Form(
      key: _formKey,
      child: Column(
        children: [

          // Text input field with a validator and controller
          // The validator ensures that the value in the input field is not null
          // The controller is used to obtain the data entered by the user when the submit button is clicked

          TextFormField(
            validator: (val) => val!.isEmpty? 'Enter a name': null,
            controller: widget._controller,
          ),

          // Submit button widget, which validates and stores input entered by the user
          ElevatedButton(
            onPressed: () async{
              if(_formKey.currentState!.validate()){
                setState(() {
                  widget.name = widget._controller.text;
                  widget.err = 'Success! You are now registered';
                  sPref(widget.name, widget.address);
                });
                
                // Show a success message to the user on successful registration
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(widget.err))
                );
                
                // Route the user to the Home Page on successful registration
                Navigator.of(context).push(
                  MaterialPageRoute(builder: ((context) {
                    return const HomePage();
                  })
                ));
              }
            }, 
            child: const Text('Finish setup'))
        ],
      ),
    );
    
  }

  // Function to store the user name, bluetooth address, and other variables for calculating trends in shared preferences.
  void sPref(String name, String address) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('name', name);
    prefs.setString('address', address);
    prefs.setDouble('todaySamples', 0);
    prefs.setInt('todayCount', 0);
    prefs.setDouble('dailySamples', 0);
    prefs.setInt('dailyCount', 0);
    prefs.setString('fullVal',"0,0");
  }
}