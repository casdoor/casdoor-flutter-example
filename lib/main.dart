import 'dart:convert';
import 'dart:io';

import 'package:casdoor_flutter_sdk/casdoor_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _token = '';
  String _selectedAuthType = 'window';
  bool _btnActive = true;
  bool _clearCache = false;

  final AuthConfig _config = AuthConfig(
    clientId: '014ae4bd048734ca2dea',
    serverUrl: 'https://door.casdoor.com',
    organizationName: 'casbin',
    appName: 'app-casnode',
    redirectUri: 'http://localhost:9000/callback.html',
    callbackUrlScheme: 'casdoor',
  );

  @override
  void initState() {
    super.initState();
    restoreToken();
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
  Future<void> login(BuildContext ctx) async {
    setState(() {
      _btnActive = false;
    });

    // Get platform information
    final platform = await CasdoorFlutterSdkPlatform().getPlatformVersion();
    String callbackUri = _config.redirectUri;
    if (platform != 'web') {
      callbackUri = '${_config.callbackUrlScheme}://callback';
    }
    _config.redirectUri = callbackUri;
    final Casdoor casdoor = Casdoor(config: _config);
    String result = '';
    try {
      if (_selectedAuthType == 'window') {
        result = await casdoor.show();
      } else {
        if (!ctx.mounted) return;
        result = await casdoor.showFullscreen(ctx);
      }
    } catch (e) {
      setState(() {
        _btnActive = true;
      });
      return;
    }
    // Get code
    final code = Uri.parse(result).queryParameters['code'] ?? '';
    final response = await casdoor.requestOauthAccessToken(code);
    final token = jsonDecode(response.body)['access_token'] as String;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);

    setState(() {
      _token = token;
      _btnActive = true;
    });
  }

  Future<void> logout() async {
    setState(() {
      _btnActive = false;
    });

    final Casdoor casdoor = Casdoor(config: _config);
    await casdoor.tokenLogout(_token, '', 'logout', clearCache: _clearCache);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', '');

    setState(() {
      _token = '';
      _btnActive = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Casdoor casdoor = Casdoor(config: _config);
    String userName = '';
    String userAvatar = '';
    if (_token != '') {
      Map<String, dynamic> map = casdoor.decodedToken(_token);
      userName = map['name'];
      userAvatar = map['avatar'];
    }

    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Casdoor Flutter Example'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      _token == '' ? 'Current user: (empty)' : 'Current user:',
                    ),
                  ),
                  Visibility(
                    visible: _token != '',
                    child: Column(
                      children: [
                        Image.network(
                          _token == '' ? '' : userAvatar,
                          width: 100,
                          height: 100,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(_token == '' ? '' : userName),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedAuthType,
                    onChanged: ((!Platform.isMacOS) &&
                            (!Platform.isLinux) &&
                            (!Platform.isWindows))
                        ? (String? newValue) {
                            setState(() {
                              _selectedAuthType = newValue!;
                              _clearCache = false;
                            });
                          }
                        : null,
                    items: const [
                      DropdownMenuItem(
                          value: 'window', child: Text('Auth in new window')),
                      DropdownMenuItem(
                          value: 'inapp', child: Text('Auth inside the app')),
                    ],
                  ),
                  ((!Platform.isMacOS) && (!Platform.isLinux))
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _clearCache,
                              onChanged: (bool? newValue) {
                                setState(() {
                                  _clearCache = newValue!;
                                });
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: Text('Clear cache on logout'),
                            ),
                          ],
                        )
                      : Container(),
                  ElevatedButton(
                    onPressed: (_btnActive == true)
                        ? () => (_token == '') ? login(context) : logout()
                        : null,
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        const EdgeInsets.all(20),
                      ),
                      minimumSize: MaterialStateProperty.all<Size>(
                        const Size(200, 50),
                      ),
                    ),
                    child: Text((_token == '') ? 'Login' : 'Logout'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
