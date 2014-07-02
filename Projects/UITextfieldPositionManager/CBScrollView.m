//
//  CBScrollView.m
//  CBWallet4iPhone
//
//  Created by zhangxiaodong on 14-7-2.
//  Copyright (c) 2014年 hanhui. All rights reserved.
//

#import "CBScrollView.h"

@implementation CBScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
    if (self.temporarilyDisableAutoScroll) {
        return;
    }
    
    [super setContentOffset:contentOffset animated:animated];
}


@end
