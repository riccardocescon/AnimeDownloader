import 'dart:io';

import 'package:fl_anime_downloader/anime.dart';
import 'package:fl_anime_downloader/download_page.dart';
import 'package:fl_anime_downloader/main.dart';
import 'package:fl_anime_downloader/options.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

enum OrderBy {
  name,
  lastDownload,
}

class AnimeGallery extends StatefulWidget {
  const AnimeGallery({Key? key}) : super(key: key);

  @override
  _AnimeGalleryState createState() => _AnimeGalleryState();
}

class _AnimeGalleryState extends State<AnimeGallery> {
  List<Anime> downloadedAnime = [];

  late String theme;

  String dropdownvalue = 'Name';
  var items = ['Name', 'Last Downloaded'];

  bool isLoading = false;

  _AnimeGalleryState() {
    HttpOverrides.global = MyHttpOverrides();
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    downloadedAnime = await Options.instance.selectAllAnime();
    reorderAnime(OrderBy.name);
    setState(() {});
  }

  void reorderAnime(OrderBy orderBy) {
    switch (orderBy) {
      case OrderBy.name:
        downloadedAnime.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;

      case OrderBy.lastDownload:
        downloadedAnime.sort((a, b) {
          String dateA = a.lastDownloadDate.split(" ")[0];
          String dateB = b.lastDownloadDate.split(" ")[0];
          String timeA = a.lastDownloadDate.split(" ")[1];
          String timeB = b.lastDownloadDate.split(" ")[1];

          for (int i = 2; i > -1; i--) {
            if (isBigger(dateA, dateB, i, Utils.day_divisor)) {
              return -1;
            } else if (isBigger(dateB, dateA, i, Utils.day_divisor)) {
              return 1;
            }
          }

          for (int i = 2; i > -1; i--) {
            if (isBigger(timeA, timeB, i, Utils.time_divisor)) {
              return -1;
            } else if (isBigger(timeB, timeA, i, Utils.time_divisor)) {
              return 1;
            }
          }

          return -1;
        });
        break;
    }
  }

  bool isBigger(String sourceA, String sourceB, int pos, String regex) {
    int a = int.parse(sourceA.split(regex)[pos]);
    int b = int.parse(sourceB.split(regex)[pos]);
    return a > b;
  }

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)!.settings.arguments;
    Map map = arg != null ? arg as Map : {};
    theme = map["theme"];
    return isLoading
        ? Utils.loadingScreen(theme)
        : Scaffold(
            backgroundColor: Colors.black87,
            appBar: AppBar(
              backgroundColor: Utils.getPrimaryColor(theme),
              centerTitle: true,
              title: const Text(
                "Anime Gallery",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              leading: IconButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, Utils.homepage, (route) => false,
                        arguments: {"theme": theme});
                  },
                  icon: const Icon(Icons.arrow_back)),
            ),
            body: layout(),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Utils.getPrimaryColor(theme),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return filterDialog();
                    }).then((value) {
                  setState(() {});
                });
              },
              child: const Icon(
                Icons.filter_alt_rounded,
                size: 32,
              ),
            ),
          );
  }

  Widget filterDialog() {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            width: 600,
            height: 300,
            decoration: BoxDecoration(
              color: Utils.getPrimaryColor(theme),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Utils.animeText("Filter", 28, Utils.whiteTextTheme),
                const Padding(padding: EdgeInsets.only(top: 90)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Utils.animeText("Order by :", 24, Utils.whiteTextTheme),
                    DropdownButton(
                      value: dropdownvalue,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white),
                      borderRadius: const BorderRadius.all(Radius.circular(6)),
                      items: items.map((String items) {
                        return DropdownMenuItem(
                            value: items,
                            child: Center(
                              child: Text(
                                items,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownvalue = newValue!;
                        });
                      },
                      dropdownColor: Utils.getPrimaryColor(theme),
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.only(top: 50)),
                Utils.animeButton("Save", Utils.greenButtonTheme, () {
                  if (dropdownvalue == items[0]) {
                    reorderAnime(OrderBy.name);
                  } else {
                    reorderAnime(OrderBy.lastDownload);
                  }
                  Navigator.pop(context);
                }, () {}, 200, 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget layout() {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.only(top: 20)),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.fromLTRB(50, 0, 0, 0),
                child: Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 300,
                  runSpacing: 50,
                  children: downloadedAnime.map((e) => animeLayout(e)).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget animeLayout(Anime anime) {
    return InkWell(
      onTap: () {
        showDialog(
            context: context,
            builder: (context) {
              return animeInfo(anime);
            });
      },
      splashColor: Colors.transparent,
      child: SizedBox(
        width: 200,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: Image.network(
                anime.imageLink,
              ),
            ),
            Text(
              anime.name.replaceAll("_", " "),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget animeInfo(Anime anime) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      actions: [
        Container(
          width: 800,
          height: 500,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Utils.getPrimaryColor(theme),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Expanded(
                        child: Container(
                      padding: const EdgeInsets.all(10),
                      child: animeImage(anime),
                    )),
                    Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Text(
                              anime.name.replaceAll("_", " "),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            infoRow("Downloaded Eps :",
                                anime.downloadedEps.toString(), 90),
                            infoRow("Total Eps :", anime.allEpisodes.toString(),
                                30),
                            infoRow("Last Download Date :",
                                anime.lastDownloadDate.split(" ")[0], 30),
                            infoRow("Last Download Time :",
                                anime.lastDownloadDate.split(" ")[1], 30),
                          ],
                        )),
                  ],
                ),
              ),
              Expanded(
                  child: Row(
                mainAxisAlignment: anime.downloadedEps < anime.allEpisodes
                    ? MainAxisAlignment.spaceEvenly
                    : MainAxisAlignment.center,
                children: [
                  Utils.animeButton("Delete", Utils.redButtonTheme, () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return deleteDialog(anime);
                        });
                  }),
                  Visibility(
                      visible: anime.downloadedEps < anime.allEpisodes,
                      child: Utils.animeButton(
                          "Resume Download", Utils.greenButtonTheme, () {
                        resumeAnime(anime);
                        Navigator.pop(context);
                      })),
                ],
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget deleteDialog(Anime anime) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      actions: [
        Container(
          width: 500,
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Utils.getPrimaryColor(theme),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Utils.animeText("Delete", 24, Utils.whiteTextTheme),
              Utils.animeText(
                  "Do you want to delete only the anime data,\nor the folder with all episodes?",
                  20,
                  Utils.whiteTextTheme),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Utils.animeButton("Everything", Utils.redButtonTheme, () {
                    deleteEverything(anime);
                    Navigator.pop(context);
                    downloadedAnime.remove(anime);
                    setState(() {});
                  }, () {}, 180, 60),
                  const Padding(padding: EdgeInsets.only(left: 50)),
                  Utils.animeButton("Only Info", Utils.greenButtonTheme, () {
                    deleteInfo(anime);
                    Navigator.pop(context);
                    downloadedAnime.remove(anime);
                    setState(() {});
                  }, () {}, 180, 60),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void showLoading() {
    isLoading = true;
    setState(() {});
  }

  void resumeAnime(Anime anime) async {
    showLoading();
    var response = await http.get(Uri.parse(anime.downloadLink));
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

    Map data = {
      "resumeAnime": true,
      "anime": anime.name,
      "image": anime.imageLink,
      "lastDownlaodedEp": anime.downloadedEps,
      "totalEps": anime.allEpisodes,
      "link": anime.downloadLink,
      "theme": theme,
    };
    for (int i = anime.downloadedEps; i < anime.allEpisodes; i++) {
      data.addAll({"ep${i + 1}": episodes[i]});
    }

    Navigator.pushReplacementNamed(context, Utils.downloadPage,
        arguments: data);
  }

  void deleteInfo(Anime anime) async {
    await Options.instance.deleteAnime(anime);
  }

  void deleteEverything(Anime anime) async {
    await Options.instance.deleteAnime(anime);
    String dirPath = await Options.instance.getDestinationPath();
    Directory animeFolderPath = Directory(dirPath + "/" + anime.name);
    animeFolderPath.deleteSync(recursive: true);
  }

  Widget animeImage(Anime anime) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Image.network(
        anime.imageLink,
      ),
    );
  }

  Widget infoRow(String key, String value, double vertialMargin) {
    return Container(
      margin: EdgeInsets.fromLTRB(50, vertialMargin, 50, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 80),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
