//
//  KLIMLabelingBlock.m
//  KLib Image
//
//  Created by KO on 13/10/14.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import "KLIMLabelingBlock.h"

@implementation KLIMLabelingBlock
{
    // 全画素のX座標の累積値
    NSInteger _xsum;
    
    // 全画素のX座標の累積値
    NSInteger _ysum;
    
    // 形状が固定したかどうか
    // 一度各種プロパティを参照するとYESになり、- addPixelWithX:andY: が呼ばれるとNOになる.
    BOOL _fixed;
    
    // 幅
    NSInteger _w;
    
    // 高さ
    NSInteger _h;
    
    // 中心座標
    CGPoint _ct;
}

#pragma mark - 初期化

- (id)initWithLabel:(NSInteger)label
{
    self = [super init];
    if (self) {
        _label = label;
        _xmin = _ymin = INT32_MAX;
        _xmax = _ymax = INT32_MIN;
        _fixed = NO;
        _numHole = 0;
    }
    return self;
}

#pragma mark - 構築

- (void)addPixelWithX:(NSInteger)x andY:(NSInteger)y
{
    _area++;
    if (x < _xmin) _xmin = x;
    if (x > _xmax) _xmax = x;
    if (y < _ymin) _ymin = y;
    if (y > _ymax) _ymax = y;
    _xsum += x;
    _ysum += y;
    _fixed = NO;
}

#pragma mark - プロパティ

- (NSInteger)width
{
    if (!_fixed) {
        [self calcParameter];
    }
    return _w;
}
    
- (NSInteger)height
{
    if (!_fixed) {
        [self calcParameter];
    }
    return _h;
}

- (CGPoint)center
{
    if (!_fixed) {
        [self calcParameter];
    }
    return _ct;
}

#pragma mark - プライベートメソッド

/**
 * 各種パラメータを計算する.
 */
- (void)calcParameter
{
    _w = _xmax - _xmin + 1;
    _h = _ymax - _ymin + 1;
    _ct = CGPointMake(((CGFloat)_xsum / _area) + 0.5, ((CGFloat)_ysum / _area) + 0.5);
    _fixed = YES;
}

@end