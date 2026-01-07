import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:powersync_client/src/attachments/post/supabase_storage_adapter.dart';
import 'package:powersync_core/attachments/attachments.dart';
import 'package:powersync_core/attachments/io.dart';
import 'package:powersync_core/powersync_core.dart';

/// The attachment queue
late AttachmentQueue postAttachmentQueue;

/// Initialize the attachment queue
Future<AttachmentQueue> initializePostAttachmentQueue(
  PowerSyncDatabase db,
  RemoteStorage remoteStorage,
) async {
  final queue = AttachmentQueue(
    db: db,
    remoteStorage: remoteStorage,
    localStorage: IOLocalStorage(await getApplicationDocumentsDirectory()),
    errorHandler: AttachmentErrorHandler(
      onDeleteError: (attachment, exception, stackTrace) async {
        return false;
      },
      onDownloadError: (attachment, exception, stackTrace) async {
        if (exception.toString().contains('Object not found')) {
          return false;
        }
        return true;
      },
      onUploadError: (attachment, exception, stackTrace) async {
        if (exception is UploadFileNotFoundFailure ||
            exception is UploadPostNotFoundFailure) {
          return false;
        }
        return true;
      },
    ),
    watchAttachments: () {
      return Stream.value([]);
    },
    downloadAttachments: false,
  );

  postAttachmentQueue = queue;

  return queue;
}
