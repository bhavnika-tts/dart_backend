import 'package:dart_frog/dart_frog.dart';
import '../../product/get-product-sub-type-by-id/[productSubTypeId].dart' as p;

Future<Response> onRequest(RequestContext context, String productSubTypeId) =>
    p.onRequest(context, productSubTypeId);
