import 'package:flutter_api_craft/flutter_api_craft.dart';
import 'package:get/get.dart';

/// Demonstrates common [FlutterApiCraft] usage patterns.
///
/// Uses JSONPlaceholder (https://jsonplaceholder.typicode.com) as a
/// free, public REST API — no sign-up required.
class ExampleController extends GetxController {
  static const String _base = 'https://jsonplaceholder.typicode.com';

  /// Stores the last response for display in the UI.
  final lastResult = ''.obs;

  // ── 1. Simple GET ─────────────────────────────────────────────────────────

  /// Fetches the first 3 posts with a loading overlay.
  Future<void> fetchPosts() async {
    final res = await FlutterApiCraft(
      baseUrl: _base,
      path: '/posts',
      apiType: ApiType.get,
      apiParams: ApiParams.simple({'_limit': '3'}),
      enableLoading: true,
      loadingMessage: 'Fetching posts...',
      enableApiSuccessResponseGetSnackBar: true,
      snackBarConfig: const ApiSnackBarConfig(
        successTitle: 'Done',
        successMessageOverride: 'Posts loaded!',
      ),
    ).call();

    if (res.isSuccess && res.data is List) {
      final posts = res.data as List;
      lastResult.value = posts
          .map((p) => '• ${p['title']}')
          .join('\n');
    }
  }

  // ── 2. POST with JSON body ────────────────────────────────────────────────

  /// Creates a new post.
  Future<void> createPost() async {
    final res = await FlutterApiCraft(
      baseUrl: _base,
      path: '/posts',
      apiType: ApiType.post,
      apiBody: ApiBody.json({
        'title': 'Hello from FlutterApiCraft',
        'body': 'This post was created by the example app.',
        'userId': 1,
      }),
      enableLoading: true,
      loadingMessage: 'Creating post...',
      enableApiSuccessResponseGetSnackBar: true,
      enableApiErrorResponseGetSnackBar: true,
      snackBarConfig: const ApiSnackBarConfig(
        successTitle: 'Created',
        successMessageOverride: 'Post created successfully!',
        errorTitle: 'Failed',
      ),
    ).call();

    if (res.isSuccess) {
      lastResult.value = 'Created post ID: ${res['id']}\n'
          'Title: ${res['title']}';
    }
  }

  // ── 3. GET with Bearer auth ───────────────────────────────────────────────

  /// Fetches a user profile with a Bearer token header.
  Future<void> fetchWithBearer() async {
    final res = await FlutterApiCraft(
      baseUrl: _base,
      path: '/users/1',
      apiType: ApiType.get,
      apiAuthorization: ApiAuthorization.bearer('demo-token-12345'),
      enableLoading: true,
      loadingMessage: 'Authenticating...',
    ).call();

    if (res.isSuccess) {
      lastResult.value =
          'Name: ${res['name']}\n'
          'Email: ${res['email']}\n'
          'Phone: ${res['phone']}';
    }
  }

  // ── 4. GET with query params ──────────────────────────────────────────────

  /// Fetches page 1 with a limit of 3 posts.
  Future<void> fetchWithParams() async {
    final res = await FlutterApiCraft(
      baseUrl: _base,
      path: '/posts',
      apiParams: ApiParams(
        query: {'_page': '1', '_limit': '3'},
      ),
      enableBodyResponseDebugPrint: true,
    ).call();

    if (res.isSuccess && res.data is List) {
      final posts = res.data as List;
      lastResult.value = 'Page 1 (limit 3):\n' +
          posts.map((p) => '• [${p['id']}] ${p['title']}').join('\n');
    }
  }

  // ── 5. Error handling ─────────────────────────────────────────────────────

  /// Hits a non-existent endpoint to demonstrate error snackbar.
  Future<void> triggerError() async {
    final res = await FlutterApiCraft(
      baseUrl: _base,
      path: '/non-existent-endpoint',
      enableLoading: true,
      enableApiErrorResponseGetSnackBar: true,
      snackBarConfig: const ApiSnackBarConfig(
        errorTitle: 'Not Found',
        errorMessageOverride: 'Endpoint does not exist (404)',
      ),
    ).call();

    lastResult.value =
        'Status: ${res.statusCode}\n'
        'Success: ${res.isSuccess}\n'
        'Error: ${res.errorMessage}';
  }
}
