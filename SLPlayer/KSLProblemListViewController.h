//
//  KSLProblemListViewController.h
//  SLPlayer
//
//  Created by KO on 2014/02/02.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSLWorkbookListViewController.h"

/**
 * 問題一覧画面のコントローラ
 */
@interface KSLProblemListViewController : UITableViewController
    <KSLWorkbookListViewControllerDelegate, UIPopoverControllerDelegate>

@end
