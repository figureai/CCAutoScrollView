//
//  autoScrollView.h
//  DsdApp
//
//  Created by Admin on 2019/1/30.
//  Copyright © 2019年 dasudian. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CCAutoScrollView;
NS_ASSUME_NONNULL_BEGIN

@protocol CCAutoScrollViewDelegate <NSObject>

@required
// 轮播内容
- (UIView *)autoScrollView:(CCAutoScrollView *)autoScrollView contentViewAtIndex:(NSInteger)index;

@optional
// 指示器
- (UIView *)autoScrollView:(CCAutoScrollView *)autoScrollView indicatorAtIndex:(NSInteger)index isFocus:(BOOL)isFocus;
// 指示器的位置
- (CGPoint)autoScrollView:(CCAutoScrollView *)autoScrollView pointForIndicatorView:(UIView *)indicatorView;

@end

@interface CCAutoScrollView : UIView

/** 数据源 */
@property(nonatomic) NSArray *dataSource;

/**  */
@property(nonatomic, weak) id <CCAutoScrollViewDelegate> delegate;

/** 用于获取缓存的轮播内容视图 */
- (UIView *)cacheContentViewForIndex:(NSInteger)index;

/** 用于获取缓存的指示器 */
- (UIView *)cacheIndicatorForIndex:(NSInteger)index;

/** 指示器间隔 默认10*/
@property(nonatomic) CGFloat indicatorSpacing;

/** 轮播时间 默认2秒*/
@property(nonatomic) NSTimeInterval intervalTime;

@end

NS_ASSUME_NONNULL_END
