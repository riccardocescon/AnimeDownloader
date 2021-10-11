import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';
import 'options.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String theme = Utils.themeIndigo;

  String githubUrl = "https://github.com/riccardocescon";
  String instagramUrl = "https://www.instagram.com/riccardocescon/";
  String discordUrl = "https://discordapp.com/users/238363863588798485";
  String telegramUrl = "https://t.me/ILogosl";

  @override
  void initState() {
    super.initState();
    setup();
  }

  void setup() async {
    theme = await Options.instance.getTheme();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }

  Widget Home() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Utils.getPrimaryColor(theme),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.black87),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Center(
                      child: Text(
                        "V 1.0.1",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 80),
                      child: const Text(
                        "Anime Downlaoder",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                        margin: const EdgeInsets.only(top: 50),
                        child: Utils.animeButton("Download Anime", theme, () {
                          Navigator.pushNamedAndRemoveUntil(
                              context, Utils.downloadPage, (route) => false,
                              arguments: {"theme": theme});
                        })),
                    Container(
                        margin: const EdgeInsets.only(top: 50),
                        child: Utils.animeButton("Gallery Anime", theme, () {
                          Navigator.pushNamedAndRemoveUntil(
                              context, Utils.gallery, (route) => false,
                              arguments: {"theme": theme});
                        })),
                    Container(
                        margin: const EdgeInsets.only(top: 50),
                        child: Utils.animeButton("Settings", theme, () {
                          Navigator.pushNamedAndRemoveUntil(
                              context, Utils.settings, (route) => false,
                              arguments: {"theme": theme});
                        })),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            flexText("Made by Logos"),
                            flexAccount("assets/images/github.png",
                                "riccardocescon", () => openWeb(githubUrl)),
                            flexAccount("assets/images/instagram.png",
                                "@riccardocescon", () => openWeb(instagramUrl)),
                            flexAccount("assets/images/discord.png",
                                "Logos#1021", () => openWeb(discordUrl)),
                            flexAccount("assets/images/telegram.png",
                                "@IoSonoCesc", () => openWeb(telegramUrl)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openWeb(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("Could not launch url $url");
    }
  }

  Widget flexAccount(String image, String text, Function onClick) {
    return InkWell(
      onTap: () {
        onClick.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Image.asset(image),
            ),
            const Padding(padding: EdgeInsets.only(left: 10)),
            Text(
              text,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget flexText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 30),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
