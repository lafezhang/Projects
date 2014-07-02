//
//  CBKeyboardManager.m
//  CBWallet4iPhone
//
//  Created by zhangxiaodong on 14-7-1.
//  Copyright (c) 2014年 hanhui. All rights reserved.
//

#import "CBKeyboardManager.h"
#import "CBPayUtils.h"
#import <objc/runtime.h>

const static CGFloat standardSpace = 18.f;

@interface UIView (findFirstResponder)

@end
@implementation UIView (findFirstResponder)

- (UIView*)findFirstResponder
{
    if ([self isFirstResponder])
        return self;
    
    for (UIView * subView in self.subviews)
    {
        UIView * fr = [subView findFirstResponder];
        if (fr != nil)
            return fr;
    }
    
    return nil;
}

@end

UIView* findFirstResponder()
{
    UIWindow* window = [[UIApplication sharedApplication] keyWindow];
    return [window findFirstResponder];
}

#define declere_property(type, name, setMethod, key, retainType) \
- (type)name \
{ \
id ret = objc_getAssociatedObject(self, (void*)key); \
return ret; \
} \
- (void)setMethod:(type)value \
{ \
objc_setAssociatedObject(self, (void*)key, value, retainType); \
}

@interface UITextField(KeyboardManager)

@end

@implementation UITextField(KeyboardManager)

declere_property(UITextField*, prevTextField, setPreveTextField, 0, OBJC_ASSOCIATION_ASSIGN)

declere_property(UIView*, nextTextField, setNextTextField, 1, OBJC_ASSOCIATION_ASSIGN)

declere_property(CBScrollView*, parentScrollView, setParentScrollView, 2, OBJC_ASSOCIATION_ASSIGN)

@end

@interface CBScrollView (KeyboardManager)

@end
@implementation CBScrollView (KeyboardManager)

declere_property(NSValue*, oldContentInset, setOldContentInset, 0, OBJC_ASSOCIATION_RETAIN)
declere_property(NSDictionary*, keyboardInfo, setKeyboardInfo, 1, OBJC_ASSOCIATION_RETAIN)
declere_property(NSNumber*, keyboardHeightInScrollView, setKeyboardHeightInScrollView, 2, OBJC_ASSOCIATION_RETAIN)

@end

@interface CBKeyboardManager ()
{
    BOOL _keyboardShown;
}
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *prevButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;

@end

@implementation CBKeyboardManager

+ (CBKeyboardManager*)sharedManager
{
    static CBKeyboardManager* manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CBKeyboardManager alloc] init];
    });
    return manager;
}

- (id)init
{
    if (self = [super init]) {
        // will never remove observer
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cb_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cb_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        _toolbar = [[[NSBundle mainBundle] loadNibNamed:@"KeyboardToolbar" owner:self options:nil] objectAtIndex:0];
        
    }
    return self;
}

- (void)combineTextFields:(NSArray *)textFieldArray withCommitButton:(UIButton *)commitButton parentScrollView:(CBScrollView *)parentScrollView
{
    NSAssert(!CBPayUtils.IsBlankArray(textFieldArray), @"你为什么要传入一个空数组？？");
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cb_onTapGesture:)];
    tapGesture.cancelsTouchesInView = NO;
    [parentScrollView addGestureRecognizer:tapGesture];
    
    __block UITextField* prev = nil;
    [textFieldArray enumerateObjectsUsingBlock:^(UITextField* obj, NSUInteger idx, BOOL *stop) {
        obj.returnKeyType = UIReturnKeyNext;
        if (prev) {
            [prev setNextTextField:obj];
            [obj setPreveTextField:prev];
        }
        prev = obj;
        [obj setParentScrollView:parentScrollView];
        [obj addTarget:self action:@selector(cb_textFieldDidBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
        [obj setInputAccessoryView:_toolbar];
    }];
    
    if (textFieldArray.count == 1) {
        [prev setInputAccessoryView:nil];
    }
    
    if (commitButton) {
        [prev setNextTextField:commitButton];
    }
    
    ((UITextField*)[textFieldArray lastObject]).returnKeyType = UIReturnKeyDone;
}

- (void)focusNextComponet:(UITextField *)textField
{
    UIView* next = [textField nextTextField];
    if ([next isKindOfClass:[UITextField class]]) {
        [self onNext:textField];
    }
    else if ([next isKindOfClass:[UIButton class]]) {
        [(UIButton*)next sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    else if (!next) {
        [textField resignFirstResponder];
    }

}

#pragma mark - Private
- (void)cb_onTapGesture:(UIGestureRecognizer*)gesture
{
    UIView* view = gesture.view;
    [view endEditing:YES];
}

- (void)cb_keyboardWillShow:(NSNotification*)notification
{
    _keyboardShown = YES;
    UITextField* textField = (UITextField*)findFirstResponder();
    CBScrollView* parentScrollView = [textField parentScrollView];
    if (parentScrollView) {
        [parentScrollView setOldContentInset:[NSValue valueWithUIEdgeInsets:parentScrollView.contentInset]];
        [parentScrollView setKeyboardInfo:notification.userInfo];
    }
    
    // 获得链表中最后一个元素的MaxY，如果最后一个元素是commitButton，
    // 则获取该Button的MaxY，如果最后一个元素是输入框，则获取该输入框
    // 的MaxY。获取该MaxY的目的是保证其总是在键盘上沿。
    CGFloat maxY = 0;
    UITextField* nextTextField = textField;
    do {
        CGRect textRectInScroll = [parentScrollView convertRect:nextTextField.bounds fromView:nextTextField];
        maxY = CGRectGetMaxY(textRectInScroll) + standardSpace;
        if (![nextTextField isKindOfClass:[UITextField class]]) {
            break;
        }
        nextTextField = (UITextField*)[nextTextField nextTextField];
    } while (nextTextField);
    
    UIEdgeInsets currentInset = parentScrollView.contentInset;
    CGFloat realContentHeight = parentScrollView.contentSize.height + currentInset.bottom;
    CGRect keyboardRect = [parentScrollView convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    CGFloat keyboardTop = keyboardRect.origin.y + realContentHeight - CGRectGetHeight(parentScrollView.frame) - parentScrollView.contentOffset.y;
    [parentScrollView setKeyboardHeightInScrollView:@(keyboardRect.origin.y - parentScrollView.contentOffset.y)];
    if (keyboardTop < maxY) {
        currentInset.bottom = realContentHeight - keyboardTop;
        
        /**
         *  这个动画块一定要这么写，要不然会有很奇怪的事情发生，原因不详
         */
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationCurve:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
        [UIView setAnimationDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
        parentScrollView.contentInset = currentInset;
        [self cb_scrollToTextFeild:textField scrollView:parentScrollView animated:NO];
        [UIView commitAnimations];
    }
    else {
        [self cb_scrollToTextFeild:textField scrollView:parentScrollView animated:YES];
    }
}

- (void)cb_keyboardWillHide:(NSNotification*)notification
{
    _keyboardShown = NO;
    UITextField* textField = (UITextField*)findFirstResponder();
    CBScrollView* parentScrollView = [textField parentScrollView];
    NSValue* oldValue = [parentScrollView oldContentInset];
    if (oldValue) {
        UIEdgeInsets oldInsets = [oldValue UIEdgeInsetsValue];
        if (!UIEdgeInsetsEqualToEdgeInsets(oldInsets, parentScrollView.contentInset)) {
            [UIView animateWithDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue] animations:^{
                parentScrollView.contentInset = [oldValue UIEdgeInsetsValue];
            }];
        }
    }
}

- (void)cb_textFieldDidBeginEditing:(UITextField*)sender
{
    if (!_keyboardShown) {
        return;
    }
    
    _prevButton.enabled = [sender prevTextField] != nil;
    _nextButton.enabled = [sender nextTextField] != nil && [[sender nextTextField] isKindOfClass:[UITextField class]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self cb_scrollToTextFeild:sender scrollView:[sender parentScrollView] animated:YES];
    });
}

- (void)cb_scrollToTextFeild:(UITextField*)textField scrollView:(CBScrollView*)scrollView animated:(BOOL)animated
{
    if (!scrollView) {
        return;
    }
    // 保证前一个和后一个textfield都可见，
    UIView* prev = [textField prevTextField];
    UIView* next = [textField nextTextField];
    
    CGFloat top = CGRectGetMinY([scrollView convertRect:textField.bounds fromView:textField]) - standardSpace;
    CGFloat bottom = CGRectGetMaxY([scrollView convertRect:textField.bounds fromView:textField]) + standardSpace;
    if (prev) {
        top = CGRectGetMinY([scrollView convertRect:prev.bounds fromView:prev]) - standardSpace;
    }
    
    if (next) {
        bottom = CGRectGetMaxY([scrollView convertRect:next.bounds fromView:next]) + standardSpace;
    }
    
    top = MAX(top, 0);
    
    CGFloat keyboardHeightOutScroll = [[scrollView keyboardHeightInScrollView] floatValue];
    keyboardHeightOutScroll = MIN(keyboardHeightOutScroll, CGRectGetHeight(scrollView.frame));
    CGPoint targetContentOffset = scrollView.contentOffset;
    if (top < scrollView.contentOffset.y) {
        targetContentOffset = CGPointMake(0, top);
    }
    else if (bottom > scrollView.contentOffset.y + keyboardHeightOutScroll){
        targetContentOffset = CGPointMake(0, bottom - keyboardHeightOutScroll);
    }
    
    [scrollView setContentOffset:targetContentOffset animated:animated];
}

- (IBAction)onPrev:(id)sender {
    UITextField* textField = (UITextField*)findFirstResponder();
    UITextField* prev = [textField prevTextField];
    CBScrollView* parentScrollView = [textField parentScrollView];
    parentScrollView.temporarilyDisableAutoScroll = YES;
    [prev becomeFirstResponder];
    parentScrollView.temporarilyDisableAutoScroll = NO;
    [self cb_textFieldDidBeginEditing:prev];
}
- (IBAction)onNext:(id)sender {
    UITextField* textField = (UITextField*)findFirstResponder();
    UIView* next = [textField nextTextField];
    CBScrollView* parentScrollView = [textField parentScrollView];
    parentScrollView.temporarilyDisableAutoScroll = YES;
    [next becomeFirstResponder];
    parentScrollView.temporarilyDisableAutoScroll = NO;
    [self cb_textFieldDidBeginEditing:(UITextField*)next];
}

@end
