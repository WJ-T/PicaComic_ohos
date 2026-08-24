import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/app.dart';

bool get supportsKeepScreenOn => App.isAndroid || App.isIOS;

void setKeepScreenOn() async{
  if(!supportsKeepScreenOn)  return;
  var channel = const MethodChannel("com.github.pacalini.pica_comic/keepScreenOn");
  await channel.invokeMethod("set");
}

void cancelKeepScreenOn() async{
  if(!supportsKeepScreenOn)  return;
  var channel = const MethodChannel("com.github.pacalini.pica_comic/keepScreenOn");
  await channel.invokeMethod("cancel");
}
