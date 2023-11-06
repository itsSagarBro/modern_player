/// Source Type for Modern Player
///
/// This can define type of data source of Modern Player.
enum ModernPlayerSourceType {
  /// The video is downloaded from the internet.
  network,

  /// The video is load from the local filesystem.
  file,

  /// The video is load from the youtube.
  youtube,

  /// The video is load from asset
  asset
}

/// Source Type for Modern Player Subtitle
///
/// This can define type of data source of Modern Player Subtitle.
enum ModernPlayerSubtitleSourceType {
  /// The subtitle file is downloaded from the internet.
  network,

  /// The subtitle file is load from the local filesystem.
  file
}

/// Source Type for Modern Player Audio
///
/// This can define type of data source of Modern Player Audio.
enum ModernPlayerAudioSourceType {
  /// The audio file is downloaded from the internet.
  network,

  /// The audio file is load from the local filesystem.
  file
}
