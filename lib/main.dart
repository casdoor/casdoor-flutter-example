import 'dart:convert';

import 'package:casdoor_flutter_sdk/casdoor_flutter_sdk.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  // On Linux and Windows the sign-in window runs in a separate Flutter engine
  if (!kIsWeb && runWebViewTitleBarWidget(args)) {
    return;
  }
  runApp(const MyApp());
}

// The Casdoor application, the defaults are the public demo server https://door.casdoor.com
final AuthConfig casdoorConfig = AuthConfig(
  clientId: '014ae4bd048734ca2dea',
  serverUrl: 'https://door.casdoor.com',
  organizationName: 'casbin',
  appName: 'app-casnode',
  // must be in the Redirect URLs of the application.
  // Native platforms: the custom scheme. Web: web/callback.html of this app.
  redirectUri:
      kIsWeb ? 'http://localhost:9000/callback.html' : 'casdoor://callback',
  callbackUrlScheme: 'casdoor',
);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _accessToken = '';
  String _idToken = '';
  String _message = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _restoreTokens();
  }

  Future<void> _restoreTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token') ?? '';
    // an expired token means signing in again
    if (accessToken.isEmpty ||
        Casdoor(config: casdoorConfig).isTokenExpired(accessToken)) {
      return;
    }
    setState(() {
      _accessToken = accessToken;
      _idToken = prefs.getString('id_token') ?? '';
    });
  }

  Future<void> _saveTokens(String accessToken, String idToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('id_token', idToken);
    setState(() {
      _accessToken = accessToken;
      _idToken = idToken;
    });
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _message = '';
    });
    // the same instance signs in and requests the token,
    // it holds the PKCE code verifier, the nonce and the state of this sign-in
    final casdoor = Casdoor(config: casdoorConfig);
    try {
      final callbackUrl = await casdoor.show(scope: 'openid profile email');
      if (!casdoor.isState(callbackUrl)) {
        throw Exception('invalid state, please sign in again');
      }
      final params = Uri.parse(callbackUrl).queryParameters;
      if (params['error'] != null) {
        throw Exception(params['error_description'] ?? params['error']);
      }

      final response = await casdoor.requestOauthAccessToken(
        params['code'] ?? '',
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = body['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception(body['error_description'] ?? response.body);
      }
      await _saveTokens(accessToken, body['id_token'] as String? ?? '');
    } on CasdoorAuthCancelledException {
      setState(() => _message = 'Sign-in cancelled');
    } catch (e) {
      setState(() => _message = 'Failed to sign in: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    try {
      // ends the Casdoor session, and clears the cookies of the sign-in window
      await Casdoor(config: casdoorConfig)
          .tokenLogout(_idToken, null, 'logout', clearCache: true);
    } catch (e) {
      // the Casdoor session may already have ended
    }
    await _saveTokens('', '');
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> claims = _accessToken.isEmpty
        ? {}
        : Casdoor(config: casdoorConfig).decodedToken(_accessToken);
    final String avatar = claims['avatar'] as String? ?? '';

    return MaterialApp(
      title: 'Casdoor Flutter Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Casdoor Flutter Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_accessToken.isEmpty)
                const Text('Not signed in')
              else ...[
                if (avatar.isNotEmpty)
                  Image.network(avatar, width: 100, height: 100),
                const SizedBox(height: 12),
                Text('${claims['displayName'] ?? ''} (${claims['name']})'),
                Text(claims['email'] as String? ?? ''),
              ],
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _message,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    _busy ? null : (_accessToken.isEmpty ? _login : _logout),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: Text(_accessToken.isEmpty ? 'Login' : 'Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
