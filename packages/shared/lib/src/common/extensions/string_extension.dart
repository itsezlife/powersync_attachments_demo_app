import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

/// Extension for string related operations.
extension StringExtension on String {
  /// Returns the string as it is.
  String get hardcoded => this;

  /// Returns the string with the first character capitalized.
  String get capitalized => this[0].toUpperCase() + substring(1);

  /// Change to lower case and capitalize first letter
  ///
  /// Used for changing `CANCEL` to `Cancel` typically.
  String get capitalizedForce => toLowerCase().capitalized;

  /// Returns the string without the extension.
  String get removeExtension {
    final lastDotIndex = lastIndexOf('.');
    final pureName = lastDotIndex != -1 ? substring(0, lastDotIndex) : this;
    return pureName;
  }

  /// returns the media type from the passed file name.
  MediaType? get mediaType {
    if (toLowerCase().endsWith('heic')) {
      return MediaType.parse('image/heic');
    } else {
      final mimeType = lookupMimeType(this);
      if (mimeType == null) return null;
      return MediaType.parse(mimeType);
    }
  }

  /// Returns a resized imageUrl with the given [width], [height] and [resize].
  String getResizedImageUrl({
    double width = 400,
    double height = 400,
    String? /*cover|contain|fill*/ resize,
  }) {
    final uri = Uri.parse(this);
    final host = uri.host;

    final fromSupabase = host.contains('supabase.co');

    if (!fromSupabase) return this;

    final queryParameters = {...uri.queryParameters};

    queryParameters['height'] = height.floor().toString();
    queryParameters['width'] = width.floor().toString();
    if (resize != null) queryParameters['resize'] = resize;

    return uri.replace(queryParameters: queryParameters).toString();
  }
}
