import 'package:dart_frog/dart_frog.dart';
import '../../product/getFavoriteProduct/[userId].dart' as p;

Future<Response> onRequest(RequestContext context, String userId) =>
    p.onRequest(context, userId);
