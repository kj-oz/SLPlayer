//
//  KSLPlayer.h
//  SLPlayer
//
//  Created by KO on 2014/01/18.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSLBoard.h"

@class KSLProblem;

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
 * Undo対象の一連の操作を1つ追加する.
 * @param step 一連の操作
 */
- (void)addStep:(NSArray *)step;

/**
 * Edgeを全てクリアする.（未設定の状態にする）
 */
- (void)clear;

/**
 * 固定されていないEdgeを全て未設定の状態にする.
 */
- (void)erase;

/**
 * 未設定以外のEdgeを固定する.
 */
- (void)fix;

/**
 * 既存の最後の操作の値を与えれた値に変更する.
 * (盤面編集時のセルの数値の変更等、同じ対象に対して続けて操作をした場合）
 * @param newValue 新たな値
 */
- (void)changeAction:(NSInteger)newValue;

/**
 * 直前の一連の操作をアンドゥする.
 */
- (void)undo;

/**
 * ループが完成したか銅貨を調べる
 * @return ループの状態
 */
- (KSLLoopStatus)isLoopFinished;

@end
