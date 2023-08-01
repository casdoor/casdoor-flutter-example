import 'dart:convert';

import 'package:casdoor_flutter_sdk/casdoor.dart';
import 'package:casdoor_flutter_sdk/casdoor_flutter_sdk_config.dart';
import 'package:casdoor_flutter_sdk/casdoor_flutter_sdk_platform_interface.dart';
import 'package:casdoor_flutter_sdk/casdoor_flutter_sdk_oauth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver{
  String _token = '';

  final AuthConfig _config = AuthConfig(
      clientId: '014ae4bd048734ca2dea',
      serverUrl: 'https://door.casdoor.com',
      organizationName: 'casbin',
      appName: 'app-casnode',
      redirectUri: 'http://localhost:9000/callback.html',
      callbackUrlScheme: 'casdoor');

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    super.initState();
    restoreToken();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      CasdoorOauth.registerWXApi(app_id: 'wx049c70e6c2027b0b', universal_link: 'https://testdomain.com');
    }
  }

  Future<void> restoreToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null) {
      setState(() {
        _token = token;
      });
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> login() async {
    // Get platform information
    final platform =
        await CasdoorFlutterSdkPlatform.instance.getPlatformVersion() ?? '';
    String callbackUri;
    if (platform == 'web') {
      callbackUri = '${_config.redirectUri}';
    } else {
      callbackUri = '${_config.callbackUrlScheme}://callback';
    }
    _config.redirectUri = callbackUri;
    final Casdoor _casdoor = Casdoor(config: _config);
    final result = await _casdoor.show();
    // Get code
    final code = Uri.parse(result).queryParameters['code'] ?? '';
    final response = await _casdoor.requestOauthAccessToken(code);
    final token = jsonDecode(response.body)['access_token'] as String;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);

    setState(() {
      _token = token;
    });
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', '');

    setState(() {
      _token = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final Casdoor _casdoor = Casdoor(config: _config);
    String userName = "";
    String userAvatar = "";
    if (_token != '') {
      Map<String, dynamic> map = _casdoor.decodedToken(_token);
      userName = map['name'];
      userAvatar = map['avatar'];
    }

    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Casdoor Flutter Example'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(_token == '' ? 'Current user: (empty)\n' : 'Current user:\n'),
                Visibility(
                  visible: _token != '',
                  child:
                  Column(
                    children: [
                      Image.network(
                        _token == '' ? '' : userAvatar,
                        width: 100,
                        height: 100,
                      ),
                      Text(_token == '' ? '' : userName),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: (_token == '') ? login : logout,
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.all(20),
                    ),
                    minimumSize: MaterialStateProperty.all<Size>(
                      Size(200, 50),
                    ),
                  ),
                  child: Text((_token == '') ? 'Login' : 'Logout'),
                ),
              ],
            ),
          )),
    );
  }
}
