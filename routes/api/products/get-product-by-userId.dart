import 'package:dart_frog/dart_frog.dart';
import '../product/get-product-by-userId.dart' as p;

Future<Response> onRequest(RequestContext context) => p.onRequest(context);
