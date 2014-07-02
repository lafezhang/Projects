//
//  CBScrollView.h
//  CBWallet4iPhone
//
//  Created by zhangxiaodong on 14-7-2.
//  Copyright (c) 2014年 hanhui. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  IOS7 下，如果scrollView中有输入框，当输入框获取焦点时会自动滚动到该输入框，
    这种行为与CBKeyBoardManager中得输入框显示规则相违背，因此添加了一个属性temporarilyDisableAutoScroll。
    当该属性为YES时，setContentOffset方法会失效，借此来阻止IOS7的自动行为
 */
@interface CBScrollView : UIScrollView

@property (nonatomic) BOOL temporarilyDisableAutoScroll;

@end
