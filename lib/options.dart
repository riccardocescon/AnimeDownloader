import 'package:fl_anime_downloader/anime.dart';
import 'package:fl_anime_downloader/main.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Options {
  static const _databaseName = "animeDownlaoder.db";
  static const _databaseVersion = 1;

  // make this a singleton class
  Options._privateConstructor();
  static final Options instance = Options._privateConstructor();

  // only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async =>
      // lazily instantiate the db the first time it is accessed
      _database ??= await _initDatabase();

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    var databaseFactory = databaseFactoryFfi;
    return await databaseFactory.openDatabase(_databaseName,
        options: OpenDatabaseOptions(
            version: _databaseVersion, onCreate: _onCreate));
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute(createOptionsTableQuery);
    await db.execute(createAnimeTableQuery);
  }

  static String optionsTable = "options";
  static String optionsDestinationPath = "optionsDestPath";
  static String noDestinationPath = "No path setted";
  static String optionsTheme = "optionsTheme";
  static String createOptionsTableQuery =
      "CREATE TABLE IF NOT EXISTS $optionsTable ($optionsDestinationPath TEXT DEFAULT '$noDestinationPath', $optionsTheme TEXT DEFAULT '${Utils.themeIndigo}')";

  static String animeTable = "anime";
  static String animeId = "animeId";
  static String animeName = "animeName";
  static String animeImage = "animeImage";
  static String animeDownlaodedEps = "animeDownlaodedEps";
  static String animeDownloadLink = "animeDownloadLink";
  static String animeTotalEpisodes = "animeTotalEpisodes";
  static String animeLastDownloadedDate = "animeLastDownloadedDate";
  static String createAnimeTableQuery =
      "CREATE TABLE IF NOT EXISTS $animeTable ($animeId INTEGER PRIMARY KEY, $animeName TEXT NOT NULL, $animeImage TEXT NOT NULL, $animeDownlaodedEps INTEGER NOT NULL, $animeDownloadLink TEXT NOT NULL, $animeTotalEpisodes INTEGER NOT NULL, $animeLastDownloadedDate TEXT NOT NULL)";

  Future<String> getDestinationPath() async {
    Database db = await instance.database;
    try {
      List<Map> queryRes = await db.rawQuery("SELECT * FROM $optionsTable");
      if (queryRes.isEmpty) {
        return noDestinationPath;
      }
      Map source = queryRes[0];
      return source[optionsDestinationPath];
    } catch (error) {
      print(error);
      return error.toString();
    }
  }

  Future<String> getTheme() async {
    Database db = await instance.database;
    try {
      List<Map> queryRes = await db.rawQuery("SELECT * FROM $optionsTable");
      if (queryRes.isEmpty) {
        return noDestinationPath;
      }
      Map source = queryRes[0];
      return source[optionsTheme];
    } catch (error) {
      print(error);
      return error.toString();
    }
  }

  Future<void> saveDestinationPath(String path) async {
    String _theme = await getTheme();
    Database db = await instance.database;
    await db.delete(optionsTable);
    await db.rawInsert(
        "INSERT INTO $optionsTable($optionsDestinationPath, $optionsTheme) VALUES ('$path', '$_theme')");
  }

  Future<void> saveTheme(String theme) async {
    String _destPath = await getDestinationPath();
    Database db = await instance.database;
    await db.delete(optionsTable);
    await db.rawInsert(
        "INSERT INTO $optionsTable($optionsTheme, $optionsDestinationPath) VALUES ('$theme', '$_destPath')");
  }

  Future<int> insertAnime(Anime anime) async {
    Database db = await instance.database;
    List<Map> res = await db.rawQuery(
        "SELECT * FROM $animeTable WHERE $animeName = ?", [anime.name]);
    if (res.isEmpty) {
      // Insert new anime
      int id = await db.rawInsert(
          "INSERT INTO $animeTable($animeName, $animeImage, $animeDownloadLink, $animeDownlaodedEps, $animeTotalEpisodes, $animeLastDownloadedDate) VALUES (?,?,?,?,?,?)",
          [
            anime.name,
            anime.imageLink,
            anime.downloadLink,
            anime.downloadedEps,
            anime.allEpisodes,
            anime.lastDownloadDate
          ]);
      return id;
    } else {
      // Update anime
      Map<String, dynamic> row = {
        animeDownlaodedEps: anime.downloadedEps,
        animeLastDownloadedDate: anime.lastDownloadDate,
      };
      int id = await db.update(animeTable, row,
          where: "$animeName = ?", whereArgs: [anime.name]);
      return id;
    }
  }

  /// Returns true if the anime get updated, returns false if the anime does not exists
  Future<bool> updateAnime(Anime anime) async {
    Database db = await instance.database;
    List<Map> res = await db.rawQuery(
        "SELECT * FROM $animeTable WHERE $animeName = ?", [anime.name]);
    if (res.isEmpty) {
      return false;
    } else {
      // Update anime
      Map<String, dynamic> row = {
        animeDownloadLink: anime.downloadLink,
        animeDownlaodedEps: anime.downloadedEps,
        animeImage: anime.imageLink,
        animeLastDownloadedDate: anime.lastDownloadDate,
      };
      await db.update(animeTable, row,
          where: "$animeName = ?", whereArgs: [anime.name]);
      return true;
    }
  }

  Future<List<Anime>> selectAllAnime() async {
    List<Anime> allAnime = [];
    Database db = await instance.database;
    List<Map> results = await db.rawQuery("SELECT * FROM $animeTable");
    for (Map current in results) {
      allAnime.add(Anime.fromMap(current));
    }
    return allAnime;
  }

  Future<void> deleteAllAnime() async {
    Database db = await instance.database;
    await db.rawDelete("DELETE FROM $animeTable");
  }

  Future<void> deleteAnime(Anime anime) async {
    Database db = await instance.database;
    await db.rawDelete(
        "DELETE FROM $animeTable WHERE $animeName = ?", [anime.name]);
  }
}
