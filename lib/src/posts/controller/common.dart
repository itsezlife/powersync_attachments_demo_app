import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared/shared.dart';

/// Useful extension for [XFile]
extension XFileX on XFile {
  /// Converts the [PlatformFile] into [AttachmentFile]
  Future<AttachmentFile> get toAttachmentFile async {
    final bytes = await readAsBytes();
    return AttachmentFile(
      // Path is not supported on web.
      path: kIsWeb ? null : path,
      name: name,
      size: bytes.length,
      bytes: bytes,
    );
  }

  /// Converts the [XFile] to a [Attachment].
  Future<Attachment> toAttachment({required String type}) async {
    final file = await toAttachmentFile;

    final mimeType = this.mimeType ?? file.mediaType?.mimeType;

    final attachment = Attachment(
      file: file,
      type: type,
      mimeType: mimeType,
      fileSize: file.size,
    );

    return attachment;
  }
}
