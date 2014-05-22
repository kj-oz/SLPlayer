//
//  KSLBook.m
//  SLPlayer
//
//  Created by KO on 2014/01/03.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLWorkbook.h"
#import "KSLProblem.h"
#import "KSLProblemManager.h"

@implementation KSLWorkbook
{
    NSMutableArray *_problems;
}

#pragma mark - 初期化

- (id)initWithTitle:(NSString *)title
{
    self = [super init];
    if (self) {
        self.title = title;
        _problems = [NSMutableArray array];
        
        KSLProblemManager *pm = [KSLProblemManager sharedManager];
        NSString *path = [pm.documentDir stringByAppendingPathComponent:title];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDir;
        if (![fm fileExistsAtPath:path isDirectory:&isDir]) {
            NSError *error;
            [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
        }
        
        NSArray *files = [fm contentsOfDirectoryAtPath:path error:NULL];
        for (NSString *file in files) {
            if ([[file pathExtension] isEqualToString:@"problem"]) {
                NSString *filePath = [path stringByAppendingPathComponent:file];
                KSLProblem *problem = [[KSLProblem alloc] initWithFile:filePath];
                [_problems addObject:problem];
            }
        }
    }
    return self;
}

#pragma mark - 操作

- (void)addProblem:(KSLProblem *)problem withSave:(BOOL)save
{
    [_problems addObject:problem];
    
    if (save) {
        KSLProblemManager *pm = [KSLProblemManager sharedManager];
        [problem saveToFile:[pm.documentDir stringByAppendingPathComponent:_title]];
    }
}

- (void)removeProblem:(KSLProblem *)problem withDelete:(BOOL)delete
{
    [_problems removeObject:problem];
    
    if (delete) {
        NSFileManager *fm = [NSFileManager defaultManager];
        KSLProblemManager *pm = [KSLProblemManager sharedManager];
        NSString *dir = [pm.documentDir stringByAppendingPathComponent:_title];
        NSString *file = [dir stringByAppendingPathComponent:problem.uid];
        NSError *error;
        [fm removeItemAtPath:[file stringByAppendingPathExtension:@"problem"] error:&error];
        [fm removeItemAtPath:[file stringByAppendingPathExtension:@"play"] error:&error];
    }
}

- (void)copyProblem:(KSLProblem *)problem
{
    KSLProblem *newProblem = [[KSLProblem alloc] initWithProblem:problem];
    NSString *seed;
    NSInteger number;
    NSRange range = [problem.title rangeOfString:@"\\(\\d+\\)" options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        seed = [problem.title substringToIndex:range.location];
        number = [[problem.title substringWithRange:
                   NSMakeRange(range.location + 1, range.length - 2)] integerValue];
    } else {
        seed = problem.title;
        number = 2;
    }
    NSString *newTitle;
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    while (1) {
        newTitle = [NSString stringWithFormat:@"%@(%ld)", seed, (long)number];
        if (![self hasSameTitleProblem:newTitle]) {
            break;
        }
        number++;
    }
    
    newProblem.title = newTitle;
    [_problems addObject:newProblem];
    
    [problem saveToFile:[pm.documentDir stringByAppendingPathComponent:_title]];
}

#pragma mark - プライベート・メソッド群

/**
 * 同じ名称の問題が存在しているか調べる
 * @param title 名称
 * @return 同じ名称の問題が存在しているかどうか
 */
- (BOOL)hasSameTitleProblem:(NSString *)title
{
    for (KSLProblem *problem in _problems) {
        if ([problem.title isEqualToString:title]) {
            return YES;
        }
    }
    return NO;
}

@end
