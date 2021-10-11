import 'package:fl_anime_downloader/options.dart';

class Anime {
  int id = -1;
  late String name;
  late String downloadLink;
  late String imageLink;
  late String lastDownloadDate;
  int downloadedEps = 0;
  late int allEpisodes = 0;

  Anime({
    required this.name,
    required this.imageLink,
    required this.downloadLink,
    required this.lastDownloadDate,
    required this.allEpisodes,
  });

  Anime.fromMap(Map source) {
    if (source.containsKey(Options.animeId)) {
      id = source[Options.animeId];
    } else {
      print(
          "**** could not create Anime because i'm missing animeId parameter");
    }

    if (source.containsKey(Options.animeName)) {
      name = source[Options.animeName];
    } else {
      print(
          "**** could not create Anime because i'm missing animeName parameter");
    }

    if (source.containsKey(Options.animeImage)) {
      imageLink = source[Options.animeImage];
    } else {
      print(
          "**** could not create Anime because i'm missing animeImage parameter");
    }

    if (source.containsKey(Options.animeDownloadLink)) {
      downloadLink = source[Options.animeDownloadLink];
    } else {
      print(
          "**** could not create Anime because i'm missing animeDownloadLink parameter");
    }

    if (source.containsKey(Options.animeDownlaodedEps)) {
      downloadedEps = source[Options.animeDownlaodedEps];
    } else {
      print(
          "**** could not create Anime because i'm missing animeDownlaodedEps parameter");
    }

    if (source.containsKey(Options.animeTotalEpisodes)) {
      allEpisodes = source[Options.animeTotalEpisodes];
    } else {
      print(
          "**** could not create Anime because i'm missing animeTotalEpisodes parameter");
    }

    if (source.containsKey(Options.animeLastDownloadedDate)) {
      lastDownloadDate = source[Options.animeLastDownloadedDate];
    } else {
      print(
          "**** could not create Anime because i'm missing animeLastDownloadedDate parameter");
    }
  }
}
