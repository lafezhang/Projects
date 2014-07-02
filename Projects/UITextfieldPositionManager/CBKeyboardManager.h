//
//  CBKeyboardManager.h
//  CBWallet4iPhone
//
//  Created by zhangxiaodong on 14-7-1.
//  Copyright (c) 2014年 hanhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBScrollView.h"

@interface CBKeyboardManager : NSObject

+ (CBKeyboardManager*)sharedManager;

/**
 *  此函数在自动布局下使用，完成以下功能：
 *  1.将一系列输入框进行组合，组合的结果是给键盘添加一个toolbar，点击toolbar上的“向前、
 向后”按钮时，会将焦点移到相应的输入框中。
 2.当一个输入框获取焦点时，与其相组合的前后输入框都是可见。
 3.设置键盘的回车按钮，除最后一个输入框外，其他输入框的回车按钮都是“next”，最后一个输入
 框为“done”，
 4.用户输入done之后，会触发按钮的touchUpInside事件
 5.由于在自动布局情况下，不能直接操作frame，因此无法像上面函数那样通过上移parantView
 来使某个输入框可见。本方法可以传入一个作为parentView的scrollView，通过配合使用
 scroll功能和contentInset可以达到上述目的
 *
 *  @param textFieldArray           输入框数组
 *  @param commitButton             提交按钮，可以为nil
 *  @param parentUIViewOrScrollView parentView
 */
- (void)combineTextFields:(NSArray*)textFieldArray withCommitButton:(UIButton*)commitButton parentScrollView:(CBScrollView*)parentScrollView;

/**
 *  将焦点移到下一个控件。下一个控件一般是另一个输入框，如果你在combine方法中指定了
    了一个commitButton，那么最后一个输入框的下一个控件将是这个按钮，该方法会触发
    按钮的点击事件。
    你应该在UITextFeildDelegate的回车按钮回调中，调用这个方法
 *
 *  @param textField 
 */
- (void)focusNextComponet:(UITextField*)textField;

@end
