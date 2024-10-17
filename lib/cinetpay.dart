library cinetpay;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  final GlobalKey webViewKey = GlobalKey();
  final Uri wave = Uri.parse("https://play.google.com/store/apps/details?id=com.wave.personal");

  InAppWebViewController? webViewController;
  InAppWebViewSettings options = InAppWebViewSettings(
  useShouldOverrideUrlLoading: true,
  useHybridComposition: true,
  userAgent: 'Your Custom User Agent String',
);

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();

    if (Platform.isAndroid) {
      InAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
  }

  Future<void> playStore(InAppWebViewController controller) async {
    await controller.goBack();
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
      body: SafeArea(
        child: InAppWebView(
          key: webViewKey,
          initialUrlRequest: URLRequest(
            url: WebUri.uri(Uri.parse('about:blank')),
            headers: {},
          ),
          initialSettings: options,
          onWebViewCreated: (InAppWebViewController controller) {
            webViewController = controller;
            controller.loadData(data: """
              <!DOCTYPE html>
                <html>
                <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <script src="https://cdn.cinetpay.com/seamless/main.js"></script>
                    <script>
                        window.onerror = function(message, source, lineno, colno, error) {
    console.error("JavaScript Error:", message, "at", source, ":", lineno);
    if (error && error.stack) {
      console.error("Stack trace:", error.stack);
    }
    return true;
  };

  // Wrap CinetPay calls in try-catch
  function checkout() {
    window.addEventListener("flutterInAppWebViewPlatformReady", function(event) {
      window.flutter_inappwebview.callHandler('elementToSend')
        .then(function(result) {
          try {
            var configData = result.configData;
            var paymentData = result.paymentData;
            
            console.log("Config Data:", JSON.stringify(configData));
            console.log("Payment Data:", JSON.stringify(paymentData));
            
            CinetPay.setConfig(configData);
            CinetPay.getCheckout(paymentData);
            
            CinetPay.waitResponse(function(data) {
              console.log("CinetPay Response:", JSON.stringify(data));
              wait('finished', data);
            });
            
            CinetPay.onError(function(data) {
              console.error("CinetPay Error:", JSON.stringify(data));
              error('error', data);
            });
          } catch (e) {
            console.error("Error in CinetPay setup:", e);
            error('error', { message: "Error in CinetPay setup", description: e.toString() });
          }
        });
    });
  }

                    </script>
                </head>
                <body onload="checkout()">
                </body>
                </html>
            """);

            controller.addJavaScriptHandler(
  handlerName: 'error',
  callback: (args) async {
    print("Detailed CinetPay error:");
    print(args[0]);
    if (args[0] is Map<String, dynamic>) {
      final errorData = args[0] as Map<String, dynamic>;
      print("Error Code: ${errorData['code']}");
      print("Error Message: ${errorData['message']}");
      print("Error Description: ${errorData['description']}");
      // Add any additional fields that might be present in the error response
    }
    return widget.onError!(args[0]);
  },
);

            controller.addJavaScriptHandler(
              handlerName: 'finished',
              callback: (args) async {
                print("CinetPay Checkout send payment response");
                return widget.waitResponse!(args[0]);
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'error',
              callback: (args) async {
                print("An error occurred : ${args[0]}");
                return widget.onError!(args[0]);
              },
            );
          },
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(resources: request.resources, action: PermissionResponseAction.GRANT);
          },
          onReceivedError: (controller, request, error) {
            print("An error occurred : ${error.description}");
          },
          onConsoleMessage: (controller, consoleMessage) async {
            String response = consoleMessage.message;
            print("console : $response");
            if (response.contains('https://play.google.com/')) {
              await playStore(controller);
            }
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            Uri url = navigationAction.request.url!;
            try {
              await launchUrl(url, mode: LaunchMode.externalApplication);
              await controller.goBack();
              print("Redirect to : $url");
            } catch (exception) {
              print("Exception to redirect : $exception");
              await playStore(controller);
            }
            return NavigationActionPolicy.ALLOW;
          },
        ),
      ),
    );
  }
}
