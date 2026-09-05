import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/models/banner.dart';
import 'package:dart_frog_backend/services/imagekit_service.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final collection = MongoClient.instance.collection('banners');
    final stream = collection.find(where.sortBy('order', descending: false));
    final list = await stream.toList();

    final banners = list.map(BannerModel.fromBson).map((b) => b.toJson()).toList();
    final signed = ImageKitService.instance.signImageKitUrls(banners);

    return Response.json(
      body: signed,
    );
  } catch (error) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to fetch banners', 'error': error.toString()},
    );
  }
}
