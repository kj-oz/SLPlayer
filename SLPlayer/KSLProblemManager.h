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

/**
 * 指定の名称の問題種を得る
 * @param title 名称
 * @return 指定の名称の問題種
 */
- (KSLWorkbook *)findWorkbook:(NSString *)title;

/**
 * 指定の問題集の配列内インデックスを得る.
 * @param workbook 問題集
 * @return 指定の問題集の配列内インデックス、見つからなければ-1
 */
- (NSInteger)indexOfWorkbook:(KSLWorkbook *)workbook;

/**
 * 指定の問題集を追加する.
 * @param workbook 問題集
 */
- (void)addWorkbook:(KSLWorkbook *)workbook;

/**
 * 指定のインデックスの問題集を削除する.
 * @param index 問題集のインデックス
 */
- (void)removeWorkbookAtIndex:(NSInteger)index;

/**
 * 指定の問題（複数）を、指定の問題種へ移動する.
 * @param problem 問題の配列
 * @param to 移動先の問題集
 */
- (void)moveProblems:(NSArray *)problems toWorkbook:(KSLWorkbook *)to;

/**
 * 現在時刻の文字列を得る（YYYYMMDDhhmmssSSS）
 * @return 現在時刻の文字列
 */
- (NSString *)currentTimeString;

@end
