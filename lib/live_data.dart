// Import necessary libraries and files

// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:convert';
import 'dart:typed_data';

import 'package:co2_emission_final/graphs.dart';
import 'package:co2_emission_final/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Declare variables for calculating average of CO2 concentration for each day
double dailySamples = 0;
int dailyCount = 0;
double dailyAvg = 0;
Map<String, dynamic> dailyMap = {};

// Declare variables for calculating average of CO2 concentration for the present day
double todaySamples = 0;
int todayCount = 0;
double todayAvg = 0;
Map<String, dynamic> todayMap = {};

// Create a stateless widget to display the Live Data Page widget.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LiveDataPage()
    );
  }
}

// Create a stateful widget to constantly recieve, update and plot the message of CO2 concentrations sent by the HC-05
class LiveDataPage extends StatefulWidget {
  const LiveDataPage({Key? key}) : super(key: key);

  @override
  State<LiveDataPage> createState() => _LiveDataPageState();
}

class _LiveDataPageState extends State<LiveDataPage> {

  // Variable for getting bluetooth address of the HC-05, stored in shared preferences
  String address = "";

  // Function to obtain address of HC-05 from shared preferences
  void getAddress() async{

    // Create instance of shared preferences and get the string 'address' 
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      address = prefs.getString('address')!;
    });
  }
  
  // Declare variables to keep track of the messages sent, count, formatted data for plotting and state of bluetooth connection
  Map<String, dynamic> full_data = {};
  String full_val = "0";
  int count = 0;
  bool disable = false;
  List<CO2Data> _co2data = [];

  // Instance of the 'user emission' class in the Firebase Firestore database
  final CollectionReference collection = FirebaseFirestore.instance.collection('user emission');

  // Call the recieve_data() function when the page initializes
  @override
  void initState(){
    recieve_data(collection);
    super.initState();
  }

  // Main build widget of the page.
  @override
  Widget build(BuildContext context) {

    // Safe area to prevent interferences of application with OS 
    return SafeArea(
      child: Scaffold(

        // App bar widget
        appBar: AppBar(
          title: const Text("Live CO2 Data"),
        ),

        // Create a drawer (accessible as a hamburger menu on the app bar) widget
        drawer: Drawer(
          child: ListView(
            children: [

              // Head portion visible on the top of the drawer
              const DrawerHeader(
                child: Text("CO2 Emission Tracker")
                ),
              
              // List tile which, when tapped, routes the user to the Home page
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: ((context) => const HomePage()))
                    );
                },
              ),

              // List tile which, when tapped, routes the user to the Live Data page (current page)
              ListTile(
                leading: const Icon(Icons.data_thresholding_rounded),
                title: const Text('Live Data'),
                onTap: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: ((context) => const LiveDataPage()))
                    );
                },
              ),

              // List tile which, when tapped, routes the user to the Graphs page
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Previous Data'),
                onTap: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: ((context) => const GraphPhage()))
                    );
                },
              )
            ],
          ),
        ),

        // Main body of scaffold- a cartesian chart widget
        body: SfCartesianChart(
          
          // Show before and after legend - red color for before values, green color for after values
          legend: Legend(
            isVisible: true,
            ),

          // List of line series to plot on the cartesian chart
          series: <ChartSeries>[

            // Line series to plot CO2 concentration values before filtration. Maps the 'CO2' data values to display on the x and y axes.
            LineSeries<CO2Data, int>(
              name: 'Before',
              dataSource: _co2data, 
              xValueMapper: (CO2Data val1, _) => val1.index, 
              yValueMapper: (CO2Data val1, _) => val1.val1,
              enableTooltip: true,
              color: Colors.red
              ),
            
            // Line series to plot CO2 concentration values after filtration. Maps the 'CO2' data values to display on the x and y axes.
            LineSeries<CO2Data, int>(
              name: 'After',
              dataSource: _co2data, 
              xValueMapper: (CO2Data val2, _) => val2.index, 
              yValueMapper: (CO2Data val2, _) => val2.val2,
              enableTooltip: true,
              color: Colors.green
              )
          ],

          // Format the chart

          // Set both x and y axes to contain numerical values, and allow axes to be adaptive to the values being plotted
          primaryXAxis: NumericAxis(edgeLabelPlacement: EdgeLabelPlacement.shift),
          primaryYAxis: NumericAxis(
            edgeLabelPlacement: EdgeLabelPlacement.shift,

            // Minimum and maximum values seen on the y axis of the chart
            visibleMinimum: 0,
            visibleMaximum: 1500
            ),


        ),

        // Bloetooth icon to connect to HC-05 if connection fails. Turns grey if connected, and blue if not connected.
        // Displays snackbar as an alert saying that the device is connected to the HC-05 on a successful connection
        bottomNavigationBar: IconButton(
            icon: Icon(
              Icons.bluetooth_connected_rounded,
              color: disable? Colors.grey
                : Colors.blue,
              ),
            
            // Call recieve_data() function to attempt to connect to HC-05, and change color of the icon by changing the value of 'disable'
            onPressed: (){
              recieve_data(collection);
              setState(() {
                disable = !disable;
              });
            },
            tooltip: "Connect/Disconnect",
          ),
      )
      );
  }

  // Function to recieve, format and store CO2 concentration data sent from the HC-05
  void recieve_data(CollectionReference collection) async{

    // Instance of shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Attempt to make a connection to the bluetooth address stored in shared preferences
    BluetoothConnection connection = await BluetoothConnection.toAddress(prefs.getString('address'));

    // If device is successfulle connected to the HC-05, set the disable value to true, send a '1' to the HC-05, and show the alert (snackbar) message of successful connection
    // A '1' is constantly sent to the HC-05, as it is programmed to send data only when a '1' is read in the bluetooth serial. 

    if(connection.isConnected){
      setState(() {
        disable = true;
        sendData(connection);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected!'))
        );
      });


      // Constantly listen for input from the bluetooth serial
      connection.input.listen(
        // Recieve input as a Uint 8 List
        (Uint8List data) {

          // Obtain full message of 16 characters from the serial, and send a '1' to the HC-05 to continue recieving data
          data.forEach((element) { 
            sendData(connection);
            String decoded_letter = ascii.decode([element]);
            if(full_val.length < 16){
              full_val += decoded_letter;
            }

            // If full message has been obtained
            else{
              setState(() {
                // Add the value to a map, with the count as the key
                full_data[count.toString()] = full_val;
                count += 1;

                // Format and add data to the _co2Data list, for plotting
                chartData(full_val);

                // Set string to shared preferences
                prefs.setString('fullVal', full_val);

                // Calculate daily average and present day average
                dailyAverage();
                todayAverage();

                // Add the data, daily data and today data values to Firebase Firestore
                collection.doc('data').update(full_data);
                collection.doc('daily_data').update(dailyMap);
                collection.doc('today').set(todayMap);

                // Reset full_val variable to recieve the next message sent by the HC-05
                full_val = "";
              });

            }
          });
        }
        );
    }

    // If there is no sucessful connection, set disable to false, and attempt to connect again
    else{
      setState(() {
        disable = false;
      });
      connection =  await BluetoothConnection.toAddress(address);
    }
  }

// Function to send a '1' to the HC-05.
// Used as a form of conformation that the message from the HC-05 has been recieved.
// The arduino queues the data until a '1' is read in the serial 

void sendData(BluetoothConnection connection) async{
  connection.output.add(Uint8List.fromList([1]));
  await connection.output.allSent;
}
  // List containing instances of CO2Data class, used for plotting
  List<CO2Data> chartData(String val){
    if(val.contains(',')){
      
      // Check if the value (the full message obtained from the HC-05) contains ',' and is a double (contains '.').
      // If yes, create an instance of the CO2Data class and add it to the _co2data list
      // If no, set default values and add to the list
      if(val.split(',').first.contains('.') && val.split(',').last.contains('.')){
        _co2data.add(
          CO2Data(count, double.parse(val.split(',').first), double.parse(val.split(',').last))
        );
      }

      else{
        _co2data.add(
          CO2Data(count, 0.00, 0.00)
        );
      }
    }
    
    // return the _co2data list
    return _co2data;
  }

  // Calculate the average CO2 concentration per day
  void dailyAverage() async{

    // Create instance of shared preferences
    final SharedPreferences pref = await SharedPreferences.getInstance();

    // Try to obtain total daily samples and daily count from shared preferences.
    // If an exception is thrown, set the above values to 0 and 1 respectively.
    try {
      setState(() {
        dailySamples = pref.getDouble('dailySamples')!;
        dailyCount = pref.getInt('dailyCount')!;
      });
    } catch (e) {
      setState(() {
        dailySamples = 0;
        dailyCount = 1;
      });
    }

    // Obtain the present hour, minute and second to determine when to reset the daily average value
    int presMin = DateTime.now().minute;
    int presentHour = DateTime.now().hour;
    int presSecond = DateTime.now().second;

    // Continue calculating th daily average if the time is not 11:59:59 pm
    if(presentHour != 22 && presMin != 59 && presSecond != 59){ 
      setState(() {

        // Try to get the after filtration value from shared preferences and use it to compute daily average
        try {
          dailySamples += double.parse(pref.getString('fullVal')!.split(',').last);
        } catch (e) {
          dailyCount -= 1;
        }
        dailyCount += 1;

        dailyAvg = dailySamples/dailyCount;

        // Format the key of the daily data map and add a key value pair for each day
        String dtNow = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
        dailyMap[dtNow] = dailyAvg.toString();

        // Set daily sample and daily count values to shared preferences for future access.
        // Will be used to calculate the daily average if the app is opened more than once in the same day
        pref.setDouble('dailySamples', dailySamples);
        pref.setInt('dailyCount', dailyCount);
      });
    }

    // If the time is 11:59:59 pm
    else{
      setState(() {
          // Set daily samples and daily count to 0- reset values
          dailySamples = 0;
          dailyCount = 0;

          // Add final value of the day to the daily map
          String dtNow = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
          dailyMap[dtNow] = "${pref.getDouble('dailySamples')!/pref.getInt('dailyCount')!}";

          // Reset values in shared preferences
          pref.setDouble('dailySamples', 0);
          pref.setInt('dailyCount', 0);
        });
    }
  }

  // Calculate average CO2 concentration for the present day
  void todayAverage() async{
    
    // Create instance of shared preferences
    final SharedPreferences pref = await SharedPreferences.getInstance();

    // Try to get today samples today count variables from shared preferences.
    // If an exception is thrown, set the above values to 0 and 1 respectively
    try {
      setState(() {
        todaySamples = pref.getDouble('todaySamples')!;
        todayCount = pref.getInt('todayCount')!;
      });
    } catch (e) {
      setState(() {
        todaySamples = 0;
        todayCount = 1;
      });
    }

    // Obtain the present minute, hour and second to determine the time to reset the above values.
    int presMin = DateTime.now().minute;
    int presentHour = DateTime.now().hour;
    int presSecond = DateTime.now().second;

    // Compute the average while it is not the last second of any hour.
    if(presMin != 59 && presSecond != 59){
      setState(() {
        
        // Add the present sensor value obtained to the today samples value obtained from shared preferences to the to
        try {
          todaySamples += double.parse(pref.getString('fullVal')!.split(',').last);
        } catch (e) {
          todayCount -= 1;
        }

        todayCount += 1;
        todayAvg = todaySamples/todayCount;

        // Set the key value pair for the today map 
        String tNow = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day} ${DateTime.now().hour}:00:00";
        todayMap[tNow] = todayAvg.toString();

        // Set the today samples and today count values to shared preferences, for future reference.
        pref.setDouble('todaySamples', todaySamples);
        pref.setInt('todayCount', todayCount);
      });

    }

    // Reset all values at the end of each hour. Store the previous hour's average to Firebase, and reset the today samples and today count values. 
    else{
      setState(() {
        String tNow = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day} ${DateTime.now().hour}:00:00";
        todayMap[tNow] = "${pref.getDouble('todaySamples')!/pref.getInt('todayCount')!}";
        todaySamples = 0;
        todayCount = 0;

        pref.setDouble('todaySamples', 0);
        pref.setInt('todayCount', 0);
      });
    }

    // Reset the entire map for the day at the end of each day.
    if(presentHour == 23 && presMin == 59 && presSecond == 59){
      setState(() {
        todayMap = {};
      });

      collection.doc('today').delete();

    }

  }

} 

//  Class of CO2Data used for plotting graph using SF Cartesian chart
class CO2Data{
    CO2Data(this.index, this.val1, this.val2);
    final int index;
    final double val1;
    final double val2;
  }