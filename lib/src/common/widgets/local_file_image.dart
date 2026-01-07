// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes, prefer_asserts_with_message, lines_longer_than_80_chars, avoid_annotating_with_dynamic

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui show Codec;
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:powersync_attachments_example/src/common/widgets/image_download_manager.dart';

// Top-level function
bool _checkFileExists(String path) => File(path).existsSync();

/// This is a mixture of [FileImage] and [NetworkImage].
/// It will download the image from the url once, save it locally in the file system,
/// and then use it from there in the future.
///
/// In more detail:
///
/// Given a file and url of an image, it first tries to read it from the local file.
/// It decodes the given [File] object as an image, associating it with the given scale.
///
/// However, if the image doesn't yet exist as a local file, it fetches the given URL
/// from the network, associating it with the given scale, and then saves it to the local file.
/// The image will be cached regardless of cache headers from the server.
///
/// Notes:
///
/// - If the provided url is null or empty, [NetworkToFileImage] will default
/// to [FileImage]. It will read the image from the local file, and won't try to
/// download it from the network.
///
/// - If the provided file is null, [NetworkToFileImage] will default
/// to [NetworkImage]. It will download the image from the network, and won't
/// save it locally.
///
/// - If you make debug=true it will log to the console whether the image was
/// read from the file or fetched from the network.
///
/// ## Tests
///
/// You can set mock files. Please see methods:
///
/// * `setMockFile(File file, Uint8List bytes)`
/// * `setMockUrl(String url, Uint8List bytes)`
/// * `clearMocks()`
/// * `clearMockFiles()`
/// * `clearMockUrls()`
///
/// ## See also:
///
///  * flutter_image: https://pub.dartlang.org/packages/flutter_image
///  * image_downloader: https://pub.dartlang.org/packages/image_downloader
///  * cached_network_image: https://pub.dartlang.org/packages/cached_network_image
///  * flutter_advanced_networkimage: https://pub.dartlang.org/packages/flutter_advanced_networkimage
class NetworkToFileImage extends ImageProvider<NetworkToFileImage>
    with EquatableMixin {
  //
  const NetworkToFileImage({
    /// Same parameter as [FileImage].
    this.file,

    /// Same parameter as [NetworkImage].
    this.url,

    /// Same parameter as both [FileImage] and [NetworkImage].
    this.scale = 1.0,

    /// Same parameter as [NetworkImage].
    this.headers,

    /// If debug is true, log to the console if the image is from file or network.
    this.debug = false,
  }) : assert(file != null || url != null);

  final File? file;
  final String? url;
  final double scale;
  final Map<String, String>? headers;
  final bool debug;

  static final Map<String, Uint8List?> _mockFiles = {};
  static final Map<String, Uint8List> _mockUrls = {};

  /// Call this if you want your mock urls to be visible for regular http requests.
  static void startHttpOverride() {
    HttpOverrides.global = _MockHttpOverrides();
  }

  static void stopHttpOverride() {
    HttpOverrides.global = null;
  }

  /// You can set mock files. It searches for an exact file.path (string comparison).
  /// To set an empty file, use null: `setMockFile(File("photo.png"), null);`
  static void setMockFile(File file, Uint8List? bytes) {
    _mockFiles[file.path] = bytes;
  }

  /// You can set mock urls. It searches for an exact url (string comparison).
  static void setMockUrl(String url, Uint8List bytes) {
    _mockUrls[url] = bytes;
  }

  static void clearMocks() {
    clearMockFiles();
    clearMockUrls();
  }

  static void clearMockFiles() {
    _mockFiles.clear();
  }

  static void clearMockUrls() {
    _mockUrls.clear();
  }

  @override
  Future<NetworkToFileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<NetworkToFileImage>(this);

  // New: override resolveStreamForKey to integrate with ImageCache.containsKey
  // and to keep logging behavior without reimplementing error handling.
  @override
  void resolveStreamForKey(
    ImageConfiguration configuration,
    ImageStream stream,
    NetworkToFileImage key,
    ImageErrorListener handleError,
  ) {
    final cache = PaintingBinding.instance.imageCache;
    final inCache = cache.containsKey(key);
    if (debug) {
      log(
        'ImageCache status for key $key: ${cache.statusForKey(key)}, '
        'cache size: ${cache.currentSize}, cache limit: ${cache.maximumSize}, '
        'current size bytes: ${(cache.currentSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB, cache limit bytes: ${(cache.maximumSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
      );
      log(
        inCache
            ? 'ImageCache hit for $key'
            : 'ImageCache miss for $key — will load if not pending',
      );
    }
    // Delegate to default cache+load behavior, which calls loadImage() below as needed.
    super.resolveStreamForKey(configuration, stream, key, handleError);
  }

  @override
  ImageStreamCompleter loadImage(
    NetworkToFileImage key,
    ImageDecoderCallback decode,
  ) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: 'File: ${key.file?.path}, Url: ${key.url}',
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Image provider: $this'),
        ErrorDescription('File: ${file?.path}'),
        ErrorDescription('Url: $url'),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    NetworkToFileImage key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    try {
      assert(key == this);
      // ---

      final file = key.file;
      final url = key.url;

      late Uint8List bytes;

      // Reads a MOCK file.
      if (file != null && _mockFiles.containsKey(file.path)) {
        bytes = _mockFiles[file.path] ?? Uint8List(0);
      }
      // Reads from the local file.
      else if (file != null && _checkFileExists(file.path)) {
        if (debug) log('Reading image file: ${file.path}');

        // Read file in isolate to avoid blocking
        bytes = File(file.path).readAsBytesSync();
      }
      // Reads from the MOCK network and saves it to the local file.
      // Note: This wouldn't be necessary when startHttpOverride() is called.
      else if (url != null && url.isNotEmpty && _mockUrls.containsKey(url)) {
        bytes = await _downloadFromTheMockNetworkAndSaveToTheLocalFile(
          file,
          url,
        );
      }
      // Reads from the network and saves it to the local file.
      else if (url != null && url.isNotEmpty) {
        bytes = await _downloadFromTheNetworkAndSaveToTheLocalFile(
          chunkEvents,
          file,
          url,
        );
      }
      // This is executed when:
      // - Both the url and the file are null. Or,
      // - The file doesn't exist locally, but the url was not provided.
      else {
        final uri = (url == null) ? null : Uri.base.resolve(url);
        throw NetworkToFileImageLoadException(
          file: file,
          uri: uri,
          statusCode: 0,
        );
      }

      return decode(await ImmutableBuffer.fromUint8List(bytes));
    } catch (error) {
      if (debug) log('Failed fetching image from: $url - $error');
      // Depending on where the exception was thrown, the image cache may not have had a chance to
      // track the key in the cache. Schedule a microtask to give the cache a chance to add the key.
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });

      rethrow;
      //
    } finally {
      await chunkEvents.close();
    }
  }

  Future<Uint8List> _downloadFromTheNetworkAndSaveToTheLocalFile(
    StreamController<ImageChunkEvent> chunkEvents,
    File? file,
    String url,
  ) async {
    assert(url.isNotEmpty, 'Url cannot be empty');
    if (debug) log('Fetching image from: $url');

    // Use the global download manager instead of downloading directly
    try {
      final bytes = await ImageDownloadManager().downloadImage(
        url: url,
        file: file,
        httpClient: _httpClient,
        headers: headers,
        onProgress: (cumulative, total) {
          chunkEvents.add(
            ImageChunkEvent(
              cumulativeBytesLoaded: cumulative,
              expectedTotalBytes: total,
            ),
          );
        },
      );

      return bytes;
    } catch (error) {
      if (debug) log('Failed fetching image from: $url - $error');
      rethrow;
    }
  }

  // Do not access this field directly; use [_httpClient] instead.
  // We set `autoUncompress` to false to ensure that we can trust the value of
  // the `Content-Length` HTTP header. We automatically uncompress the content
  // in our call to [consolidateHttpClientResponseBytes].
  static final HttpClient _sharedHttpClient = HttpClient()
    ..autoUncompress = false;

  static HttpClient get _httpClient {
    var client = _sharedHttpClient;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null) {
        client = debugNetworkImageHttpClientProvider!();
      }
      return true;
    }());
    return client;
  }

  Future<Uint8List> _downloadFromTheMockNetworkAndSaveToTheLocalFile(
    File? file,
    String url,
  ) async {
    assert(url.isNotEmpty, 'Url cannot be empty');
    if (debug) log('Fetching image from: $url');
    // ---

    final resolved = Uri.base.resolve(url);
    final bytes = _mockUrls[url] ?? Uint8List(0);
    if (bytes.lengthInBytes == 0) {
      throw Exception('NetworkImage is an empty file: $resolved');
    }

    if (file != null) await saveImageToTheLocalFile(file, bytes);

    return bytes;
  }

  Future<void> saveImageToTheLocalFile(File file, Uint8List bytes) async {
    if (debug) log('Saving image to file: ${file.path}');
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  List<Object?> get props => [file?.path, url, scale];
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _MockHttpClient(super.createHttpClient(context));
}

class _MockHttpClient implements HttpClient {
  _MockHttpClient(this._realClient);
  //
  final HttpClient _realClient;

  @override
  bool get autoUncompress => _realClient.autoUncompress;

  @override
  set autoUncompress(bool value) => _realClient.autoUncompress = value;

  @override
  Duration? get connectionTimeout => _realClient.connectionTimeout;

  @override
  set connectionTimeout(Duration? value) =>
      _realClient.connectionTimeout = value;

  @override
  Duration get idleTimeout => _realClient.idleTimeout;

  @override
  set idleTimeout(Duration value) => _realClient.idleTimeout = value;

  @override
  int? get maxConnectionsPerHost => _realClient.maxConnectionsPerHost;

  @override
  set maxConnectionsPerHost(int? value) =>
      _realClient.maxConnectionsPerHost = value;

  @override
  String? get userAgent => _realClient.userAgent;

  @override
  set userAgent(String? value) => _realClient.userAgent = value;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) => _realClient.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) => _realClient.addProxyCredentials(host, port, realm, credentials);

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) => _realClient.authenticate = f;

  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) => _realClient.authenticateProxy = f;

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) => _realClient.badCertificateCallback = callback;

  @override
  void close({bool force = false}) => _realClient.close(force: force);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      _realClient.delete(host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => _realClient.deleteUrl(url);

  @override
  set findProxy(String Function(Uri url)? f) => _realClient.findProxy = f;

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      _realClient.get(host, port, path);

  /// Searches the mock first.
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final urlStr = url.toString();

    if (urlStr.isNotEmpty && NetworkToFileImage._mockUrls.containsKey(urlStr)) {
      return _MockHttpClientRequest(NetworkToFileImage._mockUrls[urlStr]);
    }

    return _realClient.getUrl(url);
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      _realClient.head(host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => _realClient.headUrl(url);

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) => _realClient.open(method, host, port, path);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    if (method == 'GET') {
      final urlStr = url.toString();

      if (urlStr.isNotEmpty &&
          NetworkToFileImage._mockUrls.containsKey(urlStr)) {
        return _MockHttpClientRequest(NetworkToFileImage._mockUrls[urlStr]);
      }
    }
    return _realClient.openUrl(method, url);
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      _realClient.patch(host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _realClient.patchUrl(url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _realClient.post(host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => _realClient.postUrl(url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      _realClient.put(host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => _realClient.putUrl(url);

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
    f,
  ) => _realClient.connectionFactory = f;

  @override
  set keyLog(void Function(String line)? callback) =>
      _realClient.keyLog = callback;
}

class _MockHttpClientRequest implements HttpClientRequest {
  _MockHttpClientRequest(this.bytes);
  //
  final Uint8List? bytes;

  @override
  late Encoding encoding;

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  bool bufferOutput = true;

  @override
  int contentLength = -1;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) => Future<void>.value();

  @override
  Future<HttpClientResponse> close() => done;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => [];

  @override
  Future<HttpClientResponse> get done =>
      SynchronousFuture<HttpClientResponse>(_MockHttpClientResponse(bytes!));

  @override
  Future<void> flush() => Future<void>.value();

  @override
  String get method => '';

  @override
  Uri get uri => Uri();

  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? obj = '']) {}

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
}

class _MockHttpClientResponse implements HttpClientResponse {
  _MockHttpClientResponse(Uint8List bytes)
    : _delegate = Stream<Uint8List>.value(bytes),
      _contentLength = bytes.length;
  //
  final Stream<Uint8List> _delegate;
  final int _contentLength;

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  int get contentLength => _contentLength;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.decompressed;

  @override
  List<Cookie> get cookies => [];

  @override
  Future<Socket> detachSocket() =>
      Future<Socket>.error(UnsupportedError('Mocked response'));

  @override
  bool get isRedirect => false;

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _delegate.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => '';

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) => Future<HttpClientResponse>.error(UnsupportedError('Mocked response'));

  @override
  List<RedirectInfo> get redirects => <RedirectInfo>[];

  @override
  int get statusCode => 200;

  @override
  Future<bool> any(bool Function(Uint8List element) test) =>
      _delegate.any(test);

  @override
  Stream<Uint8List> asBroadcastStream({
    void Function(StreamSubscription<Uint8List> subscription)? onListen,
    void Function(StreamSubscription<Uint8List> subscription)? onCancel,
  }) => _delegate.asBroadcastStream(onListen: onListen, onCancel: onCancel);

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(Uint8List event) convert) =>
      _delegate.asyncExpand<E>(convert);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(Uint8List event) convert) =>
      _delegate.asyncMap<E>(convert);

  @override
  Stream<R> cast<R>() => _delegate.cast<R>();

  @override
  Future<bool> contains(Object? needle) => _delegate.contains(needle);

  @override
  Stream<Uint8List> distinct([
    bool Function(Uint8List previous, Uint8List next)? equals,
  ]) => _delegate.distinct(equals);

  @override
  Future<E> drain<E>([E? futureValue]) => _delegate.drain<E>(futureValue);

  @override
  Future<Uint8List> elementAt(int index) => _delegate.elementAt(index);

  @override
  Future<bool> every(bool Function(Uint8List element) test) =>
      _delegate.every(test);

  @override
  Stream<S> expand<S>(Iterable<S> Function(Uint8List element) convert) =>
      _delegate.expand(convert);

  @override
  Future<Uint8List> get first => _delegate.first;

  @override
  Future<Uint8List> firstWhere(
    bool Function(Uint8List element) test, {
    List<int> Function()? orElse,
  }) => _delegate.firstWhere(test, orElse: () => Uint8List.fromList(orElse!()));

  @override
  Future<S> fold<S>(
    S initialValue,
    S Function(S previous, Uint8List element) combine,
  ) => _delegate.fold<S>(initialValue, combine);

  @override
  Future<dynamic> forEach(void Function(Uint8List element) action) =>
      _delegate.forEach(action);

  @override
  Stream<Uint8List> handleError(
    Function onError, {
    bool Function(dynamic error)? test,
  }) => _delegate.handleError(onError, test: test);

  @override
  bool get isBroadcast => _delegate.isBroadcast;

  @override
  Future<bool> get isEmpty => _delegate.isEmpty;

  @override
  Future<String> join([String separator = '']) => _delegate.join(separator);

  @override
  Future<Uint8List> get last => _delegate.last;

  @override
  Future<Uint8List> lastWhere(
    bool Function(Uint8List element) test, {
    List<int> Function()? orElse,
  }) => _delegate.lastWhere(test, orElse: () => Uint8List.fromList(orElse!()));

  @override
  Future<int> get length => _delegate.length;

  @override
  Stream<S> map<S>(S Function(Uint8List event) convert) =>
      _delegate.map<S>(convert);

  @override
  Future<dynamic> pipe(StreamConsumer<List<int>> streamConsumer) =>
      _delegate.cast<List<int>>().pipe(streamConsumer);

  @override
  Future<Uint8List> reduce(
    List<int> Function(Uint8List previous, Uint8List element) combine,
  ) => _delegate.reduce(
    (previous, element) => Uint8List.fromList(combine(previous, element)),
  );

  @override
  Future<Uint8List> get single => _delegate.single;

  @override
  Future<Uint8List> singleWhere(
    bool Function(Uint8List element) test, {
    List<int> Function()? orElse,
  }) =>
      _delegate.singleWhere(test, orElse: () => Uint8List.fromList(orElse!()));

  @override
  Stream<Uint8List> skip(int count) => _delegate.skip(count);

  @override
  Stream<Uint8List> skipWhile(bool Function(Uint8List element) test) =>
      _delegate.skipWhile(test);

  @override
  Stream<Uint8List> take(int count) => _delegate.take(count);

  @override
  Stream<Uint8List> takeWhile(bool Function(Uint8List element) test) =>
      _delegate.takeWhile(test);

  @override
  Stream<Uint8List> timeout(
    Duration timeLimit, {
    void Function(EventSink<Uint8List> sink)? onTimeout,
  }) => _delegate.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<Uint8List>> toList() => _delegate.toList();

  @override
  Future<Set<Uint8List>> toSet() => _delegate.toSet();

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) =>
      _delegate.cast<List<int>>().transform<S>(streamTransformer);

  @override
  Stream<Uint8List> where(bool Function(Uint8List event) test) =>
      _delegate.where(test);
}

class _MockHttpHeaders implements HttpHeaders {
  //
  @override
  late bool chunkedTransferEncoding;

  @override
  int contentLength = -1;

  @override
  ContentType? contentType;

  @override
  DateTime? date;

  @override
  DateTime? expires;

  @override
  String? host;

  @override
  DateTime? ifModifiedSince;

  @override
  late bool persistentConnection;

  @override
  int? port;

  @override
  List<String> operator [](String name) => <String>[];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void clear() {}

  @override
  void forEach(void Function(String name, List<String> values) f) {}

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {}

  @override
  void removeAll(String name) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  String? value(String name) => null;
}

class NetworkToFileImageLoadException implements Exception {
  /// Creates a [NetworkImageLoadException] with the specified http [statusCode],
  /// [uri] and [file].
  NetworkToFileImageLoadException({
    required this.statusCode,
    required this.uri,
    required this.file,
  }) : _message =
           'Image load failed: file: ${file?.path}, URL: $uri'
           '${statusCode != 0 ? ", statusCode: $statusCode." : ""}.';

  /// The HTTP status code from the server.
  final int statusCode;

  /// A human-readable error message.
  final String _message;

  /// Resolved URL of the requested image.
  final Uri? uri;

  /// File of the requested image.
  final File? file;

  @override
  String toString() => _message;
}
