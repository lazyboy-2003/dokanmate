import 'package:telephony/telephony.dart';

/// Handles local SMS reminders for overdue customer payments.
/// This service deliberately sends only normal SMS. WhatsApp is not used.
class PaymentSmsReminderService {
  PaymentSmsReminderService._();

  static final Telephony _telephony = Telephony.instance;

  static Future<bool> requestSmsPermission() async {
    try {
      final granted = await _telephony.requestSmsPermissions;
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendDueReminder({
    required String phone,
    required String customerName,
    required String businessName,
    required String amount,
    required String dueDate,
    String? invoiceNumber,
    bool overdue = false,
  }) async {
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (normalized.isEmpty) return false;

    final permission = await requestSmsPermission();
    if (!permission) return false;

    final invoiceText = (invoiceNumber == null || invoiceNumber.isEmpty)
        ? ''
        : ' Invoice $invoiceNumber.';
    final status = overdue ? 'overdue' : 'due';
    final message =
        'Dear $customerName, your payment of Rs. $amount is $status.$invoiceText '
        'Due date: $dueDate. Please make the payment at your earliest convenience. '
        '- $businessName';

    try {
      await _telephony.sendSms(
        to: normalized,
        message: message,
        isMultipart: message.length > 160,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
