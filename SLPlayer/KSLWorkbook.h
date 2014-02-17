//
//  KSLBook.h
//  SLPlayer
//
//  Created by KO on 2014/01/03.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSLProblem;

/**
 * 問題集を表すクラス.
 */
@interface KSLWorkbook : NSObject

// 一覧に表示する題名
@property (nonatomic, copy) NSString *title;

// 問題の配列
@property (nonatomic, readonly) NSArray *problems;

/**
 * 与えられた名称の問題集オブジェクトを生成する.
 * @param title 名称
 * @return 問題集オブジェクト
 */
- (id)initWithTitle:(NSString *)title;

/**
 * 与えられた問題を自分自身に追加する.
 * @param problem 問題
 * @param save 同時に問題の保存を実行するかどうか
 */
- (void)addProblem:(KSLProblem *)problem withSave:(BOOL)save;

/**
 * 与えられた問題を削除する.
 * @param problem 問題
 * @param delete 同時に問題のファイルを実際に削除するかどうか
 */
- (void)removeProblem:(KSLProblem *)problem withDelete:(BOOL)delete;

@end
