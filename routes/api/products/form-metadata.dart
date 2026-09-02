import 'package:dart_frog/dart_frog.dart';
import '../product/form-metadata.dart' as p;

Future<Response> onRequest(RequestContext context) => p.onRequest(context);
