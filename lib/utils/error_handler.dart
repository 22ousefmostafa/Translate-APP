class ErrorHandler {
  static String handleError(dynamic error) {
    if (error.toString().contains('No internet connection')) {
      return 'No internet connection. Please check your network and try again.';
    } else if (error.toString().contains('API Error')) {
      return 'Translation service is temporarily unavailable. Please try again later.';
    } else {
      return 'An unexpected error occurred: ${error.toString()}';
    }
  }
}
