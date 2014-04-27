//
//  KSLWorkbookListViewController.m
//  SLPlayer
//
//  Created by KO on 2014/04/26.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLWorkbookListViewController.h"
#import "KLUITextFieldCell.h"
#import "KSLProblemManager.h"
#import "KSLWorkbook.h"
#import "UIAlertView+Blocks.h"

@interface KSLWorkbookListViewController ()

@end

@implementation KSLWorkbookListViewController
{
    // 新規本棚追加中フラグ
    BOOL _adding;
    
    // 既存本棚の名称変更中フラグ
    BOOL _renaming;
    
    // 削除対象の行
    NSInteger _deletingRow;
    
    IBOutlet UIBarButtonItem* _addButton;
    IBOutlet UIBarButtonItem* _endButton;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // テーブルの行の数と本棚の数を比較する
    if ([self.tableView numberOfRowsInSection:0] != [KSLProblemManager sharedManager].workbooks.count) {
        // データの再読み込みを行う
        [self.tableView reloadData];
    } else {
        // セルの表示更新を行う
        for (UITableViewCell* cell in [self.tableView visibleCells]) {
            [self updateCell:cell atIndexPath:[self.tableView indexPathForCell:cell]];
        }
    }
    
    [self updateNavigationItemAnimated:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 編集モード

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    // テーブルビューの編集モードを設定する
    [self.tableView setEditing:editing animated:animated];
    
    for (UITableViewCell* cell in [self.tableView visibleCells]) {
        UITextField* tf = ((KLUITextFieldCell*)cell).textField;
        if (editing) {
            tf.enabled = YES;
        } else {
            if ([tf isFirstResponder]) {
                [tf resignFirstResponder];
            }
            tf.enabled = NO;
        }
    }
    
    // ナビゲーションボタンを更新する
    [self updateNavigationItemAnimated:animated];
}

#pragma mark - 画面の更新

- (void)updateNavigationItemAnimated:(BOOL)animated
{
    if (_adding || _renaming) {
        [self.navigationItem setLeftBarButtonItem:_endButton animated:animated];
        [self.navigationItem setRightBarButtonItem:nil animated:animated];
    } else {
        if (self.editing) {
            [self.navigationItem setLeftBarButtonItem:nil animated:animated];
        } else {
            [self.navigationItem setLeftBarButtonItem:_addButton animated:animated];
        }
        [self.navigationItem setRightBarButtonItem:[self editButtonItem] animated:animated];
    }
}

- (void)updateCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    NSString* text;
    NSArray* workbooks = [KSLProblemManager sharedManager].workbooks;
    KSLWorkbook *workbook = nil;
    if (indexPath.row == workbooks.count) {
        text = @"";
    } else {
        workbook = [workbooks objectAtIndex:indexPath.row];
        text = workbook.title;
    }
    UITextField* tf = ((KLUITextFieldCell*)cell).textField;
    tf.text = text;
    tf.textAlignment = UITextAlignmentCenter;
    tf.returnKeyType = UIReturnKeyDone;
    tf.delegate = self;
    tf.tag = indexPath.row;
    
    // 新規追加時の最終行および編集モード時の2行目以降は編集可、それ以外は編集不可
    if ((_adding && indexPath.row == workbooks.count) || (self.editing && indexPath.row > 0)) {
        tf.enabled = YES;
    } else {
        tf.enabled = NO;
    }
    
    if (workbook == [KSLProblemManager sharedManager].currentWorkbook) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark - Action

- (IBAction)addAction
{
    // 末尾に行を追加
    _adding = YES;
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:
                              [self.tableView numberOfRowsInSection:0] inSection:0];
    NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexPaths
                      withRowAnimation:UITableViewRowAnimationBottom];
    [self.tableView endUpdates];
    
    // スクロール
    // endUpdateの前に実行すると、エラー
    [self.tableView scrollToRowAtIndexPath:indexPath
                      atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    // フォーカスの設定
    KLUITextFieldCell* cell = (KLUITextFieldCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell.textField becomeFirstResponder];
}

- (IBAction)endAction
{
    KLUITextFieldCell* cell = [self findRenamingCell];
    [cell.textField resignFirstResponder];
}


#pragma mark - UITableView データソース

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [KSLProblemManager sharedManager].workbooks.count + (_adding ? 1 : 0);
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"WorkbookListCell"];
    if (!cell) {
        cell = [[KLUITextFieldCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"WorkbookListCell"];
    }
    
    // セルの値を更新する
    [self updateCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    NSInteger current = [pm indexOfWorkbook:pm.currentWorkbook];
    return indexPath.row != current;
}

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    return NO;
}

- (void)tableView:(UITableView*)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
    forRowAtIndexPath:(NSIndexPath*)indexPath
{
    KSLWorkbook* workbook = [[KSLProblemManager sharedManager].workbooks objectAtIndex:indexPath.row];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        _deletingRow = indexPath.row;
        if (workbook.problems.count > 0) {
            // 削除操作の場合
            // アラートを表示する
            UIAlertView *alert = nil;
            RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"キャンセル" action:nil];
            RIButtonItem *deleteItem = [RIButtonItem itemWithLabel:@"削除" action:^{
                [self removeSelectedWorkbook];
            }];
            alert = [[UIAlertView alloc] initWithTitle:@"問題集の削除"
                            message:@"含まれている全ての問題も同時に削除されます。\n%@を削除してもよろしいですか？"
                            cancelButtonItem:cancelItem
                            otherButtonItems:deleteItem, nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
        } else {
            [self removeSelectedWorkbook];
        }
    }
}

#pragma mark - UITableView デリゲート

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    KSLWorkbook *workbook = [[KSLProblemManager sharedManager].workbooks objectAtIndex:indexPath.row];
    
    [_delegate workbookListViewControllerWorkbookDidSelect:workbook];
}

#pragma mark - UITextField デリゲート

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (!_adding) {
        _renaming = YES;
    }
    [self updateNavigationItemAnimated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    NSString* text = [textField.text stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (_adding) {
        // 末尾の行が空なら、行を削除、入力されていれば問題集を追加
        _adding = NO;
        if (text.length == 0) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:
                                      [self.tableView numberOfRowsInSection:0]-1 inSection:0];
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationBottom];
            [self.tableView endUpdates];
        } else {
            KSLProblemManager *pm = [KSLProblemManager sharedManager];
            if ([pm findWorkbook:text]) {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"問題集"
                                      message:@"その名称の問題集が既に存在します。異なる名称を指定して下さい。"
                                      delegate:nil cancelButtonTitle:nil
                                      otherButtonTitles:@"了解", nil];
                [alert show];
                _adding = YES;
                textField.text = @"";
                [textField  becomeFirstResponder];
                return;
            }
            KSLWorkbook* workbook = [[KSLWorkbook alloc] initWithTitle:text];
            [pm addWorkbook:workbook];
            textField.enabled = NO;
        }
    } else {
        _renaming = NO;
        KLUITextFieldCell* cell = [self findCellForTextField:textField];
        NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
        KSLProblemManager *pm = [KSLProblemManager sharedManager];
        KSLWorkbook* workbook = [pm.workbooks objectAtIndex:indexPath.row];
        
        if (text.length > 0) {
            if ([text compare:workbook.title] != NSOrderedSame) {
                if ([pm findWorkbook:text]) {
                    UIAlertView *alert = [[UIAlertView alloc]
                                          initWithTitle:@"問題集"
                                          message:@"その名称の問題集が既に存在します。異なる名称を指定して下さい。"
                                          delegate:nil cancelButtonTitle:nil
                                          otherButtonTitles:@"了解", nil];
                    [alert show];
                    _renaming = YES;
                    textField.text = @"";
                    [textField  becomeFirstResponder];
                    return;
                }
                // 本棚の名称を変更する
                workbook.title = text;
                [_delegate workbookListViewControllerWorkbookDidRename:workbook];
            }
        } else {
            textField.text = workbook.title;
        }
    }
    
    // ボタンの更新
    [self updateNavigationItemAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (KLUITextFieldCell*)findCellForTextField:(UITextField*)textField
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:
                             [NSIndexPath indexPathForRow:textField.tag inSection:0]];
    return (KLUITextFieldCell*)cell;
}

- (KLUITextFieldCell*)findRenamingCell
{
    NSInteger nRows = [self.tableView numberOfRowsInSection:0];
    for (NSInteger row = 0; row < nRows; row++) {
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:
                                 [NSIndexPath indexPathForRow:row inSection:0]];
        UITextField* tf = ((KLUITextFieldCell*)cell).textField;
        if (tf.isFirstResponder) {
            return (KLUITextFieldCell*)cell;
        }
    }
    return nil;
}

- (void)removeSelectedWorkbook
{
    // ドキュメントを削除する
    [[KSLProblemManager sharedManager] removeWorkbookAtIndex:_deletingRow];
    
    // テーブルの行を削除する
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:
                                        [NSIndexPath indexPathForRow:_deletingRow inSection:0]]
                      withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
    
    
}

@end
