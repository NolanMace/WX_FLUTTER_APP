// lib/config.dart
class AppConfig {
  static const String iP = 'www.yfsmax.top';
  //管理员登录
  static const String loginUrl = 'https://$iP/admin/login';

  //用户表请求
  static const String getAllUsersUrl = 'https://$iP/admin/GetAllUsers';
  static const String editUserUrl = 'https://$iP/admin/UpdateUser';

  //箱子请求
  static const String getBoxUrl = 'https://$iP/admin/GetBox';
  static const String getAllBoxesUrl = 'https://$iP/admin/GetAllBoxes';
  static const String deleteBoxUrl = 'https://$iP/admin/DeleteBoxes';
  static const String updateBoxUrl = 'https://$iP/admin/UpdateBox';
  static const String addBoxUrl = 'https://$iP/admin/CreateBox';
  static const String addDisplayBoxUrl = 'https://$iP/admin/CreateBoxDisplay';
  static const String deleteDisplayBoxUrl =
      'https://$iP/admin/DeleteBoxesDisplayByIds';
  static const String getAdminDisplayBox =
      'https://$iP/admin/GetBoxesDisplayByBoxId';
  static const String updateBoxesDisplayUrl =
      'https://$iP/admin/UpdateBoxesDisplay';
  static const String updateBoxesDisplayShowNewLabel =
      'https://$iP/admin/UpdateBoxesDisplayShowNewLabel';

  //箱子商品配置请求
  static const String addConfigUrl =
      'https://$iP/admin/CreateBoxTemplateProduct';
  static const String deleteConfigUrl =
      'https://$iP/admin/DeleteBoxTemplateProductByAutoIds';
  static const String updateConfigUrl =
      'https://$iP/admin/UpdateBoxTemplateProduct';
  static const String getConfigUrl =
      'https://$iP/admin/GetBoxTemplateProductByBoxId';

  //商品请求
  static const String getAllProductsUrl = 'https://$iP/admin/GetAllProducts';
  static const String deleteProductUrl = 'https://$iP/admin/DeleteProducts';
  static const String updateProductUrl = 'https://$iP/admin/UpdateProduct';
  static const String addProductUrl = 'https://$iP/admin/CreateProduct';

  //箱子实例请求
  static const String getBoxInstanceByBoxId =
      'https://$iP/admin/GetBoxInstanceByBoxId';
  static const String deleteBoxInstanceByIds =
      'https://$iP/admin/DeleteBoxInstanceByIds';
  static const String updateBoxInstance = 'https://$iP/admin/UpdateBoxInstance';

  //商品实例请求
  static const String getBoxItemsByBoxIdUrl =
      'https://$iP/admin/GetBoxItemsByBoxId';
  static const String generateBoxItemsUrl =
      'https://$iP/admin/GenerateBoxItems';
  static const String deleteBoxItemsUrl = 'https://$iP/admin/DeleteBoxItems';
  static const String updateBoxItemUrl = 'https://$iP/admin/UpdateBoxItem';

//池子请求
  static const String getPoolUrl = 'https://$iP/admin/GetPool';
  static const String getAllPoolsUrl = 'https://$iP/admin/GetAllPools';
  static const String deletePoolUrl = 'https://$iP/admin/DeletePools';
  static const String updatePoolUrl = 'https://$iP/admin/UpdatePool';
  static const String addPoolUrl = 'https://$iP/admin/CreatePool';
  static const String getAdminDisplayPool =
      'https://$iP/admin/GetPoolsDisplayByPoolId';
  static const String addDisplayPoolUrl = 'https://$iP/admin/CreatePoolDisplay';
  static const String deleteDisplayPoolUrl =
      'https://$iP/admin/DeletePoolsDisplayByIds';
  static const String updatePoolsDisplayUrl =
      'https://$iP/admin/UpdatePoolsDisplay';
  static const String updatePoolsDisplayShowNewLabel =
      'https://$iP/admin/UpdatePoolsDisplayShowNewLabel';

  //池子商品配置请求
  static const String addPoolItemUrl = 'https://$iP/admin/CreatePoolItem';
  static const String deletePoolItemUrl =
      'https://$iP/admin/DeletePoolItemsByIds';
  static const String updatePoolItemUrl = 'https://$iP/admin/UpdatePoolItem';
  static const String getPoolItemsByPoolIdUrl =
      'https://$iP/admin/GetPoolItemsByPoolId';

  //发货订单请求
  static const String getAdminShipmentOrderResponses =
      'https://$iP/admin/GetAdminShipmentOrderResponses';
  static const String toShipUrl = 'https://$iP/admin/AdminToShip';
  static const String waitingShipUrl =
      'https://$iP/admin/CreateWaitingShipmentOrder';

  //消费记录
  static const String getBoxLotteryRecordAdmin =
      'https://$iP/admin/GetBoxLotteryRecordAdmin';
  static const String getPoolLotteryRecordAdmin =
      'https://$iP/admin/GetPoolLotteryRecordAdmin';
  static const String getDqLotteryRecordAdmin =
      'https://$iP/admin/GetDqLotteryRecordAdmin';

  //用户协议
  static const String getUserAgreementByAppId =
      'https://$iP/admin/GetUserAgreementByAppId';
  static const String updateUserAgreement =
      'https://$iP/admin/UpdateUserAgreement';
  static const String createUserAgreement =
      'https://$iP/admin/CreateUserAgreement';
  static const String deleteUserAgreement =
      'https://$iP/admin/DeleteUserAgreement';

  //首页弹窗
  static const String getAppHomePopups = 'https://$iP/admin/GetAppHomePopups';
  static const String createAppHomePopup =
      'https://$iP/admin/CreateAppHomePopup';
  static const String updateAppHomePopup =
      'https://$iP/admin/UpdateAppHomePopup';
  static const String deleteAppHomePopups =
      'https://$iP/admin/DeleteAppHomePopups';

  //首页轮播图配置
  static const String createAppSwiperItem =
      'https://$iP/admin/CreateAppSwiperItem';
  static const String updateAppSwiperItem =
      'https://$iP/admin/UpdateAppSwiperItem';
  static const String deleteAppSwiperItem =
      'https://$iP/admin/DeleteAppSwiperItem';
  static const String getAppSwiperItems = 'https://$iP/admin/GetAppSwiperItems';

  //优惠券
  static const String getCoupons = 'https://$iP/admin/GetCoupons';
  static const String createCoupon = 'https://$iP/admin/CreateCoupon';
  static const String updateCoupon = 'https://$iP/admin/UpdateCoupon';
  static const String deleteCoupons = 'https://$iP/admin/DeleteCoupons';

  //优惠券配置
  static const String getCouponTemplates =
      'https://$iP/admin/GetCouponTemplates';
  static const String createCouponTemplates =
      'https://$iP/admin/CreateCouponTemplates';
  static const String deleteCouponTemplates =
      'https://$iP/admin/DeleteCouponTemplates';

  //优惠券上架
  static const String getCouponDisplays = 'https://$iP/admin/GetCouponDisplays';
  static const String createCouponDisplays =
      'https://$iP/admin/CreateCouponDisplays';
  static const String deleteCouponDisplays =
      'https://$iP/admin/DeleteCouponDisplays';

  //上传图片
  static const String uploadImage = 'https://$iP/admin/UploadImage';
}
