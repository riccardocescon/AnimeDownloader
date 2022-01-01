import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fl_anime_downloader/download_page.dart';
import 'package:fl_anime_downloader/gallery.dart';
import 'package:fl_anime_downloader/homepage.dart';
import 'package:fl_anime_downloader/settings.dart';
import 'package:fl_anime_downloader/web_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:window_size/window_size.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Anime Downloader');
    setWindowMinSize(const Size(1000, 800));
    setWindowMaxSize(Size.infinite);
  }

  runApp(MaterialApp(
    initialRoute: Utils.homepage,
    routes: {
      Utils.homepage: (context) => const Homepage(),
      Utils.downloadPage: (context) => const DownloadPage(),
      Utils.animeWebView: (context) => const AnimeWebView(),
      Utils.gallery: (context) => const AnimeGallery(),
      Utils.settings: (context) => const Settings(),
    },
  ));
}

class Utils {
  static String homepage = "homepage";
  static String downloadPage = "downloadPage";
  static String animeWebView = "animeWebView";
  static String gallery = "gallery";
  static String settings = "settings";

  static const String themeIndigo = "themeIndigo";
  static const String themeRed = "themeRed";
  static const String themeGreen = "themeGreen";
  static const String themeAmber = "themeAmber";

  static const String redButtonTheme = "red";
  static const String greenButtonTheme = "green";
  static const String whiteTextTheme = "white";

  static Color getPrimaryColor(String theme) {
    switch (theme) {
      case themeIndigo:
        return Colors.indigo.shade400;

      case themeRed:
        return Colors.red.shade400;

      case themeGreen:
        return Colors.green.shade400;

      case themeAmber:
        return Colors.amber.shade600;

      default:
        return Colors.indigo.shade400;
    }
  }

  static Widget animeButton(String text, String theme, Function onClick,
      [Function? onLongClick, double? width, double? height]) {
    Color baseColor = Colors.indigo.shade400;
    Color hoverColor = Colors.indigo.shade600;
    Color splashColor = Colors.indigo.shade800;
    switch (theme) {
      case themeRed:
      case redButtonTheme:
        baseColor = Colors.red.shade400;
        hoverColor = Colors.red.shade600;
        splashColor = Colors.red.shade800;
        break;
      case themeGreen:
      case greenButtonTheme:
        baseColor = Colors.green.shade400;
        hoverColor = Colors.green.shade600;
        splashColor = Colors.green.shade800;
        break;
      case themeIndigo:
        baseColor = Colors.indigo.shade400;
        hoverColor = Colors.indigo.shade600;
        splashColor = Colors.indigo.shade800;
        break;
      case themeAmber:
        baseColor = Colors.amber.shade600;
        hoverColor = Colors.amber.shade800;
        splashColor = Colors.amber.shade400;
        break;
    }
    return SizedBox(
      width: width ?? 240,
      height: height ?? 70,
      child: MaterialButton(
        onPressed: () {
          onClick.call();
        },
        onLongPress: () {
          if (onLongClick != null) {
            onLongClick.call();
          }
        },
        color: baseColor,
        hoverColor: hoverColor,
        splashColor: splashColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  static Widget animeInput(String theme, TextEditingController controller) {
    Color baseColor = Colors.indigo.shade400;
    Color hoverColor = Colors.indigo.shade600;
    Color splashColor = Colors.indigo.shade800;
    switch (theme) {
      case themeRed:
      case redButtonTheme:
        baseColor = Colors.red.shade400;
        hoverColor = Colors.red.shade600;
        splashColor = Colors.red.shade800;
        break;
      case themeGreen:
      case greenButtonTheme:
        baseColor = Colors.green.shade400;
        hoverColor = Colors.green.shade600;
        splashColor = Colors.green.shade800;
        break;
      case themeIndigo:
        baseColor = Colors.indigo.shade400;
        hoverColor = Colors.indigo.shade600;
        splashColor = Colors.indigo.shade800;
        break;
      case themeAmber:
        baseColor = Colors.amber.shade400;
        hoverColor = Colors.amber.shade600;
        splashColor = Colors.amber.shade800;
        break;
    }
    return SizedBox(
      width: 150,
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          fillColor: baseColor,
          filled: true,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }

  static Widget animeText(String text, double fontSize, String theme) {
    Color textColor = Colors.white;
    switch (theme) {
      case themeIndigo:
        textColor = Colors.indigo.shade400;
        break;
      case themeRed:
        textColor = Colors.red.shade400;
        break;
      case themeGreen:
        textColor = Colors.green.shade400;
        break;
      case themeAmber:
        textColor = Colors.amber.shade400;
        break;
      case whiteTextTheme:
        textColor = Colors.white;
        break;
    }
    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static String day_divisor = "/";
  static String time_divisor = ":";

  static String getAnimeDateTime() {
    DateTime dateTime = DateTime.now();
    return dateTime.day.toString() +
        day_divisor +
        dateTime.month.toString() +
        day_divisor +
        dateTime.year.toString() +
        " " +
        dateTime.hour.toString() +
        time_divisor +
        dateTime.minute.toString() +
        time_divisor +
        dateTime.second.toString();
  }

  static Widget loadingScreen(String theme) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitDoubleBounce(
              color: getPrimaryColor(theme),
              size: 80,
            ),
            const Padding(padding: EdgeInsets.only(top: 30)),
            animeText("I am fetching all the links...\nPlease wait master", 28,
                theme),
          ],
        ),
      ),
    );
  }

  static void showToast(String text, Color color, Color textColor) {
    Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: color,
        textColor: textColor,
        fontSize: 16.0);
  }

  static Future<List<String>> fetchLinks(
      {required String animeSaturnHomepage}) async {
    var response = await http.get(Uri.parse(animeSaturnHomepage));
    String htmlToParse = response.body;
    List<String> lines = htmlToParse.split("\n");
    List<String> interestingLines = [];
    for (String line in lines) {
      if (line.contains("www.animesaturn.it/ep/")) {
        interestingLines.add(line);
      }
    }

    if (interestingLines.isEmpty) {
      Utils.showToast(
          "You must select the anime homepage!", Colors.red, Colors.white);
      return [];
    }

    List<String> episodeLinks = [];
    for (String current in interestingLines) {
      List<String> parts = current.trim().split(" ");
      bool found = false;
      for (String currentPart in parts) {
        if (currentPart.contains("href")) {
          found = true;
          String link = currentPart.split("\"")[1];
          episodeLinks.add(link);
        }
        if (found) {
          break;
        }
      }
    }

    if (episodeLinks.isEmpty) {
      Utils.showToast(
          "You must select the anime homepage!", Colors.red, Colors.white);
      return [];
    }

    List<String> episodes = [];

    for (String current in episodeLinks) {
      var response = await http.get(Uri.parse(current));
      String htmlToParse = response.body;
      List<String> lines = htmlToParse.split("\n");
      String videoUrlRaw = "";
      for (String line in lines) {
        if (line.contains("www.animesaturn.it/watch?")) {
          videoUrlRaw = line;
          break;
        }
      }

      List<String> parts = videoUrlRaw.split(" ");
      String videoUrl = "";
      for (String currenPart in parts) {
        if (currenPart.contains("href")) {
          videoUrl = currenPart.split("\"")[1];
          break;
        }
      }

      episodes.add(videoUrl);
    }

    return episodes;
  }
}
