//
//  MyViewController.h
//  TestNavagation
//
//  Created by zhangxiaodong on 14-6-13.
//  Copyright (c) 2014年 zhangxiaodong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepLabel;

@property (nonatomic) NSInteger step;
@property (nonatomic) NSString* processName;

@end
