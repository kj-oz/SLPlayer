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
@class KSLBoardZoomedView;
@class KSLProblem;

@interface KSLProblemEditViewController : UIViewController
        <UINavigationControllerDelegate, UIImagePickerControllerDelegate, KSLProblemViewDelegate>

@property (nonatomic, strong) KSLProblem *problem;

@property (nonatomic, assign) BOOL addNew;

@end
