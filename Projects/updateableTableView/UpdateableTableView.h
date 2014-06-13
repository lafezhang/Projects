//
//  UpdateableTableView.h
//  CBWallet4iPhone
//
//  Created by zhangxiaodong on 14-4-12.
//  Copyright (c) 2014年 hanhui. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 * IMPORTANT:
   此tableView具有如下功能：上拉加载更多（networkDelegate)、下拉刷新、提供空白cell。
   你应该注意的是在设置delegate和datasource时，原delegate和datasource的某些selector会被挂钩子，具体实现方式见m文件。
 */

@class UpdateableTableView;
@protocol NetworkRequestDelegate <NSObject>

@required
// 下拉刷新的回调
- (void)updateableTableViewRequestUpdate:(UpdateableTableView*)tableView;
// 上拉加载更多的回调
- (void)updateableTableViewRequestMore:(UpdateableTableView*)tableView;
@end

@interface UpdateableTableView : UITableView

@property (nonatomic, weak) id<NetworkRequestDelegate> networkDelegate;

// 停止更新，结束动画
- (void)endUpdateAnimation;

@end
