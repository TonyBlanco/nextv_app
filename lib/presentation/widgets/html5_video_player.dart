export 'html5_video_player_stub.dart'
    if (dart.library.js_util) 'html5_video_player_web.dart'
    if (dart.library.html) 'html5_video_player_web.dart'
    if (dart.library.js_interop) 'html5_video_player_web.dart';
