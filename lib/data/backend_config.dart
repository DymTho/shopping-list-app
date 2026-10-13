import 'grocery_repository.dart';
import 'http_grocery_repository.dart';
import 'mock_grocery_repository.dart';

/// The only place that decides where the shopping list is stored.
///
/// Until we get the real backend address, keep [useMockBackend] = true.
/// When the teacher provides the Firebase Realtime Database URL, paste it
/// into [backendBaseUrl] and set [useMockBackend] to false.
const bool useMockBackend = true;

// Example: 'https://my-project-default-rtdb.firebaseio.com'
const String backendBaseUrl = 'https://YOUR-PROJECT-default-rtdb.firebaseio.com';

GroceryRepository createGroceryRepository() {
  return useMockBackend
      ? MockGroceryRepository()
      : HttpGroceryRepository(baseUrl: backendBaseUrl);
}
