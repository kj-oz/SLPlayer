//
//  KSLPlayer.h
//  SLPlayer
//
//  Created by KO on 2014/01/18.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSLProblem;

/**
 * 問題を解いている過程を保持するクラス
 */
@interface KSLPlayer : NSObject

// 「固定」したインデックス
@property (nonatomic, assign) NSInteger fixedIndex;

// 現時点のインデックス（Undoがあるので末尾とは限らない）
@property (nonatomic, assign) NSInteger currentIndex;

// 実行した全ステップ（Actionの配列）の配列
@property (nonatomic, readonly) NSArray *steps;

/**
 * 与えられた問題に対するPlayerを作成する.
 * ファイルが残っていればファイルからロードする.残っていなければ初期状態で作成.
 * @param problem 問題
 * @return Player
 */
- (id)initWithProblem:(KSLProblem *)problem;

/**
 * 状態をファイルに保存する.
 */
- (void)save;

@end
