<h1 align="center" style="border-bottom: none;">📦⚡️Casdoor flutter example</h1>
<h3 align="center">An example of casdoor-flutter-sdk</h3>

## 	The example uses the following casdoor server:

The server: https://door.casdoor.com/

## Quick Start

- download the code

```bash
 git clone git@github.com:casdoor/casdoor-flutter-example.git
```

- install dependencies

```shell
 flutter pub get
```
## Configure
Initialization requires 6 parameters, which are all str type:
|  Name (in order)   | Must  | Description |
|  ----  | ----  |----  |
| clientId  | Yes | Application.client_id |
| endpoint  | Yes | Casdoor Server Url, such as `door.casdoor.com` |
| organizationName  | Yes | Organization name |
| appName  | Yes | Application name |
| redirectUri  | Yes | URI of Web redirection |
| callbackUrlScheme  | Yes | URL Scheme |

```
  final AuthConfig _config =  AuthConfig(
      clientId: "014ae4bd048734ca2dea",
      endpoint: "door.casdoor.com",
      organizationName: "casbin",
      appName: "app-casnode",
      redirectUri: "http://localhost:9000/callback",
      callbackUrlScheme: "casdoor"
  );
```

## Note here that for Android and Web

### Android
In order to capture the callback url, the following activity needs to be added to your AndroidManifest.xml. Be sure to relpace YOUR_CALLBACK_URL_SCHEME_HERE with your actual callback url scheme.
```
 <activity android:name="com.example.casdoor_flutter_sdk.CallbackActivity"
           android:exported="true">
           <intent-filter android:label="casdoor_flutter_sdk">
               <action android:name="android.intent.action.VIEW" />
               <category android:name="android.intent.category.DEFAULT" />
               <category android:name="android.intent.category.BROWSABLE" />
               <data android:scheme="casdoor" />
           </intent-filter>
       </activity>
```

### Web
On the Web platform an endpoint needs to be created that captures the callback URL and sends it to the application using the JavaScript postMessage() method. In the ./web folder of the project, create an HTML file with the name e.g. callback.html with content:

```
<!DOCTYPE html>
<title>Authentication complete</title>
<p>Authentication is complete. If this does not happen automatically, please
close the window.
<script>
  window.opener.postMessage({
    'casdoor-auth': window.location.href
  }, window.location.origin);
  window.close();
</script>

```
Redirection URL passed to the authentication service must be the same as the URL on which the application is running (schema, host, port if necessary) and the path must point to created HTML file, /callback.html in this case, like  `callbackUri = "${_config.redirectUri}.html"`. The callbackUrlScheme parameter of the authenticate() method does not take into account, so it is possible to use a schema for native platforms in the code.It should be noted that when obtaining a token, cross domain may occur

For the Sign in with Apple in web_message response mode, postMessage from https://appleid.apple.com is also captured, and the authorization object is returned as a URL fragment encoded as a query string (for compatibility with other providers).

## After running, you will see the following  interfaces:
|  **Android**   | **iOS**  | **Web** |
|  ----  | ----  |----  |
| ![Android](screen-andriod.gif) |![iOS](screen-ios.gif)  |![Web](screen-web.gif) |
