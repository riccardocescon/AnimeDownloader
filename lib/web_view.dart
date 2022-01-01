import 'package:fl_anime_downloader/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class AnimeWebView extends StatefulWidget {
  const AnimeWebView({Key? key}) : super(key: key);

  @override
  _AnimeWebViewState createState() => _AnimeWebViewState();
}

class _AnimeWebViewState extends State<AnimeWebView> {
  final _controller = WebviewController();
  final _textController = TextEditingController();

  late String theme;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    initPlatformState();
  }

  Future<void> initPlatformState() async {
    await _controller.initialize();
    _controller.url.listen((url) {
      _textController.text = url;
    });

    await _controller.setBackgroundColor(Colors.transparent);
    await _controller.loadUrl('https://www.animesaturn.it/');

    if (!mounted) return;

    setState(() {});
  }

  Widget compositeView() {
    if (!_controller.value.isInitialized) {
      return const Text(
        'Not Initialized',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 0,
              child: TextField(
                decoration: InputDecoration(
                    hintText: 'URL',
                    contentPadding: EdgeInsets.all(10.0),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () {
                        _controller.reload();
                      },
                    )),
                textAlignVertical: TextAlignVertical.center,
                controller: _textController,
                onSubmitted: (val) {
                  _controller.loadUrl(val);
                },
              ),
            ),
            Expanded(
                child: Card(
                    color: Colors.transparent,
                    elevation: 0,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Stack(
                      children: [
                        Webview(
                          _controller,
                          permissionRequested: _onPermissionRequested,
                        ),
                        StreamBuilder<LoadingState>(
                            stream: _controller.loadingState,
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data == LoadingState.loading) {
                                return LinearProgressIndicator();
                              } else {
                                return Container();
                              }
                            }),
                      ],
                    ))),
            bottomBar(),
          ],
        ),
      );
    }
  }

  Widget bottomBar() {
    return Container(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 0),
            child: Utils.animeButton("Cancel", Utils.redButtonTheme, () {
              Navigator.pushNamedAndRemoveUntil(
                  context, Utils.downloadPage, (route) => false);
            }),
          )),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 0),
            child: Utils.animeButton("Select", Utils.greenButtonTheme, () {
              fetchLinks();
            }),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)!.settings.arguments;
    Map map = arg != null ? arg as Map : {};
    theme = map["theme"];
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: isLoading
          ? Utils.loadingScreen(theme)
          : Scaffold(
              backgroundColor: Colors.black87,
              appBar: AppBar(
                  backgroundColor: Utils.getPrimaryColor(theme),
                  leading: IconButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, Utils.downloadPage,
                            arguments: {"theme": theme});
                      },
                      icon: const Icon(Icons.arrow_back)),
                  title: StreamBuilder<String>(
                    stream: _controller.title,
                    builder: (context, snapshot) {
                      return Text(snapshot.hasData
                          ? snapshot.data!
                          : 'WebView (Windows) Example');
                    },
                  )),
              body: Center(
                child: compositeView(),
              ),
            ),
    );
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView permission requested'),
        content: Text('WebView has requested permission \'$kind\''),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.none;
  }

  String extractAnimeName(String source) {
    List<String> parts = source.split("/");
    String animeName = parts[parts.length - 1].replaceAll("-", "_");
    return animeName;
  }

  void showLoading() {
    isLoading = true;
    setState(() {});
  }

  void fetchLinks() async {
    String pagePath = _textController.text;
    String animeName = extractAnimeName(pagePath);
    String animeImage = "";
    print(pagePath + " fetching...");
    showLoading();
    var response = await http.get(Uri.parse(pagePath));
    String htmlToParse = response.body;
    List<String> lines = htmlToParse.split("\n");
    List<String> interestingLines = [];
    for (String line in lines) {
      if (line.contains("www.animesaturn.it/ep/")) {
        interestingLines.add(line);
      } else if (animeImage == "" && line.contains("cdn.animesaturn.it")) {
        List<String> parts = line.split("http");
        String firstLine = "http" + parts[1];
        String composed = firstLine.contains(".jpg")
            ? firstLine.split(".jpg")[0] + ".jpg"
            : firstLine.split(".png")[0] + ".png";
        animeImage = composed;
      }
    }

    if (interestingLines.isEmpty) {
      Utils.showToast(
          "You must select the anime homepage!", Colors.red, Colors.white);
      return;
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
      return;
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

    Map eps = {
      "anime": animeName,
      "image": animeImage,
      "link": pagePath,
      "theme": theme
    };
    int i = 1;
    for (String current in episodes) {
      eps.addAll({"ep" + i.toString(): current});
      i++;
    }

    Navigator.pushNamed(context, Utils.downloadPage, arguments: eps);
  }
}
