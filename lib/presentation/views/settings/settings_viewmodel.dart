/// ViewModel responsible for application settings.
///
/// Responsibilities:
/// - load persisted settings
/// - update setting values
/// - persist modified settings
class SettingsViewModel {
  /// TODO:
  /// Current selected language.
  String languageCode = 'en';

  /// TODO:
  /// Default file storage mode.
  ///
  /// Possible values:
  /// - save file copy in app storage
  /// - save only original file path
  String fileStorageMode = 'copy';

  /// TODO:
  /// Default dataset results view mode.
  ///
  /// Possible values:
  /// - table
  /// - cards
  String defaultResultsView = 'table';

  /// TODO:
  /// Whether workspace UI state should be saved automatically.
  bool autoSaveWorkspaceState = true;

  /// TODO:
  /// Theme mode preference.
  ///
  /// Possible values:
  /// - system
  /// - light
  /// - dark
  String themeMode = 'system';

  /// TODO:
  /// Load persisted settings from storage.
  Future<void> loadSettings() async {
    throw UnimplementedError();
  }

  /// TODO:
  /// Persist updated settings.
  Future<void> saveSettings() async {
    throw UnimplementedError();
  }
}