import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config.dart';

/// Wolof text-to-speech via the Oolel-Voices Hugging Face Space (Gradio API).
///
/// No reference audio is sent: the model falls back to its default voice
/// (see soynade-research/Oolel-Voices-Demo app.py — audio_prompt_path is
/// optional). This keeps the app free of any bundled/cached voice sample.
class TtsService {
  /// Returns a local file path with the synthesized audio for [text].
  /// Subsequent calls with the same text are served from disk cache.
  /// Throws [TtsException] on failure.
  static Future<String> synthesize(String text) async {
    final cachePath = await _cacheFilePath(text);
    if (await File(cachePath).exists()) return cachePath;

    final audioUrl = await _requestAudioUrl(text);
    final bytes = await _download(audioUrl);

    final file = File(cachePath);
    await file.writeAsBytes(bytes, flush: true);
    return cachePath;
  }

  static Future<String> _cacheFilePath(String text) async {
    final dir = await getTemporaryDirectory();
    final hash = sha256.convert(utf8.encode(text)).toString();
    return '${dir.path}/gblackai_tts_$hash.wav';
  }

  static Future<String> _requestAudioUrl(String text) async {
    // The demo caps generation at 500 chars; the backend prompt already
    // targets ~350 chars, this is just a safety net.
    final truncated = text.length > 480 ? text.substring(0, 480) : text;
    final submitUri = Uri.parse('$kOolelSpaceUrl/gradio_api/call/$kTtsApiName');

    final http.Response submitResp;
    try {
      submitResp = await http
          .post(
            submitUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'data': [truncated, null, 0.3, 0.2, 0, 0.5],
            }),
          )
          .timeout(kTtsRequestTimeout);
    } on TimeoutException {
      throw const TtsException(
          'The Wolof voice service is taking too long to respond.');
    } on SocketException {
      throw const TtsException('No connection to the Wolof voice service.');
    }

    if (submitResp.statusCode != 200) {
      throw TtsException(
          'Wolof voice service unavailable (${submitResp.statusCode}).');
    }

    final eventId =
        (jsonDecode(submitResp.body) as Map<String, dynamic>)['event_id']
            as String?;
    if (eventId == null) {
      throw const TtsException(
          'Wolof voice service returned an unexpected response.');
    }

    return _listenForAudioUrl(eventId);
  }

  static Future<String> _listenForAudioUrl(String eventId) async {
    final streamUri =
        Uri.parse('$kOolelSpaceUrl/gradio_api/call/$kTtsApiName/$eventId');
    final request = http.Request('GET', streamUri);
    final http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(kTtsRequestTimeout);
    } on TimeoutException {
      throw const TtsException('The Wolof voice generation timed out.');
    }

    final completer = Completer<String>();
    String? lastEvent;
    late final StreamSubscription<String> sub;

    sub = streamed.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        if (line.startsWith('event:')) {
          lastEvent = line.substring(6).trim();
          return;
        }
        if (!line.startsWith('data:')) return;
        final data = line.substring(5).trim();

        if (lastEvent == 'error') {
          sub.cancel();
          if (!completer.isCompleted) {
            completer.completeError(
                TtsException('Wolof voice generation failed: $data'));
          }
          return;
        }

        if (lastEvent == 'complete') {
          try {
            final parsed = jsonDecode(data) as List<dynamic>;
            final first = parsed.first as Map<String, dynamic>;
            final url = first['url'] as String;
            sub.cancel();
            if (!completer.isCompleted) completer.complete(url);
          } catch (_) {
            sub.cancel();
            if (!completer.isCompleted) {
              completer.completeError(
                  const TtsException('Could not parse the audio response.'));
            }
          }
        }
      },
      onError: (Object e) {
        if (!completer.isCompleted) {
          completer.completeError(TtsException('Wolof voice stream error: $e'));
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(const TtsException(
              'Wolof voice service closed the connection unexpectedly.'));
        }
      },
      cancelOnError: true,
    );

    return completer.future.timeout(
      kTtsRequestTimeout,
      onTimeout: () {
        sub.cancel();
        throw const TtsException('The Wolof voice generation timed out.');
      },
    );
  }

  static Future<List<int>> _download(String url) async {
    final http.Response resp;
    try {
      resp = await http.get(Uri.parse(url)).timeout(kTtsRequestTimeout);
    } on TimeoutException {
      throw const TtsException('Downloading the audio took too long.');
    }
    if (resp.statusCode != 200) {
      throw TtsException(
          'Could not download the generated audio (${resp.statusCode}).');
    }
    return resp.bodyBytes;
  }
}

class TtsException implements Exception {
  final String message;
  const TtsException(this.message);

  @override
  String toString() => message;
}
