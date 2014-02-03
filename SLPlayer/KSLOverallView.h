//
//  KSLOverallView.h
//  SLPlayer
//
//  Created by KO on 2014/01/02.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSLProblemViewDelegate.h"

/**
 * プレイ画面、編集画面等で盤面全体を表示するビュー
 */
@interface KSLOverallView : UIView

// 盤面の情報の取得、設定を行うデリゲート
@property (nonatomic, weak) id<KSLProblemViewDelegate> delegate;

@end
