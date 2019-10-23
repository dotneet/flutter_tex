library flutter_tex;

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mime/mime.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TeXView extends StatefulWidget {
  final Key key;
  final String teXHTML;
  final Function(double, double) onRenderFinished;
  final Function(String) onPageFinished;

  TeXView({this.key, this.teXHTML, this.onRenderFinished, this.onPageFinished});

  @override
  _TeXViewState createState() => _TeXViewState();
}

class _TeXViewState extends State<TeXView> {
  WebViewController _webViewController;
  _Server _server;
  double _width = 1;
  double _height = 1;
  String baseUrl;

  @override
  void initState() {
    _server = _Server();
    baseUrl = "http://localhost:8080/packages/flutter_tex/MathJax/index.html";
    super.initState();
    _server.start();
  }

  @override
  Widget build(BuildContext context) {
    if (_webViewController != null) {
      _webViewController
          .loadUrl("$baseUrl?data=${Uri.encodeComponent(widget.teXHTML)}");
    }
    return SizedBox(
      width: _width,
      height: _height,
      child: WebView(
        key: widget.key,
        onPageFinished: (message) {
          if (widget.onPageFinished != null) {
            widget.onPageFinished(message);
          }
        },
        onWebViewCreated: (controller) {
          _webViewController = controller;
          _webViewController
              .loadUrl("$baseUrl?data=${Uri.encodeComponent(widget.teXHTML)}");
        },
        javascriptChannels: Set.from([
          JavascriptChannel(
              name: 'RenderedWebViewHeight',
              onMessageReceived: (JavascriptMessage message) {
                Map<String, dynamic> params = jsonDecode(message.message);
                final w = params["width"].toDouble();
                final h = params["height"].toDouble();
                if (_height != h) {
                  setState(() {
                    _height = h;
                  });
                }
                if (_width != w) {
                  setState(() {
                    _width = w;
                  });
                }
                if (widget.onRenderFinished != null) {
                  widget.onRenderFinished(_width, _height);
                }
              })
        ]),
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }

  @override
  void dispose() {
    _server.close();
    super.dispose();
  }
}

class _Server {
  // class from inAppBrowser

  HttpServer _server;

  int _port = 8080;

  _Server({int port = 8080}) {
    this._port = port;
  }

  ///Closes the server.
  Future<void> close() async {
    if (this._server != null) {
      await this._server.close(force: true);
      print('Server running on http://localhost:$_port closed');
      this._server = null;
    }
  }

  Future<void> start() async {
    if (this._server != null) {
      throw Exception('Server already started on http://localhost:$_port');
    }

    var completer = new Completer();
    runZoned(() {
      HttpServer.bind('127.0.0.1', _port, shared: true).then((server) {
        print('Server running on http://localhost:' + _port.toString());

        this._server = server;

        server.listen((HttpRequest request) async {
          var body = List<int>();
          var path = request.requestedUri.path;
          path = (path.startsWith('/')) ? path.substring(1) : path;
          path += (path.endsWith('/')) ? 'index.html' : '';

          try {
            body = (await rootBundle.load(path)).buffer.asUint8List();
          } catch (e) {
            print(e.toString());
            request.response.close();
            return;
          }

          var contentType = ['text', 'html'];
          if (!request.requestedUri.path.endsWith('/') &&
              request.requestedUri.pathSegments.isNotEmpty) {
            var mimeType =
                lookupMimeType(request.requestedUri.path, headerBytes: body);
            if (mimeType != null) {
              contentType = mimeType.split('/');
            }
          }

          request.response.headers.contentType =
              new ContentType(contentType[0], contentType[1], charset: 'utf-8');
          request.response.add(body);
          request.response.close();
        });

        completer.complete();
      });
    }, onError: (e, stackTrace) => print('Error: $e $stackTrace'));

    return completer.future;
  }
}
