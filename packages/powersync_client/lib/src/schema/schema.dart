import 'package:powersync/powersync.dart';
import 'package:powersync_core/attachments/attachments.dart';

/// Global schema in local async SQLite database.
final schema = Schema(
  [
    // Create attachments queue table, required for PowerSync attachments helper
    AttachmentsQueueTable(
      additionalColumns: const [
        Column.text('post_id'),
        Column.integer('sent'), // amount of bytes uploaded
      ],
    ),
    const Table(
      'users',
      [
        Column.text('name'),
        Column.text('email'),
        Column.text('avatar_url'),
        Column.text('created_at'),
        Column.text('updated_at'),
      ],
      indexes: [
        Index('email', [IndexedColumn('email')]),
      ],
    ),
    const Table(
      'posts',
      [
        Column.text('user_id'),
        Column.text('content'),
        Column.text('created_at'),
        Column.text('updated_at'),
      ],
      indexes: [
        Index('user_id', [IndexedColumn('user_id')]),
        Index('created_at', [IndexedColumn('created_at')]),
      ],
    ),
    const Table.localOnly(
      'posts_local',
      [
        Column.text('user_id'),
        Column.text('content'),
        Column.text('created_at'),
        Column.text('updated_at'),
      ],
      indexes: [
        Index('user_id', [IndexedColumn('user_id')]),
        Index('created_at', [IndexedColumn('created_at')]),
      ],
    ),
    const Table(
      'post_attachments',
      [
        Column.text('post_id'),
        Column.text('type'),
        Column.text('title_link'),
        Column.text('title'),
        Column.text('thumb_url'),
        Column.text('text'),
        Column.text('pretext'),
        Column.text('og_scrape_url'),
        Column.text('image_url'),
        Column.text('footer_icon'),
        Column.text('footer'),
        Column.text('fields'),
        Column.text('fallback'),
        Column.text('color'),
        Column.text('author_name'),
        Column.text('author_link'),
        Column.text('author_icon'),
        Column.text('asset_url'),
        Column.text('actions'),
        Column.integer('original_width'),
        Column.integer('original_height'),
        Column.integer('file_size'),
        Column.text('mime_type'),
        Column.text('minithumbnail'),
        Column.text('created_at'),
        Column.text('updated_at'),
      ],
      indexes: [
        Index('post_id', [IndexedColumn('post_id')]),
        Index('type', [IndexedColumn('type')]),
        Index('created_at', [IndexedColumn('created_at')]),
      ],
    ),
    const Table.localOnly(
      'post_attachments_local',
      [
        Column.text('post_id'),
        Column.text('type'),
        Column.text('title_link'),
        Column.text('title'),
        Column.text('thumb_url'),
        Column.text('text'),
        Column.text('pretext'),
        Column.text('og_scrape_url'),
        Column.text('image_url'),
        Column.text('footer_icon'),
        Column.text('footer'),
        Column.text('fields'),
        Column.text('fallback'),
        Column.text('color'),
        Column.text('author_name'),
        Column.text('author_link'),
        Column.text('author_icon'),
        Column.text('asset_url'),
        Column.text('actions'),
        Column.integer('original_width'),
        Column.integer('original_height'),
        Column.integer('file_size'),
        Column.text('mime_type'),
        Column.text('minithumbnail'),
        Column.text('created_at'),
        Column.text('updated_at'),
        Column.integer('sent'),
      ],
      indexes: [
        Index('post_id', [IndexedColumn('post_id')]),
        Index('type', [IndexedColumn('type')]),
        Index('created_at', [IndexedColumn('created_at')]),
      ],
    ),
  ],
);
