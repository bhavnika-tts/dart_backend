import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final authHeader = context.request.headers['authorization'];
    final claims = JwtService.instance.verifyAuthHeader(authHeader);
    if (claims == null ||
        (claims.role != 'superadmin' && claims.role != 'subadmin' && claims.role != 'admin')) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'message': 'Admin access required'},
      );
    }

    final userCol = MongoClient.instance.collection('users');
    final userCatPermCol = MongoClient.instance.collection('usercategorypermissions');
    final prodCol = MongoClient.instance.collection('products');
    final prodCatCol = MongoClient.instance.collection('productcategories');
    final reportProdCol = MongoClient.instance.collection('reportproducts');
    final chatReportCol = MongoClient.instance.collection('chatreports');
    final featureReqCol = MongoClient.instance.collection('featurerequests');

    // Subadmin filter
    final isSubadmin = claims.role == 'subadmin';
    ObjectId? subadminObjectId;
    if (isSubadmin && claims.userId.isNotEmpty) {
      try {
        subadminObjectId = ObjectId.fromHexString(claims.userId);
      } catch (_) {}
    }

    // --- CATEGORY STATS HELPER ---
    Future<Map<String, int>> getCategoryStats(String categoryKey) async {
      final baseMatch = <String, dynamic>{
        'userCategory': {'\$regex': categoryKey, '\$options': 'i'},
      };
      if (subadminObjectId != null) {
        baseMatch['assignedByAdmin'] = subadminObjectId;
      }

      final total = await userCol.count(baseMatch);
      final verified = await userCol.count({
        ...baseMatch,
        'isPinVerified': true,
        'isOtpVerified': true,
      });
      final pending = await userCol.count({
        ...baseMatch,
        '\$or': [
          {'isPinVerified': false, 'isOtpVerified': true},
          {'isPinVerified': true, 'isOtpVerified': false},
        ],
      });
      final deleted = await userCol.count({
        ...baseMatch,
        'isDeleted': true,
      });
      final disable = await userCol.count({
        ...baseMatch,
        'isActive': false,
      });

      return {
        'total': total,
        'verified': verified,
        'pending': pending,
        'deleted': deleted,
        'disable': disable,
      };
    }

    final subadminFilter = <String, dynamic>{};
    if (subadminObjectId != null) {
      subadminFilter['assignedByAdmin'] = subadminObjectId;
    }

    // Distinct user categories
    final permDocs = await userCatPermCol.find().toList();
    final permCategories = permDocs
        .map((doc) => doc['categoryKey']?.toString())
        .whereType<String>()
        .toSet();

    final distinctUsersRes = await userCol.distinct('userCategory');
    final rawValues = distinctUsersRes['values'] as List? ?? [];
    final distinctUserCategories = rawValues.map((e) => e?.toString()).whereType<String>().toSet();

    final allUserCategories = {...permCategories, ...distinctUserCategories}.toList();

    final categoryStats = <String, dynamic>{};
    for (final cat in allUserCategories) {
      if (cat.isNotEmpty) {
        categoryStats['Category_$cat'] = await getCategoryStats(cat);
      }
    }

    final totalUsers = await userCol.count(subadminFilter);
    final totalVerifiedUsers = await userCol.count({
      ...subadminFilter,
      'isPinVerified': true,
      'isOtpVerified': true,
    });
    final totalPendingAccessUsers = await userCol.count({
      ...subadminFilter,
      '\$or': [
        {'isPinVerified': false, 'isOtpVerified': true},
        {'isPinVerified': true, 'isOtpVerified': false},
      ],
    });
    final totalDeletedUsers = await userCol.count({
      ...subadminFilter,
      'isDeleted': true,
    });
    final totalDisabledUsers = await userCol.count({
      ...subadminFilter,
      'isActive': false,
    });

    // --- PRODUCT CATEGORY STATS ---
    final prodFilters = <String, dynamic>{'isDeleted': false};
    if (subadminObjectId != null) {
      final managedUsers = await userCol.find(
        where.eq('assignedByAdmin', subadminObjectId),
      ).toList();
      final managedIds = managedUsers.map((u) => u['_id']).toList();
      prodFilters['userId'] = {'\$in': managedIds};
    }

    // Get product category buckets
    final allProductDocs = await prodCol.find(prodFilters).toList();
    final categoryCounts = <String, int>{};

    final productCategories = await prodCatCol.find().toList();
    for (final pc in productCategories) {
      final label = pc['label']?.toString().toUpperCase();
      if (label != null && label.isNotEmpty) {
        categoryCounts[label] = 0;
      }
    }

    for (final p in allProductDocs) {
      final cat = p['categories']?.toString().toUpperCase();
      if (cat != null && cat.isNotEmpty) {
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
      }
    }

    final totalProductCount = allProductDocs.length;

    // --- REPORT STATS ---
    final reportFilter = <String, dynamic>{};
    if (subadminObjectId != null) {
      final managedUsers = await userCol.find(
        where.eq('assignedByAdmin', subadminObjectId),
      ).toList();
      final managedIds = managedUsers.map((u) => u['_id']).toList();
      reportFilter['userId'] = {'\$in': managedIds};
    }

    final validReportCount = await reportProdCol.count(reportFilter);
    final totalResolveReports = await reportProdCol.count({
      ...reportFilter,
      'isActive': false,
    });

    final totalChatReports = await chatReportCol.count();
    final totalPendingChatReports = await chatReportCol.count({'status': 'pending'});
    final totalResolvedChatReports = await chatReportCol.count({'status': 'resolve'});
    final totalDeclinedChatReports = await chatReportCol.count({'status': 'decline'});

    // --- FEATURE REQUEST STATS ---
    final totalFeatureRequests = await featureReqCol.count();
    final totalPendingFeatureRequests = await featureReqCol.count({'status': 'pending'});
    final totalAcceptedFeatureRequests = await featureReqCol.count({'status': 'accepted'});
    final totalDeclinedFeatureRequests = await featureReqCol.count({'status': 'declined'});

    return Response.json(
      body: {
        'success': true,
        'totalUsers': totalUsers,
        'verifiedUsers': totalVerifiedUsers,
        'pendingAccessUsers': totalPendingAccessUsers,
        'deletedUsers': totalDeletedUsers,
        'disabledUsers': totalDisabledUsers,
        'categoryStats': categoryStats,
        'productStats': {
          'totalProductCount': totalProductCount,
          'categoryCounts': categoryCounts,
        },
        'reportStats': {
          'totalReportedProducts': validReportCount,
          'totalResolveRepoerts': totalResolveReports,
          'totalPendingReports': validReportCount - totalResolveReports,
          'totalChatReports': totalChatReports,
          'totalPendingChatReports': totalPendingChatReports,
          'totalResolvedChatReports': totalResolvedChatReports,
          'totalDeclinedChatReports': totalDeclinedChatReports,
        },
        'featureRequestStats': {
          'totalFeatureRequests': totalFeatureRequests,
          'totalPendingFeatureRequests': totalPendingFeatureRequests,
          'totalAcceptedFeatureRequests': totalAcceptedFeatureRequests,
          'totalDeclinedFeatureRequests': totalDeclinedFeatureRequests,
        },
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch user stats', 'error': error.toString()},
    );
  }
}

