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
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
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
        <script src="https://cdn.cinetpay.com/seamless/latest/main.js"></script>
        <script>
          function checkout() {
            var configData = ${jsonEncode(widget.configData)};
            var paymentData = ${jsonEncode(widget.paymentData)};
            
            console.log("Config Data:", JSON.stringify(configData));
            console.log("Payment Data:", JSON.stringify(paymentData));
            
            CinetPay.setConfig(configData);
            CinetPay.getCheckout(paymentData);
            
            CinetPay.waitResponse(function(data) {
              console.log("CinetPay Response:", JSON.stringify(data));
              Flutter.postMessage(JSON.stringify({type: 'finished', data: data}));
            });
            
            CinetPay.onError(function(data) {
              console.error("CinetPay Error:", JSON.stringify(data));
              Flutter.postMessage(JSON.stringify({type: 'error', data: data}));
            });
          }

          window.onload = checkout;
        </script>
      </head>
      <body>
        <div id="cinet-pay-checkout"></div>
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