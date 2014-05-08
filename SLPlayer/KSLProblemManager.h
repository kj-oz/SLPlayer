//
//  KSLProblemManager.h
//  SLPlayer
//
//  Created by KO on 2014/01/03.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSLWorkbook;
@class KSLProblem;

/**
 * 問題管理クラス、シングルトンとして利用する.
 */
@interface KSLProblemManager : NSObject

// 問題集の配列
@property (nonatomic, readonly) NSArray *workbooks;

// カレントの問題集
@property (nonatomic, weak) KSLWorkbook *currentWorkbook;

// カレントの問題、問題の操作中でなければnil
@property (nonatomic, weak) KSLProblem *currentProblem;

// 問題集を配置するデイレクトリー
@property (nonatomic, readonly) NSString *documentDir;

// カレントの問題集のディレクトリー
@property (nonatomic, readonly) NSString *currentWorkbookDir;

/**
 * シングルトンオブジェクトを得る.
 */
+ (KSLProblemManager *)sharedManager;

/**
 * 問題集のデータをロードする.
 */
- (void)load;

- (KSLWorkbook *)findWorkbook:(NSString *)title;

- (NSInteger)indexOfWorkbook:(KSLWorkbook *)workbook;

- (void)addWorkbook:(KSLWorkbook *)workbook;

- (void)removeWorkbookAtIndex:(NSInteger)index;

- (void)moveProblem:(KSLProblem *)problem toWorkbook:(KSLWorkbook *)to;

- (void)moveProblems:(NSArray *)problems toWorkbook:(KSLWorkbook *)to;

- (NSString *)currentTimeString;

@end
