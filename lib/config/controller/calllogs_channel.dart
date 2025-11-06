// 📁 lib/services/calllog_channel.dart
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class CalllogChannel {
  static const _channel = MethodChannel('smartassist/calllog');

  /// Request necessary permissions for call log access
  static Future<bool> requestPermissions() async {
    try {
      final statuses = await [Permission.phone, Permission.contacts].request();

      final bool allGranted = statuses.values.every(
        (status) => status.isGranted,
      );

      if (!allGranted) {
        // Check individual permissions
        final phoneGranted = await Permission.phone.isGranted;
        final contactsGranted = await Permission.contacts.isGranted;

        print('📞 Permission Status:');
        print('   Phone (Call Log): $phoneGranted');
        print('   Contacts: $contactsGranted');

        return phoneGranted; // At minimum we need phone permission
      }

      return true;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if permissions are granted
  static Future<bool> arePermissionsGranted() async {
    try {
      final phoneGranted = await Permission.phone.isGranted;
      return phoneGranted;
    } catch (e) {
      print('❌ Error checking permissions: $e');
      return false;
    }
  }

  /// List all available SIM accounts
  static Future<List<Map<String, dynamic>>> listSimAccounts() async {
    try {
      final hasPermission = await arePermissionsGranted();
      if (!hasPermission) {
        throw Exception(
          'Permissions not granted. Call requestPermissions() first.',
        );
      }

      final result = await _channel.invokeMethod<List<dynamic>>(
        'listSimAccounts',
      );

      if (result == null) {
        return [];
      }

      return result.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('❌ Error listing SIM accounts: $e');
      rethrow;
    }
  }

  /// Get call logs for a specific SIM account
  static Future<List<Map<String, dynamic>>> getCallLogsForAccount({
    required String phoneAccountId,
    int limit = 100,
    int? afterMillis,
  }) async {
    try {
      final hasPermission = await arePermissionsGranted();
      if (!hasPermission) {
        throw Exception(
          'Permissions not granted. Call requestPermissions() first.',
        );
      }

      final Map<String, dynamic> arguments = {
        'phoneAccountId': phoneAccountId,
        'limit': limit,
      };

      if (afterMillis != null) {
        arguments['after'] = afterMillis;
      }

      final result = await _channel.invokeMethod<List<dynamic>>(
        'getCallLogsForAccount',
        arguments,
      );

      if (result == null) {
        return [];
      }

      return result.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('❌ Error getting call logs for account $phoneAccountId: $e');
      rethrow;
    }
  }

  /// Get all call logs (from all SIMs)
  static Future<List<Map<String, dynamic>>> getAllCallLogs({
    int limit = 100,
    int? afterMillis,
  }) async {
    try {
      final hasPermission = await arePermissionsGranted();
      if (!hasPermission) {
        throw Exception(
          'Permissions not granted. Call requestPermissions() first.',
        );
      }

      final Map<String, dynamic> arguments = {'limit': limit};

      if (afterMillis != null) {
        arguments['after'] = afterMillis;
      }

      final result = await _channel.invokeMethod<List<dynamic>>(
        'getAllCallLogs',
        arguments,
      );

      if (result == null) {
        return [];
      }

      return result.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('❌ Error getting all call logs: $e');
      rethrow;
    }
  }

  /// Helper method to format call type
  static String getCallTypeLabel(int? type) {
    switch (type) {
      case 1:
        return 'Incoming';
      case 2:
        return 'Outgoing';
      case 3:
        return 'Missed';
      case 5:
        return 'Rejected';
      default:
        return 'Other';
    }
  }

  /// Helper method to format call type from string
  static String getCallTypeFromString(String? callType) {
    switch (callType?.toLowerCase()) {
      case 'incoming':
      case 'in':
        return 'Incoming';
      case 'outgoing':
      case 'out':
        return 'Outgoing';
      case 'missed':
        return 'Missed';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Other';
    }
  }
}
