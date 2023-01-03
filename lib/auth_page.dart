import 'package:co2_emission_final/local_auth_api.dart';
import 'package:co2_emission_final/wrapper.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {

  void initState(){
    auth();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: ElevatedButton(
          onPressed: () async{
            final isAuthenticated = await LocalAuthApi.try_authenticate();
            if(isAuthenticated){
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => HomePage())
              );
            }
          },
          child: Text('Authenticate')),
      ),
    );
  }

  void auth() async{
    final isAuthenticated = await LocalAuthApi.try_authenticate();
    if(isAuthenticated){
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => HomePage())
      );
    }
  }
}