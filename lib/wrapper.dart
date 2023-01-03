// Import libraries and other files of this project

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co2_emission_final/graphs.dart';
import 'package:co2_emission_final/live_data.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

// Create a stateful widget so that values displayed in the widget can be dynamically changed

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  // Instance of Firebase collection for reading to and writing from the Cloud Firestore database 
  final CollectionReference collection = FirebaseFirestore.instance.collection('user emission');

  // Declare variables

  // For calculating average of CO2 concentration for the present day
  int todayAvg = 0;

  // For calculating average of CO2 concentration for each day
  double dailySamples = 0;
  int dailyCount = 0;
  int dailyAvg = 0;

  // For formatting data obtained from sensors stored in shared preferences
  String fullVal = "";
  double val1 = 0;
  double val2 = 0;

  // Filter efficienvy
  double filterEff = 0;

  // Function which obtains CO2 concentration data stored in shared preferences and Firebase, and calculates certain values to be displayed on the screen.
  void getData() async{

    // Create an instance of shared preferences
    SharedPreferences pref = await SharedPreferences.getInstance();

    // Create a snapshot of the 'daily_doc' document from the initialized Firebase collection
    DocumentSnapshot daily_snapshot = await collection.doc('daily_data').get();

    // Calculate the average for the present day, average for each day, and filter efficiency
    setState(() {
      
      // Get a stored value of the original message recieved from the HC-05 in the live data page
      fullVal = pref.getString('fullVal')!;

      // Obtain value of each sensor from the full message
      val1 = double.tryParse(fullVal.split(',').first)!;
      val2 = double.tryParse(fullVal.split(',').last)!;

      // Calculate present day average by dividing the sum of the samples of the present day by the total number of samples in the day.
      todayAvg = pref.getDouble('dailySamples')!~/pref.getInt('dailyCount')!;

      // Format the data in the 'daily_data' document and store it as a map.
      Map<String, dynamic> daily_data = daily_snapshot.data() as Map<String, dynamic>;


      // Calculate cumulative average of each day by taking the sum of daily samples and dividing by the total number of samples.
      for (var element in daily_data.values) { 
        dailySamples +=  double.parse(element);
      }

      dailyAvg = dailySamples~/daily_data.values.length;

      // Calculate filter efficienvy by taking the percentage difference between the values of the 2 sensors.
      filterEff = ((val2-val1)/val1 * 100).abs();
    });
  }

  // Call the getData() function declared above when the page initializes
  void initState(){
    super.initState();
    getData();
  }

  // Main UI build of the screen
  @override
  Widget build(BuildContext context) {

    // Return a scaffold widget, which allows to create an appbar, body, drawer, etc. on the UI of the application.
    return Scaffold(

      // Create an app bar with the title 'Home'
      appBar: AppBar(
        title: const Text('Home'),
      ),

      // Create a drawer (accessible as a hamburger menu on the app bar) widget
      drawer: Drawer(
          child: ListView(
            children: [

              // Head portion visible on the top of the drawer
              const DrawerHeader(
                child: Text("CO2 Emission Tracker")
                ),
                
              // List tile which, when tapped, routes the user to the Home page (current page)
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: ((context) => const HomePage()))
                    );
                },
              ),

              // List tile which, when tapped, routes the user to the Live data page
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
        
      body: Column(
        children: [
          
          // Format and display the present day's average, cumulative average of each day, and the filter efficiency.
          Row(
            children: [

              // Container to display present day average
              Container(
                width: MediaQuery.of(context).size.width/2,
                child: ListTile(
                  title: Text(
                    '$todayAvg',
                    style: const TextStyle(fontSize: 30),
                    ),
                  subtitle: const Text("Today's average"),
                ),
              ),

              // Container to display cumulative average of each day
              Container(
                width: MediaQuery.of(context).size.width/2,
                child: ListTile(
                  title: Text(
                    '$dailyAvg',
                    style: const TextStyle(fontSize: 30),
                    ),
                  subtitle: const Text("Daily average"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30,),

          // Widget to display filter efficiency as a percent using a circular percent indicator.

          CircularPercentIndicator(
            radius: 100,
            lineWidth: 30,
            backgroundColor: Colors.grey,
            progressColor: Colors.green,
            percent: filterEff / 100,
            animation: true,
            center: Text('${filterEff.toInt()} %'),
            circularStrokeCap: CircularStrokeCap.round,
            footer: Column(
              children: const [
                SizedBox(height: 10,),
                Text('Filter efficiency'),
              ],
            ),
            )
        ],
      )
    );
  }
}