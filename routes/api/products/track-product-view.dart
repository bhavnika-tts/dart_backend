import 'package:dart_frog/dart_frog.dart';
import '../product/track-product-view.dart' as p;

Future<Response> onRequest(RequestContext context) => p.onRequest(context);
