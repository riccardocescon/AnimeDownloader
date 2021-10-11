import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class DownloadTest extends StatefulWidget {
  const DownloadTest({Key? key}) : super(key: key);

  @override
  _DownloadTestState createState() => _DownloadTestState();
}

class _DownloadTestState extends State<DownloadTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
        ),
        child: Center(
          child: MaterialButton(
            onPressed: () {
              download();
            },
            child: const Text(
              "Try Download",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            color: Colors.amber,
            minWidth: 200,
            height: 80,
          ),
        ),
      ),
    );
  }

  void download() async {
    String path =
        "C:\\Users\\ricca\\Desktop\\FlutterProject\\fl_anime_downloader\\anime";
    String destPath =
        "C:\\Users\\ricca\\Desktop\\FlutterProject\\fl_anime_downloader\\anime\\test.mp4";

    String url = "https://www.animesaturn.it/watch?file=1IckIAWSKy3PD";
    String downloadString = "youtube-dl -f best $url -o test.mp4";
    var process = await Process.start(downloadString, [],
        runInShell: true, workingDirectory: path);
    process.stdout.transform(utf8.decoder).forEach(print).whenComplete(() {
      print("COMPLETED BITCH!");
    });

    print("End download");
  }
}
