import '../common_widgets/custom_toast.dart';

final class ToastUtil {
  ToastUtil._();

  static void showShortToast(String message) {
    customToastMessage("System Info", message);
  }
}
