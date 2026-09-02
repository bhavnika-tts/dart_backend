import 'package:dart_frog/dart_frog.dart';
import '../product/get-product-by-id.dart' as p;

Future<Response> onRequest(RequestContext context) => p.onRequest(context);
