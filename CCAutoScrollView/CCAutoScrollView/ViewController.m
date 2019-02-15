//
//  ViewController.m
//  CCAutoScrollView
//
//  Created by Admin on 2019/2/14.
//  Copyright © 2019年 Admin. All rights reserved.
//

#import "ViewController.h"

#import "CCAutoScrollView.h"

@interface ViewController ()<CCAutoScrollViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CCAutoScrollView *autoScrollV = [[CCAutoScrollView alloc] initWithFrame:CGRectMake(0, 200, [UIScreen mainScreen].bounds.size.width, 200)];
    autoScrollV.backgroundColor = [UIColor blackColor];
    autoScrollV.delegate = self;
    autoScrollV.intervalTime = 2;
    [self.view addSubview:autoScrollV];
    autoScrollV.dataSource = @[[UIColor blueColor], [UIColor redColor], [UIColor yellowColor], [UIColor greenColor], [UIColor orangeColor]];
}

- (UIView *)autoScrollView:(CCAutoScrollView *)autoScrollView contentViewAtIndex:(NSInteger)index {
    UIView *contentV = [autoScrollView cacheContentViewForIndex:index];
    UILabel *label = [UILabel new];
    if (!contentV) {
        contentV = [UIView new];
        label.textColor = [UIColor blackColor];
        label.frame = CGRectMake(100, 100, 100, 100);
        [contentV addSubview:label];
    }
    label.text = [NSString stringWithFormat:@"lch---%ld", index];
    NSArray *colors = @[[UIColor blueColor], [UIColor redColor], [UIColor yellowColor], [UIColor greenColor], [UIColor orangeColor]];
    contentV.backgroundColor = colors[index];
    return contentV;
}




@end
