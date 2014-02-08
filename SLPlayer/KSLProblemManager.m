//
//  KSLProblemManager.m
//  SLPlayer
//
//  Created by KO on 2014/01/03.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLProblemManager.h"
#import "KSLWorkbook.h"

// シングルトンオブジェクト
static KSLProblemManager *_sharaedInstance = nil;


@implementation KSLProblemManager
{
    // 問題集の配列
    NSMutableArray *_workbooks;
    
    // アプリケーションドメインのドキュメントディレクトリー
    NSString *_documentDir;
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
    
    NSArray *dirs = [fm contentsOfDirectoryAtPath:_documentDir error:NULL];
    if ([dirs count]) {
        for (NSString *dir in dirs) {
            KSLWorkbook *book = [[KSLWorkbook alloc] initWithDirectory:dir];
            [_workbooks addObject:book];
        }
    } else {
        // サンプル問題集の展開
        NSString *path = [_documentDir stringByAppendingPathComponent:@"問題集1"];
        [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:NULL];
        KSLWorkbook *book = [[KSLWorkbook alloc] initWithDirectory:path];
        [_workbooks addObject:book];
    }
}

@end
