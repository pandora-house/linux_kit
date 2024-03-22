import 'package:flutter/material.dart';
import 'package:linux_kit/fmedia_linux.dart';
import 'package:linux_kit/web_camera_ffmpeg_mixin.dart';
import 'package:media_kit/media_kit.dart' as m_kit;

void main() {
  m_kit.MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter linux demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FMediaRecorder()),
                );
              },
              child: const Text('Fmedia recorder'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WebCameraRecorder()),
                );
              },
              child: const Text('Webcamera recorder'),
            ),
          ],
        ),
      ),
    );
  }
}

class WebCameraRecorder extends StatefulWidget {
  const WebCameraRecorder({super.key});

  @override
  State<WebCameraRecorder> createState() => _WebCameraRecorderState();
}

class _WebCameraRecorderState extends State<WebCameraRecorder>
    with WebCameraFfmpegMixin {
  var _recording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Webcamera recorder'),
      ),
      body: webCameraOpenView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_recording) {
            setState(() {
              _recording = false;
            });
            final path = await stop();
            print('=============');
            print(path);
            if (!context.mounted) return;
            Navigator.of(context).pop();
          } else {
            setState(() {
              _recording = true;
            });
            await start();
          }
        },
        child: Icon(_recording ? Icons.stop : Icons.play_arrow),
      ),
    );
  }
}

class FMediaRecorder extends StatefulWidget {
  const FMediaRecorder({super.key});

  @override
  State<FMediaRecorder> createState() => _FMediaRecorderState();
}

class _FMediaRecorderState extends State<FMediaRecorder> {
  final _fmedia = FMediaLinux();
  var _recording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fmedia recorder'),
      ),
      body: Center(
        child: IconButton(
          onPressed: () async {
            if (_recording) {
              setState(() {
                _recording = false;
              });
              final path = await _fmedia.stop();
              print(path);
            } else {
              setState(() {
                _recording = true;
              });
              await _fmedia.started();
            }
          },
          icon: Icon(_recording ? Icons.stop : Icons.play_arrow),
        ),
      ),
    );
  }
}
