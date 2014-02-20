//
//  KSLAppDelegate.h
//  SLPlayer
//
//  Created by KO on 2014/02/02.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KSLProblem;

@interface KSLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// 前回起動時の最後のビュー（"List", "Play", "Edit")
@property (nonatomic, readonly) NSString *lastView;

// 前回起動時の最後の問題（ビューがList時はnil）
@property (nonatomic, weak, readonly) KSLProblem *lastProblem;

// 前回起動時の状態を再現している途中か
@property (nonatomic, assign) BOOL restoring;

// 現在表示中のビュー（"List", "Play", "Edit")
@property (nonatomic, copy) NSString *currentView;

- (void)saveData;

@end
