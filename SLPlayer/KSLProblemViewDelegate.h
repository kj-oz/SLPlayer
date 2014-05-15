//
//  KSLProblemDelegate.h
//  SLPlayer
//
//  Created by KO on 2014/01/19.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <Foundation/Foundation.h>


// 問題の末端の点からの余白（問題座標系）
#define KSLPROBLEM_MARGIN           1.0

// 拡大表示時の端部のグレー表示幅（問題座標系）
#define KSLPROBLEM_BORDER_WIDTH     0.2

// 拡大表示時の最小ピッチ（ピクセル単位）
#define KSLPROBLEM_TOUCHABLE_PITCH    44

@class KSLAction;
@class KSLBoard;


/**
 * 問題表示専用のビューのデリゲートクラス.
 */
@protocol KSLProblemViewDelegate <NSObject>

@optional

/**
 * 線の入力／消去時のステップの開始
 */
- (void)stepBegan;

/**
 * 何らかの操作が行われた時の発生するイベント
 * @param action 操作
 */
- (void)actionPerformed:(KSLAction *)action;

/**
 * 直前の操作と同じ対象に対して異なる操作が続けて行われた時に呼び出される
 * @param newValue
 */
- (void)actionChanged:(NSInteger)newValue;

/**
 * 線の入力／消去時のステップの終了
 */
- (void)stepEnded;

/**
 * 直前の操作が取り消された
 */
- (void)undo;

@end
