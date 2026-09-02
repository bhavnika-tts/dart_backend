import 'package:dart_frog_backend/core/db/mongo_client.dart';

void main() async {
  final client = MongoClient.instance;
  await client.connect();
  final subs = await client.collection('subproducttypes').find().toList();
  print('Found ${subs.length} subproducttypes:');
  for (final s in subs) {
    print('Sub: id=${s["_id"]} name="${s["name"]}" productType=${s["productType"]} (${s["productType"].runtimeType})');
  }
  final pts = await client.collection('producttypes').find().toList();
  print('Found ${pts.length} producttypes:');
  for (final p in pts) {
    print('ProdType: id=${p["_id"]} name="${p["name"]}" modelName="${p["modelName"]}"');
  }
  final brands = await client.collection('brandmodels').find().toList();
  print('Found ${brands.length} brandmodels:');
  for (final b in brands.take(10)) {
    print('Brand: id=${b["_id"]} brand="${b["brand"]}" productType="${b["productType"]}"');
  }
}
