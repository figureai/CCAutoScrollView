//
//  autoScrollView.m
//  DsdApp
//
//  Created by Admin on 2019/1/30.
//  Copyright © 2019年 dasudian. All rights reserved.
//

#import "CCAutoScrollView.h"

@interface MiddleTimer: NSObject

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, weak) NSTimer *timer;

@end

@implementation MiddleTimer

- (void)timerTargetAction:(NSTimer *)timer
{
    if (self.target) {
        //该方法会在RunLoop为DefaultMode时才会调用，与timer的CommonMode冲突
        //[self.target performSelector:self.selector withObject:timer afterDelay:0.0];
        
        //该方法可以正常在CommonMode中调用，但是会报警告
        //[self.target performSelector:self.selector withObject:timer];
        
        //最终方法
        IMP imp = [self.target methodForSelector:self.selector];
        void (*func)(id, SEL, NSTimer*) = (void *)imp;
        func(self.target, self.selector, timer);
    } else {
        [self.timer invalidate];
        self.timer = nil;
    }
}

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo
{
    MiddleTimer *timerTarget = [MiddleTimer new];
    timerTarget.target = aTarget;
    timerTarget.selector = aSelector;
    NSTimer *timer = [NSTimer timerWithTimeInterval:ti target:timerTarget selector:@selector(timerTargetAction:) userInfo:userInfo repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    timerTarget.timer = timer;
    return timerTarget.timer;
}

@end



@interface CCAutoScrollView()<UIScrollViewDelegate>

{
    NSInteger _leftIndex;
    NSInteger _currentIndex;
    NSInteger _rightIndex;
}

/**  */
@property(nonatomic) UIScrollView *scrollV;

/** 当前下标 */
@property(nonatomic) NSInteger indexCount;
/**  */
@property(nonatomic) UIView *leftView;
/**  */
@property(nonatomic) UIView *currentView;
/**  */
@property(nonatomic) UIView *rightView;
/** 用来缓存cell的数组 */
@property(nonatomic) NSMutableDictionary *cacheViews;
/**  */
@property(nonatomic) NSMutableDictionary<NSNumber *, UIView *> *indicators;

/**  */
@property(nonatomic) UIView *indicatorContent;

/** 标记指示器的下标 */
@property(nonatomic) NSInteger prevIndex;

/**  */
@property(nonatomic, weak) NSTimer *timer;
@end

@implementation CCAutoScrollView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#pragma mark - interface
- (UIView *)cacheContentViewForIndex:(NSInteger)index {
    if (index == _leftIndex) {
        return self.cacheViews[@(0)];
    } else if (index == _currentIndex) {
        return self.cacheViews[@(1)];
    } else if (index == _rightIndex) {
        return self.cacheViews[@(2)];
    } else {
        return nil;
    }
}

- (UIView *)cacheIndicatorForIndex:(NSInteger)index {
    if (self.indicators[@(index)]) {
        return self.indicators[@(index)];
    }
    return nil;
}


#pragma mark - setter getter
- (void)setDataSource:(NSMutableArray *)dataSource {
    _dataSource = dataSource;
    // 初始化指示器
    UIView *indicatorV = [UIView new];
    __weak typeof(self)weakSelf = self;
    __block CGSize indicatorSize;
    [_dataSource enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView *indicator;
        if ([self.delegate respondsToSelector:@selector(autoScrollView:indicatorAtIndex:isFocus:)]) {
            indicator = [self.delegate autoScrollView:self indicatorAtIndex:idx isFocus:idx == 0];
            CGFloat indicatorX = (indicator.frame.size.width + weakSelf.indicatorSpacing) * (CGFloat)idx;
            indicator.frame = CGRectMake(indicatorX, 0, indicator.frame.size.width, indicator.frame.size.height);
            [indicatorV addSubview:indicator];
            // 缓存指示器
            weakSelf.indicators[@(idx)] = indicator;
            indicatorSize = indicator.frame.size;
        }
    }];
    indicatorV.frame = CGRectMake(0, 0, (indicatorSize.width + _indicatorSpacing) * dataSource.count, indicatorSize.height);
    if ([_delegate respondsToSelector:@selector(autoScrollView:pointForIndicatorView:)]) {
        CGPoint point = [_delegate autoScrollView:self pointForIndicatorView:indicatorV];
        indicatorV.frame = CGRectMake(point.x, point.y, indicatorV.frame.size.width, indicatorV.frame.size.height);
    }
    
    self.indicatorContent = indicatorV;
    [self addSubview:indicatorV];
    if ([self.delegate respondsToSelector:@selector(autoScrollView:contentViewAtIndex:)]) {
        // 从外部获取视图
        self.leftView = [self.delegate autoScrollView:self contentViewAtIndex:_dataSource.count - 1];
        self.leftView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        [self.scrollV addSubview:self.leftView];
        
        self.currentView = [self.delegate autoScrollView:self contentViewAtIndex:0];
        self.currentView.frame = CGRectMake(self.frame.size.width, 0, self.frame.size.width, self.frame.size.height);
        [self.scrollV addSubview: self.currentView];
        
        self.rightView = [self.delegate autoScrollView:self contentViewAtIndex:1];
        self.rightView.frame = CGRectMake(self.frame.size.width * 2, 0, self.frame.size.width, self.frame.size.height);
        [self.scrollV addSubview:self.rightView];
        
        // 缓存视图
        self.cacheViews[@(0)] = self.leftView;
        self.cacheViews[@(1)] = self.currentView;
        self.cacheViews[@(2)] = self.rightView;
    }
    [self.scrollV setContentOffset:CGPointMake(self.frame.size.width, 0)];
    [self createTimer];
}


- (void)setIndexCount:(NSInteger)indexCount {
    _indexCount = indexCount;
    NSInteger index = (_indexCount ) % _dataSource.count;
    // 更新指示器
    if ([_delegate respondsToSelector:@selector(autoScrollView:indicatorAtIndex:isFocus:)]) {
        // 恢复上一个指示器的样式
        CGRect lastRect = _indicators[@(_prevIndex)].frame;
        UIView *lastIndicator = [_delegate autoScrollView:self indicatorAtIndex:_prevIndex isFocus:NO];
        lastIndicator.frame = lastRect;
        _indicators[@(_prevIndex)] = lastIndicator;
        // 设置当前指示器的样式
        CGRect prevRect = _indicators[@(index)].frame;
        UIView *currentIndicator = [_delegate autoScrollView:self indicatorAtIndex:index isFocus:YES];
        currentIndicator.frame = prevRect;
        _indicators[@(index)] = currentIndicator;
        _prevIndex = index;
    }
   // 更新视图
    _leftIndex = (index + _dataSource.count - 1) % _dataSource.count;
    _currentIndex = (index + _dataSource.count) % _dataSource.count;
    _rightIndex = (index + _dataSource.count + 1) % _dataSource.count;
    if ([_delegate respondsToSelector:@selector(autoScrollView:contentViewAtIndex:)]) {
        [_delegate autoScrollView:self contentViewAtIndex:_leftIndex];
        [_delegate autoScrollView:self contentViewAtIndex:_currentIndex];
        [_delegate autoScrollView:self contentViewAtIndex:_rightIndex];
    }
    [self.scrollV setContentOffset:CGPointMake(self.frame.size.width, 0)];
}

- (UIScrollView *)scrollV {
    if (!_scrollV) {
        _scrollV = [UIScrollView new];
        _scrollV.delegate = self;
        _scrollV.pagingEnabled = YES;
        _scrollV.bounces = NO;
        _scrollV.showsVerticalScrollIndicator = NO;
        _scrollV.showsHorizontalScrollIndicator = NO;
        _scrollV.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        _scrollV.contentSize = CGSizeMake(self.frame.size.width * 3, self.frame.size.height);
    }
    return _scrollV;
}

- (NSMutableDictionary *)cacheViews {
    if (!_cacheViews) {
        _cacheViews = [NSMutableDictionary new];
    }
    return _cacheViews;
}

- (NSMutableDictionary<NSNumber *,UIView *> *)indicators {
    if (!_indicators) {
        _indicators = [NSMutableDictionary new];
    }
    return _indicators;
}


#pragma mark - life cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.scrollV];
        self.indicatorSpacing = 10;
        self.intervalTime = 2;
    }
    return self;
}

- (void)dealloc {
    [self removeTimer];
}

#pragma mark - 定时器
- (void)createTimer {
    self.timer = [MiddleTimer timerWithTimeInterval:_intervalTime target:self selector:@selector(addIndex) userInfo:nil];
}

- (void)removeTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)addIndex {
    [self.scrollV setContentOffset:CGPointMake(self.frame.size.width * 2, 0) animated:YES];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // 开始滑动，取消定时器
    [self removeTimer];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if(scrollView.contentOffset.x > self.frame.size.width) {
        self.indexCount += 1;
    }
    if (scrollView.contentOffset.x < self.frame.size.width) {
        self.indexCount -= 1;
    }
//     开启定时器
    [self createTimer];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.indexCount += 1;
}



@end
