import 'package:fl_anime_downloader/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'options.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String dropdownvalue = 'Indigo';
  var items = ['Indigo', 'Red', 'Green', 'Amber'];
  String theme = "None";

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)!.settings.arguments;
    Map map = arg != null ? arg as Map : {};
    if (map.isNotEmpty && theme == "None") {
      theme = map["theme"];
      switch (theme) {
        case Utils.themeIndigo:
          dropdownvalue = items[0];
          break;
        case Utils.themeRed:
          dropdownvalue = items[1];
          break;
        case Utils.themeGreen:
          dropdownvalue = items[2];
          break;
        case Utils.themeAmber:
          dropdownvalue = items[3];
          break;
      }
    }

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Utils.getPrimaryColor(theme),
        centerTitle: true,
        title: const Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, Utils.homepage, (route) => false);
            },
            icon: const Icon(Icons.arrow_back)),
      ),
      body: layout(),
    );
  }

  Widget layout() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Padding(padding: EdgeInsets.only(top: 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Utils.animeText("Theme", 24, theme),
              DropdownButton(
                value: dropdownvalue,
                icon:
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
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
          Container(
              margin: const EdgeInsets.only(bottom: 30),
              child: Utils.animeButton("Save", Utils.greenButtonTheme, () {
                uploadTheme(items.indexOf(dropdownvalue));
              })),
        ],
      ),
    );
  }

  void uploadTheme(int pos) async {
    String picked = "";
    switch (pos) {
      case 0:
        picked = Utils.themeIndigo;
        break;
      case 1:
        picked = Utils.themeRed;
        break;
      case 2:
        picked = Utils.themeGreen;
        break;
      case 3:
        picked = Utils.themeAmber;
        break;
    }
    await Options.instance.saveTheme(picked);
    theme = picked;
    print("reloading with theme $theme");
    setState(() {});
  }
}
