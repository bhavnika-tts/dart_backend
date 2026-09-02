import 'package:dart_frog_backend/models/admin.dart';
import 'package:dart_frog_backend/models/admin_audit_log.dart';
import 'package:dart_frog_backend/models/admin_permission.dart';
import 'package:test/test.dart';

void main() {
  group('Admin & RBAC Models', () {
    test('Admin model serialization and role checks', () {
      final admin = Admin(
        id: '507f1f77bcf86cd799439011',
        username: 'superadmin',
        email: 'superadmin@classical.com',
        password: 'hashed_password',
        fName: 'Super',
        lName: 'Admin',
        role: 'superadmin',
      );

      final json = admin.toJson();
      expect(json['email'], equals('superadmin@classical.com'));
      expect(json['role'], equals('superadmin'));
      expect(admin.isSuperAdmin, isTrue);
    });

    test('AdminPermission modules mapping', () {
      final perm = AdminPermission(
        adminId: '507f1f77bcf86cd799439011',
        permissions: {
          'user': ModulePermission(read: true, write: false),
          'reports': ModulePermission(read: true, write: true),
        },
      );

      final json = perm.toJson();
      expect(json['permissions']['user']['read'], isTrue);
      expect(json['permissions']['reports']['write'], isTrue);
    });

    test('AdminAuditLog records target and action', () {
      final log = AdminAuditLog(
        adminId: '507f1f77bcf86cd799439011',
        action: 'APPROVE_USER',
        method: 'POST',
        endpoint: '/api/admin/verify_by_admin',
        details: {'targetId': '507f1f77bcf86cd799439022', 'isApproved': true},
      );

      final json = log.toJson();
      expect(json['action'], equals('APPROVE_USER'));
      expect(json['endpoint'], equals('/api/admin/verify_by_admin'));
      expect(json['details']['isApproved'], isTrue);
    });
  });
}
