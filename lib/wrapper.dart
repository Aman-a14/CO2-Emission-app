import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co2_emission_final/graphs.dart';
import 'package:co2_emission_final/live_data.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final CollectionReference collection = FirebaseFirestore.instance.collection('user emission');

  int todayAvg = 0;

  double dailySamples = 0;
  int dailyCount = 0;
  int dailyAvg = 0;

  String fullVal = "";
  double val1 = 0;
  double val2 = 0;
  double filterEff = 0;

  bool auth_check = false;

  void getData() async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    DocumentSnapshot daily_snapshot = await collection.doc('daily_data').get();

    setState(() {
      
      fullVal = pref.getString('fullVal')!;

      val1 = double.tryParse(fullVal.split(',').first)!;
      val2 = double.tryParse(fullVal.split(',').last)!;

      todayAvg = pref.getDouble('dailySamples')!~/pref.getInt('dailyCount')!;
      Map<String, dynamic> daily_data = daily_snapshot.data() as Map<String, dynamic>;

      for (var element in daily_data.values) { 
        dailySamples +=  double.parse(element);
      }

      dailyAvg = dailySamples~/daily_data.values.length;

      filterEff = ((val2-val1)/val1 * 100).abs();
    });
  }

  void initState(){
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {

    // final user = Provider.of<UserData>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
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
        
      body: Column(
        children: [
          
          Row(
            children: [
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