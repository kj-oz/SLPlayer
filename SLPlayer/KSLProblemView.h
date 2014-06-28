//
//  KSLProbremView.h
//  SLPlayer
//
//  Created by KO on 2014/01/02.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSLProblemViewDelegate.h"

#pragma mark - 定数

/**
 * 問題表示ビューのモード
 */
typedef enum {
    KSLProblemViewModeScroll,       // 表示のみ
    KSLProblemViewModeInputLine,    // EdgeのOn、Offの指定
    KSLProblemViewModeInputNumber   // 数字の入力
} KSLProblemViewMode;


#pragma mark - KSLProbremView

/**
 * 問題の一部を拡大表示し各種操作を行うためのビュー
 */
@interface KSLProblemView : UIView

// 盤面の情報の取得、設定を行うデリゲート
@property (nonatomic, weak) id<KSLProblemViewDelegate> delegate;

// 描画対象の盤面データ
@property (nonatomic) KSLBoard *board;

// ビューのモード
@property (nonatomic, assign) KSLProblemViewMode mode;

@end
