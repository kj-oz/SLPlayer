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
#import "KSLSolver.h"

// シングルトンオブジェクト
static KSLProblemManager *_sharaedInstance = nil;


@implementation KSLProblemManager
{
    // 問題集の配列
    NSMutableArray *_workbooks;
    
    // 日付書式
    NSDateFormatter *_dateFormatter;
    
    // 直前に返した日時文字列
    NSString *_lastDateString;
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
        
        // 日付フォーマットオブジェクトの生成
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyyMMddHHmmssSSS"];
        
        _lastDateString = @"00000000000000000";
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
    
    // アプリにバンドルされたサンプル問題集の展開
    NSBundle *bundle = [NSBundle mainBundle];
    NSArray *paths = [bundle pathsForResourcesOfType:@"workbook" inDirectory:nil];
    for (NSString *path in paths) {
        NSString *title = [[path lastPathComponent] stringByDeletingPathExtension];
        NSString *docPath = [_documentDir stringByAppendingPathComponent:title];
        if (![fm fileExistsAtPath:docPath isDirectory:NULL]) {
            [self importWorkbook:path];
        }
    }

    // Docディレクトリーに置かれた問題集ファイルの展開
    NSArray *files = [fm contentsOfDirectoryAtPath:_documentDir error:NULL];
    NSError *error;
    for (NSString *file in files) {
        NSString *path = [_documentDir stringByAppendingPathComponent:file];
        [fm fileExistsAtPath:path isDirectory:NULL];
        if ([[file pathExtension] isEqualToString:@"workbook"]) {
            [self importWorkbook:path];
            [fm removeItemAtPath:path error:&error];
        }
    }

    // ディレクトリーの問題集化
    files = [fm contentsOfDirectoryAtPath:_documentDir error:NULL];
    BOOL isDir;
    for (NSString *file in files) {
        NSString *path = [_documentDir stringByAppendingPathComponent:file];
        [fm fileExistsAtPath:path isDirectory:&isDir];
        if (isDir) {
            KSLWorkbook *book = [[KSLWorkbook alloc] initWithTitle:file];
            [_workbooks addObject:book];
        }
    }
}

- (KSLWorkbook *)findWorkbook:(NSString *)title
{
    for (KSLWorkbook *wb in _workbooks) {
        if ([wb.title isEqualToString:title]) {
            return wb;
        }
    }
    return nil;
}

- (NSInteger)indexOfWorkbook:(KSLWorkbook *)workbook
{
    NSInteger index = 0;
    for (KSLWorkbook *wb in _workbooks) {
        if (wb == workbook) {
            return index;
        }
        index++;
    }
    return -1;
}

- (void)addWorkbook:(KSLWorkbook *)workbook
{
    [_workbooks addObject:workbook];
}

- (void)removeWorkbookAtIndex:(NSInteger)index
{
    KSLWorkbook *wb = _workbooks[index];
    NSError *error;
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:[_documentDir stringByAppendingPathComponent:wb.title] error:&error];
    
    [_workbooks removeObjectAtIndex:index];
}

- (void)moveProblems:(NSArray *)problems toWorkbook:(KSLWorkbook *)to
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *fromDir = self.currentWorkbookDir;
    NSString *toDir = [_documentDir stringByAppendingPathComponent:to.title];
    
    for (KSLProblem *problem in problems) {
        NSString *fromFile = [fromDir stringByAppendingPathComponent:problem.uid];
        NSString *toFile = [toDir stringByAppendingPathComponent:problem.uid];
        NSError *error;
        [fm moveItemAtPath:[fromFile stringByAppendingPathComponent:@"problem"]
                    toPath:[toFile stringByAppendingPathComponent:@"problem"] error:&error];
        [fm moveItemAtPath:[fromFile stringByAppendingPathComponent:@"play"]
                    toPath:[toFile stringByAppendingPathComponent:@"play"] error:&error];
        
        [to addProblem:problem withSave:NO];
        [_currentWorkbook removeProblem:problem withDelete:NO];
    }
}

- (void)renameWorkbook:(KSLWorkbook *)workbook toNewName:(NSString *)name
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSString *fromDir = [_documentDir stringByAppendingPathComponent:workbook.title];
    NSString *toDir = [_documentDir stringByAppendingPathComponent:name];
    [fm moveItemAtPath:fromDir toPath:toDir error:&error];
    
    if (!error) {
        workbook.title = name;
    }
}

- (NSString *)currentTimeString
{
    // 日付型の文字列を生成
    NSString *dateString = [_dateFormatter stringFromDate:[NSDate date]];
    if ([dateString compare:_lastDateString] != NSOrderedDescending) {
        long long lastDate = [_lastDateString longLongValue];
        dateString = [NSString stringWithFormat:@"%ld", (long)lastDate];
    }
    _lastDateString = dateString;
    return dateString;
}


#pragma mark - プライベートメソッド

/**
 * 与えられたパスのjsonファイルから問題集を読み込む.
 * @param jsonPath jsonファイルのパス
 * @return 実際に採用された問題集の名称
 */
- (NSString *)importWorkbook:(NSString *)jsonPath
{
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:
                          [NSData dataWithContentsOfFile:jsonPath] options:0 error:&error];
    if (error) {
        [[NSException exceptionWithName:error.description reason:jsonPath userInfo:nil] raise];
    }
    NSString *title = json[@"title"];
    
    NSString *path = [_documentDir stringByAppendingPathComponent:title];
    
    NSInteger num = 1;
    NSString *base = title;
    NSFileManager *fm = [NSFileManager defaultManager];
    while ([fm fileExistsAtPath:path]) {
        num++;
        title = [NSString stringWithFormat:@"%@-%ld", base, (long)num];
        path = [_documentDir stringByAppendingPathComponent:title];
    }
    [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
    
    NSArray *problems = json[@"problems"];
    for (NSDictionary *dic in problems) {
        KSLProblem *problem = [[KSLProblem alloc] initWithJson:dic];
#if TARGET_IPHONE_SIMULATOR
        // エミュレータで実行中の場合のみ問題の正しさを検証する
        KSLSolver *solver = [[KSLSolver alloc] initWithBoard:
                             [[KSLBoard alloc] initWithProblem:problem]];
        NSError *error;
        if (![solver solveWithError:&error]) {
            problem.status = KSLProblemStatusEditing;
        }
#endif
        [problem saveToFile:path];
    }
    return title;
}

@end
