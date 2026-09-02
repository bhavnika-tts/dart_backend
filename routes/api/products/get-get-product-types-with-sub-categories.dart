import 'package:dart_frog/dart_frog.dart';
import '../product/get-get-product-types-with-sub-categories.dart' as p;

Future<Response> onRequest(RequestContext context) => p.onRequest(context);
