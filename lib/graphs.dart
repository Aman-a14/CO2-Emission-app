import 'package:co2_emission_final/live_data.dart';
import 'package:co2_emission_final/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

List<String> frequencies = ['Today', 'Daily'];

class GraphPhage extends StatefulWidget {
  const GraphPhage({Key? key,}) : super(key: key);

  @override
  State<GraphPhage> createState() => _GraphPhageState();
}

class _GraphPhageState extends State<GraphPhage> {

  final CollectionReference collection = FirebaseFirestore.instance.collection('user emission');

  Map<String, dynamic> d_data = {};
  List<daily_data> _daily_data = [];
  late DateTime day;
  double daily = 0;

  Map<String, dynamic> t_data = {};
  List<today_data> _today_data = [];
  late DateTime t_day;
  double today = 0;

  String dropDownVal = frequencies.first;

  @override
  void initState(){
    get_data();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),

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
                    MaterialPageRoute(builder: ((context) => LiveDataPage()))
                    );
                },
              ),

              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Previous Data'),
                onTap: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: ((context) => GraphPhage()))
                    );
                },
              )
            ],
          ),
        ),
        
        body: Column(
          children: [
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
                  dropDownVal = freq!;
                });
              }
              ),
            
              dropDownVal == 'Daily'? displayDaily_data()
              :displayToday_data(),

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
  void get_data() async{

    DocumentSnapshot today_snapshot = await collection.doc('today').get();
    DocumentSnapshot daily_snapshot = await collection.doc('daily_data').get();

    d_data = daily_snapshot.data() as Map<String, dynamic>;

    d_data.forEach((key, value) {
      setState(() {
        try {
          daily = double.parse(value);
        } catch (e) {
          daily = 0;
        }
        day = DateTime.parse(key);
        dailyChartdata(day, daily);
      });
    });

    t_data = today_snapshot.data() as Map<String, dynamic>;
    t_data.forEach((key, value) { 
      setState(() {
        try {
          today = double.parse(value);
        } catch (e) {
          today = 0;
        }
        t_day = DateTime.parse(key);
        todayChartData(t_day, today);
      });
    });

  }
  
  Widget displayToday_data(){
    return SfCartesianChart(
      series: <ChartSeries>[
        ColumnSeries<today_data, DateTime>(
          name: 'Today',
          dataSource: _today_data, 
          xValueMapper: (today_data todayVal, _) => todayVal.index,
          yValueMapper: (today_data todayVal, _) => todayVal.todayVal,
          enableTooltip: true
          ),
      ],

      primaryXAxis: CategoryAxis(
        // intervalType: DateTimeIntervalType.hours,
        // dateFormat: DateFormat.Hm(),
        majorGridLines: MajorGridLines(width: 0),
        majorTickLines: MajorTickLines(width: 0)
      ),
    );
  }

  Widget displayDaily_data(){
    return SfCartesianChart(
      series: <ChartSeries>[
        ColumnSeries<daily_data, DateTime>(
          name: 'Daily data',
          dataSource: _daily_data, 
          xValueMapper: (daily_data dailyVal, _) => dailyVal.index,
          yValueMapper: (daily_data dailyVal, _) => dailyVal.dailyVal,
          enableTooltip: true
          ),
      ],

      primaryXAxis: DateTimeAxis(
        intervalType: DateTimeIntervalType.days,
        dateFormat: DateFormat.MMMd(),
        majorGridLines: MajorGridLines(width: 0),
        majorTickLines: MajorTickLines(width: 0)
      ),
    );
  }

  List dailyChartdata(DateTime day, double daily_val){
      _daily_data.add(
        daily_data(day, daily_val)
      );
    return _daily_data;
  }

  List todayChartData(DateTime t_day, double today_val){
    _today_data.add(
      today_data(t_day, today_val)
    );

    return _today_data;
  }
}

class daily_data{
  daily_data(this.index, this.dailyVal);
  final DateTime index;
  final double dailyVal;
}

class today_data{
  today_data(this.index, this.todayVal);
  final DateTime index;
  final double todayVal;
}
