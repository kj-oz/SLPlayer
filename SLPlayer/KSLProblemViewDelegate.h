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
#define KSLPROBLEM_MINIMUM_PITCH    44

@class KSLAction;
@class KSLBoard;

@protocol KSLProblemViewDelegate <NSObject>

// 描画対象の盤面データ
@property (nonatomic, readonly) KSLBoard *board;

// 拡大画面で表示中の領域（問題座標系）
@property (nonatomic, assign) CGRect zoomedArea;

// 問題全体を表示するのに必要な領域（問題座標系）
@property (nonatomic, readonly) CGRect problemArea;

@optional
// 線の入力／消去時のステップの開始
- (void)stepBegan;

// 何らかの操作が行われた
- (void)actionPerformed:(KSLAction *)action;

// 直前の操作と同じ対象に対して異なる操作が続けて行われた
- (void)actionChanged:(NSInteger)newValue;

// 線の入力／消去時のステップの終了
- (void)stepEnded;

// 直前の操作が取り消された
- (void)undo;

@end
