import 'package:dart_frog/dart_frog.dart';
import '../product/delete-product-image.dart' as p;

Future<Response> onRequest(RequestContext context) => p.onRequest(context);
