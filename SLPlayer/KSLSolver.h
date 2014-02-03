//
//  KSLSolver.h
//  SLPlayer
//
//  Created by KO on 13/10/29.
//  Copyright (c) 2013年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSLBoard.h"

#pragma mark - 定数

/**
 * ソルバーのエラーコードの定義
 */
typedef enum {
    KSLSolverErrorNoLoop = 1001,    // ループが存在しない
    KSLSolverErrorMultipleLoops     // 複数のループが存在する
} KSLSolverError;


#pragma mark - KSLSolver

/**
 * スリザーリンクの問題を自動的に解くクラス.
 */
@interface KSLSolver : NSObject

// 正解のルート
@property (nonatomic, readonly) NSArray *route;

// 盤面データ
@property (nonatomic, readonly) KSLBoard *board;

/**
 * 与えられた盤面で初期化する.
 * @param board 盤面
 * @return ソルバオブジェクト
 */
- (id)initWithBoard:(KSLBoard *)board;

/**
 * 問題を解く
 * @param error 問題が正常に解けなかった場合にその原因となったエラー（KSLSolverError)を返す.
 *              返されるエラーの
 * @return 問題が正常に解けたかどうか
 */
- (BOOL)solveWithError:(NSError **)error;

@end
