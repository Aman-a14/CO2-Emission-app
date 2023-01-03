import 'dart:convert';
import 'dart:typed_data';

import 'package:co2_emission_final/graphs.dart';
import 'package:co2_emission_final/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:shared_preferences/shared_preferences.dart';

double dailySamples = 0;
int dailyCount = 0;
double dailyAvg = 0;
Map<String, dynamic> dailyMap = {};

double todaySamples = 0;
int todayCount = 0;
double todayAvg = 0;
Map<String, dynamic> todayMap = {};


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

class LiveDataPage extends StatefulWidget {
  const LiveDataPage({Key? key}) : super(key: key);

  @override
  State<LiveDataPage> createState() => _LiveDataPageState();
}

class _LiveDataPageState extends State<LiveDataPage> {

  String address = "";

  void getAddress() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      address = prefs.getString('address')!;
    });
    print('address: $address');
  }

  Map<String, dynamic> full_data = {};
  String full_val = "0";
  int count = 0;

  List<CO2Data> _co2data = [];

  final CollectionReference collection = FirebaseFirestore.instance.collection('user emission');

  bool disable = false;

  @override
  void initState(){
    recieve_data(collection);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Live CO2 Data"),
        ),

        drawer: Drawer(
          child: ListView(
            children: [
              const DrawerHeader(
                child: Text("CO2 Emission Tracker")
                ),
                
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: ((context) => const HomePage()))
                    );
                },
              ),

              ListTile(
                leading: const Icon(Icons.data_thresholding_rounded),
                title: const Text('Live Data'),
                onTap: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: ((context) => const LiveDataPage()))
                    );
                },
              ),

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

        body: SfCartesianChart(
        
          legend: Legend(
            isVisible: true,
            ),

          series: <ChartSeries>[
            LineSeries<CO2Data, int>(
              name: 'Before',
              dataSource: _co2data, 
              xValueMapper: (CO2Data val1, _) => val1.index, 
              yValueMapper: (CO2Data val1, _) => val1.val1,
              enableTooltip: true,
              color: Colors.red
              ),

            LineSeries<CO2Data, int>(
              name: 'After',
              dataSource: _co2data, 
              xValueMapper: (CO2Data val2, _) => val2.index, 
              yValueMapper: (CO2Data val2, _) => val2.val2,
              enableTooltip: true,
              color: Colors.green
              )
          ],
          primaryXAxis: NumericAxis(edgeLabelPlacement: EdgeLabelPlacement.shift),
          primaryYAxis: NumericAxis(
            edgeLabelPlacement: EdgeLabelPlacement.shift,
            visibleMinimum: 0,
            visibleMaximum: 1500
            ),
        ),

        bottomNavigationBar: IconButton(
            icon: Icon(
              Icons.bluetooth_connected_rounded,
              color: disable? Colors.grey
                : Colors.blue,
              ),
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

  void recieve_data(CollectionReference collection) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(address);
    BluetoothConnection connection = await BluetoothConnection.toAddress(prefs.getString('address'));
    final SharedPreferences pref = await SharedPreferences.getInstance();

    if(connection.isConnected){
      setState(() {
        disable = true;
        sendData(connection);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected!'))
        );
      });


      connection.input.listen(
        (Uint8List data) {
          data.forEach((element) { 
            sendData(connection);
            print(element);
            String decoded_letter = ascii.decode([element]);
            if(full_val.length < 16){
              full_val += decoded_letter;
            }
            else{
              setState(() {
                full_data[count.toString()] = full_val;
                count += 1;
                chartData(full_val);

                pref.setString('fullVal', full_val);

                dailyAverage();
                todayAverage();
                print(full_val);
                collection.doc('data').update(full_data);
                collection.doc('daily_data').update(dailyMap);
                collection.doc('today').set(todayMap);
                full_val = "";
              });

            }
          });
        }
        );
    }
    else{
      setState(() {
        disable = false;
      });
      connection =  await BluetoothConnection.toAddress(address);
    }
  }

void sendData(BluetoothConnection connection) async{
  connection.output.add(Uint8List.fromList([1]));
  await connection.output.allSent;
  print('Sent');
}

  List<CO2Data> chartData(String val){
    if(val.contains(',')){

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

    return _co2data;
  }

  void dailyAverage() async{

    final SharedPreferences pref = await SharedPreferences.getInstance();

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

    int presMin = DateTime.now().minute;
    int presentHour = DateTime.now().hour;
    int presSecond = DateTime.now().second;


    if(presentHour != 22 && presMin != 59 && presSecond != 59){ 
      setState(() {
        try {
          dailySamples += double.parse(pref.getString('fullVal')!.split(',').last);
        } catch (e) {
          dailyCount -= 1;
        }
        dailyCount += 1;

        dailyAvg = dailySamples/dailyCount;
        String dtNow = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
        dailyMap[dtNow] = dailyAvg.toString();

        pref.setDouble('dailySamples', dailySamples);
        pref.setInt('dailyCount', dailyCount);
      });
    }

    else{
      setState(() {
          dailySamples = 0;
          dailyCount = 0;
          String dtNow = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
          dailyMap[dtNow] = "${pref.getDouble('dailySamples')!/pref.getInt('dailyCount')!}";

          pref.setDouble('dailySamples', 0);
          pref.setInt('dailyCount', 0);
        });
    }
  }

  void todayAverage() async{
    
    final SharedPreferences pref = await SharedPreferences.getInstance();

    try {
      setState(() {
        todaySamples = pref.getDouble('todaySamples')!;
        todayCount = pref.getInt('todayCount')!;
      });
      // print(todaySamples);
    } catch (e) {
      setState(() {
        todaySamples = 0;
        todayCount = 1;
      });
    }

    int presMin = DateTime.now().minute;
    int presentHour = DateTime.now().hour;
    int presSecond = DateTime.now().second;

    if(presMin != 59 && presSecond != 59){
      setState(() {

        try {
          todaySamples += double.parse(pref.getString('fullVal')!.split(',').last);
        } catch (e) {
          todayCount -= 1;
        }

        todayCount += 1;
        todayAvg = todaySamples/todayCount;

        String tNow = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day} ${DateTime.now().hour}:00:00";
        todayMap[tNow] = todayAvg.toString();
        pref.setDouble('todaySamples', todaySamples);
        pref.setInt('todayCount', todayCount);
      });

    }

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

    if(presentHour == 23 && presMin == 59 && presSecond == 59){
      setState(() {
        todayMap = {};
      });

      collection.doc('today').delete();

    }

  }

} 

class CO2Data{
    CO2Data(this.index, this.val1, this.val2);
    final int index;
    final double val1;
    final double val2;
  }