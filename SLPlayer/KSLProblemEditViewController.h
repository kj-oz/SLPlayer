//
//  KSLAddProblemViewController.h
//  SLPlayer
//
//  Created by KO on 2014/01/04.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSLProblemViewDelegate.h"

@class KSLBoardOverallView;
@class KSLProblemView;
@class KSLProblem;

@interface KSLProblemEditViewController : UIViewController
        <UINavigationControllerDelegate, UIImagePickerControllerDelegate, KSLProblemViewDelegate>

// 対象の問題
@property (nonatomic, strong) KSLProblem *problem;

// 新規追加か（既存の問題の編集か）
@property (nonatomic, assign) BOOL addNew;

@end
