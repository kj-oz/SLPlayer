//
//  KLIHistgram.m
//  SLPlayer
//
//  Created by KO on 2014/10/28.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KLIMHistgram.h"

@implementation KLIMHistgram
{
    NSInteger* _histgram;
}

- (id)initWithMin:(NSInteger)min max:(NSInteger)max bandWidth:(NSInteger)bandWidth
{
    self = [super init];
    if (self) {
        _min = min;
        _bandWidth = bandWidth;
        NSInteger w = max + 1 - min;
        _bandCount = w / bandWidth;
        if (w % bandWidth > 0) {
            _bandCount++;
        }
        _max = min + _bandCount * bandWidth - 1;
        _histgram = calloc(_bandCount, sizeof(NSInteger));
    }
    return self;
}

- (void)dealloc
{
    free(_histgram);
}

- (BOOL)addValue:(NSInteger)value
{
    if (value >= _min && value <= _max) {
        NSInteger index = (value - _min) / _bandWidth;
        _histgram[index]++;
        return YES;
    }
    return NO;
}

- (NSInteger)countAtIndex:(NSInteger)index
{
    return _histgram[index];
}

- (NSInteger)minAtIndex:(NSInteger)index
{
    return _min + _bandWidth * index;
}

- (NSInteger)maxAtIndex:(NSInteger)index
{
    return _min + _bandWidth * (index + 1) - 1;
}

- (NSInteger)findPeak
{
    NSInteger maxCount = -1;
    NSInteger maxIndex = -1;
    for (int i = 0; i < _bandCount; i++) {
        if (_histgram[i] > maxCount) {
            maxCount = _histgram[i];
            maxIndex = i;
        }
    }
    return maxIndex;
}

- (NSInteger)findNextBottom:(NSInteger)peak limit:(CGFloat)limit
{
    NSInteger maxCount = _histgram[peak];
    NSInteger prevCount = maxCount;
    NSInteger limitCount = (NSInteger)ceil(maxCount * limit);
    int increasing = 0;
    for (int i = (int)peak + 1; i < _bandCount; i++) {
        NSInteger count = _histgram[i];
        if (count < limitCount) {
            return i;
        }
        if (count > prevCount) {
            increasing++;
            if (increasing > 2) {
                return i - increasing;
            }
        } else if (count < prevCount) {
            increasing = 0;
        }
        prevCount = count;
    }
    return -1;
}

- (NSInteger)findPrevBottom:(NSInteger)peak limit:(CGFloat)limit
{
    NSInteger maxCount = _histgram[peak];
    NSInteger prevCount = maxCount;
    NSInteger limitCount = (NSInteger)ceil(maxCount * limit);
    int increasing = 0;
    for (int i = (int)peak - 1; i >= 0; i--) {
        NSInteger count = _histgram[i];
        if (count < limitCount) {
            return i;
        }
        if (count > prevCount) {
            increasing++;
            if (increasing > 2) {
                return i + increasing;
            }
        } else if (count < prevCount) {
            increasing = 0;
        }
        prevCount = count;
    }
    return -1;
    
}

- (void)dump
{
    int cmax = 20;
    int rmax = (int)_bandCount / cmax + 1;
    int i = 0;
    for (int r = 0; r < rmax; r++) {
        KLDBGPrint("%4d:", (int)[self minAtIndex:i]);
        for (int c = 0; c < cmax && i < _bandCount; c++, i++) {
            KLDBGPrint("%4d,", (int)_histgram[i]);
        }
        KLDBGPrint("\n");
    }
}

@end
