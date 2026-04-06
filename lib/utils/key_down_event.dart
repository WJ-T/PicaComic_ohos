import 'dart:async';
import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/platform_utils.dart';

bool get supportsVolumeKeyListener =>
    App.isAndroid || App.isIOS || PlatformUtils.isOhos;

class ListenVolumeController{
  void Function() whenUp;
  void Function() whenDown;
  static const channel = EventChannel("com.github.pacalini.pica_comic/volume");
  StreamSubscription? _streamSubscription;

  ListenVolumeController(this.whenUp,this.whenDown);

  void listenVolumeChange(){
    if(!supportsVolumeKeyListener)  return;
    _streamSubscription = channel.receiveBroadcastStream().listen((event) {
      if(event == 1){
        whenUp();
      }else if(event==2){
        whenDown();
      }
    });
  }

  void stop(){
    if(!supportsVolumeKeyListener)  return;
    _streamSubscription?.cancel();
  }
}
