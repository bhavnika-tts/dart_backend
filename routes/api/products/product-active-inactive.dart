import 'package:dart_frog/dart_frog.dart';
import '../product/product-active-inactive.dart' as p;

Future<Response> onRequest(RequestContext context) => p.onRequest(context);
