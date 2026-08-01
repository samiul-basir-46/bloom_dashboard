import '../common_widgets/custom_toast.dart';

final class ToastUtil {
  ToastUtil._();

  static void showShortToast(String message) {
    customToastMessage("System Info", message, type: WebToastType.info);
  }

  static void showSuccessToast(String message, {String title = "Success"}) {
    customToastMessage(title, message, type: WebToastType.success);
  }

  static void showErrorToast(String message, {String title = "Error"}) {
    customToastMessage(title, message, type: WebToastType.error);
  }

  static void showInfoToast(String message, {String title = "Information"}) {
    customToastMessage(title, message, type: WebToastType.info);
  }

  static void showWarningToast(String message, {String title = "Warning"}) {
    customToastMessage(title, message, type: WebToastType.warning);
  }
}
