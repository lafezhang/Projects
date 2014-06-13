//
//  UIViewController+Process.h
//  TestNavagation
//
//  Created by zhangxiaodong on 14-6-13.
//  Copyright (c) 2014年 zhangxiaodong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Process)

/**
 *  标记此controller为一个新流程的开始
 *
 *  @param processIdentifier 流程id
 */
- (void)markAsProcessStartWithIdentifier:(NSString*)processIdentifier;

/**
 *  标记此controller为一个流程的开始，并用一个uuid作为id
 *
 *  @return
 */
- (NSString*)markAsProcessStart;

// only call these method before you push a new controller.
/**
 *  标记此controller为最近一个流程的结束，在push新的controller之后，所有属于这个
    流程的controller都会从navigation中移除
 */
- (void)markAsProcessEnd;

/**
 *  同上
 *
 *  @param processIdentifier
 */
- (void)markAsProcessEndWithIdentifier:(NSString*)processIdentifier;

/**
 *  后退到前一个流程的最后一个controller
 */
- (void)popToPreviouseProcess;

/**
 *  后退到process的最后一个controller
 *
 *  @param processIdentifier
 */
- (void)popToProcess:(NSString*)processIdentifier;

@end

@interface UIViewController (InternalUse)
- (UIViewController*)startControllerOfProcess:(NSString*)processIdentifier;
- (NSString*)closeIdentifier;

- (NSString*)processIdentifier;
- (void)setProcessIdentifier:(NSString*)processIdentifier;
@end
