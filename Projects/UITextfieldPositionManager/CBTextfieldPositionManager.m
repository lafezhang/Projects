//
//  CBTextfieldPositionManager.m
//  TestUI
//
//  Created by zhangxiaodong on 14-4-28.
//  Copyright (c) 2014年 zhangxiaodong. All rights reserved.
//

#import "CBTextfieldPositionManager.h"
#import <objc/runtime.h>

/**
 *  不对外开发的内部类
 */

@class TextFieldWrapper;
@protocol TextFieldWrapperDelegate <NSObject>

@required
- (void)textFieldWrapperWillDealloced:(TextFieldWrapper*)wrapper;

@end

@interface TextFieldWrapper : NSObject

@property (nonatomic, readonly) NSValue* textFieldValue;
@property (nonatomic) CGFloat parentPosOriginal;
@property (nonatomic, weak) UIView* parentView;
@property (nonatomic, weak) UIView* visibleView;
@property (nonatomic, weak) id<TextFieldWrapperDelegate> delegate;

@property (nonatomic) CGFloat animationTarget;

@end

@implementation TextFieldWrapper

- (id)initWithTextField:(UITextField*)textField
{
    if (self = [super init]) {
        _textFieldValue = [NSValue valueWithNonretainedObject:textField];
    }
    return self;
}

- (void)dealloc
{
//    NSLog(@"dealloced");
    [self.delegate textFieldWrapperWillDealloced:self];
}

@end

/**
 *  Manager实现
 */

CGFloat KeyBoardHeight = 216.f;

@interface CBTextfieldPositionManager ()<TextFieldWrapperDelegate>
{
    NSMutableDictionary* _dict;
}

- (void)cb_textFieldDidBeginEditing:(UITextField*)textField;
- (void)cb_textFieldDidEndEditing:(UITextField*)textField;
- (void)cb_onTapGesture:(UIGestureRecognizer*)gesture;

@end

@implementation CBTextfieldPositionManager

+ (CBTextfieldPositionManager*)sharedManager
{
    static CBTextfieldPositionManager* manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CBTextfieldPositionManager alloc] init];
    });
    return manager;
}

- (id)init
{
    if (self = [super init]) {
        _dict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)makeViewVisible:(UIView *)view whenTextFieldEditing:(UITextField *)textField withRootParentView:(UIView *)parentView
{
    BOOL hasTapGesture = NO;
    for (UIGestureRecognizer* gesture in parentView.gestureRecognizers) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            hasTapGesture = YES;
            break;
        }
    }
    
    if (!hasTapGesture) {
        // 如果没有tap手势，则添加
        UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cb_onTapGesture:)];
        tapGesture.cancelsTouchesInView = NO;
        [parentView addGestureRecognizer:tapGesture];
    }
    
    TextFieldWrapper* wrapper = [[TextFieldWrapper alloc] initWithTextField:textField];
    [textField addTarget:self action:@selector(cb_textFieldDidBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
    [textField addTarget:self action:@selector(cb_textFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
    
    wrapper.parentPosOriginal = parentView.frame.origin.y;
    wrapper.delegate = self;
    wrapper.parentView = parentView;
    wrapper.visibleView = view;
    NSValue* wrapperValue = [NSValue valueWithNonretainedObject:wrapper];
    [_dict setObject:wrapperValue forKey:wrapper.textFieldValue];
    
    static int aaa = 0;
    objc_setAssociatedObject(textField, &aaa, wrapper, OBJC_ASSOCIATION_RETAIN);
}

- (void)cb_performAnimation:(TextFieldWrapper *)wrapper
{
    CGRect frame = wrapper.parentView.frame;
    frame.origin.y = wrapper.animationTarget;
    [UIView animateWithDuration:0.3f delay:0.f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        wrapper.parentView.frame = frame;
    } completion:nil];
}

- (void)cb_onTapGesture:(UIGestureRecognizer *)gesture
{
    [gesture.view endEditing:YES];
}

- (void)cb_textFieldDidBeginEditing:(UITextField *)textField
{
    // 取消pendding的动画
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    NSValue* textFieldValue = [NSValue valueWithNonretainedObject:textField];
    NSValue* wrapperValue = [_dict objectForKey:textFieldValue];
    TextFieldWrapper* wrapper = [wrapperValue nonretainedObjectValue];
    
    UIView* window = [UIApplication sharedApplication].keyWindow;
    CGFloat y = CGRectGetMaxY([wrapper.visibleView convertRect:wrapper.visibleView.bounds toView:window]);
    CGFloat keyBoardY = (SCREEN_HEIGHT - KeyBoardHeight) - 5.f;
    if (keyBoardY < y) {
        wrapper.animationTarget = keyBoardY - y + wrapper.parentView.frame.origin.y;
        [self performSelector:@selector(cb_performAnimation:) withObject:wrapper afterDelay:0];
    }
}

- (void)cb_textFieldDidEndEditing:(UITextField *)textField
{
    NSValue* textFieldValue = [NSValue valueWithNonretainedObject:textField];
    NSValue* wrapperValue = [_dict objectForKey:textFieldValue];
    TextFieldWrapper* wrapper = [wrapperValue nonretainedObjectValue];
    wrapper.animationTarget = wrapper.parentPosOriginal;
    [self performSelector:@selector(cb_performAnimation:) withObject:wrapper afterDelay:0];
}

- (void)textFieldWrapperWillDealloced:(TextFieldWrapper *)wrapper
{
    [_dict removeObjectForKey:wrapper.textFieldValue];
}

@end
