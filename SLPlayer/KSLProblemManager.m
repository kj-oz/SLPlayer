//
//  KSLProblemManager.m
//  SLPlayer
//
//  Created by KO on 2014/01/03.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLProblemManager.h"
#import "KSLProblem.h"
#import "KSLWorkbook.h"

// シングルトンオブジェクト
static KSLProblemManager *_sharaedInstance = nil;


@implementation KSLProblemManager
{
    // 問題集の配列
    NSMutableArray *_workbooks;
}

#pragma mark - シングルトンオブジェクト

+ (KSLProblemManager *)sharedManager
{
    if (!_sharaedInstance) {
        _sharaedInstance = [[KSLProblemManager alloc] init];
    }
    return _sharaedInstance;
}

#pragma mark - 初期化

- (id)init
{
    self = [super init];
    if (self) {
        _workbooks = [NSMutableArray array];
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        _documentDir = [[paths objectAtIndex:0] copy];
        KLDBGPrint("** Application start **\n");
        KLDBGPrint(" document directory:%s\n", _documentDir.UTF8String);
    }
    
    return self;
}

#pragma mark - プロパティ

- (NSString *)currentWorkbookDir
{
    return [_documentDir stringByAppendingPathComponent:_currentWorkbook.title];
}

#pragma mark - ロード

- (void)load
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSMutableArray *dirs = [NSMutableArray array];
    NSArray *files = [fm contentsOfDirectoryAtPath:_documentDir error:NULL];
    BOOL isDir;
    for (int i = 0, n = files.count; i < n; i++) {
        [fm fileExistsAtPath:[_documentDir stringByAppendingPathComponent:files[i]] isDirectory:&isDir];
        if (isDir) {
            [dirs addObject:files[i]];
        }
    }
    
    if ([dirs count]) {
        for (NSString *dir in dirs) {
            KSLWorkbook *book = [[KSLWorkbook alloc] initWithTitle:dir];
            [_workbooks addObject:book];
        }
    } else {
        // サンプル問題集の展開
        NSString *path = [_documentDir stringByAppendingPathComponent:@"サンプル"];
        NSError *error;
        if (![fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error]) {
            KLDBGPrint("%s", error.description.UTF8String);
        };
        KSLWorkbook *book = [[KSLWorkbook alloc] initWithTitle:@"サンプル"];
        [_workbooks addObject:book];
    }
}

- (void)moveProblem:(KSLProblem *)problem toWorkbook:(KSLWorkbook *)to
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *fromDir = self.currentWorkbookDir;
    NSString *fromFile = [fromDir stringByAppendingPathComponent:problem.uid];
    NSString *toDir = [_documentDir stringByAppendingPathComponent:to.title];
    NSString *toFile = [toDir stringByAppendingPathComponent:problem.uid];
    NSError *error;
    [fm moveItemAtPath:[fromFile stringByAppendingPathComponent:@"problem"]
                toPath:[toFile stringByAppendingPathComponent:@"problem"] error:&error];
    [fm moveItemAtPath:[fromFile stringByAppendingPathComponent:@"play"]
                toPath:[toFile stringByAppendingPathComponent:@"play"] error:&error];
    
    [to addProblem:problem withSave:NO];
    [_currentWorkbook removeProblem:problem withDelete:NO];
}

@end
