import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

// --- HLS.js Interop ---

@JS('Hls')
@staticInterop
class Hls {
  external factory Hls([JSObject? config]);
  
  @JS('isSupported')
  external static bool isSupported();
}

extension HlsTrackExtension on JSObject {
  external String? get name;
  external String? get lang;

  String get displayName {
    final n = name;
    final l = lang;
    if (n != null && n.isNotEmpty) return n;
    if (l != null && l.isNotEmpty) return l;
    return 'Unknown';
  }
}

extension HlsExtension on Hls {
  external void loadSource(String src);
  external void attachMedia(web.HTMLVideoElement video);
  external void on(String event, JSFunction callback);
  external void startLoad();
  
  external JSArray<JSObject> get audioTracks;
  external set audioTrack(int index);
  external int get audioTrack;

  external JSArray<JSObject> get subtitleTracks;
  external set subtitleTrack(int index);
  external int get subtitleTrack;
}

class Html5VideoPlayer extends StatefulWidget {
  final String url;
  final bool autoPlay;
  final bool controls;
  final bool muted;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onEnded;
  final bool isLive; 
  final Function(String)? onError;

  const Html5VideoPlayer({
    super.key,
    required this.url,
    this.autoPlay = true,
    this.controls = true,
    this.muted = false,
    this.isLive = false,
    this.onPlay,
    this.onPause,
    this.onEnded,
    this.onError,
  });

  @override
  State<Html5VideoPlayer> createState() => _Html5VideoPlayerState();
}

class _Html5VideoPlayerState extends State<Html5VideoPlayer> {
  late web.HTMLVideoElement _videoElement;
  late String _viewType;
  bool _isInitialized = false;
  Hls? _hls;
  
  List<JSObject> _audioTracks = [];
  List<JSObject> _subtitleTracks = [];
  int _currentAudioIndex = -1;
  int _currentSubtitleIndex = -1;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _viewType = 'video-player-${DateTime.now().millisecondsSinceEpoch}';
    
    _videoElement = web.HTMLVideoElement();
    _videoElement.controls = widget.controls;
    _videoElement.autoplay = widget.autoPlay;
    _videoElement.muted = widget.muted || widget.autoPlay;
    
    _videoElement.style.width = '100%';
    _videoElement.style.height = '100%';
    _videoElement.style.objectFit = 'contain';
    _videoElement.style.backgroundColor = '#000000';

    _videoElement.onplay = ((web.Event e) => widget.onPlay?.call()).toJS;
    _videoElement.onpause = ((web.Event e) => widget.onPause?.call()).toJS;
    _videoElement.onended = ((web.Event e) => widget.onEnded?.call()).toJS;
    _videoElement.onerror = ((web.Event e) {
       if (_hls == null) widget.onError?.call('Playback error');
    }).toJS;

    _videoElement.onloadedmetadata = ((web.Event e) {
      if (mounted) setState(() => _isInitialized = true);
    }).toJS;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _videoElement,
    );
    
    _loadStream(widget.url);
  }

  void _loadStream(String src) {
     if (src.toLowerCase().contains('.m3u8') && _isHlsSupported()) {
         _initHls(src);
     } else {
         _videoElement.src = src;
     }
  }

  bool _isHlsSupported() {
    try {
      return Hls.isSupported();
    } catch (e) {
      return false;
    }
  }

  void _initHls(String src) {
     try {
       final config = JSObject();
       config.setProperty('maxBufferLength'.toJS, 30.toJS);
       config.setProperty('maxMaxBufferLength'.toJS, 600.toJS);
       config.setProperty('enableWorker'.toJS, true.toJS);

       if (widget.isLive) {
           config.setProperty('liveSyncDurationCount'.toJS, 3.toJS);
           config.setProperty('liveMaxLatencyDurationCount'.toJS, 10.toJS);
           config.setProperty('infiniteLiveStream'.toJS, true.toJS);
       } else {
           config.setProperty('startFragPrefetch'.toJS, true.toJS);
       }
       
       final hls = Hls(config);
       _hls = hls;
       hls.loadSource(src);
       hls.attachMedia(_videoElement);
       
       hls.on('hlsManifestParsed', (() {
         if (widget.autoPlay) _videoElement.play();
         _updateTracks();
       }).toJS);
       
       hls.on('hlsAudioTracksUpdated', (() => _updateTracks()).toJS);
       hls.on('hlsSubtitleTracksUpdated', (() => _updateTracks()).toJS);
     } catch (e) {
       _videoElement.src = src;
     }
  }

  void _updateTracks() {
    if (_hls == null) return;
    try {
      final audios = _hls!.audioTracks.toDart;
      final subs = _hls!.subtitleTracks.toDart;
      
      setState(() {
        _audioTracks = audios;
        _subtitleTracks = subs;
        _currentAudioIndex = _hls!.audioTrack;
        _currentSubtitleIndex = _hls!.subtitleTrack;
      });
    } catch (e) {
    }
  }

  void _setAudioTrack(int index) {
    if (_hls != null) {
      _hls!.audioTrack = index;
      _updateTracks();
    }
  }

  void _setSubtitleTrack(int index) {
    if (_hls != null) {
      _hls!.subtitleTrack = index;
      _updateTracks();
    }
  }

  void _showTrackDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Audio', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTrackList(_audioTracks, _currentAudioIndex, _setAudioTrack),
            const Divider(color: Colors.grey),
            const Text('Subtitles', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
            _buildTrackList(_subtitleTracks, _currentSubtitleIndex, _setSubtitleTrack, isSubtitle: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList(List<JSObject> tracks, int currentIndex, Function(int) onSelect, {bool isSubtitle = false}) {
    if (tracks.isEmpty) return const Text('None available', style: TextStyle(color: Colors.grey));
    
    return Wrap(
      spacing: 8,
      children: [
        if (isSubtitle) 
           ChoiceChip(
            label: const Text('Off'),
            selected: currentIndex == -1,
            onSelected: (_) => onSelect(-1),
          ),
        ...List.generate(tracks.length, (index) {
          final track = tracks[index];
          return ChoiceChip(
            label: Text(track.displayName),
            selected: currentIndex == index,
            onSelected: (_) => onSelect(index),
          );
        }),
      ],
    );
  }

  @override
  void didUpdateWidget(Html5VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
       if (_hls != null) {
          _hls!.loadSource(widget.url);
       } else {
          _videoElement.src = widget.url;
          if (widget.autoPlay) _videoElement.play();
       }
    }
  }

  @override
  void dispose() {
    _videoElement.pause();
    _videoElement.removeAttribute('src');
    _videoElement.load();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: HtmlElementView(viewType: _viewType),
        ),
        if (_hls != null && (_audioTracks.length > 1 || _subtitleTracks.isNotEmpty))
          Positioned(
            top: 20,
            right: 20,
            child: Material(
               color: Colors.black54,
               shape: const CircleBorder(),
               child: IconButton(
                 icon: const Icon(Icons.settings, color: Colors.white),
                 onPressed: _showTrackDialog,
                 tooltip: 'Audio & Subtitles',
               ),
            ),
          ),
      ],
    );
  }
}
