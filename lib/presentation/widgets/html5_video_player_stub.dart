import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('HTML5 Player only works on web'));
  }
}
