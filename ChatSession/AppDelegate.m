//
//  AppDelegate.m
//  EnjoySkyLine
//
//  Created by WangGray on 15/5/12.
//  Copyright (c) 2015年 西安融科通信技术有限公司. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "RegisterViewController.h"
#import "HomePageViewController.h"
#import "AirportServiceViewController.h"
#import "CateringShoppingViewController.h"
#import "PersonalCenterViewController.h"
#import "ToolsFunction.h"
#import "Definition.h"
#import "ThreadsManager.h"
#import "RKCloudBase.h"
#import "UIAlertView+CustomAlertView.h"
#import "DatabaseManager+ServiceDetailtypesTable.h"
#import "PaymentManager.h"
#import "WXApi.h"
#import "PersonalOrdersViewController.h"
#import "UIAlertView+CustomAlertView.h"
#import "HomePageViewController.h"

@interface AppDelegate () <UITabBarControllerDelegate, UIAlertViewDelegate, RKCloudBaseDelegate, LocationManagerDelegate, WXApiDelegate>

@property (nonatomic, strong) NavigationViewController *loginNavController; // Navigation for Login
@property (nonatomic, strong) NavigationViewController *registerNavController; // Navigation for Register
@property (nonatomic, strong) NSMutableDictionary *userMessageDic; // 用户推送消息提示的数组

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    // 设置页面的背景颜色
    [self.window setBackgroundColor:COLOR_VIEW_BACKGROUND];
    
    NSLog(@"SYS: %@ Application Start, AppVersion: %@, RKCloudBaseVersion: %@", APP_DISPLAY_NAME, APP_WHOLE_VERSION, [RKCloudBase sdkVersion]);
    
    // 初始化应用程序实例中所有数据
    [self applicationInitialize];
    
    // 启动App系统
    [self launchApp:launchOptions];
    
    // 启动后等1秒来显示启动页面
    [NSThread sleepForTimeInterval:1];
    
    [self.window makeKeyAndVisible];
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // 清除主程序图标的BadgeNumber
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    // 断开数据库连接
    if (self.databaseManager) {
        [self.databaseManager closeDataBase];
    }
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    if ([url.scheme isEqualToString:ALIPAY_APP_SCHEME])
    {
        // 处理支付宝支付的结果
        [self.paymentManager processAlipayPay:url];
    }
    else if ([url.scheme isEqualToString:WECHAT_APP_ID])
    {
        [WXApi handleOpenURL:url delegate:self];
    }
    
    return YES;
}

#pragma mark -
#pragma mark Get AppDelegate

+ (AppDelegate *)appDelegate
{
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}


#pragma mark -
#pragma mark Initialize All Data

// 初始化应用程序实例中所有数据
- (void)applicationInitialize
{
    NSLog(@"APP: applicationInitialize");
    
    // 设置状态栏的风格（纯黑色）
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
#ifdef DEBUG_LOG
    [RKCloudBase setDebugMode:YES];
#endif
    // 注册云视互动SDK
    [RKCloudBase registerSDKWithAppKey:RKCLOUD_SDK_APPKEY withDelegate:self];
    // 设置要使用云视互动的功能点
    [RKCloudBase use:RKCLOUD_CAPABILITY_BASE];
    // 设置启动RKCloud的host地址
    [RKCloudBase setRootHost:DEFAULT_RKCLOUD_ROOT_SERVER_ADDRESS withPort:8000];
    
    // 向微信注册
    [WXApi registerApp:WECHAT_APP_ID withDescription:APP_DISPLAY_NAME];
    
    // 注册APNS Push通知
    [ToolsFunction registerAPNSNotifications];
    
    // 当前用户身份信息
    self.userProfilesInfo = [[UserProfilesInfo alloc] init];
    [self.userProfilesInfo loadUserProfiles];
    // 创建与用户数据相关的文件夹
    [self.userProfilesInfo createUserDataDirectory];
    
    // 数据库管理类
    self.databaseManager = [[DatabaseManager alloc] init];
    
    // 线程管理类
    self.threadsManager = [[ThreadsManager alloc] initThreadsManager:self];
    
    // 定位管理类
    self.locationManager = [[LocationManager alloc] init];
    // 设置代理
    self.locationManager.delegate = self;
    
    // 购物管理类
    self.shoppingManager = [[ShoppingManager alloc] initShoppingManager:self];
    if (self.userProfilesInfo.currentAirportCode == nil)
    {
        self.userProfilesInfo.currentAirportCode = DEFAULT_AIRPORT_CODE;
        [self.userProfilesInfo saveUserProfiles];
    }
    [self.shoppingManager asyncGetPromotionListFromServerWithAirportIata:self.userProfilesInfo.currentAirportCode];
    
    // 机场管理类
    self.airportManager = [[AirportManager alloc] init];
    
    // 收货地址管理类
    self.userInfoManager = [[UserInfoManager alloc] init];
    
    // 用户订单管理类
    self.userOrdersManager = [[UserOrdersManager alloc] init];
    
    // 支付管理类
    self.paymentManager = [[PaymentManager alloc] init];
}

// 启动App系统
- (void)launchApp:(NSDictionary *)launchOptions
{
    // 创建主页面
    [self createMainTabbarController];
    
    // 用户是否已经登录
    if ([self.userProfilesInfo isLogined]) {
        // 已经登录则执行登录成后的处理
        [self.threadsManager doLoginSuccess];
    }
    else {
        // 未登录则执行未登录启动App的处理
        [self.threadsManager doNoLoginLaunchSuccess];
    }
}


#pragma mark -
#pragma mark UI Components

// push and show Login navigation view controller
- (void)pushLoginNavigation {
    NSLog(@"APP: pushLoginNavigation");
    
    if (self.loginNavController != nil) {
        NSLog(@"DEBUG: pushLoginNavigation--loginNavController != nil return");
        return;
    }
    
    // create naviagtion container
    NavigationViewController *navControllerLogin = [[NavigationViewController alloc] init];
    
    // create login view as the initial page
    LoginViewController *viewControllerLogin = [[LoginViewController alloc]
                                                initWithNibName:@"LoginViewController" bundle:[NSBundle mainBundle]];
    
    // 设置动画效果
    [ToolsFunction moveUpTransition:YES forLayer:self.window.layer];
    
    [navControllerLogin pushViewController:viewControllerLogin animated:NO];
    
    // show the login view
    self.window.rootViewController = navControllerLogin;
    self.loginNavController = navControllerLogin;
}

// pop and hide Login navigation view controller
- (void)popLoginNavigation
{
    NSLog(@"APP: popLoginNavigation");
    
    if (self.loginNavController == nil) {
        NSLog(@"DEBUG: popLoginNavigation--loginNavController == nil return");
        return;
    }
    
    // 设置动画效果
    [ToolsFunction moveUpTransition:NO forLayer:self.window.layer];
    
    [self.loginNavController popViewControllerAnimated:NO];
    
    // release login views
    if (self.loginNavController)
    {
        [self.loginNavController.view removeFromSuperview];
        self.loginNavController = nil;
    }
    
    if (self.mainTabController) {
        // show main Tab Controller
        self.window.rootViewController = self.mainTabController;
    }
    
    self.mainTabController.tabBar.hidden = YES;
}

// push register view controller
- (void)pushRegisterViewController
{
    NSLog(@"APP: pushRegisterViewController");
    
    if (self.registerNavController != nil) {
        NSLog(@"DEBUG: pushRegisterViewController--registerNavController != nil return");
        return;
    }
    
    // create naviagtion container
    NavigationViewController *navControllerRegister = [[NavigationViewController alloc] init];
    
    // 弹出注册页面
    RegisterViewController *viewControllerRegister = [[RegisterViewController alloc]
                                                      initWithNibName:@"RegisterViewController" bundle:[NSBundle mainBundle]];
    
    // 设置动画效果
    [ToolsFunction moveUpTransition:YES forLayer:[AppDelegate appDelegate].window.layer];
    
    viewControllerRegister.isAlonePush = YES;
    viewControllerRegister.hidesBottomBarWhenPushed = YES;
    
    [navControllerRegister pushViewController:viewControllerRegister animated:NO];
    
    // show the register view
    self.window.rootViewController = navControllerRegister;
    self.registerNavController = navControllerRegister;
}

// pop register view controller
- (void)popRegisterViewController
{
    NSLog(@"APP: popRegisterViewController");
    
    if (self.registerNavController == nil) {
        NSLog(@"DEBUG: popRegisterViewController--registerNavController == nil return");
        return;
    }
    
    // 设置动画效果
    [ToolsFunction moveUpTransition:NO forLayer:self.window.layer];
    
    [self.registerNavController popViewControllerAnimated:NO];
    
    // release register views
    if (self.registerNavController)
    {
        [self.registerNavController.view removeFromSuperview];
        self.registerNavController = nil;
    }
    
    if (self.mainTabController) {
        // show main Tab Controller
        self.window.rootViewController = self.mainTabController;
    }
}

// create and show the main tab view for normal operation
- (void)createMainTabbarController
{
    if (self.mainTabController != nil) {
        NSLog(@"DEBUG: createMainTabbarController != nil return");
        return;
    }
    
    NSLog(@"APP: createMainTabbarController");
    
    // "HomePage"
    HomePageViewController *homePageViewController = [[HomePageViewController alloc]
                                                    initWithNibName:@"HomePageViewController" bundle:[NSBundle mainBundle]];
    NavigationViewController *navHomePage = [[NavigationViewController alloc] initWithRootViewController:homePageViewController];
    
    // "AirportService"
    AirportServiceViewController *airportServiceViewController = [[AirportServiceViewController alloc] initWithNibName:@"AirportServiceViewController" bundle:[NSBundle mainBundle]];
    NavigationViewController *navAirportService = [[NavigationViewController alloc] initWithRootViewController: airportServiceViewController];
    
    // "CateringShopping"
    CateringShoppingViewController *cateringShoppingViewController = [[CateringShoppingViewController alloc]
                                          initWithNibName:@"CateringShoppingViewController" bundle:[NSBundle mainBundle]];
    
    NavigationViewController *navCateringShopping = [[NavigationViewController alloc] initWithRootViewController:cateringShoppingViewController];
    
    // "PersonalCenter"
    PersonalCenterViewController *personalCenterViewController = [[PersonalCenterViewController alloc]
                                                                      initWithNibName:@"PersonalCenterViewController" bundle:[NSBundle mainBundle]];
    
    NavigationViewController *navPersonalCenter = [[NavigationViewController alloc] initWithRootViewController:personalCenterViewController];
    
    // 创建主界面的TabBarController
    UITabBarController *controllerMainTabBar = [[UITabBarController alloc] init];
    controllerMainTabBar.delegate = self;
    [controllerMainTabBar.tabBar setTintColor:COLOR_TABBAR_TINTCOLOR];
    [controllerMainTabBar.tabBar setBarTintColor:[UIColor whiteColor]];
    controllerMainTabBar.viewControllers = [NSArray arrayWithObjects:navHomePage, navAirportService, navCateringShopping, navPersonalCenter, nil];
    self.mainTabController = controllerMainTabBar;
    
    // show main Tab Controller
    self.window.rootViewController = self.mainTabController;
}

// push到订单页面
- (void)pushOrderListView:(UIViewController *)viewController
{
    [viewController.navigationController popToRootViewControllerAnimated:NO];
    self.mainTabController.selectedIndex = PersonalCenterTabIndex;
    
    [self performSelector:@selector(pushPeronalCenterOrderListView) withObject:nil afterDelay:0.0];
}

- (void)pushPeronalCenterOrderListView
{
    // 查找到PersonalCenterViewController
    PersonalCenterViewController *personalCenterViewCtr = nil;
    NSArray *controllerArray = [self.mainTabController viewControllers];
    UINavigationController *navController = [controllerArray objectAtIndex:PersonalCenterTabIndex];
    if ([[[navController viewControllers] objectAtIndex: 0] isKindOfClass:[PersonalCenterViewController class]])
    {
        personalCenterViewCtr = (PersonalCenterViewController *)[[navController viewControllers] objectAtIndex: 0];
        
        // push进入订单页面
        if (personalCenterViewCtr) {
            PersonalOrdersViewController *personalOrdersViewCtr = [[PersonalOrdersViewController alloc] initWithNibName:@"PersonalOrdersViewController" bundle:[NSBundle mainBundle]];
            
            personalOrdersViewCtr.hidesBottomBarWhenPushed = YES;
            [personalCenterViewCtr.navigationController pushViewController:personalOrdersViewCtr animated:YES];
        }
    }
}

// 判断是否Tabbar的Root Controller为顶层窗口
- (BOOL)isTabbarRootControllerInTopViewController
{
    BOOL bInTop = NO;
    UINavigationController *selectedNavigationController = (UINavigationController *)self.mainTabController.selectedViewController;
    UIViewController *topViewController = selectedNavigationController.topViewController;
    
    if ([topViewController isKindOfClass:[HomePageViewController class]])
    {
        NSLog(@"APP: topViewController: FlightDynamicsViewController");
        bInTop = YES;
    }
    else if ([topViewController isKindOfClass:[AirportServiceViewController class]])
    {
        NSLog(@"APP: topViewController: AirportServiceViewController");
        bInTop = YES;
    }
    else if ([topViewController isKindOfClass:[CateringShoppingViewController class]])
    {
        NSLog(@"APP: topViewController: CateringShoppingViewController");
        bInTop = YES;
    }
    else if ([topViewController isKindOfClass:[PersonalCenterViewController class]])
    {
        NSLog(@"APP: topViewController: PersonalCenterViewController");
        bInTop = YES;
    }
    
    return bInTop;
}

// 显示自定义消息的提示框
- (void)showReceivedCustomUserMessageAlertView
{
    if ([self.userMessageDic allKeys].count == 0) {
        return;
    }
    
    NSString *alertTitle = nil;
    // 获取Key
    NSString *messageTypeKey = [[self.userMessageDic allKeys] objectAtIndex:0];
    
    switch ([messageTypeKey intValue]) {
        case 101: // 航班关注提醒消息
        {
            alertTitle = NSLocalizedString(@"PROMPT_RECIVER_USER_MESSAGE_PLANE", @"");
        }
            break;
            
        case 201: // 自由购到货提醒消息
        {
            alertTitle = NSLocalizedString(@"PROMPT_RECIVER_USER_MESSAGE_BOOK_SHOPPING", @"");
        }
            break;
            
        case 202: // 自由购取消消息
        {
            alertTitle = NSLocalizedString(@"PROMPT_RECIVER_USER_MESSAGE_CANCEL_SHOPPING", @"");
        }
            break;
            
        default:
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIAlertView showSimpleAlert:[self.userMessageDic objectForKey:messageTypeKey]
                           withTitle:alertTitle
                          withButton:NSLocalizedString(@"STR_OK", @"确定")
                            toTarget:self];
    });
}


#pragma mark -
#pragma mark UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    /*
    // 是当前的mainTabController并且用户没有登录，则进行登录页面的弹出逻辑
    if (self.mainTabController == tabBarController && ![self.userProfilesInfo isLogined]) {
        
        UINavigationController *navController = (UINavigationController *)viewController;
        NSArray *arrayViewControllers = [navController viewControllers];
        if (arrayViewControllers && [arrayViewControllers count] > 0)
        {
            // 找到Tabbar Item上第一个UIViewController
            UIViewController *viewControllerFirst = [arrayViewControllers objectAtIndex:0];
            // 如果点击的是“个人中心”则直接弹出登录页面
            if ([viewControllerFirst isKindOfClass:[PersonalCenterViewController class]])
            {
                // 设置当前选中为个人中心
                self.mainTabController.selectedIndex = PersonalCenterTabIndex;
                
                // 弹出登录页面
                [self pushLoginNavigation];
                
                return NO;
            }
        }
    }
     */
    
    return YES;
}


#pragma mark - RKCloudBaseDelegate

/**
 * @brief 代理方法: 账号异常的回调处理
 *
 * @param errorCode 错误码 1：重复登录，2：账号被禁
 * @return
 */
- (void)didRKCloudFatalException:(int)errorCode
{
    switch (errorCode) {
        case 1: // 重复登录
        {
            // 提示重复登录帐号并自动登出
            [self.userProfilesInfo promptRepeatLogin];
        }
            break;
            
        case 2: // 账号被禁
        {
            // 提示用户被禁止使用
            [self.userProfilesInfo promptBannedUsers];
        }
            break;
            
        default:
            break;
    }
}

// 通知用户接收到自定义消息
- (void)didReceivedCustomUserMsg:(NSArray *)customMessages
{
    NSLog(@"RKCloudBaseDelegate: didReceivedCustomUserMsg: customMessages = %@", customMessages);
 
    if (customMessages == nil || [customMessages count] == 0) {
        return;
    }
    
    /*
     3.6.1	消息推送说明：
     这里指通过运势互动PPM消息推送的业务消息，包括航班动态变更消息，自由购到货通知消息，自由购取消消息等。格式为JSON，包括一个简单的数据结构，客户端根据msg_type来解析具体的业务。
     
     具体格式：
     1、航班关注提醒消息:
     {"msg_type":101,"flight_id":"CA1234","content":"天气原因延误"}
     客户端处理方式：接收到消息，通知栏点击后，弹出对话框显示即可。不用去关联跳转到航班详情。
     
     2、航班状态变更通知，客户端主动去服务器同步状态
     {"msg_type":102,"flight_id":10001234}
     
     3、自由购到货提醒消息:
     {"msg_type":201,"goods_id":10001234,"order_id":"213123123","content":"你预定的台湾大芒果，20kg装已经到达，请前往***拿取","time":1441234567}
     
     4、自由购取消消息：
     {"msg_type":202,"goods_id":10001234,"order_id":"213123123","content":"你预定的台湾大芒果，因为团购人数不足已撤销，支付费用3天内返还至个人帐户","time":1441234567}
     
     msg_type:消息内容
     flight_no:航班号
     goods_id:单品id
     order_id:订单id
     content:业务对应消息内容。
     */
    
    if (self.userMessageDic == nil) {
        self.userMessageDic = [[NSMutableDictionary alloc] init];
    }
    
    // 解析自定义消息
    for (NSString *strCustomMessage in customMessages)
    {
        NSDictionary *dictCustomMessage = [strCustomMessage JSONValue];
        if (![dictCustomMessage isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        NSDictionary *dictContent = [[dictCustomMessage objectForKey:@"content"] JSONValue];
        
        // msg_type
        NSString *msgType = [dictContent objectForKey:@"msg_type"];
        switch ([msgType intValue]) {
            case 101: // 航班关注提醒消息
            {
               [self.userMessageDic setObject:[dictContent objectForKey:@"content"] forKey:@"101"];
                
                // 更新本地关注航班信息
               [self.airportManager getAirportDetailAndUpdateToDB:[dictContent objectForKey:@"flight_id"]];
            }
                break;
                
            case 102: // 航班状态变更通知，客户端主动去服务器同步状态
            {
                // 更新本地关注航班信息
                [self.airportManager getAirportDetailAndUpdateToDB:[dictContent objectForKey:@"flight_id"]];
            }
                break;
                
            case 201: // 自由购到货提醒消息
            {
                [self.userMessageDic setObject:[dictContent objectForKey:@"content"] forKey:@"201"];
            }
                break;
                
            case 202: // 自由购取消消息
            {
                [self.userMessageDic setObject:[dictContent objectForKey:@"content"] forKey:@"202"];
            }
                break;
                
            default:
                break;
        }
    }
    
    // 显示自定义消息的提示框
    [self showReceivedCustomUserMessageAlertView];
}


#pragma mark -
#pragma mark - User Message UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self.userMessageDic removeObjectForKey:[[self.userMessageDic allKeys] objectAtIndex:0]];
    }
    
    [self showReceivedCustomUserMessageAlertView];
}

#pragma mark - LocationManagerDelegate

- (void)didFinishLocation:(LocationInfo *)locationInfo
{
    NSLog(@"LOCATION: didFinishLocation: cityName = %@", locationInfo.cityName);
    
    // 同步获取定位机场，根据用户提交城市匹配可用机场
    [self.airportManager asyncGetAirportPositionByCityName:locationInfo.cityName];
}

- (void)didFailLocation:(NSError *)error
{
    NSLog(@"LOCATION: didFailLocation: error = %@", error);
    
    // 初次进入，若个人信息三字码为空 进行操作
    if (self.userProfilesInfo.currentAirportCode == nil)
    {
        [self.airportManager failedGetAirportPosition];
    }
}


#pragma mark - WXApiDelegate

/*! @brief 收到一个来自微信的请求，处理完后调用sendResp
 *
 * 收到一个来自微信的请求，异步处理完成后必须调用sendResp发送处理结果给微信。
 * 可能收到的请求有GetMessageFromWXReq、ShowMessageFromWXReq等。
 * @param req 具体请求内容，是自动释放的
 */
- (void)onReq:(BaseReq*)req
{
    if([req isKindOfClass:[GetMessageFromWXReq class]])
    {
        // 微信请求App提供内容， 需要app提供内容后使用sendRsp返回
        NSString *strTitle = [NSString stringWithFormat:@"微信请求App提供内容"];
        NSString *strMsg = @"微信请求App提供内容，App要调用sendResp:GetMessageFromWXResp返回给微信";
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        alert.tag = 1000;
        [alert show];
    }
    else if([req isKindOfClass:[ShowMessageFromWXReq class]])
    {
        ShowMessageFromWXReq* temp = (ShowMessageFromWXReq*)req;
        WXMediaMessage *msg = temp.message;
        
        //显示微信传过来的内容
        WXAppExtendObject *obj = msg.mediaObject;
        
        NSString *strTitle = [NSString stringWithFormat:@"微信请求App显示内容"];
        NSString *strMsg = [NSString stringWithFormat:@"标题：%@ \n内容：%@ \n附带信息：%@ \n缩略图:%lu bytes\n\n", msg.title, msg.description, obj.extInfo, (unsigned long)msg.thumbData.length];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
    else if([req isKindOfClass:[LaunchFromWXReq class]])
    {
        //从微信启动App
        NSString *strTitle = [NSString stringWithFormat:@"从微信启动"];
        NSString *strMsg = @"这是从微信启动的消息";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

/*! @brief 发送一个sendReq后，收到微信的回应
 *
 * 收到一个来自微信的处理结果。调用一次sendReq后会收到onResp。
 * 可能收到的处理结果有SendMessageToWXResp、SendAuthResp等。
 * @param resp具体的回应内容，是自动释放的
 */
- (void)onResp:(BaseResp*)resp
{
    NSString *strMsg = [NSString stringWithFormat:@"errcode:%d", resp.errCode];
    NSString *strTitle = nil;
    
    if ([resp isKindOfClass:[SendMessageToWXResp class]])
    {
        strTitle = [NSString stringWithFormat:@"发送媒体消息结果"];
    }
    
    // 微信支付
    if ([resp isKindOfClass:[PayResp class]])
    {
        //支付返回结果，实际支付结果需要去微信服务器端查询
        strTitle = [NSString stringWithFormat:@"微信支付结果"];
        
        switch (resp.errCode) {
            case WXSuccess:
            {
                strMsg = @"支付结果：成功！";
                NSLog(@"%@ 微信支付成功－PaySuccess，retcode = %d, strMsg = %@", strTitle, resp.errCode, strMsg);
                
                // 告知代理者支付成功
                if (self.paymentManager.delegate && [self.paymentManager.delegate respondsToSelector:@selector(didPaymentSuccess:)])
                {
                    self.paymentManager.paymentOrderInfoObject.payResult = PayResultSuccess;
                    [self.paymentManager.delegate didPaymentSuccess:self.paymentManager.paymentOrderInfoObject];
                }
            }
                break;
                
            default:
            {
                strMsg = [NSString stringWithFormat:@"支付结果：失败！retcode = %d, retstr = %@", resp.errCode, resp.errStr];
                NSLog(@"%@ 微信支付错误，retcode = %d, strMsg = %@", strTitle, resp.errCode, strMsg);
                
                // 告知代理者支付失败
                if (self.paymentManager.delegate && [self.paymentManager.delegate respondsToSelector:@selector(didPaymentFail:)])
                {
                    self.paymentManager.paymentOrderInfoObject.payResult = PayResultFailure;
                    [self.paymentManager.delegate didPaymentFail:self.paymentManager.paymentOrderInfoObject];
                }
            }
                break;
        }
    }
}

@end
