import 'package:dio/dio.dart';
import 'package:sacco_mobile/app/app_constants.dart';
import 'package:sacco_mobile/core/di/service_locator.dart';
import 'package:sacco_mobile/core/storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage = getIt<SecureStorageService>();
  
  @override
  Future<void> onRequest(
    RequestOptions options, 
    RequestInterceptorHandler handler,
  ) async {
    // Skip adding token for auth endpoints
    if (options.path.contains('/auth/login') || 
        options.path.contains('/auth/register')) {
      return handler.next(options);
    }
    
    final token = await _secureStorage.read(AppConstants.accessTokenKey);
    
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    return handler.next(options);
  }
  
  @override
  Future<void> onError(
    DioException err, 
    ErrorInterceptorHandler handler,
  ) async {
    // If the error is 401 Unauthorized, attempt to refresh the token
    if (err.response?.statusCode == 401) {
      try {
        // Get refresh token
        final refreshToken = await _secureStorage.read(AppConstants.refreshTokenKey);
        
        if (refreshToken == null || refreshToken.isEmpty) {
          // No refresh token available, proceed with error
          return handler.next(err);
        }
        
        // Create a new Dio instance for the refresh request
        // to avoid infinite loops in interceptors
        final dio = Dio();
        
        // Attempt to refresh the token
        final response = await dio.post(
          '${AppConstants.apiBaseUrl}${AppConstants.refreshTokenEndpoint}',
          data: {'refresh_token': refreshToken},
        );
        
        if (response.statusCode == 200 && response.data['tokens'] != null) {
          // Store the new tokens
          await _secureStorage.write(
            AppConstants.accessTokenKey,
            response.data['tokens']['access_token'],
          );
          
          await _secureStorage.write(
            AppConstants.refreshTokenKey,
            response.data['tokens']['refresh_token'],
          );
          
          // Retry the original request with the new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 
            'Bearer ${response.data['tokens']['access_token']}';
          
          final newDio = Dio();
          final newResponse = await newDio.fetch(options);
          
          return handler.resolve(newResponse);
        }
      } catch (e) {
        // If token refresh fails, log the user out
        await _secureStorage.deleteAll();
        // Continue with the original error
        return handler.next(err);
      }
    }
    
    // For other errors, just pass them through
    return handler.next(err);
  }
}