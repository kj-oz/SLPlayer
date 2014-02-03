//
//  KSLPlayer.h
//  SLPlayer
//
//  Created by KO on 2014/01/18.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSLProblem;

@interface KSLPlayer : NSObject

@property (nonatomic, assign) NSInteger fixedIndex;

@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, readonly) NSArray *steps;

- (id)initWithProblem:(KSLProblem *)problem;

- (void)save;

@end
