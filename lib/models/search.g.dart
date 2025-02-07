// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SearchStateImpl _$$SearchStateImplFromJson(Map<String, dynamic> json) =>
    _$SearchStateImpl(
      query: json['query'] as String,
      isLoading: json['isLoading'] as bool? ?? false,
      error: json['error'] as String?,
      videoResults: (json['videoResults'] as List<dynamic>?)
              ?.map((e) => Video.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      userResults: (json['userResults'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      recentSearches: (json['recentSearches'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SearchStateImplToJson(_$SearchStateImpl instance) =>
    <String, dynamic>{
      'query': instance.query,
      'isLoading': instance.isLoading,
      'error': instance.error,
      'videoResults': instance.videoResults,
      'userResults': instance.userResults,
      'recentSearches': instance.recentSearches,
    };
