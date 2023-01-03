// Import necessary libraries and files

// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:co2_emission_final/live_data.dart';
import 'package:co2_emission_final/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

// List of frequency views visible
List<String> frequencies = ['Today', 'Daily'];

// Stateful widget to dynamically change the values in the graph, as it is updated in real time
class GraphPhage extends StatefulWidget {
  const GraphPhage({Key? key,}) : super(key: key);

  @override
  State<GraphPhage> createState() => _GraphPhageState();
}

class _GraphPhageState extends State<GraphPhage> {

  // Instance of Firebase collection
  final CollectionReference collection = FirebaseFirestore.instance.collection('user emission');

  // List of variables for accessing, formatting and displaying average for each day
  Map<String, dynamic> d_data = {};
  List<daily_data> _daily_data = [];
  late DateTime day;
  double daily = 0;

  // List of variables for accessing, formatting and displaying average the present day
  Map<String, dynamic> t_data = {};
  List<today_data> _today_data = [];
  late DateTime t_day;
  double today = 0;

  // Default dropdown value of frequencies
  String dropDownVal = frequencies.first;

  // Call the getData() function when the page is initialized
  @override
  void initState(){
    get_data();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    // Safe area to prevent interference from OS
    return SafeArea(
      child: Scaffold(

        // App bar
        appBar: AppBar(),

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

              // List tile which, when tapped, routes the user to the Graphs page (this page)
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
        
        // Main body of the page- column widget
        body: Column(
          children: [

            // Dropdown to select from different frequencies- today and daily
            DropdownButton<String>(
              value: dropDownVal,
              items: frequencies.map<DropdownMenuItem<String>>(
                (String freq){
                  return DropdownMenuItem<String>(
                  value: freq,
                  child: Text(freq)
                    );
                  }
                ).toList(), 
              onChanged: (String? freq){
                setState(() {
                  // Set the dropDownVal variable to the value selected in the drop down
                  dropDownVal = freq!;
                });
              }
              ),

              // Display the appropriate graph according to the dropdown value selected
              dropDownVal == 'Daily'? displayDaily_data()
              :displayToday_data(),

              // Button to update the data in the graph.
              ElevatedButton(
                onPressed: (){
                  get_data();
                }, 
                child: const Text('Refresh'))
          ],
        ),
      )
      );
  }

  // Function to get data of the present day's average and the average of each day from Firebase
  void get_data() async{
    
    // Get snapshots of data from the 'today' and 'daily_data' documents
    DocumentSnapshot today_snapshot = await collection.doc('today').get();
    DocumentSnapshot daily_snapshot = await collection.doc('daily_data').get();

    // Format daily data to be displayed in the graph
    d_data = daily_snapshot.data() as Map<String, dynamic>;

    d_data.forEach((key, value) {
      setState(() {
        try {
          daily = double.parse(value);
        } catch (e) {
          daily = 0;
        }
        day = DateTime.parse(key);
        // Call the dailyChartdata() function for formatting the data to plot it on the graph
        dailyChartdata(day, daily);
      });
    });

    // Format today data to be displayed in the graph
    t_data = today_snapshot.data() as Map<String, dynamic>;
    t_data.forEach((key, value) { 
      setState(() {
        try {
          today = double.parse(value);
        } catch (e) {
          today = 0;
        }
        t_day = DateTime.parse(key);
        // Call the todayChartdata() function for formatting the data to plot it on the graph
        todayChartData(t_day, today);
      });
    });

  }
  
  // Widget to plot the present day's data
  Widget displayToday_data(){
    return SfCartesianChart(

      // List of line series to plot on the cartesian chart
      series: <ChartSeries>[

        // Column series to plot average of each hour for the present day. Maps the 'todayVal' values to display on the x and y axes.
        ColumnSeries<today_data, DateTime>(
          name: 'Today',
          dataSource: _today_data, 
          xValueMapper: (today_data todayVal, _) => todayVal.index,
          yValueMapper: (today_data todayVal, _) => todayVal.todayVal,
          enableTooltip: true
          ),
      ],

      // Set the x axis as a datetime axis, where the values displayed are of type DateTime
      // Each interval represents 1 hour
      primaryXAxis: DateTimeAxis(
        intervalType: DateTimeIntervalType.hours,
        dateFormat: DateFormat.H(),
        majorGridLines: MajorGridLines(width: 0),
        majorTickLines: MajorTickLines(width: 0)
      ),
    );
  }

  // Widget to plot each day's data
  Widget displayDaily_data(){
    return SfCartesianChart(

      // List of line series to plot on the cartesian chart
      series: <ChartSeries>[

        // Column series to plot average of each day. Maps the 'dailyVal' values to display on the x and y axes.
        ColumnSeries<daily_data, DateTime>(
          name: 'Daily data',
          dataSource: _daily_data, 
          xValueMapper: (daily_data dailyVal, _) => dailyVal.index,
          yValueMapper: (daily_data dailyVal, _) => dailyVal.dailyVal,
          enableTooltip: true
          ),
      ],

      // Set the x axis as a datetime axis, where the values displayed are of type DateTime
      // Each interval represents 1 day
      primaryXAxis: DateTimeAxis(
        intervalType: DateTimeIntervalType.days,
        dateFormat: DateFormat.MMMd(),
        majorGridLines: MajorGridLines(width: 0),
        majorTickLines: MajorTickLines(width: 0)
      ),
    );
  }

  // List containing instances of 'daily_data' class for plotting on graph
  List dailyChartdata(DateTime day, double daily_val){
      // Add instance of daily_data class to the _daily_data list
      _daily_data.add(
        daily_data(day, daily_val)
      );

    // Return the list for plotting
    return _daily_data;
  }

  // List containing instances of 'today_data' class for plotting on graph
  List todayChartData(DateTime t_day, double today_val){
    // Add instance of today_data class to _today_data list
    _today_data.add(
      today_data(t_day, today_val)
    );

    // Return the list for plotting
    return _today_data;
  }
}

// Class for plotting the average for each day
class daily_data{
  daily_data(this.index, this.dailyVal);
  final DateTime index;
  final double dailyVal;
}

// Class for plotting the average for the present day
class today_data{
  today_data(this.index, this.todayVal);
  final DateTime index;
  final double todayVal;
}
