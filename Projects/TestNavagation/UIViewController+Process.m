//
//  UIViewController+Process.m
//  TestNavagation
//
//  Created by zhangxiaodong on 14-6-13.
//  Copyright (c) 2014年 zhangxiaodong. All rights reserved.
//

#import "UIViewController+Process.h"
#import <objc/runtime.h>

@class MyNavigationDelegate;
@interface MyNavigationDelegate : NSObject<UINavigationControllerDelegate>
@property (nonatomic, weak) id oldDelegate;
@end

@implementation MyNavigationDelegate
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    navigationController.delegate = self.oldDelegate;
    NSInteger prevIndex = navigationController.viewControllers.count - 2;
    UIViewController* prev = [navigationController.viewControllers objectAtIndex:prevIndex];
    NSString* closeIdentifier = [prev closeIdentifier];
    UIViewController* start = [viewController startControllerOfProcess:closeIdentifier];
    NSInteger startIndex = [navigationController.viewControllers indexOfObject:start];
    NSMutableArray* newViewControllers = [NSMutableArray arrayWithArray:navigationController.viewControllers];
    [newViewControllers removeObjectsInRange:NSMakeRange(startIndex, prevIndex - startIndex + 1)];
    [navigationController setViewControllers:newViewControllers animated:NO];
}

@end

#define declere_property(type, name, setMethod, key) \
- (type)name \
{ \
   id ret = objc_getAssociatedObject(self, (void*)key); \
   return ret; \
} \
- (void)setMethod:(type)value \
{ \
   objc_setAssociatedObject(self, (void*)key, value, OBJC_ASSOCIATION_RETAIN); \
}
    

@implementation UIViewController (Process)

declere_property(NSString*, processIdentifier, setProcessIdentifier, 0)
declere_property(NSString*, closeIdentifier, setCloseIdentifier, 1)

// retain is ok.
declere_property(MyNavigationDelegate*, newDelegate, setNewDelegate, 2)

- (NSString*)markAsProcessStart
{
    NSString* uuid = [[NSUUID UUID] UUIDString];
    [self markAsProcessStartWithIdentifier:uuid];
    return uuid;
}

- (void)markAsProcessEnd
{
    NSEnumerator* enumerator = [self.navigationController.viewControllers reverseObjectEnumerator];
    UIViewController* obj;
    NSString* processID;
    while ((obj = enumerator.nextObject)) {
        if ([obj processIdentifier]) {
            processID = [obj processIdentifier];
            break;
        }
    }
    
    if (processID) {
        [self markAsProcessEndWithIdentifier:processID];
    }
}

- (void)markAsProcessStartWithIdentifier:(NSString *)processIdentifier
{
    self.processIdentifier = processIdentifier;
}

- (void)markAsProcessEndWithIdentifier:(NSString *)processIdentifier
{
    [self setCloseIdentifier:processIdentifier];
    MyNavigationDelegate* delegate = [[MyNavigationDelegate alloc] init];
    delegate.oldDelegate = self.navigationController.delegate;
    self.navigationController.delegate = delegate;
    [self setNewDelegate:delegate];
}

- (UIViewController*)startControllerOfProcess:(NSString*)processIdentifier
{
    NSEnumerator* enumerator = [self.navigationController.viewControllers reverseObjectEnumerator];
    UIViewController* controller;
    while ((controller = enumerator.nextObject)) {
        if ([[controller processIdentifier] isEqualToString:processIdentifier]) {
            return controller;
        }
    }
    return nil;
}

- (void)popToProcess:(NSString *)processIdentifier
{
    if (!processIdentifier) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    // 先找到processIdentifier的下一个process，找到的controller
    // 的前一个controller就是我们需要的那个
    UIViewController* vcForNextProcessIdentifier;
    UIViewController* currentVC;
    NSEnumerator* enumerator;
    enumerator = [self.navigationController.viewControllers reverseObjectEnumerator];
    while ((currentVC = enumerator.nextObject)) {
        NSString* processID = [currentVC processIdentifier];
        if ([processID isEqualToString:processIdentifier]) {
            break;
        }
        else if (processID) {
            vcForNextProcessIdentifier = currentVC;
        }
    }
    
    NSAssert(currentVC != nil, @"can not fount that process");
    [self popToViewControllerInclude:vcForNextProcessIdentifier];
}

- (void)popToViewControllerInclude:(UIViewController*)controller
{
    if (controller) {
        NSInteger index = [self.navigationController.viewControllers indexOfObject:controller];
        NSAssert(index >= 1, @"");
        UIViewController* target = [self.navigationController.viewControllers objectAtIndex:index - 1];
        [self.navigationController popToViewController:target animated:YES];
    }
    else {
    }
}

- (void)popToPreviouseProcess
{
    // 先找到当前controller所在的process
    UIViewController* startController;
    UIViewController* currentVC;
    NSEnumerator* enumerator;
    enumerator = [self.navigationController.viewControllers reverseObjectEnumerator];
    while ((currentVC = enumerator.nextObject)) {
        NSString* processID = [currentVC processIdentifier];
        if(processID) {
            startController = currentVC;
            break;
        }
    }
    
    [self popToViewControllerInclude:startController];
}

@end
