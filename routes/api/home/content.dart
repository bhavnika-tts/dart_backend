import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/models/banner.dart';
import 'package:dart_frog_backend/repositories/product_repository.dart';
import 'package:dart_frog_backend/services/imagekit_service.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final bannerCol = MongoClient.instance.collection('banners');
    final bannerDocs = await bannerCol.find(where.eq('isActive', true).sortBy('order', descending: false)).toList();
    final banners = bannerDocs.map(BannerModel.fromBson).map((b) => b.toJson()).toList();

    final categories = await ProductRepository.instance.getProductTypes();
    final counts = await ProductRepository.instance.getProductCountsByCategory();

    final signedBanners = ImageKitService.instance.signImageKitUrls(banners);

    return Response.json(
      body: {
        'success': true,
        'banners': signedBanners,
        'categories': categories.map((c) => c.toJson()).toList(),
        'categoryCounts': counts,
      },
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to load home content', 'error': error.toString()},
    );
  }
}
