// ignore_for_file: public_member_api_docs

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared/shared.dart';

part 'attachment.g.dart';

Map<String, dynamic>? _uploadStateReadValue(
  Map<dynamic, dynamic> json,
  String key,
) {
  final uploadState = json[key] as Map<String, dynamic>?;
  if (uploadState != null) {
    return uploadState;
  }

  // Sent will be null in remote attachments table and will be 0 in local
  // attachments table and progressive upload will be used to determine the
  // upload state.
  final sent = json['sent'] as int?;
  if (sent == null) {
    return const UploadState.success().toJson();
  }

  final total = json['file_size'] as int;
  if (total == sent) {
    return const UploadState.success().toJson();
  }
  return UploadState.inProgress(uploaded: sent, total: total).toJson();
}

/// The class that contains the information about an attachment
@JsonSerializable()
class Attachment extends Equatable {
  /// Constructor used for json serialization
  Attachment({
    String? id,
    String? type,
    this.titleLink,
    String? title,
    this.thumbUrl,
    this.text,
    this.pretext,
    this.ogScrapeUrl,
    this.imageUrl,
    this.footerIcon,
    this.footer,
    this.fields,
    this.fallback,
    this.color,
    this.authorName,
    this.authorLink,
    this.authorIcon,
    this.assetUrl,
    this.originalWidth,
    this.originalHeight,
    this.file,
    this.uploadState = const UploadState.preparing(),
    int? fileSize,
    String? mimeType,
    this.minithumbnail,
    this.createdAt,
    this.updatedAt,
  }) : id = id ?? uuid.v4(),
       _type = switch (type) {
         String() => AttachmentType(type),
         _ => null,
       },
       title = title ?? file?.name,
       localUri = file?.path != null ? Uri.parse(file!.path!) : null,
       fileSize = fileSize ?? file?.size,
       mimeType = mimeType ?? file?.mediaType?.mimeType;

  /// Create a new instance from a json
  factory Attachment.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromJson(json);
  ///The attachment type based on the URL resource. This can be: audio,
  ///image or video
  @JsonKey(
    includeIfNull: false,
    toJson: AttachmentType.toJson,
    fromJson: AttachmentType.fromJson,
  )
  AttachmentType? get type {
    // If the attachment contains ogScrapeUrl as well as titleLink, we consider
    // it as a urlPreview.
    if (ogScrapeUrl != null && titleLink != null) {
      return AttachmentType.urlPreview;
    }

    return _type;
  }

  final AttachmentType? _type;

  /// The raw attachment type.
  String? get rawType => _type;

  ///The link to which the attachment message points to.
  final String? titleLink;

  /// The attachment title
  final String? title;

  /// The URL to the attached file thumbnail. You can use this to represent the
  /// attached link.
  final String? thumbUrl;

  /// The attachment text. It will be displayed in the channel next to the
  /// original message.
  final String? text;

  /// Optional text that appears above the attachment block
  final String? pretext;

  /// The original URL that was used to scrape this attachment.
  final String? ogScrapeUrl;

  /// The URL to the attached image. This is present for URL pointing to an
  /// image article (eg. Unsplash)
  final String? imageUrl;
  final String? footerIcon;
  final String? footer;
  final dynamic fields;
  final String? fallback;
  final String? color;

  /// The name of the author.
  final String? authorName;
  final String? authorLink;
  final String? authorIcon;

  /// The URL to the audio, video or image related to the URL.
  final String? assetUrl;

  /// The original width of the attached image.
  final int? originalWidth;

  /// The original height of the attached image.
  final int? originalHeight;

  final Uri? localUri;

  /// The file present inside this attachment.
  final AttachmentFile? file;

  /// The current upload state of the attachment
  @JsonKey(readValue: _uploadStateReadValue)
  final UploadState uploadState;

  /// The attachment ID.
  ///
  /// This is created locally for uniquely identifying a attachment.
  final String id;

  /// Shortcut for file size.
  ///
  /// {@macro fileSize}
  final int? fileSize;

  /// Shortcut for file mimeType.
  ///
  /// {@macro mimeType}
  final String? mimeType;

  /// A very low quality thumbnail for instant display while loading
  final Minithumbnail? minithumbnail;

  /// The date and time the attachment was created.
  final DateTime? createdAt;

  /// The date and time the attachment was last updated.
  final DateTime? updatedAt;

  /// Serialize to json
  Map<String, dynamic> toJson() => _$AttachmentToJson(this);

  Attachment copyWith({
    String? id,
    String? type,
    String? titleLink,
    String? title,
    String? thumbUrl,
    String? text,
    String? pretext,
    String? ogScrapeUrl,
    String? imageUrl,
    String? footerIcon,
    String? footer,
    dynamic fields,
    String? fallback,
    String? color,
    String? authorName,
    String? authorLink,
    String? authorIcon,
    String? assetUrl,
    int? originalWidth,
    int? originalHeight,
    AttachmentFile? file,
    UploadState? uploadState,
    int? fileSize,
    String? mimeType,
    Minithumbnail? minithumbnail,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Attachment(
    id: id ?? this.id,
    type: type ?? this.type,
    titleLink: titleLink ?? this.titleLink,
    title: title ?? this.title,
    thumbUrl: thumbUrl ?? this.thumbUrl,
    text: text ?? this.text,
    pretext: pretext ?? this.pretext,
    ogScrapeUrl: ogScrapeUrl ?? this.ogScrapeUrl,
    imageUrl: imageUrl ?? this.imageUrl,
    footerIcon: footerIcon ?? this.footerIcon,
    footer: footer ?? this.footer,
    fields: fields ?? this.fields,
    fallback: fallback ?? this.fallback,
    color: color ?? this.color,
    authorName: authorName ?? this.authorName,
    authorLink: authorLink ?? this.authorLink,
    authorIcon: authorIcon ?? this.authorIcon,
    assetUrl: assetUrl ?? this.assetUrl,
    originalWidth: originalWidth ?? this.originalWidth,
    originalHeight: originalHeight ?? this.originalHeight,
    file: file ?? this.file,
    uploadState: uploadState ?? this.uploadState,
    fileSize: fileSize ?? this.fileSize,
    mimeType: mimeType ?? this.mimeType,
    minithumbnail: minithumbnail ?? this.minithumbnail,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Attachment merge(Attachment? other) {
    if (other == null) return this;
    return copyWith(
      type: other.type,
      titleLink: other.titleLink,
      title: other.title,
      thumbUrl: other.thumbUrl,
      text: other.text,
      pretext: other.pretext,
      ogScrapeUrl: other.ogScrapeUrl,
      imageUrl: other.imageUrl,
      footerIcon: other.footerIcon,
      footer: other.footer,
      fields: other.fields,
      fallback: other.fallback,
      color: other.color,
      authorName: other.authorName,
      authorLink: other.authorLink,
      authorIcon: other.authorIcon,
      assetUrl: other.assetUrl,
      originalWidth: other.originalWidth,
      originalHeight: other.originalHeight,
      file: other.file,
      uploadState: other.uploadState,
      fileSize: other.fileSize,
      mimeType: other.mimeType,
      minithumbnail: other.minithumbnail,
      createdAt: other.createdAt,
      updatedAt: other.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    titleLink,
    title,
    thumbUrl,
    text,
    pretext,
    ogScrapeUrl,
    imageUrl,
    footerIcon,
    footer,
    fields,
    fallback,
    color,
    authorName,
    authorLink,
    authorIcon,
    assetUrl,
    originalWidth,
    originalHeight,
    file,
    uploadState,
    fileSize,
    mimeType,
    minithumbnail,
    createdAt,
    updatedAt,
  ];
}

/// {@template attachmentType}
/// A type of attachment that determines how the attachment is displayed and
/// handled by the system.
///
/// It can be one of the backend-specified types (image, file, giphy, video,
/// audio, voiceRecording) or application custom types like urlPreview.
/// {@endtemplate}
extension type const AttachmentType(String rawType) implements String {
  /// Backend specified types.
  static const image = AttachmentType('image');
  static const file = AttachmentType('file');
  static const giphy = AttachmentType('giphy');
  static const video = AttachmentType('video');
  static const audio = AttachmentType('audio');
  static const voiceRecording = AttachmentType('voice_recording');

  /// Application custom types.
  static const urlPreview = AttachmentType('url_preview');

  /// Create a new instance from a json string.
  static AttachmentType? fromJson(String? rawType) {
    if (rawType == null) return null;
    return AttachmentType(rawType);
  }

  /// Serialize to json string.
  static String? toJson(String? type) => type;
}

extension AttachmentTypeHelper on Attachment {
  /// True if the attachment is an image.
  bool get isImage => type == AttachmentType.image;

  /// True if the attachment is a file.
  bool get isFile => type == AttachmentType.file;

  /// True if the attachment is a gif created using Giphy.
  bool get isGiphy => type == AttachmentType.giphy;

  /// True if the attachment is a video.
  bool get isVideo => type == AttachmentType.video;

  /// True if the attachment is an audio file.
  bool get isAudio => type == AttachmentType.audio;

  /// True if the attachment is a voice recording.
  bool get isVoiceRecording => type == AttachmentType.voiceRecording;

  /// True if the attachment is a URL preview.
  bool get isUrlPreview => type == AttachmentType.urlPreview;
}
