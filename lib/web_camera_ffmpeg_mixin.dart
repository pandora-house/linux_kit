import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as m_kit;
import 'package:media_kit_video/media_kit_video.dart' as m_kit_v;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// for Linux implementation
mixin WebCameraFfmpegMixin {
  static const _videoMessageName = 'video_message.mp4';
  static const _videoSessionName = 'camera_session.mp4';

  int? _ffmpegStreamPid;
  int? _ffmpegCopyPid;
  DateTime? _startRecordTime;
  var _pathVideoSession = '';
  var _pathVideoMessage = '';

  late final m_kit.Player _cameraPlayer = m_kit.Player();
  late final m_kit_v.VideoController _cameraPlayerController =
  m_kit_v.VideoController(
    _cameraPlayer,
    configuration: const m_kit_v.VideoControllerConfiguration(
      enableHardwareAcceleration: false,
    ),
  );

  /// отключаем буффер при воспроизведении через mpv
  Future<void> _initCameraPlayerProperty() async {
    if (_cameraPlayer.platform is m_kit.NativePlayer) {
      final native = _cameraPlayer.platform! as m_kit.NativePlayer;
      await native.setProperty('cache-secs', '0');
      await native.setProperty('demuxer-readahead-secs', '0');
      await native.setProperty('untimed', '');
    }
  }

  Future<int> _findEmptyPort() async {
    final socket = await ServerSocket.bind(InternetAddress('127.0.0.1'), 0);
    final port = socket.port;
    unawaited(socket.close());
    return port;
  }

  // TODO handle error process.exitCode != 0
  Future<void> _runFfmpegStream(String udp) async {
    final commandArgs = [
      '-f',
      'v4l2',
      '-i',
      '/dev/video0',
      '-probesize',
      '32',
      '-r',
      '25',
      '-preset',
      'ultrafast',
      '-vcodec',
      'mpeg4',
      '-tune',
      'zerolatency',
      '-f',
      'mpegts',
      udp,
      '-c:v',
      'copy',
      _pathVideoSession,
      '-y',
    ];

    final process = await Process.start(
      'ffmpeg',
      commandArgs,
      mode:ProcessStartMode.inheritStdio,
    );

    _ffmpegStreamPid = process.pid;
  }

  Future<void> start() async {
    _startRecordTime = DateTime.now();
  }

  // TODO handle error process.exitCode != 0
  Future<String> stop() async {
    _killFfmpegStream();
    if (_startRecordTime == null) {
      return '';
    }

    final duration = DateTime
        .now()
        .difference(_startRecordTime!)
        .inSeconds;

    final commandArgs = [
      '-sseof',
      '-$duration',
      '-i',
      _pathVideoSession,
      '-c',
      'copy',
      _pathVideoMessage,
      '-y',
    ];

    final process = await Process.start(
      'ffmpeg',
      commandArgs,
      mode: ProcessStartMode.inheritStdio,
    );

    _ffmpegCopyPid = process.pid;

    return _pathVideoMessage;
  }

  void _killFfmpegStream() {
    if (_ffmpegStreamPid != null) {
      Process.killPid(_ffmpegStreamPid!);
    }
  }

  Future<void> _initPaths() async {
    _pathVideoSession = await _getPath(_videoSessionName);
    _pathVideoMessage = await _getPath(_videoMessageName);
  }

  Widget webCameraOpenView() =>
      _WebCameraView(
        player: _cameraPlayer,
        controller: _cameraPlayerController,
        init: () async {
          final port = await _findEmptyPort();
          final udpUrl = 'udp://127.0.0.1:$port';
          await _initPaths();
          await _initCameraPlayerProperty();
          await _runFfmpegStream(udpUrl);
          await _cameraPlayer.open(m_kit.Media(udpUrl));
        },
        dispose: _disposeWebCamera,
      );

  Future<void> _disposeWebCamera() async {
    await _cameraPlayer.stop();
    await _cameraPlayer.dispose();
    _killFfmpegStream();
    if (_ffmpegCopyPid != null) {
      Process.killPid(_ffmpegCopyPid!);
    }
  }

  Future<String> _getPath(String fileName) async {
    final dir = await getApplicationCacheDirectory();
    return p.join(dir.path, fileName);
  }
}

class _WebCameraView extends StatefulWidget {
  const _WebCameraView({
    required this.controller,
    required this.player,
    required this.init,
    required this.dispose,
  });

  final m_kit_v.VideoController controller;
  final m_kit.Player player;
  final void Function() init;
  final void Function() dispose;

  @override
  State<_WebCameraView> createState() => _WebCameraViewState();
}

class _WebCameraViewState extends State<_WebCameraView> {
  @override
  void initState() {
    super.initState();
    widget.init();
  }

  @override
  void dispose() {
    widget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: widget.player.stream.playing,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return m_kit_v.Video(
          controller: widget.controller,
          controls: null,
          subtitleViewConfiguration:
          const m_kit_v.SubtitleViewConfiguration(visible: false),
        );
      },
    );
  }
}
