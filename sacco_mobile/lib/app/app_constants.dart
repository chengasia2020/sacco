class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();
  
  // API base URL - update with your actual API endpoint
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';
  
  // Authentication endpoints
  static const String loginEndpoint = '/auth/login/';
  static const String registerEndpoint = '/auth/register/';
  static const String refreshTokenEndpoint = '/auth/refresh-token/';
  
  // Member endpoints
  static const String memberEndpoint = '/members';
  
  // Savings endpoints
  static const String savingsEndpoint = '/savings/';
  static const String transactionsEndpoint = '/transactions/';
  
  // Loan endpoints
  static const String loansEndpoint = '/loans/';
  static const String loanApplicationsEndpoint = '/loan_applications/';
  
  // Secure storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // Error messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String authErrorMessage = 'Authentication failed. Please login again.';
  
  // Regex patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\+256[0-9]{9}$'; // For Uganda phone numbers
  
  // Misc
  static const int requestTimeoutSeconds = 30;
  static const double defaultPadding = 16.0;
}