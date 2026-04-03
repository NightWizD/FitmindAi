class ApiConstants {
  // Toggle this for Local vs Production
  static const bool isProduction = true;

  // Local development URL (10.0.2.2 is the localhost address for Android emulators)
  static const String localBaseUrl = 'http://10.0.2.2:8000/api/v1';

  // Production Render URL
  static const String productionBaseUrl = 'https://fitmindai-5yn4.onrender.com/api/v1';

  // Current base URL
  static String get baseUrl => isProduction ? productionBaseUrl : localBaseUrl;
}
