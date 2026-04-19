import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_viewmodel.dart';

/// Provider for HomeViewModel.
///
/// Uses ChangeNotifier to notify UI updates.
final homeViewModelProvider =
    ChangeNotifierProvider<HomeViewModel>(
  (ref) => HomeViewModel(),
);