//
//  KSLWorkbookListViewController.h
//  SLPlayer
//
//  Created by KO on 2014/04/26.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KSLWorkbook;

/**
 * 問題集一覧画面のデリゲート
 */
@protocol KSLWorkbookListViewControllerDelegate <NSObject>

/**
 * 問題集一覧画面でCが選択された場合に呼び出されるハンドラ.
 * @param controller 問題集一覧画面のコントローラ
 */
- (void)workbookListViewControllerWorkbookDidSelect:(KSLWorkbook *)workbook;

/**
 * 問題集一覧画面で問題集が名称変更された場合に呼び出されるハンドラ.
 * @param workbook 名称が変更された問題集
 */
- (void)workbookListViewControllerWorkbookDidRename:(KSLWorkbook *)workbook;

@end


@interface KSLWorkbookListViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, weak) id<KSLWorkbookListViewControllerDelegate> delegate;

@end

