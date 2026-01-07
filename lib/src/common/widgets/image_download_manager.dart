import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Global singleton that manages all image downloads with queuing and
/// concurrency control
class ImageDownloadManager {
  factory ImageDownloadManager() => _instance;
  ImageDownloadManager._internal();
  static final ImageDownloadManager _instance =
      ImageDownloadManager._internal();

  // Configuration
  static const int _maxConcurrentDownloads = 10;

  // Active downloads tracking
  int _activeDownloads = 0;
  final Queue<_DownloadTask> _downloadQueue = Queue<_DownloadTask>();
  final Map<String, Completer<Uint8List>> _activeRequests = {};

  /// Download image from URL with automatic queuing
  Future<Uint8List> downloadImage({
    required String url,
    required File? file,
    required HttpClient httpClient,
    Map<String, String>? headers,
    void Function(int bytes, int? total)? onProgress,
  }) async {
    // If already downloading this URL, wait for that download
    if (_activeRequests.containsKey(url)) {
      return _activeRequests[url]!.future;
    }

    final completer = Completer<Uint8List>();
    _activeRequests[url] = completer;

    final task = _DownloadTask(
      url: url,
      file: file,
      httpClient: httpClient,
      headers: headers,
      onProgress: onProgress,
      completer: completer,
    );

    if (_activeDownloads < _maxConcurrentDownloads) {
      await _startDownload(task);
    } else {
      _downloadQueue.add(task);
    }

    try {
      return await completer.future;
    } finally {
      _activeRequests.remove(url);
    }
  }

  Future<void> _startDownload(_DownloadTask task) async {
    _activeDownloads++;

    try {
      final bytes = await _performDownload(task);

      // Save to file in isolate (non-blocking)
      if (task.file != null) {
        await compute(_saveFileInIsolate, {
          'path': task.file!.path,
          'bytes': bytes,
        });
      }

      task.completer.complete(bytes);
    } catch (error, stackTrace) {
      task.completer.completeError(error, stackTrace);
    } finally {
      _activeDownloads--;
      _processNextInQueue();
    }
  }

  Future<Uint8List> _performDownload(_DownloadTask task) async {
    final resolved = Uri.base.resolve(task.url);
    final request = await task.httpClient.getUrl(resolved);

    task.headers?.forEach((name, value) {
      request.headers.add(name, value);
    });

    final response = await request.close();

    if (response.statusCode != HttpStatus.ok) {
      await response.drain<List<int>?>();
      throw HttpException(
        'Failed to download: ${response.statusCode}',
        uri: resolved,
      );
    }

    final bytes = await consolidateHttpClientResponseBytes(
      response,
      onBytesReceived: task.onProgress,
    );

    if (bytes.lengthInBytes == 0) {
      throw Exception('Downloaded image is empty: $resolved');
    }

    return bytes;
  }

  void _processNextInQueue() {
    if (_downloadQueue.isNotEmpty &&
        _activeDownloads < _maxConcurrentDownloads) {
      final nextTask = _downloadQueue.removeFirst();
      _startDownload(nextTask);
    }
  }
}

/// Internal task representation
class _DownloadTask {
  _DownloadTask({
    required this.url,
    required this.file,
    required this.httpClient,
    required this.headers,
    required this.onProgress,
    required this.completer,
  });
  final String url;
  final File? file;
  final HttpClient httpClient;
  final Map<String, String>? headers;
  final void Function(int bytes, int? total)? onProgress;
  final Completer<Uint8List> completer;
}

/// Top-level function for isolate (must be top-level or static)
Future<void> _saveFileInIsolate(Map<String, dynamic> params) async {
  final file = File(params['path'] as String);
  final bytes = params['bytes'] as Uint8List;

  // Ensure directory exists
  if (!file.parent.existsSync()) {
    await file.parent.create(recursive: true);
  }

  await file.writeAsBytes(bytes, flush: true);
}
