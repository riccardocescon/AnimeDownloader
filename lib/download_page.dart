import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:fl_anime_downloader/anime.dart';
import 'package:fl_anime_downloader/main.dart';
import 'package:fl_anime_downloader/options.dart';
import 'package:flutter/material.dart';
import 'package:file_picker_desktop/file_picker_desktop.dart';
import 'package:flutter/services.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class DownloadPage extends StatefulWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  String destinationPath = "None";
  bool showPathInfo = false;
  Color infoColor = Colors.red;
  List<String> episodeLinks = [];
  String animeName = "";
  NetworkImage animeImage = const NetworkImage(
      "https://upload.wikimedia.org/wikipedia/commons/2/2e/Exclamation_mark_red.png");

  bool isDownloading = false;
  String perc = "0";
  String size = "0";
  String speed = "0MiB/s";
  String eta = "0s";
  int currentEp = 0;
  int totalEps = 0;

  List<String> funnyMessages = [
    "What a beautiful shit anime you are downloading!",
    "Oh I remember this episode, it's beautiful!",
    "Eh eh eh I know why you are downloading this anime, you little Hentai!",
    "Super funny this episode, the boy dies",
    "Hey master, hit the cancel button, this anime is too boring",
    "Not bad, it's nice enough"
  ];
  String currentMessage = "";
  bool switchMessage = true;

  late Process process;

  TextEditingController firtEpController = TextEditingController(text: "1");
  TextEditingController lastEpController = TextEditingController(text: "12");

  late String theme;

  late Anime anime;
  bool loadedFromMap = false;
  bool _loadResumedOptions = false;
  bool _loadResumeOptionsEnded = false;
  bool _hasLoadedResumedOptions = false;

  bool _baseLoading = false;

  _DownloadPageState() {
    HttpOverrides.global = MyHttpOverrides();
  }

  @override
  void initState() {
    super.initState();
    setup();
  }

  Future<void> setup() async {
    destinationPath = await Options.instance.getDestinationPath();
    setState(() {});
  }

  void loadResumeOptions(Map map) async {
    if (_hasLoadedResumedOptions) {
      return;
    }
    _hasLoadedResumedOptions = true;
    episodeLinks.clear();
    anime = map["anime_obj"];
    firtEpController.text = anime.downloadedEps.toString();
    log("Started fetching...");
    episodeLinks =
        await Utils.fetchLinks(animeSaturnHomepage: anime.downloadLink);
    for (String current in episodeLinks) {
      log("Ep : $current");
    }
    _loadResumeOptionsEnded = true;
    log("Ended fetching!");
    setState(() {});
  }

  void directDownload(Map map) async {
    if (isDownloading) {
      return;
    }
    isDownloading = true;
    episodeLinks.clear();
    destinationPath = await Options.instance.getDestinationPath();
    int resumeEp = map["lastDownlaodedEp"];
    int totalEps = map["totalEps"];
    for (int i = 0; i < resumeEp; i++) {
      episodeLinks.add("Ep $i Already Downlaoded");
    }
    for (int i = resumeEp + 1; i <= totalEps; i++) {
      String currentLink = map["ep" + i.toString()];
      episodeLinks.add(currentLink);
    }
    anime = Anime(
        name: animeName,
        imageLink: map["image"],
        downloadLink: map["link"],
        allEpisodes: episodeLinks.length,
        lastDownloadDate: Utils.getAnimeDateTime());
    downloadAnime(resumeEp + 1, totalEps, destinationPath + "\\" + animeName);
    setState(() {});
  }

  Future<void> loadImage(String imgUrl) async {
    try {
      scheduleMicrotask(() {
        animeImage = NetworkImage(imgUrl);
      });

      animeImage
          .resolve(const ImageConfiguration())
          .addListener(ImageStreamListener((image, synchronousCall) {
        setState(() {});
      }));
    } catch (err) {
      animeImage = const NetworkImage(
          "https://upload.wikimedia.org/wikipedia/commons/2/2e/Exclamation_mark_red.png");
    }
  }

  Future<void> saveAnime(Anime source) async {
    int id = await Options.instance.insertAnime(source);
    source.id = id;
  }

  void loadData(context) {
    if (_baseLoading) {
      return;
    }
    _baseLoading = true;
    final arg = ModalRoute.of(context)!.settings.arguments;
    Map map = arg != null ? arg as Map : {};
    theme = map["theme"];
    if (map.length > 1) {
      loadedFromMap = true;
      animeName = map["anime"];
      loadImage(map["image"]);
      if (map.containsKey("resumeAnime")) {
        directDownload(map);
      } else if (map.containsKey("resumeAnimeWithOptions")) {
        _loadResumedOptions = true;
        loadResumeOptions(map);
      } else {
        episodeLinks.clear();
        for (int i = 4; i < map.length; i++) {
          String currentLink = map["ep" + (i - 3).toString()];
          episodeLinks.add(currentLink);
        }
        lastEpController.text = episodeLinks.length.toString();
        anime = Anime(
            name: animeName,
            imageLink: map["image"],
            downloadLink: map["link"],
            allEpisodes: episodeLinks.length,
            lastDownloadDate: Utils.getAnimeDateTime());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    loadData(context);
    String showPath = destinationPath;
    if (destinationPath.contains("\\")) {
      List<String> parts = destinationPath.split("\\");
      if (parts.length > 2) {
        String lastPart = parts[parts.length - 1];
        String beforeLastPart = parts[parts.length - 2];
        if (lastPart.length + beforeLastPart.length > 18) {
          showPath = "...\\$lastPart";
        } else {
          showPath = "...\\$beforeLastPart\\$lastPart";
        }
      }
    }
    return Scaffold(
        backgroundColor: Colors.black87,
        appBar: AppBar(
          backgroundColor: Utils.getPrimaryColor(theme),
          centerTitle: true,
          title: const Text(
            "Download Anime",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, Utils.homepage, (route) => false,
                    arguments: {"theme": theme});
              },
              icon: const Icon(Icons.arrow_back)),
        ),
        body: _loadResumedOptions && !_loadResumeOptionsEnded
            ? Center(
                child: CircularProgressIndicator(
                  color: Utils.getPrimaryColor(theme),
                ),
              )
            : isDownloading
                ? downloadingScreen()
                : mainScreen(showPath));
  }

  Widget downloadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Downloading ${animeName.replaceAll("_", " ")} Ep $currentEp of $totalEps",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "$perc of $size with speed of $speed. Eta : $eta",
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            getRandomFunnyMessage(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Padding(padding: EdgeInsets.only(top: 30)),
          Container(
            width: 200,
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(image: animeImage, fit: BoxFit.fill),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Utils.animeButton("Cancel", Utils.redButtonTheme, () async {
                  process.kill();
                  isDownloading = false;
                  showDialog(
                      context: context,
                      builder: (context) {
                        return warningPanel();
                      }).then((value) {
                    Navigator.pushReplacementNamed(context, Utils.homepage,
                        arguments: {"theme": theme});
                  });
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget warningPanel() {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      actions: [
        Container(
          width: 500,
          height: 300,
          decoration: BoxDecoration(
            color: Utils.getPrimaryColor(theme),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              child: const Text(
                "Please restart you application to make sure everything is closed in the right way",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget mainScreen(String showPath) {
    return Center(
        child: Column(
      children: [
        Column(
          children: [
            Container(
                margin: const EdgeInsets.only(top: 100),
                child: Utils.animeText("Destination Folder", 30, theme)),
            Container(
              padding: const EdgeInsets.only(top: 10),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                        child: Utils.animeButton(showPath, theme, () {
                      pickPath();
                    }, () async {
                      setState(() {
                        showPathInfo = true;
                      });
                      await Future.delayed(const Duration(seconds: 3));
                      setState(() {
                        showPathInfo = false;
                      });
                    })),
                  ),
                  Visibility(
                    visible: showPathInfo,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(600, 0, 0, 0),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          InkWell(
                            onTap: () async {
                              ClipboardData data =
                                  ClipboardData(text: destinationPath);
                              await Clipboard.setData(data);
                              infoColor = Colors.deepOrange;
                              setState(() {});
                              await Future.delayed(
                                  const Duration(milliseconds: 200));
                              infoColor = Colors.red;
                              setState(() {});
                            },
                            child: Container(
                              width: 300,
                              decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(4)),
                                color: infoColor,
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(10),
                                child: Center(
                                  child: Text(
                                    destinationPath,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.only(top: 50),
          child: Column(
            children: [
              Container(child: Utils.animeText("Anime", 30, theme)),
              Container(
                  padding: const EdgeInsets.only(top: 10),
                  child: Utils.animeButton(
                      loadedFromMap
                          ? anime.name.replaceAll("_", " ")
                          : "No anime selected...",
                      theme, () {
                    if (destinationPath == "None") {
                      Utils.showToast(
                          "You must set the destination folder before downloading anime!",
                          Colors.red,
                          Colors.white);
                      return;
                    }
                    Navigator.pushNamedAndRemoveUntil(
                        context, Utils.animeWebView, (route) => false,
                        arguments: {"theme": theme});
                  })),
            ],
          ),
        ),
        Visibility(
          visible: episodeLinks.isNotEmpty,
          child: Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Utils.animeInput(theme, firtEpController),
                const Padding(padding: EdgeInsets.only(left: 150)),
                Utils.animeInput(theme, lastEpController),
              ],
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 50),
              child: Visibility(
                visible: episodeLinks.isNotEmpty,
                child:
                    Utils.animeButton("Download", Utils.greenButtonTheme, () {
                  String currentAnimePath = destinationPath + "\\" + animeName;
                  Directory(currentAnimePath).create().then((value) {
                    print("created");
                  });
                  isDownloading = true;
                  int firstEp = int.tryParse(firtEpController.text) ?? 1;
                  firstEp = firstEp < 1 ? 1 : firstEp;
                  int lastEp = int.tryParse(lastEpController.text) ??
                      episodeLinks.length;
                  lastEp = lastEp > episodeLinks.length
                      ? episodeLinks.length
                      : lastEp;
                  saveAnime(anime);
                  downloadAnime(firstEp, lastEp, currentAnimePath);
                }),
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void pickPath() async {
    try {
      final selectedDirectory = await getDirectoryPath();
      if (selectedDirectory != null) {
        File directory = File(selectedDirectory);
        String path = directory.path;
        await Options.instance.saveDestinationPath(path);
        setState(() {
          destinationPath = path;
        });
      } else {
        print("canceled");
      }
    } catch (e) {
      print(e);
    }
  }

  void downloadAnime(int currentEp, int lastEp, String currentAnimePath) async {
    if (currentEp - 1 > lastEp) {
      print("Everything downlaoded");
      return;
    }

    if (!mounted) {
      return;
    }

    String currentName = animeName + "_" + currentEp.toString() + ".mp4";
    String downloadString =
        "yt-dlp --newline -f best -o $currentName ${episodeLinks[currentEp - 1]}";
    this.currentEp = currentEp;
    totalEps = lastEp;

    setState(() {});

    print("Sending command : $downloadString");

    bool showCmd = await Options.instance.getShowCmd();
    log("Showing cmd : $showCmd");

    process = await Process.start(
      downloadString,
      [],
      runInShell: true,
      workingDirectory: currentAnimePath,
    );
    process.stdout.transform(utf8.decoder).forEach((value) {
      print(value);
      if (value.contains("ETA")) {
        List<String> parts = value.split(" ");
        for (String current in parts) {
          if (current.contains("%")) {
            perc = current;
          }
          if (current.contains("~")) {
            size = current.replaceAll("~", "");
          }
          if (current.contains("/s")) {
            speed = current;
          }
          if (current.contains(":")) {
            eta = current;
          }
        }
      }
      if (mounted) {
        setState(() {});
      }
    }).whenComplete(() async {
      anime.downloadedEps = currentEp;
      anime.lastDownloadDate = Utils.getAnimeDateTime();
      await Options.instance.updateAnime(anime);
      downloadAnime(currentEp + 1, lastEp, currentAnimePath);
    });
  }

  String getRandomFunnyMessage() {
    if (!switchMessage) {
      return currentMessage;
    }
    switchMessage = false;
    messageRefresher();
    String msg = funnyMessages[math.Random().nextInt(funnyMessages.length - 1)];
    currentMessage = msg;
    return msg;
  }

  void messageRefresher() async {
    await Future.delayed(const Duration(seconds: 20));
    if (mounted) {
      setState(() {
        switchMessage = true;
      });
    }
  }
}
