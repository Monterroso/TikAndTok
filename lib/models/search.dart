import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'video.dart';

part 'search.freezed.dart';
part 'search.g.dart';

enum SearchResultType {
  video,
  user,
  recentSearch,
}

@freezed
class SearchState with _$SearchState {
  const factory SearchState({
    required String query,
    @Default(false) bool isLoading,
    String? error,
    @Default([]) List<Video> videoResults,
    @Default([]) List<Map<String, dynamic>> userResults,
    @Default([]) List<String> recentSearches,
  }) = _SearchState;

  factory SearchState.initial() => const SearchState(query: '');
  
  factory SearchState.loading(String query) => SearchState(
    query: query,
    isLoading: true,
  );

  factory SearchState.error(String query, String error) => SearchState(
    query: query,
    error: error,
  );

  factory SearchState.fromJson(Map<String, dynamic> json) => 
      _$SearchStateFromJson(json);
} 