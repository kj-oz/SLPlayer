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
    KSLProblemViewModeScroll,       // パン、ズーム
    KSLProblemViewModeEnter,        // EdgeのOn、Offの設定
    KSLProbremViewModeErase         // Edgeのクリア
} KSLProblemViewMode;


#pragma mark - KSLProbremView

/**
 * 問題の一部を拡大表示し各種操作を行うためのビュー
 */
@interface KSLBoardZoomedView : UIView

// 盤面の情報の取得、設定を行うデリゲート
@property (nonatomic, weak) id<KSLProblemViewDelegate> delegate;

// ビューのモード
@property (nonatomic, assign) KSLProblemViewMode mode;

@end
