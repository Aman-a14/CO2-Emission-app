// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:co2_emission_final/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({Key? key}) : super(key: key);

  FlutterBluetoothSerial flutterBlue = FlutterBluetoothSerial.instance;
  bool discover = true;
  String address = "";
  String name = "";
  final TextEditingController _controller = TextEditingController();
  String err = "";
  int public_key = 0;
  int private_key = 0;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  void initState(){
    super.initState();
    discoverDevices(widget.flutterBlue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),

      body: Container(
        child: (widget.discover)? Column(
          children: const [
            CircularProgressIndicator(),
            Text('Discovering devices...')
          ],
        ): pairedDevice(),
      ),
      
    );
  }


  void discoverDevices(FlutterBluetoothSerial bluetoothInst) async{
    await bluetoothInst.startDiscovery().listen((result) { 
      if(result.device.name == 'HC-05'){
        setState(() {
          widget.discover = false;
          widget.address = result.device.address;
        });
        bluetoothInst.cancelDiscovery();

      }
    });
  }

  Widget pairedDevice(){

    final _formKey = GlobalKey<FormState>();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            validator: (val) => val!.isEmpty? 'Enter a name': null,
            controller: widget._controller,
          ),

          ElevatedButton(
            onPressed: () async{
              if(_formKey.currentState!.validate()){
                setState(() {
                  widget.name = widget._controller.text;
                  widget.err = 'Success! You are now registered';
                  sPref(widget.name, widget.address);
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(widget.err))
                );
                
                
                Navigator.of(context).push(
                  MaterialPageRoute(builder: ((context) {
                    return HomePage();
                  })
                ));
              }
            }, 
            child: const Text('Finish setup'))
        ],
      ),
    );
    
  }

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