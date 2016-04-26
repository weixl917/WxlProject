//
//  AddFriendViewController.m
//  ExcellentLearning
//
//  Created by 程荣刚 on 15/12/1.
//  Copyright © 2015年 rongkecloud. All rights reserved.
//

#import "AddFriendOrGroupViewController.h"
#import "TextFieldTableViewCell.h"
#import "SearchConditionViewController.h"

#import "SearchGroupResultViewController.h"
#import "SearchPersonResultViewController.h"
#import "PersonalCenterViewController.h"

#import "ClassAddViewController.h"
#import "ClassConditionSearchViewController.h"
#import "RegularCheckTools.h"
#import "AppDelegate.h"
#import "GroupListTableViewController.h"

@interface AddFriendOrGroupViewController ()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *addFriendTableView; // 添加列表
@property (assign, nonatomic) UITextField *searchTextField; // 搜索
@property (assign, nonatomic) AppDelegate *appDelegate; //

@end

@implementation AddFriendOrGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.appDelegate = [AppDelegate appDelegate];
    
    //自定义左侧返回按钮
    UIButton *buttonLeft = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, SESSION_LIST_NAVIGETIONBAR_BUTTON_WIDTH_OR_HEIGTH, SESSION_LIST_NAVIGETIONBAR_BUTTON_WIDTH_OR_HEIGTH)];
    
    [buttonLeft setImage:[UIImage imageNamed:@"personal_left_Back_btn_n"] forState:UIControlStateNormal];
    [buttonLeft setImage:[UIImage imageNamed:@"personal_left_Back_btn_s"] forState:UIControlStateSelected];
    buttonLeft.imageEdgeInsets = UIEdgeInsetsMake(0, -30, 0, 0);
    [buttonLeft addTarget:self action:@selector(addFriendOrGroupTouchLeftButtonItem:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *buttonItemLeft = [[UIBarButtonItem alloc] initWithCustomView:buttonLeft];
    self.navigationItem.leftBarButtonItem = buttonItemLeft;
    
    // 注册TextField通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
    // 设置导航栏文字显示
    [self setNavigationBarTitleMode];
    
    //分割线颜色
    self.addFriendTableView.separatorColor = SeparationColor;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.searchTextField.text = @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.searchTextField resignFirstResponder];
}

#pragma mark - Custom Method

// 设置导航栏文字显示
- (void)setNavigationBarTitleMode
{
    switch (self.addType)
    {
        case ADD_TYPE_FRIEND:
        {
            self.navigationItem.title = NSLocalizedString(@"STR_ADD_FRIEND", nil);
        }
            break;
            
        case ADD_TYPE_GROUP:
        {
            self.navigationItem.title = NSLocalizedString(@"STR_ADD_GROUP", nil);
        }
            break;
            
        case ADD_TYPE_CLASS:
        {
            self.navigationItem.title = NSLocalizedString(@"CLASS_ADD_CLASS", nil);
        }
            break;
            
        default:
            break;
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionNum;
    switch (self.addType)
    {
        case ADD_TYPE_FRIEND:
        {
            sectionNum = 2;
        }
            break;
            
        case ADD_TYPE_GROUP:
        {
            sectionNum = 1;
        }
            break;
            
        case ADD_TYPE_CLASS:
        {
            sectionNum = 2;
        }
            break;
            
        default:
            break;
    }
    
    return sectionNum;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cellDefault = nil;
    
    if (self.addType == ADD_TYPE_FRIEND || self.addType == ADD_TYPE_CLASS)
    {
        switch ([indexPath section])
        {
            case 0:
            {
                static NSString *cellInde = @"TextFieldTableViewCell";
                
                //创建nib对象
                UINib *cellNib = [UINib nibWithNibName:@"TextFieldTableViewCell" bundle:[NSBundle bundleForClass:[TextFieldTableViewCell class]]];
                [self.addFriendTableView registerNib:cellNib forCellReuseIdentifier:cellInde];
                
                TextFieldTableViewCell *cellSearchFriend = [tableView dequeueReusableCellWithIdentifier:cellInde];
                
                if (cellSearchFriend == nil)
                {
                    cellSearchFriend = [[TextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellInde];
                }
                if (self.addType == ADD_TYPE_CLASS) {
                    [cellSearchFriend.searchTextField setPlaceholder:NSLocalizedString(@"CLASS_SEARCH_PLEASEHODER" , "请输入班主任手机号")];
                }
                
                if (self.addType == ADD_TYPE_FRIEND) {
                    cellSearchFriend.searchTextField.placeholder = NSLocalizedString(@"PROMPT_INPUT_MOBILE_NUM_OR_ACCOUNT", "输入手机号／账号");
                }
                self.searchTextField = cellSearchFriend.searchTextField;
                self.searchTextField.delegate = self;
                [self.searchTextField resignFirstResponder];
                [self.searchTextField setTag:111];
                cellSearchFriend.selectionStyle = UITableViewCellSelectionStyleNone;
                cellDefault = cellSearchFriend;
            }
                break;
                
            case 1:
            {
                static NSString *cellInde = @"defaultTableViewCell";
                
                UITableViewCell *cellCondition = [tableView dequeueReusableCellWithIdentifier:cellInde];
                
                if (cellCondition == nil)
                {
                    cellCondition = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellInde];
                }
                
                cellCondition.imageView.image = [UIImage imageNamed:@"class_condition_search"];
                cellCondition.textLabel.text = NSLocalizedString(@"PROMPT_CONDITION_SEARCH", nil);
                cellCondition.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
                cellDefault = cellCondition;
            }
                break;
                
            default:
                break;
        }
    } else {
        static NSString *cellInde = @"TextFieldTableViewCell";
        
        //创建nib对象
        UINib *cellNib = [UINib nibWithNibName:@"TextFieldTableViewCell" bundle:[NSBundle bundleForClass:[TextFieldTableViewCell class]]];
        [self.addFriendTableView registerNib:cellNib forCellReuseIdentifier:cellInde];
        
        TextFieldTableViewCell *cellSearchGroup = [tableView dequeueReusableCellWithIdentifier:cellInde];
        
        if (cellSearchGroup == nil)
        {
            cellSearchGroup = [[TextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellInde];
        }

        self.searchTextField = cellSearchGroup.searchTextField;
        self.searchTextField.placeholder = [NSString stringWithFormat:@"%@/群名称",NSLocalizedString(@"PROMPT_INPUT_GROUP_NUM", "输入群号")];
        self.searchTextField.delegate = self;
        [self.searchTextField resignFirstResponder];
        cellSearchGroup.selectionStyle = UITableViewCellSelectionStyleNone;
        cellDefault = cellSearchGroup;
    }
    
    return cellDefault;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.addType == ADD_TYPE_FRIEND && [indexPath section] == 1)
    {
        SearchConditionViewController *vwcSearch = [[SearchConditionViewController alloc] initWithNibName:@"SearchConditionViewController" bundle:[NSBundle mainBundle]];
        vwcSearch.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vwcSearch animated:YES];
    }
    
    if (self.addType == ADD_TYPE_CLASS && indexPath.section == 1) {
        ClassConditionSearchViewController *vwcCon = [[ClassConditionSearchViewController alloc] initWithNibName:@"ClassConditionSearchViewController" bundle:[NSBundle mainBundle]];
        [self.navigationController pushViewController:vwcCon animated:YES];
    }
}


#pragma mark - UITextFieldDelegate

// 键盘的done操作
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *stringtextField = [[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
    //4/4S上  提示窗被键盘挡住
        NSInteger iOSMachineHardwareType = [ToolsFunction iOSMachineHardwareType];
        if (iOSMachineHardwareType == MACHINE_IPHONE_4
            || iOSMachineHardwareType == MACHINE_IPHONE_4S) {
            [self.searchTextField resignFirstResponder];
        }
    
    if ([stringtextField length] == 0)
    {
        [ToolsFunction showAutoHidePromptView:NSLocalizedString(@"PROMPT_INPUT_CORRECT_FORMAT", "输入内容不能为空格或空") background:nil showTime:DEFAULT_TIMER_WAITING_VIEW];
        return NO;
    }
    
    // 没有网络则提示没有连接
    if ([ToolsFunction checkInternetReachability] == NO)
    {
        // Gray.Wang:2012.11.10: 提供用户用好性，网络提示不用用户点击即可，一秒提示自动消失。
        [ToolsFunction showAutoHidePromptView:NSLocalizedString(@"PROMPT_NETWORK_ERROR", nil)
                                   background:[UIImage imageNamed:@"mac_no_net"]
                                     showTime:AUTO_HIDE_TIMER_WAITING_VIEW];

        return NO;
    }
    
    // FIXME: 调用搜索接口
    switch (self.addType)
    {
        case ADD_TYPE_FRIEND:
        {
            // 搜索好友
            [self.searchTextField resignFirstResponder];
            [ToolsFunction showWaitingMaskView:NSLocalizedString(@"PROMPT_LATER_ON", "")];
            [self asyncsyncFindUserWithUserAccountOrMobile];
        }
            break;
            
        case ADD_TYPE_GROUP:
        {
            // 搜索群
            [self.searchTextField resignFirstResponder];
            [ToolsFunction showWaitingMaskView:NSLocalizedString(@"PROMPT_LATER_ON", "")];
            [self syncSearchGroupWithGroupId];
        }
            break;
            
        case ADD_TYPE_CLASS:
        {
            [self syncSearchClassWithClassId];
        }
            break;
        default:
            break;
    }

    return YES;
}


#pragma mark - UIResponder

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.searchTextField resignFirstResponder];
}

#pragma mark - Http Request Method

// 搜索好友
- (void)asyncsyncFindUserWithUserAccountOrMobile
{
    // 没有网络则提示没有连接
    if ([ToolsFunction checkInternetReachability] == NO)
    {
        //网络提示不用用户点击即可，一秒提示自动消失。
        [ToolsFunction showAutoHidePromptView:NSLocalizedString(@"PROMPT_NETWORK_ERROR", nil)
                                   background:[UIImage imageNamed:@"mac_no_net"]
                                     showTime:AUTO_HIDE_TIMER_WAITING_VIEW];
        return;
    }
    
    [ToolsFunction showWaitingMaskView:NSLocalizedString(@"STR_WAITING", "请稍候...")];
    
    BOOL isSelfAccount = [self.searchTextField.text isEqualToString:self.appDelegate.userProfilesInfo.userAccount];
    BOOL isSelfMobile = [self.searchTextField.text isEqualToString:self.appDelegate.userProfilesInfo.userMobile];
    if (isSelfAccount ||isSelfMobile) {
        [ToolsFunction hideWaitingMaskView];
        [ToolsFunction showAutoHidePromptView:@"不能搜索自己的账号" background:nil showTime:1.5];
        return;
    }
    
    [self.appDelegate.userInfoManager asyncFindUserWithUserAccountOrMobile:self.searchTextField.text
                                                            findResultPage:0
                                                                 onSuccess:^(NSArray <ContactTable *> *resultUsersArray)
     {
         // 成功
         [ToolsFunction hideWaitingMaskView];
         if ([resultUsersArray count] == 0)
         {
             [ToolsFunction showAutoHidePromptView:NSLocalizedString(@"STR_NO_RESULT", "无数据") background:nil showTime:DEFAULT_TIMER_WAITING_VIEW];
         }
//         else if ([resultUsersArray count] == 1)
//         {
//             ContactTable *contactTable = [resultUsersArray lastObject];
//             
//             // 好友 查找到 跳转个人详情
//             PersonalCenterViewController *vwcPersonalCenter = [[PersonalCenterViewController alloc] init];
//             if (![contactTable.userId isEqualToString:self.appDelegate.userProfilesInfo.userId])
//             {
//                 vwcPersonalCenter.passedUserId = contactTable.userId;
//             }
//             [self.navigationController pushViewController:vwcPersonalCenter animated:YES];
//         }
         else
         {
             SearchPersonResultViewController *vwcSearchPersonResult = [[SearchPersonResultViewController alloc] initWithNibName:NSStringFromClass([SearchPersonResultViewController class]) bundle:[NSBundle mainBundle]];
             vwcSearchPersonResult.searchUserType = SearchUserTypeAccountOrMobile;
             vwcSearchPersonResult.searchContactsArray = [NSMutableArray arrayWithArray:resultUsersArray];
             vwcSearchPersonResult.findUserAccountOrMobile = self.searchTextField.text;
             [self.navigationController pushViewController:vwcSearchPersonResult animated:YES];
         }
     }
                                                                  onFailed:^(int errCode)
     {
         // 失败
         [ToolsFunction hideWaitingMaskView];
         [HttpClientKit errorCodePrompt:errCode];
     }];
}

// 搜索群
- (void)syncSearchGroupWithGroupId
{
    // 没有网络则提示没有连接
    if ([ToolsFunction checkInternetReachability] == NO)
    {
        //网络提示不用用户点击即可，一秒提示自动消失。
        [ToolsFunction showAutoHidePromptView:NSLocalizedString(@"PROMPT_NETWORK_ERROR", nil)
                                   background:[UIImage imageNamed:@"mac_no_net"]
                                     showTime:AUTO_HIDE_TIMER_WAITING_VIEW];
        return;
    }
    
    [ToolsFunction showWaitingMaskView:NSLocalizedString(@"STR_WAITING", "请稍候...")];
    NSString *groupId = [self.searchTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.appDelegate.chatGroupManager asyncSearchGroupWithGroupId:groupId
                                                         onSuccess:^(NSArray *sessionTableArray)
    {
        [ToolsFunction hideWaitingMaskView];
        DebugLog(@"searchSessionTable:%@",sessionTableArray);
        // 群 查找到
        switch (sessionTableArray.count) {
            case 0:
            {
                [ToolsFunction showAutoHidePromptView:[NSString stringWithFormat:@"群名称/%@",NSLocalizedString(@"API_ERRCODE_GROUP_ID_NOT_EXIST_6213" ,@"群号码不存在")] background:nil showTime:DEFAULT_TIMER_WAITING_VIEW];
               
            }
                break;
//            case 1:
//            {
//                SearchGroupResultViewController *vwcSearchGroup = [[SearchGroupResultViewController alloc] initWithNibName:NSStringFromClass([SearchGroupResultViewController class]) bundle:[NSBundle mainBundle]];
//                vwcSearchGroup.sessionTable = sessionTableArray.firstObject;
//                [self.navigationController pushViewController:vwcSearchGroup animated:YES];
//
//            }
//                break;
                
            default:
            {
                GroupListTableViewController *groupListController = [[GroupListTableViewController alloc] init];
                groupListController.navigationItem.title = @"查找结果";
                groupListController.sessionTableArray = sessionTableArray;
                [self.navigationController pushViewController:groupListController animated:YES];
            }
                break;
        }
       
    }
    onFailed:^(int errorCode)
    {
        [ToolsFunction hideWaitingMaskView];
        [HttpClientKit errorCodePrompt:errorCode];
    }];
}


//搜索班级
- (void)syncSearchClassWithClassId
{
    NSLog(@"AddFriendOrGroupViewController type = ADD_TYPE_CLASS");
    if (self.searchTextField.text.length > 0)
    {
        // 判断是否符合要求
        if (![RegularCheckTools isMobile:self.searchTextField.text])
        {
            [ToolsFunction showAutoHidePromptView:NSLocalizedString(@"CLASS_SEARCH_PLEASEHODER" , "请输入班主任手机号") background:nil showTime:DEFAULT_TIMER_WAITING_VIEW];
            return;
        }
        [self.searchTextField resignFirstResponder];
        GeneralTempObject *obj = [[GeneralTempObject alloc] init];

        obj.phoneNum = self.searchTextField.text;

        obj.type = 1;
        [ToolsFunction showWaitingMaskView:NSLocalizedString(@"STR_WAITING", "请稍候...")];
        //查找班级
        [self.appDelegate.classManager queryClassFromServer:obj
                                                  onSuccess:^(NSArray *classArr)
         {
             [ToolsFunction hideWaitingMaskView];
             // 班级 查找到
             ClassAddViewController *vwcAdd = [[ClassAddViewController alloc] initWithNibName:NSStringFromClass([ClassAddViewController class]) bundle:[NSBundle mainBundle]];
             vwcAdd.addType = ClassSearchTypeAcc;
             vwcAdd.arrayGeneralTemp = classArr;
             [self.navigationController pushViewController:vwcAdd animated:YES];
             
         }
                                                  onFailed:^(int errCode)
         {
             [ToolsFunction hideWaitingMaskView];
             [self.searchTextField becomeFirstResponder];
             [HttpClientKit errorCodePrompt:errCode];
         }];
    }

}


- (void)textDidChange:(NSNotification *)obj
{
    UITextField *textField = (UITextField *)obj.object;
    if (textField.tag == 111) {
        NSInteger maxStrLendth = USER_ACCOUNT_MAX_LENGTH;
        switch (self.addType)
        {
            case ADD_TYPE_FRIEND:
            case ADD_TYPE_GROUP:
            {
                maxStrLendth = USER_ACCOUNT_MAX_LENGTH;
            }
                break;
            case ADD_TYPE_CLASS:
            {
                maxStrLendth = USER_MOBILE_MAX_LENGTH;
            }
                break;
            default:
                break;
        }
        NSString *toBeString = textField.text;
        UITextRange *selectedRange = [textField markedTextRange];
        UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
        if (!position)
        {
            if (toBeString.length > maxStrLendth) {
                textField.text = [toBeString substringToIndex:maxStrLendth];
            }
        }
    }
}

- (void)addFriendOrGroupTouchLeftButtonItem:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
