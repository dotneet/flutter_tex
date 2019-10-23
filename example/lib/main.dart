import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

import 'teXHTML.dart';

main() async {
  runApp(FlutterTeX());
}

class FlutterTeX extends StatefulWidget {
  @override
  _FlutterTeXState createState() => _FlutterTeXState();
}

class _FlutterTeXState extends State<FlutterTeX> {
  String text = "Old Text (Press refresh)";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Flutter TeX Example"),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    text = "New Text (After refresh)";
                  });
                })
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TeXView(
              teXHTML: text,
              onRenderFinished: (width, height) {
                print("size: $width x $height");
              },
              onPageFinished: (string) {
                print("Page Loading finished");
              },
            ),
            TeXView(
              teXHTML: r"""\frac{1}{\Bigl(\sqrt{\phi \sqrt{5}}-\phi\Bigr) e^{\frac25 \pi}} \equiv 1+\frac{e^{-2\pi}} {1+\frac{e^{-4\pi}} {1+\frac{e^{-6\pi}} {1+\frac{e^{-8\pi}} {1+\cdots} } } }""",
            ),
          ],
        ),
      ),
    );
  }
}
