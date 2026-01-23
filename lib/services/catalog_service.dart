import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/service_item.dart';

class CatalogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===== PRODUCTS =====

  Stream<List<Product>> productsStream() {
    return _db.collection('products').snapshots().map(
          (s) => s.docs.map((d) => Product.fromFirestore(d)).toList(),
        );
  }

  Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _db.collection('products').doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // ===== SERVICES =====

  Stream<List<ServiceItem>> servicesStream() {
    return _db.collection('services').snapshots().map(
          (s) => s.docs.map((d) => ServiceItem.fromFirestore(d)).toList(),
        );
  }

  Future<void> addService(ServiceItem service) async {
    await _db.collection('services').add(service.toMap());
  }

  Future<void> deleteService(String id) async {
    await _db.collection('services').doc(id).delete();
  }
}
