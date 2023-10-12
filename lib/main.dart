import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_talk/Models/user.dart';
import 'package:swift_talk/Screens/Splash/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:swift_talk/Services/auth.dart';

String Global_error = '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseConfig = {
    "apiKey": "AIzaSyB0ZFxTjOX62Qam5YvAuyjFaftUgSl49bo",
    "authDomain": "swift-talk-co-ab21a.firebaseapp.com",
    "projectId": "swift-talk-co-ab21a",
    "storageBucket": "swift-talk-co-ab21a.appspot.com",
    "messagingSenderId": "30860858253",
    "appId": "1:30860858253:android:c7806a59197658ddfa23c4"
  };


  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: firebaseConfig["apiKey"]!,
      authDomain: firebaseConfig["authDomain"]!,
      projectId: firebaseConfig["projectId"]!,
      storageBucket: firebaseConfig["storageBucket"]!,
      messagingSenderId: firebaseConfig["messagingSenderId"]!,
      appId: firebaseConfig["appId"]!,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamProvider<Current_User?>.value(
      initialData: null,
      value: Auth_Service().user,
      catchError: (_,__) => null,
      child: MaterialApp(
        title: 'Swift Talk',
        debugShowCheckedModeBanner: false,
        home: Splash_Screen(), // Make sure SplashScreen is imported correctly
         //home: PhoneNumbersWidget(),
      ),
    );
  }
}
