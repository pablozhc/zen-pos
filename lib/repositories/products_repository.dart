import '../models/product_model.dart';

abstract class ProductsRepository {
  Stream<List<ProductCategory>> categoriesStream();
  Stream<List<Product>> productsStream();

  Future<void> setCategory(ProductCategory category);
  Future<void> deleteCategory(String categoryId);
  Future<void> setProduct(Product product);
  Future<void> deleteProduct(String productId);
  Future<bool> isCategoriesEmpty();
  Future<bool> isProductsEmpty();
}
