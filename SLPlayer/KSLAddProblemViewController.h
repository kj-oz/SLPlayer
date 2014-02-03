//
//  KSLAddProblemViewController.h
//  SLPlayer
//
//  Created by KO on 2014/01/04.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSLProblemViewDelegate.h"

@class KSLOverallView;
@class KSLProblemView;
@class KSLProblem;

@interface KSLAddProblemViewController : UIViewController
        <UINavigationControllerDelegate, UIImagePickerControllerDelegate, KSLProblemViewDelegate>

@property (nonatomic, strong) KSLProblem *problem;

@end
