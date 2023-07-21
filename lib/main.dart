import 'dart:convert';

import 'package:casdoor_flutter_sdk/casdoor.dart';
import 'package:casdoor_flutter_sdk/casdoor_flutter_sdk_config.dart';
import 'package:casdoor_flutter_sdk/casdoor_flutter_sdk_platform_interface.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _token = 'User is not logged in';
  Map<String, dynamic> map = {};

  final AuthConfig _config = AuthConfig(
      clientId: "014ae4bd048734ca2dea",
      serverUrl: "https://door.casdoor.com",
      organizationName: "casbin",
      appName: "app-casnode",
      redirectUri: "http://localhost:9000/callback",
      callbackUrlScheme: "casdoor");

  @override
  void initState() {
    super.initState();
  }

  String callbackUri = "";

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> authenticate() async {
    // Get platform information callbackUri.substring(callbackUri.length - 5) != ".html"
    final platform =
        await CasdoorFlutterSdkPlatform.instance.getPlatformVersion() ?? "";

    if (platform == "web") {
      if(callbackUri == "") {
        callbackUri = "${_config.redirectUri}.html";
      } else {

      }
    } else {
      callbackUri = "${_config.callbackUrlScheme}://callback";
    }
    _config.redirectUri = callbackUri;
    print(_config.redirectUri);
    final Casdoor _casdoor = Casdoor(config: _config);
    final result = await _casdoor.show();
    // Get code
    final code = Uri.parse(result).queryParameters['code'] ?? "";
    final response = await _casdoor.requestOauthAccessToken(code);
    _token = jsonDecode(response.body)["access_token"] as String;
    map = _casdoor.decodedToken(_token);

    setState(() {
      _token = 'User logged in';
    });
  }

  Future<void> logout() async {
    setState(() {
      _token = 'User is not logged in';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Casdoor Flutter Example'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Current user: $_token\n'),
                Visibility(
                  visible: _token != 'User is not logged in',
                  child:
                  Column(
                    children: [
                      Image.network(
                        _token == 'User is not logged in' ? "" : map['avatar'],
                        width: 100,
                        height: 100,
                      ),
                      Text('${_token == 'User is not logged in' ? "" : map['name']}'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _token == 'User is not logged in' ? authenticate : logout,
                  child: Text(_token == 'User is not logged in' ? 'Login' : 'Logout'),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.all(20),
                    ),
                    minimumSize: MaterialStateProperty.all<Size>(
                      Size(200, 50),
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
