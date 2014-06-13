//
//  ViewController.m
//  TestNavagation
//
//  Created by zhangxiaodong on 14-6-13.
//  Copyright (c) 2014年 zhangxiaodong. All rights reserved.
//

#import "ViewController.h"
#import "MyViewController.h"
#import "UIViewController+Process.h"
@interface ViewController ()

@property (nonatomic, weak) id obj;

@end

@implementation ViewController
- (IBAction)start:(id)sender {
    MyViewController *controller = [[MyViewController alloc] initWithNibName:nil bundle:nil];
    controller.infoLabel.text = @"start";
    [controller markAsProcessStartWithIdentifier:@"start"];
    controller.step = 1;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSObject* obj1 = [[NSObject alloc] init];
    self.obj = obj1;
}

- (void)setObj:(id)obj
{
    _obj = obj;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
