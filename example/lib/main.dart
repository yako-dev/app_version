import 'package:app_version/app_version.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final AppVersion _appVersion = AppVersion();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('App Version Example')),
      body: Center(
        child: FutureBuilder(
          future: _appVersion.calculateInfo(),
          builder: (_, snapshot) {
            if (snapshot.hasData) {
              final Version localVersion = _appVersion.info.localVersion;
              return Text(
                'Local app version: $localVersion',
                style: Theme.of(context).textTheme.headline6,
              );
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
