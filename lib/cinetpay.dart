library cinetpay;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:url_launcher/url_launcher.dart';

class CinetPayCheckout extends StatefulWidget {
  final String? title;
  final TextStyle? titleStyle;
  final Color? titleBackgroundColor;
  final Map<String, dynamic>? configData;
  final Map<String, dynamic>? paymentData;
  final Function(Map<String, dynamic>)? waitResponse;
  final Function(Map<String, dynamic>)? onError;

  const CinetPayCheckout({
    Key? key,
    this.title,
    this.titleStyle,
    this.titleBackgroundColor,
    required this.configData,
    required this.paymentData,
    required this.waitResponse,
    required this.onError,
  }) : super(key: key);

  @override
  CinetPayCheckoutState createState() => CinetPayCheckoutState();
}

class CinetPayCheckoutState extends State<CinetPayCheckout> {
  late WebViewController _controller;
  final Uri wave = Uri.parse("https://play.google.com/store/apps/details?id=com.wave.personal");

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            // Remove this line as we're now using onload in the HTML
            // _controller.runJavaScript('initializeCinetPay()');
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://play.google.com/')) {
              playStore();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (JavaScriptMessage message) {
          handleJavaScriptMessage(message.message);
        },
      )
      ..loadHtmlString(_generateHtml());
  }


  String _generateHtml() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        #debug { background-color: #f0f0f0; padding: 10px; margin-top: 20px; }
      </style>
      <script>
        function loadScript(url, callback) {
          var script = document.createElement("script");
          script.type = "text/javascript";
          script.onload = function() {
            document.getElementById('debug').innerHTML += '<p>CinetPay SDK loaded successfully</p>';
            callback();
          };
          script.onerror = function() {
            console.error("Failed to load CinetPay SDK");
            document.getElementById('debug').innerHTML += '<p>Failed to load CinetPay SDK</p>';
            Flutter.postMessage(JSON.stringify({type: 'error', data: {message: "Failed to load CinetPay SDK"}}));
          };
          script.src = url;
          document.getElementsByTagName("head")[0].appendChild(script);
        }

        function initializeCinetPay() {
          document.getElementById('debug').innerHTML += '<p>Initializing CinetPay...</p>';
          loadScript("https://cdn.cinetpay.com/seamless/latest/main.js", function() {
            if (typeof CinetPay === 'undefined') {
              console.error("CinetPay is still undefined after loading the script");
              document.getElementById('debug').innerHTML += '<p>CinetPay is undefined after loading</p>';
              Flutter.postMessage(JSON.stringify({type: 'error', data: {message: "CinetPay is undefined after loading"}}));
              return;
            }
            document.getElementById('debug').innerHTML += '<p>CinetPay initialized, starting checkout...</p>';
            checkout();
          });
        }

        function checkout() {
          var configData = ${jsonEncode(widget.configData)};
          var paymentData = ${jsonEncode(widget.paymentData)};
          
          document.getElementById('debug').innerHTML += '<p>Config Data: ' + JSON.stringify(configData) + '</p>';
          document.getElementById('debug').innerHTML += '<p>Payment Data: ' + JSON.stringify(paymentData) + '</p>';
          
          try {
            CinetPay.setConfig(configData);
            CinetPay.getCheckout(paymentData);
            
            CinetPay.waitResponse(function(data) {
              document.getElementById('debug').innerHTML += '<p>CinetPay Response: ' + JSON.stringify(data) + '</p>';
              Flutter.postMessage(JSON.stringify({type: 'finished', data: data}));
            });
            
            CinetPay.onError(function(data) {
              document.getElementById('debug').innerHTML += '<p>CinetPay Error: ' + JSON.stringify(data) + '</p>';
              Flutter.postMessage(JSON.stringify({type: 'error', data: data}));
            });
          } catch (error) {
            document.getElementById('debug').innerHTML += '<p>Error in CinetPay setup: ' + error.toString() + '</p>';
            Flutter.postMessage(JSON.stringify({type: 'error', data: {message: "Error in CinetPay setup", description: error.toString()}}));
          }
        }

        window.onerror = function(message, source, lineno, colno, error) {
          console.error("JavaScript Error:", message, "at", source, ":", lineno);
          document.getElementById('debug').innerHTML += '<p>JavaScript Error: ' + message + ' at ' + source + ':' + lineno + '</p>';
          Flutter.postMessage(JSON.stringify({type: 'error', data: {message: "JavaScript Error", description: message}}));
          return true;
        };
      </script>
    </head>
    <body onload="initializeCinetPay()">
      <h1>CinetPay Checkout</h1>
      <div id="cinet-pay-checkout"></div>
      <div id="debug"><h2>Debug Information:</h2></div>
    </body>
    </html>
  ''';
  }

  void handleJavaScriptMessage(String message) {
    final data = jsonDecode(message);
    if (data['type'] == 'finished') {
      widget.waitResponse!(data['data']);
    } else if (data['type'] == 'error') {
      widget.onError!(data['data']);
    }
  }

  Future<void> playStore() async {
    await PanaraInfoDialog.show(
      context,
      title: "WAVE",
      message: "Vous allez être redirigé sur Play Store. Installez l'application WAVE, connectez-vous et revenez pour effectuer votre paiement.",
      buttonText: "Ok",
      onTapDismiss: () async {
        Navigator.pop(context);
        await launchUrl(wave, mode: LaunchMode.externalApplication);
      },
      panaraDialogType: PanaraDialogType.normal,
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? "Payment Checkout", style: widget.titleStyle),
        centerTitle: true,
        backgroundColor: widget.titleBackgroundColor,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}