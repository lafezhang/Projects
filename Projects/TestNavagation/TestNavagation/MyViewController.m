//
//  MyViewController.m
//  TestNavagation
//
//  Created by zhangxiaodong on 14-6-13.
//  Copyright (c) 2014年 zhangxiaodong. All rights reserved.
//

#import "MyViewController.h"
#import "UIViewController+Process.h"

@interface MyViewController ()
@property (weak, nonatomic) IBOutlet UITextField *pidInput;


@end

@implementation MyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.view = self.view;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)setStep:(NSInteger)step
{
    _step = step;
    _stepLabel.text = [NSString stringWithFormat:@"%d", step];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)newProcess:(id)sender {
    NSString* pid = self.pidInput.text;
    if (pid.length > 0) {
        MyViewController* controller = [[MyViewController alloc] initWithNibName:nil bundle:nil];
        controller.infoLabel.text = pid;
        controller.step = 1;
        [controller markAsProcessStartWithIdentifier:pid];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (IBAction)backToPrev:(id)sender {
    [self popToPreviouseProcess];
}

- (IBAction)continueProcess:(id)sender {
    MyViewController* controller = [[MyViewController alloc] initWithNibName:nil bundle:nil];
    controller.infoLabel.text = self.infoLabel.text;
    controller.step = self.step + 1;
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)end:(id)sender {
    NSString* pid = self.pidInput.text;
    if (pid.length > 0) {
        [self markAsProcessEndWithIdentifier:pid];
        
        MyViewController* controller = [[MyViewController alloc] initWithNibName:nil bundle:nil];
        controller.step = 1;
        controller.infoLabel.text = [controller markAsProcessStart];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (IBAction)backToProcess:(id)sender {
    NSString* pid = self.pidInput.text;
    if (pid.length > 0) {
        [self popToProcess:pid];
    }
}
- (IBAction)endCurrent:(id)sender {
    [self markAsProcessEnd];
    MyViewController* controller = [[MyViewController alloc] initWithNibName:nil bundle:nil];
    controller.infoLabel.text = [controller markAsProcessStart];
    controller.step = 1;
    [self.navigationController pushViewController:controller animated:YES];
}
@end
