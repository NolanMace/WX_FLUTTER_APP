// lib/config.dart
class AppConfig {
  static const String iP = '192.168.1.106';
  //管理员登录
  static const String loginUrl = 'http://$iP:8080/admin/login';

  //用户表请求
  static const String getAllUsersUrl = 'http://$iP:8080/admin/GetAllUsers';
  static const String editUserUrl = 'http://$iP:8080/admin/UpdateUser';

  //箱子请求
  static const String getBoxUrl = 'http://$iP:8080/admin/GetBox';
  static const String getAllBoxesUrl = 'http://$iP:8080/admin/GetAllBoxes';
  static const String deleteBoxUrl = 'http://$iP:8080/admin/DeleteBoxes';
  static const String updateBoxUrl = 'http://$iP:8080/admin/UpdateBox';
  static const String addBoxUrl = 'http://$iP:8080/admin/CreateBox';
  static const String addDisplayBoxUrl =
      'http://$iP:8080/admin/CreateBoxDisplay';
  static const String deleteDisplayBoxUrl =
      'http://$iP:8080/admin/DeleteBoxesDisplayByIds';
  static const String getAdminDisplayBox =
      'http://$iP:8080/admin/GetBoxesDisplayByBoxId';

  //箱子商品配置请求
  static const String addConfigUrl =
      'http://$iP:8080/admin/CreateBoxTemplateProduct';
  static const String deleteConfigUrl =
      'http://$iP:8080/admin/DeleteBoxTemplateProductByAutoIds';
  static const String updateConfigUrl =
      'http://$iP:8080/admin/UpdateBoxTemplateProduct';
  static const String getConfigUrl =
      'http://$iP:8080/admin/GetBoxTemplateProductByBoxId';

  //商品请求
  static const String getAllProductsUrl =
      'http://$iP:8080/admin/GetAllProducts';
  static const String deleteProductUrl = 'http://$iP:8080/admin/DeleteProducts';
  static const String updateProductUrl = 'http://$iP:8080/admin/UpdateProduct';
  static const String addProductUrl = 'http://$iP:8080/admin/CreateProduct';

  //箱子实例请求
  static const String getBoxInstanceByBoxId =
      'http://$iP:8080/admin/GetBoxInstanceByBoxId';
  static const String deleteBoxInstanceByIds =
      'http://$iP:8080/admin/DeleteBoxInstanceByIds';
  static const String updateBoxInstance =
      'http://$iP:8080/admin/UpdateBoxInstance';

  //商品实例请求
  static const String getBoxItemsByBoxIdUrl =
      'http://$iP:8080/admin/GetBoxItemsByBoxId';
  static const String generateBoxItemsUrl =
      'http://$iP:8080/admin/GenerateBoxItems';
  static const String deleteBoxItemsUrl =
      'http://$iP:8080/admin/DeleteBoxItems';
  static const String updateBoxItemUrl = 'http://$iP:8080/admin/UpdateBoxItem';

  //发货订单请求
  static const String getAdminShipmentOrderResponses =
      'http://$iP:8080/admin/GetAdminShipmentOrderResponses';
  static const String toShipUrl = 'http://$iP:8080/admin/AdminToShip';
}
