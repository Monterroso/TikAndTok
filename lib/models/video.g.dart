// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoImpl _$$VideoImplFromJson(Map<String, dynamic> json) => _$VideoImpl(
      id: json['id'] as String,
      url: json['url'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      savedBy: (json['savedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      orientation:
          $enumDecodeNullable(_$VideoOrientationEnumMap, json['orientation']) ??
              VideoOrientation.portrait,
    );

Map<String, dynamic> _$$VideoImplToJson(_$VideoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'userId': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'thumbnailUrl': instance.thumbnailUrl,
      'likes': instance.likes,
      'comments': instance.comments,
      'createdAt': instance.createdAt.toIso8601String(),
      'metadata': instance.metadata,
      'likedBy': instance.likedBy.toList(),
      'savedBy': instance.savedBy.toList(),
      'orientation': _$VideoOrientationEnumMap[instance.orientation]!,
    };

const _$VideoOrientationEnumMap = {
  VideoOrientation.portrait: 'portrait',
  VideoOrientation.landscape: 'landscape',
};
