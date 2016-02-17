//
//  ViewController.m
//  NHFMDBPro
//
//  Created by hu jiaju on 15/9/9.
//  Copyright (c) 2015年 hu jiaju. All rights reserved.
//

#import "ViewController.h"
#import "NHFMDBEngine.h"
#import "NHDBEngine.h"

@interface ViewController ()

@property (nonatomic, assign) NSInteger step;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //线程不安全
    [NHFMDBEngine share];
    
    //线程安全并且数据库加密
    [NHDBEngine share];
    
    CGRect bounds = CGRectMake(100, 100, 100, 50);
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = bounds;
    [btn setTitle:@"insert" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(insertAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    bounds.origin.y += 100;
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = bounds;
    [btn setTitle:@"delete" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(deleteAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    bounds.origin.y += 100;
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = bounds;
    [btn setTitle:@"update" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(updateAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    bounds.origin.y += 100;
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = bounds;
    [btn setTitle:@"query" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(queryAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    self.step = arc4random()%500;
}

- (void)insertAction {
    NSString *n_id = [NSString stringWithFormat:@"%zd",self.step++];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:n_id,@"infoid",@"something that test !",@"info",@"2016-02-17 13:03:03",@"time", nil];
    [[NHDBEngine share] saveInfo:info];
}

- (void)deleteAction {
    NSDictionary *info = [[NHDBEngine share] getInfo];
    [[NHDBEngine share] deleteInfo:info];
}

- (void)updateAction {
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:@"213",@"infoid",@"something that test !",@"info",@"2016-02-18 13:03:03",@"time", nil];
    [[NHDBEngine share] updateInfo:info];
}

- (void)queryAction {
    NSArray *array = [[NHDBEngine share] getInfos];
    NSLog(@"counts : %zd",[array count]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
