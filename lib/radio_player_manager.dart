import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:math';

class RadioPlayerManager {
  final AudioPlayer player = AudioPlayer();
  bool isPlaying = false;
  int currentSongIndex = 0;

  final List<Map<String, String>> playlist = [
    {"title": "Ah.Lw.L3bt.Ya.Zhr", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Ah.Lw.L3bt.Ya.Zhr.mp3"},
    {"title": "Ana_Mosh_3arefni", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Ana_Mosh_3arefni%20.mp3"},
    {"title": "El Gany Baad Yomen", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/El%20Gany%20Baad%20Yomen.mp3"},
    {"title": "Dol-Mish-Habayeb", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Dol-Mish-Habayeb.mp3"},
    {"title": "El Saa 2 Bel Lail", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/El%20Saa%202%20Bel%20Lail.mp3"},
    {"title": "Habayeb_Eh", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Habayeb_Eh.mp3"},
    {"title": "Mai_Mahmoud_Ana_El_Motayyam", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Mai_Mahmoud_Ana_El_Motayyam.mp3"},
    {"title": "Mai_Mahmoud_Bakam_Thamani", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Mai_Mahmoud_Bakam_Thamani.mp3"},
    {"title": "Mai_Mahmoud_Day_El_Qamar", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Mai_Mahmoud_Day_El_Qamar.mp3"},
    {"title": "Mai_Mahmoud_Hafez_El_Rouh", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Mai_Mahmoud_Hafez_El_Rouh.mp3"},
    {"title": "Mai_Mahmoud_Khayan", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Mai_Mahmoud_Khayan.mp3"},
    {"title": "Mai_Mahmoud_Sir_El_Hawa", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Mai_Mahmoud_Sir_El_Hawa.mp3"},
    {"title": "Motashakerin", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Motashakerin.mp3"},
    {"title": "Nesyanak Sa3b Akid", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Nesyanak%20Sa3b%20Akid.mp3"},
    {"title": "Oddam_El_Nas", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/Oddam_El_Nas.mp3"},
    {"title": "El_Youmeen_Dool_Bosy", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/_El_Youmeen_Dool_-_Bosy.mp3"},
    {"title": "ahli_rsmh", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/ahli_rsmh.mp3"},
    {"title": "algay_btaay", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/algay_btaay.mp3"},
    {"title": "ana_mn_ghyrk", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/ana_mn_ghyrk.mp3"},
    {"title": "ana_msh_fadlkwa", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/ana_msh_fadlkwa.mp3"},
    {"title": "anta_omry", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/anta_omry.mp3"},
    {"title": "atakhr_atabna", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/atakhr_atabna.mp3"},
    {"title": "balbnt_alaryd", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/balbnt_alaryd.mp3"},
    {"title": "bhryh", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/bhryh.mp3"},
    {"title": "ekthary", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/ekthary.mp3"},
    {"title": "el7dod", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/el7dod.mp3"},
    {"title": "et5ad3na", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/et5ad3na.mp3"},
    {"title": "fi_elrokn_elba3ed", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/fi_elrokn_elba3ed.mp3"},
    {"title": "halwanhm", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/halwanhm.mp3"},
    {"title": "hbyby_ana_mn_ghyrk", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/hbyby_ana_mn_ghyrk.mp3"},
    {"title": "kda_kda", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/kda_kda.mp3"},
    {"title": "kdh_ya_klby", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/kdh_ya_klby.mp3"},
    {"title": "kitab_7yaty", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/kitab_7yaty.mp3"},
    {"title": "lakayetk", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/lakayetk.mp3"},
    {"title": "lwla_albnat", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/lwla_albnat.mp3"},
    {"title": "mahbetk_gnon", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/mahbetk_gnon.mp3"},
    {"title": "set_elnas", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/set_elnas.mp3"},
    {"title": "tbaaa_tbaaa", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/tbaaa_tbaaa.mp3"},
    {"title": "tybt_tany_la", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/tybt_tany_la.mp3"},
    {"title": "wnfdl_nrks", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/wnfdl_nrks.mp3"},
    {"title": "ya_5ofy", "url": "https://github.com/hayamahmoud049-bot/sout_we_rouh/raw/refs/heads/main/ya_5ofy.mp3"},
    {"title": "7kety_m3_ezman", "url": "https://github.com/soutwerouh-cloud/sout_we_rouh/raw/refs/heads/main/7kety_m3_ezman.mp3"},
  ];

  void shufflePlaylist() {
    playlist.shuffle(Random());
  }

  Future<void> initAudio(Function onStateChanged) async {
    try {
      shufflePlaylist();
      currentSongIndex = 0;
      
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          playNext(onStateChanged);
        }
      });

      await player.setUrl(playlist[currentSongIndex]["url"]!, preload: true);
      player.play();
      isPlaying = true;
      onStateChanged();
    } catch (e) {
      debugPrint("خطأ في تشغيل الراديو: $e");
    }
  }

  Future<void> _playSongAtIndex(int index, Function onStateChanged) async {
    try {
      currentSongIndex = index;
      await player.stop();
      await player.setUrl(playlist[currentSongIndex]["url"]!, preload: true);
      player.play();
      isPlaying = true;
      onStateChanged();
    } catch (e) {
      debugPrint("خطأ في تشغيل الأغنية: $e");
    }
  }

  Future<void> playNext(Function onStateChanged) async {
    int nextIndex = Random().nextInt(playlist.length);
    await _playSongAtIndex(nextIndex, onStateChanged);
  }

  Future<void> playPrevious(Function onStateChanged) async {
    int prevIndex = Random().nextInt(playlist.length);
    await _playSongAtIndex(prevIndex, onStateChanged);
  }

  Future<void> togglePlayPause(Function onStateChanged) async {
    isPlaying = !isPlaying;
    if (isPlaying) {
      await player.play();
    } else {
      await player.pause();
    }
    onStateChanged();
  }

  void dispose() {
    player.dispose();
  }
}