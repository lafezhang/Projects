//
//  UpdateableTableView.m
//  CBWallet4iPhone
//
//  Created by zhangxiaodong on 14-4-12.
//  Copyright (c) 2014年 hanhui. All rights reserved.
//

#import "UpdateableTableView.h"
#import <CBRefreshFooterView.h>
#import <CBRefreshHeaderView.h>
#import "UIView+FrameUtils.h"
#import <objc/runtime.h>

/* method type*/
typedef NSInteger(*METHOD_numberOfSection)(id, SEL, UITableView*);
typedef NSInteger(*METHOD_numberOfRows)(id, SEL, UITableView*, NSInteger);
typedef UITableViewCell*(*METHOD_cellForRow)(id, SEL, UITableView*,  NSIndexPath*);
typedef CGFloat(*METHOD_heightForRow)(id, SEL, UITableView*, NSIndexPath*);
typedef CGFloat(*METHOD_heightForHeader)(id, SEL, UITableView*, NSInteger);
typedef UIView*(*METHOD_viewForHeader)(id, SEL, UITableView*, NSInteger);


// 此类保存dataSource原始的函数指针
@interface OriginalDataSourceMethod : NSObject

@property (nonatomic) METHOD_numberOfSection numberOfSectionMethod;
@property (nonatomic) METHOD_numberOfRows numberOfRowsMethod;
@property (nonatomic) METHOD_cellForRow cellForRowMethod;

@end

// 保存delegate原始的函数指针
@interface OriginalDelegateMethod : NSObject

@property (nonatomic) METHOD_heightForRow heightForRowMethod;
@property (nonatomic) METHOD_heightForHeader heightForHeaderMethod;
@property (nonatomic) METHOD_viewForHeader viewForHeaderMethod;

@end

@implementation OriginalDataSourceMethod
@end

@implementation OriginalDelegateMethod
@end


#pragma OriginalInstanceMethodCenter define & implementation
@interface OriginalInstanceMethodCenter : NSObject
{
    NSMutableDictionary* _dataSourceMethods;
    NSMutableDictionary* _delegateMethods;
}

+ (OriginalInstanceMethodCenter*)sharedCenter;

- (void)setOriginalDataSourceMethod:(OriginalDataSourceMethod*)dataSourceMethod forClass:(Class)class;
- (OriginalDataSourceMethod*)getOrignialDataSourceMethodForClass:(Class)class;
- (void)removeOriginalDataSourceMethodForClass:(Class)class;

- (void)setOriginalDelegateMethod:(OriginalDelegateMethod*)delegateMethod forClass:(Class)class;
- (OriginalDelegateMethod*)getOriginalDelegateMethodForClass:(Class)class;
- (void)removeOriginalDelegateMethodForClass:(Class)class;

@end

@implementation OriginalInstanceMethodCenter

- (id)init
{
    if (self = [super init]) {
        _dataSourceMethods = [NSMutableDictionary dictionary];
        _delegateMethods = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (OriginalInstanceMethodCenter*)sharedCenter
{
    static OriginalInstanceMethodCenter* center;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [[OriginalInstanceMethodCenter alloc] init];
    });
    return center;
}

- (void)setOriginalDataSourceMethod:(OriginalDataSourceMethod *)dataSourceMethod forClass:(Class)class
{
    NSString* className = NSStringFromClass(class);
    [_dataSourceMethods setObject:dataSourceMethod forKey:className];
}

- (OriginalDataSourceMethod*)getOrignialDataSourceMethodForClass:(Class)class
{
    NSString* className = NSStringFromClass(class);
    return [_dataSourceMethods objectForKey:className];
}

- (void)removeOriginalDataSourceMethodForClass:(Class)class
{
    NSString* className = NSStringFromClass(class);
    [_dataSourceMethods removeObjectForKey:className];
}

- (void)setOriginalDelegateMethod:(OriginalDelegateMethod *)delegateMethod forClass:(Class)class
{
    NSString* className = NSStringFromClass(class);
    [_delegateMethods setObject:delegateMethod forKey:className];
}

- (OriginalDelegateMethod*)getOriginalDelegateMethodForClass:(Class)class
{
    NSString* className = NSStringFromClass(class);
    return [_delegateMethods objectForKey:className];
}

- (void)removeOriginalDelegateMethodForClass:(Class)class
{
    NSString* className = NSStringFromClass(class);
    [_delegateMethods removeObjectForKey:className];
}

@end


#pragma mark - UpdateableTableView implemetation
@interface UpdateableTableView ()<CBRefreshBaseViewDelegate>
{
    CBRefreshHeaderView* _refreshHeader;
    CBRefreshFooterView* _refreshFooter;
    CBRefreshBaseView* _currentRefreshingView; // 记录当前引起刷新操作的控件
    NSUInteger _isEmptyWhenUpdating; //更新操作前的数据是否为空
    
    NSInteger(*numberOfSectionsMethod)(id,SEL,UITableView*);
}

+ (UITableViewCell*)emptyCell;

- (void)cb_initTableView;
- (void)cb_customInit;

@end

@implementation UpdateableTableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self cb_customInit];
    }
    return self;
}

- (void)cb_customInit
{
    self.autoresizesSubviews = YES;
    [self cb_initTableView];
}

- (void)cb_initTableView
{
    UIView* backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    backgroundView.backgroundColor = [UIColor colorWithHex:@"#f0f0f0"];
    backgroundView.autoresizesSubviews = YES;
    self.backgroundView = backgroundView;
    
    _refreshHeader = [CBRefreshHeaderView header];
    _refreshHeader.scrollView = self;
    _refreshHeader.lastUpdateTime = [NSDate date];
    _refreshHeader.delegate = self;
    
    _refreshFooter = [CBRefreshFooterView footer];
    _refreshFooter.scrollView = self;
    _refreshFooter.delegate = self;
}

+ (UITableViewCell*)emptyCell
{
    static UITableViewCell* _emptyCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"empty"];
        _emptyCell.backgroundColor = [UIColor clearColor];
        _emptyCell.autoresizesSubviews = YES;
        _emptyCell.userInteractionEnabled = NO;
        
        UIImageView* imageView= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"noRecordImage.png"]];
        [_emptyCell addSubview:imageView];
        [imageView frameCenterInParent];
        
        UILabel* label = [UILabel labelWithText:@"暂无记录" font:CB_UIKIT_FONT_LARGE origin:CGPointZero];
        label.textColor = COLOR_TEXT_MINOR;
        UIView* panel = [[UIView alloc] initWithFrame:CGRectZero];
        panel.backgroundColor = [UIColor clearColor];
        panel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [panel frameResizeToWidth:label.width height:imageView.height + 10 + label.height];
        [panel addSubview:imageView];
        [panel addSubview:label];
        
        [imageView frameCenterHorizontallyInParent];
        [label frameCenterHorizontallyInParent];
        [label frameAlignBottomWithParentByDistance:0];
        [_emptyCell addSubview:panel];
        [panel frameCenterInParent];
    });
    return _emptyCell;
}

- (void)setDelegate:(id<UITableViewDelegate>)delegate
{
    [super setDelegate:delegate];
    
    if (delegate && ![[OriginalInstanceMethodCenter sharedCenter] getOriginalDelegateMethodForClass:delegate.class]) {
        OriginalDelegateMethod* delegateMethod = [[OriginalDelegateMethod alloc] init];
        delegateMethod.heightForRowMethod = (METHOD_heightForRow) method_setImplementation(class_getInstanceMethod(delegate.class, @selector(tableView:heightForRowAtIndexPath:)), [self methodForSelector:@selector(tableView:heightForRowAtIndexPath:)]);
        delegateMethod.heightForHeaderMethod = (METHOD_heightForHeader)method_setImplementation(class_getInstanceMethod(delegate.class, @selector(tableView:heightForHeaderInSection:)), [self methodForSelector:@selector(tableView:heightForHeaderInSection:)]);
        delegateMethod.viewForHeaderMethod = (METHOD_viewForHeader)method_setImplementation(class_getInstanceMethod(delegate.class, @selector(tableView:viewForHeaderInSection:)), [self methodForSelector:@selector(tableView:viewForHeaderInSection:)]);
        
        [[OriginalInstanceMethodCenter sharedCenter] setOriginalDelegateMethod:delegateMethod forClass:delegate.class];
        
    }
}

- (void)setDataSource:(id<UITableViewDataSource>)dataSource
{
    [super setDataSource:dataSource];
    
    if (dataSource && ![[OriginalInstanceMethodCenter sharedCenter] getOrignialDataSourceMethodForClass:dataSource.class]) {
        OriginalDataSourceMethod* OriginalMethod = [[OriginalDataSourceMethod alloc] init];
        
        // magic goes here!
        // 挂钩子
        OriginalMethod.numberOfSectionMethod =(METHOD_numberOfSection) method_setImplementation(class_getInstanceMethod(dataSource.class, @selector(numberOfSectionsInTableView:)), [self methodForSelector:@selector(numberOfSectionsInTableView:)]);
        OriginalMethod.numberOfRowsMethod = (METHOD_numberOfRows)method_setImplementation(class_getInstanceMethod(dataSource.class, @selector(tableView:numberOfRowsInSection:)), [self methodForSelector:@selector(tableView:numberOfRowsInSection:)]);
        OriginalMethod.cellForRowMethod = (METHOD_cellForRow)method_setImplementation(class_getInstanceMethod(dataSource.class, @selector(tableView:cellForRowAtIndexPath:)), [self methodForSelector:@selector(tableView:cellForRowAtIndexPath:)]);
        
        [[OriginalInstanceMethodCenter sharedCenter] setOriginalDataSourceMethod:OriginalMethod forClass:dataSource.class];
    }
}

- (void)endUpdateAnimation
{
    
    if (_isEmptyWhenUpdating) {
        [_currentRefreshingView endRefreshing];
    }
    else {
        if (_currentRefreshingView == _refreshFooter) {
            
            CGPoint lastScroll = self.contentOffset;
            UIEdgeInsets lastInset = self.contentInset;
            self.contentInset = UIEdgeInsetsMake(lastInset.top, lastInset.left, 0, lastInset.right);
            [_currentRefreshingView endRefreshing];
            
            if (self.contentSize.height > self.bounds.size.height + lastScroll.y) {
                // 意味着不需要自动下滑
                [self setContentOffset:lastScroll animated:NO];
            }
            else {
                // 自动下滑前，应该先还原状态
                self.contentInset = lastInset;
                self.contentOffset = lastScroll;
                [UIView animateWithDuration:.3f animations:^{
                    self.contentInset = UIEdgeInsetsMake(lastInset.top, lastInset.left, 0, lastInset.right);
                }];
            }
        }
        else {
            [_currentRefreshingView endRefreshing];
        }
    }
    _isEmptyWhenUpdating = NO;
}

#pragma mark - UITableViewDatasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    OriginalDataSourceMethod* OriginalMethod = [[OriginalInstanceMethodCenter sharedCenter] getOrignialDataSourceMethodForClass:self.class];
    NSInteger ret = MAX(1, OriginalMethod.numberOfSectionMethod(self, _cmd, tableView));
    return ret;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    OriginalDataSourceMethod* OriginalMethod = [[OriginalInstanceMethodCenter sharedCenter] getOrignialDataSourceMethodForClass:self.class];
    NSInteger ret = MAX(1, OriginalMethod.numberOfRowsMethod(self, _cmd, tableView, section));
    return ret;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OriginalDataSourceMethod* OriginalMethod = [[OriginalInstanceMethodCenter sharedCenter] getOrignialDataSourceMethodForClass:self.class];
    NSInteger count = OriginalMethod.numberOfSectionMethod(self, @selector(numberOfSectionsInTableView:), tableView);
    if (count == 0) {
        return [UpdateableTableView emptyCell];
    }
    else {
        return OriginalMethod.cellForRowMethod(self, _cmd, tableView, indexPath);
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OriginalDataSourceMethod* OriginalMethod = [[OriginalInstanceMethodCenter sharedCenter] getOrignialDataSourceMethodForClass:self.class];
    NSInteger count = OriginalMethod.numberOfSectionMethod(self, @selector(numberOfSectionsInTableView:), tableView);
    if (count == 0) {
        return tableView.bounds.size.height;
    }
    else {
        OriginalDelegateMethod* originalDelegateMethod = [[OriginalInstanceMethodCenter sharedCenter] getOriginalDelegateMethodForClass:self.class];
        return originalDelegateMethod.heightForRowMethod(self, _cmd, tableView, indexPath);
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    OriginalDataSourceMethod* OriginalMethod = [[OriginalInstanceMethodCenter sharedCenter] getOrignialDataSourceMethodForClass:self.class];
    NSInteger count = OriginalMethod.numberOfSectionMethod(self, @selector(numberOfSectionsInTableView:), tableView);
    if (count == 0) {
        return 0;
    }
    else {
        OriginalDelegateMethod* originalDelegateMethod = [[OriginalInstanceMethodCenter sharedCenter] getOriginalDelegateMethodForClass:self.class];
        return originalDelegateMethod.heightForHeaderMethod(self, _cmd, tableView, section);
    }
    return 0;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OriginalDataSourceMethod* OriginalMethod = [[OriginalInstanceMethodCenter sharedCenter] getOrignialDataSourceMethodForClass:self.class];
    NSInteger count = OriginalMethod.numberOfSectionMethod(self, @selector(numberOfSectionsInTableView:), tableView);
    if (count == 0) {
        return nil;
    }
    else {
        OriginalDelegateMethod* originalDelegateMethod = [[OriginalInstanceMethodCenter sharedCenter] getOriginalDelegateMethodForClass:self.class];
        return originalDelegateMethod.viewForHeaderMethod(self, _cmd, tableView, section);
    }
    return nil;
    
}

#pragma mark - CBRefreshBaseViewDelegate

- (void)refreshViewBeginRefreshing:(CBRefreshBaseView *)refreshView
{
    _currentRefreshingView = refreshView;
    OriginalDataSourceMethod* OriginalMethod = [[OriginalInstanceMethodCenter sharedCenter] getOrignialDataSourceMethodForClass:self.dataSource.class];
    NSInteger count = OriginalMethod.numberOfSectionMethod(self.dataSource, @selector(numberOfSectionsInTableView:), self);
    _isEmptyWhenUpdating = count == 0;
    
    if (_currentRefreshingView == _refreshFooter) {
        [self.networkDelegate updateableTableViewRequestMore:self];
    }
    else {
        [self.networkDelegate updateableTableViewRequestUpdate:self];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
