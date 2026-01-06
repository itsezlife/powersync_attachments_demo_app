import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'minithumbnail.g.dart';

/// {@template minithumbnail}
/// Thumbnail image of a very poor quality and low resolution.
/// Similar to Telegram's minithumbnail, used as a cheap placeholder
/// while the full image loads.
/// {@endtemplate}
@JsonSerializable()
@immutable
class Minithumbnail extends Equatable {
  /// {@macro minithumbnail}
  const Minithumbnail({
    required this.width,
    required this.height,
    required this.data,
  });

  /// Creates a [Minithumbnail] from JSON.
  factory Minithumbnail.fromJson(Map<String, dynamic> json) =>
      _$MinithumbnailFromJson(json);

  /// Thumbnail width, usually doesn't exceed 40
  final int width;

  /// Thumbnail height, usually doesn't exceed 40
  final int height;

  /// The thumbnail data in base64-encoded JPEG format
  final String data;

  /// Converts to JSON
  Map<String, dynamic> toJson() => _$MinithumbnailToJson(this);

  @override
  List<Object?> get props => [width, height, data];
}

/// {@template minithumbnail_data}
/// Data for a minithumbnail.
/// {@endtemplate}
class MinithumbnailData extends Equatable {
  /// {@macro minithumbnail_data}
  const MinithumbnailData({
    required this.data,
    required this.width,
    required this.height,
  });

  /// The data of the minithumbnail.
  final Uint8List? data;

  /// The width of the minithumbnail.
  final double width;

  /// The height of the minithumbnail.
  final double height;

  @override
  List<Object?> get props => [data, width, height];
}

/// {@template minithumbnail_extensions}
/// Extensions for a minithumbnail.
/// {@endtemplate}
extension MinithumbnailExtensions on MinithumbnailData {
  /// Converts the minithumbnail to a [MemoryImage].
  MemoryImage? toMemoryImage() => MemoryImage(data!);

  /// Returns the aspect ratio of the minithumbnail.
  double aspectRatio() => width / height;
}

/// {@template td_minithumbnail_extensions}
/// Extensions for a minithumbnail.
/// {@endtemplate}
extension TdMinithumbnailExtensions on Minithumbnail {
  /// {@macro td_minithumbnail_extensions}
  MinithumbnailData toMinithumbnailData() {
    return MinithumbnailData(
      data: const Base64Decoder().convert(data),
      width: width.toDouble(),
      height: height.toDouble(),
    );
  }
}
