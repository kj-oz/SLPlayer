//
//  KSLPlayer.h
//  SLPlayer
//
//  Created by KO on 2014/01/18.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSLProblem;
@class KSLBoard;

/**
 * 問題を解いている手順を保持するクラス
 */
@interface KSLPlayer : NSObject

// 「固定」したインデックス
@property (nonatomic, assign) NSInteger fixedIndex;

// 現時点のインデックス（Undoがあるので末尾とは限らない）
@property (nonatomic, assign) NSInteger currentIndex;

// 実行した全ステップ（Actionの配列）の配列
@property (nonatomic, readonly) NSArray *steps;

// 問題
@property (nonatomic, readonly) KSLProblem *problem;

// 盤面
@property (nonatomic, readonly) KSLBoard *board;

/**
 * 与えられた問題に対するPlayerを作成する.
 * ファイルが残っていればファイルからロードし残っていなければ初期状態で作成する.
 * @param problem 問題
 * @return 手順管理オブジェクト
 */
- (id)initWithProblem:(KSLProblem *)problem;

/**
 * 状態をファイルに保存する.
 */
- (void)save;

/**
 *
 * @param step
 */
- (void)addStep:(NSArray *)step;

- (void)clear;

- (void)erase;

- (void)fix;

- (void)changeAction:(NSInteger)newValue;

- (void)undo;

- (BOOL)isFinished;

@end
