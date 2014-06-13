//
//  CBTextfieldPositionManager.h
//  TestUI
//
//  Created by zhangxiaodong on 14-4-28.
//  Copyright (c) 2014年 zhangxiaodong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CBTextfieldPositionManager : NSObject

+ (CBTextfieldPositionManager*)sharedManager;

/**
 *  当textField开始编辑时，确保view可见。如果不可见，则会移动parentView使其可见；
 *  如果view已经可见，则不会移动parentView
 *
 *  此方法会给parentView添加一个tap手势，点击取消编辑。如果parentView已经有tap手势，
 *  则不会添加。
 *  @param view
 *  @param textField
 *  @param parentView
 */
- (void)makeViewVisible:(UIView*)view whenTextFieldEditing:(UITextField*)textField withRootParentView:(UIView*)parentView;

@end
