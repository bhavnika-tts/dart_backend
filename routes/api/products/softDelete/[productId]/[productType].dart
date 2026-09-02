import 'package:dart_frog/dart_frog.dart';
import '../../../product/softDelete/[productId]/[productType].dart' as p;

Future<Response> onRequest(RequestContext context, String productId, String productType) =>
    p.onRequest(context, productId, productType);
