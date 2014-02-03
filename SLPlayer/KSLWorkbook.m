//
//  KSLBook.m
//  SLPlayer
//
//  Created by KO on 2014/01/03.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLWorkbook.h"
#import "KSLProblem.h"

@implementation KSLWorkbook
{
    NSMutableArray *_problems;
}

#pragma mark - 初期化

- (id)initWithDirectory:(NSString *)path
{
    self = [super init];
    if (self) {
        self.title = [path lastPathComponent];
        _problems = [NSMutableArray array];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *files = [fm contentsOfDirectoryAtPath:path error:NULL];
        for (NSString *file in files) {
            KSLProblem *problem = [[KSLProblem alloc] initWithFile:file];
            [_problems addObject:problem];
        }
    }
    return self;
}

@end
