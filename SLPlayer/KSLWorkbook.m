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

@end
