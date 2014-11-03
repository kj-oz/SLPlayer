//
//  KLIHistgram.h
//  SLPlayer
//
//  Created by KO on 2014/10/28.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KLIMHistgram : NSObject

@property (nonatomic, readonly) NSInteger min;
@property (nonatomic, readonly) NSInteger max;
@property (nonatomic, readonly) NSInteger bandWidth;
@property (nonatomic, readonly) NSInteger bandCount;

- (id)initWithMin:(NSInteger)min max:(NSInteger)max bandWidth:(NSInteger)bandWidth;

- (BOOL)addValue:(NSInteger)value;

- (NSInteger)countAtIndex:(NSInteger)index;

- (NSInteger)minAtIndex:(NSInteger)index;

- (NSInteger)maxAtIndex:(NSInteger)index;

- (NSInteger)findPeak;

- (NSInteger)findNextBottom:(NSInteger)peak limit:(CGFloat)limit;

- (NSInteger)findPrevBottom:(NSInteger)peak limit:(CGFloat)limit;

- (void)dump;

@end
