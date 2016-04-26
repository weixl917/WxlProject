//
//  AppDelegate.h
//  EnjoySkyLine
//
//  Created by WangGray on 15/5/12.
//  Copyright (c) 2015年 西安融科通信技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NavigationViewController.h"
#import "UserProfilesInfo.h"
#import "DatabaseManager.h"
#import "ThreadsManager.h"
#import "LocationManager.h"
#import "ShoppingManager.h"
#import "AirportManager.h"
#import "UserInfoManager.h"
#import "UserOrdersManager.h"
#import "PaymentManager.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate, LocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UITabBarController *mainTabController; // Main TabBar UIViewController

@property (strong, nonatomic) UserProfilesInfo *userProfilesInfo; // 当前帐号信息类
@property (strong, nonatomic) DatabaseManager *databaseManager; // 数据库管理类
@property (strong, nonatomic) ThreadsManager *threadsManager; // Threads Manager
@property (strong, nonatomic) LocationManager *locationManager; // 定位管理类
@property (strong, nonatomic) ShoppingManager *shoppingManager; // 购物管理类
@property (strong, nonatomic) AirportManager *airportManager; // 机场管理类
@property (strong, nonatomic) UserInfoManager *userInfoManager; // 个人信息管理类
@property (strong, nonatomic) UserOrdersManager *userOrdersManager; // 用户订单管理类
@property (strong, nonatomic) PaymentManager *paymentManager; // 支付管理类

@property (nonatomic) short applicationRunState; // 程序运行状态的标志位

/* 程序运行状态的标志位
 BIT0: 是否重置帐号过程中
 BIT1: 是否登录账号过程中
 */

#pragma mark -
#pragma mark Get AppDelegate

+ (AppDelegate *)appDelegate;

#pragma mark -
#pragma mark UI Components

// push and show Login navigation view controller
- (void)pushLoginNavigation;
// pop and hide Login navigation view controller
- (void)popLoginNavigation;

// push register view controller
- (void)pushRegisterViewController;
// pop register view controller
- (void)popRegisterViewController;

// create and show the main tab view for normal operation
- (void)createMainTabbarController;

// push and show OrderListViewController
- (void)pushOrderListView:(UIViewController *)viewController;

// 判断是否Tabbar的Root Controller为顶层窗口
- (BOOL)isTabbarRootControllerInTopViewController;
@end

