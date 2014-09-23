//
//  KSLProblemListViewController.m
//  SLPlayer
//
//  Created by KO on 2014/02/02.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLProblemListViewController.h"
#import "KSLProblemEditViewController.h"
#import "KSLProblemManager.h"
#import "KSLWorkbook.h"
#import "KSLProblem.h"
#import "KLDBGUtil.h"
#import "KSLAppDelegate.h"
#import "KSLWorkbookListViewController.h"
#import "KSLProblemListCell.h"
#import "UIAlertView+Blocks.h"

#pragma mark - エクステンション

@interface KSLProblemListViewController ()

// 問題集ボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *workbookButton;

@end


#pragma mark - 実装

@implementation KSLProblemListViewController
{
    // 現在編集中の問題
    KSLProblem *_editingProblem;
    
    // 問題集一覧画面のコントローラ
    KSLWorkbookListViewController *_workbookList;
    
    // 削除ボタン
    UIBarButtonItem *deleteButton;
    
    // 複写ボタン
    UIBarButtonItem *copyButton;

    // 修正ボタン
    UIBarButtonItem *modifyButton;
    
    // 追加ボタン
    UIBarButtonItem *addButton;
    
    // カレントのポップアップ画面に対するコントローラ
    UIPopoverController *_poController;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"削除" style:UIBarButtonItemStylePlain
                                        target:self action:@selector(deleteClicked:)];
    copyButton = [[UIBarButtonItem alloc] initWithTitle:@"複製" style:UIBarButtonItemStylePlain
                                        target:self action:@selector(copyClicked:)];
    modifyButton = [[UIBarButtonItem alloc] initWithTitle:@"修正" style:UIBarButtonItemStylePlain
                                        target:self action:@selector(modifyClicked:)];
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                        target:self action:@selector(addClicked:)];
    
    self.editing = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    KSLAppDelegate *app = [UIApplication sharedApplication].delegate;
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    self.title = pm.currentWorkbook.title;

    NSUInteger problemIndex;
    if (app.restoring) {
        if (app.lastProblem) {
            problemIndex = [pm.currentWorkbook.problems indexOfObject:app.lastProblem];
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:problemIndex inSection:0]
                                        animated:NO scrollPosition:UITableViewScrollPositionBottom];
        }
        
        if ([app.lastView isEqualToString:@"Play"]) {
            [self performSegueWithIdentifier:@"PlayProblem" sender:self];
        } else if ([app.lastView isEqualToString:@"Edit"]) {
            //TODO 編集ビューの状態保存は将来対応予定
            //self.editing = YES;
            //[self performSegueWithIdentifier:@"EditProblem" sender:self];
        }
        app.restoring = NO;
    } else if ([app.currentView isEqualToString:@"Play"]) {
        // Backボタンで戻った場合には、アクションは発生しないためここで処理
        problemIndex = [pm.currentWorkbook.problems indexOfObject:pm.currentProblem];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:problemIndex inSection:0];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self updateCell:cell atIndexPath:indexPath];
        
        pm.currentProblem = nil;
        app.currentView = @"List";
    }
}


#pragma mark - 編集モード

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    // テーブルビューの編集モードを設定する
    // ボタンのキャプションを日本語にするためには、①PROJECTのLocalizationsにJapaneseを追加、
    // ②info.plistのLocalization native development regionをJapanに設定
    // シミュレータでも日本語にするには、環境設定でInternationalizationを設定
    [self.tableView setEditing:editing animated:animated];
    
    // ナビゲーションボタンを更新する
    [self updateNavigationItemAnimated:animated];
}

#pragma mark - プライベートメッソド（各種アクション）

/**
 * 追加（＋）ボタン押下
 */
- (IBAction)addClicked:(id)sender
{
    [self performSegueWithIdentifier:@"AddProblem" sender:sender];
}

/**
 * 修正ボタン押下
 */
- (IBAction)modifyClicked:(id)sender
{
    [self performSegueWithIdentifier:@"EditProblem" sender:sender];
}

/**
 * 削除ボタン押下
 */
- (IBAction)deleteClicked:(id)sender
{
    UIAlertView *alert = nil;
    NSArray *problems = [self selectedProblems];
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"キャンセル" action:nil];
    RIButtonItem *deleteItem = [RIButtonItem itemWithLabel:@"削除" action:^{
        KSLWorkbook *wb = [KSLProblemManager sharedManager].currentWorkbook;
        for (KSLProblem *problem in problems) {
            [wb removeProblem:problem withDelete:YES];
        }
        [self.tableView reloadData];
    }];
    NSString *msg = [NSString stringWithFormat:
                     @"選択されている%ld個の問題が削除されます。\n削除してもよろしいですか？",
                     (unsigned long)problems.count];
    alert = [[UIAlertView alloc] initWithTitle:@"問題の削除" message:msg
                              cancelButtonItem:cancelItem
                              otherButtonItems:deleteItem, nil];
    [alert show];
}

/**
 * 複写ボタン押下
 */
- (IBAction)copyClicked:(id)sender {
    NSArray *problems = [self selectedProblems];
    KSLWorkbook *wb = [KSLProblemManager sharedManager].currentWorkbook;
    for (KSLProblem *problem in problems) {
        [wb copyProblem:problem];
    }
    [self.tableView reloadData];
}

#pragma mark - Tableビューのデータソース・デリゲート

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    return pm.currentWorkbook.problems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProblemCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                            forIndexPath:indexPath];
    [self updateCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    KSLProblem *problem = pm.currentWorkbook.problems[indexPath.row];
    if (self.editing) {
        modifyButton.enabled = [self.tableView indexPathsForSelectedRows].count == 1;
        copyButton.enabled = YES;
        _workbookButton.enabled = YES;
        deleteButton.enabled = YES;
    } else {
        if (problem.status != KSLProblemStatusEditing) {
            [self performSegueWithIdentifier:@"PlayProblem" sender:self];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        NSUInteger count = [self.tableView indexPathsForSelectedRows].count;
        modifyButton.enabled = count == 1;
        if (!count) {
            copyButton.enabled = NO;
            _workbookButton.enabled = NO;
            deleteButton.enabled = NO;
        }
    }
}

#pragma mark - セグエ関係

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    KLDBGPrintMethodName(">>");
    KSLAppDelegate *app = [UIApplication sharedApplication].delegate;
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    
    if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
        if (_poController) {
            [_poController dismissPopoverAnimated:NO];
        }
        _poController = ((UIStoryboardPopoverSegue*)segue).popoverController;
        _poController.delegate = self;
        
        // ナビゲーションバーのenabledをNoにしないと、Popoverを表示したままナビゲーションバーの操作ができてしまう.
        self.navigationController.navigationBar.userInteractionEnabled = NO;
    }

    if ([segue.identifier isEqualToString:@"PlayProblem"]) {
        KSLProblem *problem = pm.currentWorkbook.problems[[self.tableView indexPathForSelectedRow].row];
        pm.currentProblem = problem;
        app.currentView = @"Play";
    } else if ([segue.identifier isEqualToString:@"EditProblem"]) {
        UINavigationController *nc = (UINavigationController *)segue.destinationViewController;
        KSLProblemEditViewController *pev = (KSLProblemEditViewController *)nc.topViewController;
        KSLProblem *problem = pm.currentWorkbook.problems[[self.tableView indexPathForSelectedRow].row];
        pev.problem = [[KSLProblem alloc] initWithProblem:problem];
        pev.addNew = NO;
        pm.currentProblem = problem;
        app.currentView = @"Edit";
    } else if ([segue.identifier isEqualToString:@"AddProblem"]) {
        UINavigationController *nc = (UINavigationController *)segue.destinationViewController;
        KSLProblemEditViewController *pev = (KSLProblemEditViewController *)nc.visibleViewController;
        pev.problem = [[KSLProblem alloc] initWithWidth:10 andHeight:20 data:nil];
        pev.addNew = YES;
        app.currentView = @"Edit";
    } else if ([segue.identifier isEqualToString:@"ShowWorkbookList"]) {
        UINavigationController *nc = (UINavigationController *)segue.destinationViewController;
        KSLWorkbookListViewController *wlv = (KSLWorkbookListViewController *)nc.visibleViewController;
        wlv.delegate = self;
    }
}

/**
 * 問題追加・編集画面からのDoneによる復帰
 */
- (IBAction)doneProblemEdit:(UIStoryboardSegue *)segue
{
    KSLAppDelegate *app = [UIApplication sharedApplication].delegate;
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    
    KSLProblemEditViewController *pev = (KSLProblemEditViewController *)segue.sourceViewController;
    pev.problem.title = pev.titleText.text;
    pev.problem.difficulty = [pev.difficultyText.text integerValue];
    
    if (pev.addNew) {
        [pm.currentWorkbook addProblem:pev.problem withSave:YES];
        [self.tableView reloadData];
    } else {
        KSLProblem *problem = pm.currentProblem;
        [problem updateWithProblem:pev.problem];
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self updateCell:cell atIndexPath:indexPath];
    }
    pm.currentProblem = nil;
    app.currentView = @"List";
}

/**
 * 問題追加・編集画面からのCancelによる復帰
 */
- (IBAction)cancelProblemEdit:(UIStoryboardSegue *)segue
{
    KSLAppDelegate *app = [UIApplication sharedApplication].delegate;
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    
    pm.currentProblem = nil;
    app.currentView = @"List";
}

#pragma mark - KSLWorkbookListViewControllerDelegate

- (void)workbookListViewControllerWorkbookDidSelect:(KSLWorkbook *)workbook
{
    if (!self.editing) {
        [self changeWorkbook:workbook];
    } else {
        [self moveSelectedProblemsToWorkbook:workbook];
    }
    
    // コントローラを隠す
    [_poController dismissPopoverAnimated:YES];
    _poController = nil;
    
    // 強制的にdismissした場合、PopoverのpopoverControllerDidDismissPopover:は呼び出されない
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

- (void)workbookListViewControllerWorkbookDidRename:(KSLWorkbook *)workbook
{
    if ([KSLProblemManager sharedManager].currentWorkbook == workbook) {
        self.title = workbook.title;
    }
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    // 強制的にdismissした場合、PopoverのpopoverControllerDidDismissPopover:は呼び出されない
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

#pragma mark - プライベートメソッド（問題の扱い）

/**
 * 問題集の定義を変更する
 * @param workbook 対象の問題集
 */
- (void)changeWorkbook:(KSLWorkbook *)workbook
{
    [KSLProblemManager sharedManager].currentWorkbook = workbook;
    self.title = workbook.title;
    [self.tableView reloadData];
}

/**
 * 選択されている問題を与えれた問題集へ移す
 * @param workbook 対象の問題集
 */
- (void)moveSelectedProblemsToWorkbook:(KSLWorkbook *)workbook
{
    NSArray* problems = [self selectedProblems];
    
    // 実体を移動する
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    [pm moveProblems:problems toWorkbook:workbook];
    
    [self.tableView reloadData];
}

#pragma mark - プライベートメソッド（画面の更新）

/**
 * ナビゲーションバー上のボタンを状況に応じて更新する.
 * @param animated アニメーションの有無
 */
- (void)updateNavigationItemAnimated:(BOOL)animated
{
    // setLeftBarButtonItems と setLeftBarButtonItem を状況によって使い分けると、setLeftBarButtonItem
    // 実行時にエラーになるので１つしかない場合も、setLeftBarButtonItems を使用する
    if (self.editing) {
        _workbookButton.title = @"移動";
        [self.navigationItem setLeftBarButtonItems:
         @[modifyButton, copyButton, _workbookButton, deleteButton] animated:animated];
        [self.navigationItem setRightBarButtonItems:
         @[[self editButtonItem]] animated:animated];
        modifyButton.enabled = NO;
        copyButton.enabled = NO;
        _workbookButton.enabled = NO;
        deleteButton.enabled = NO;
    } else {
        _workbookButton.title = @"問題集";
        _workbookButton.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:
         @[_workbookButton] animated:animated];
        [self.navigationItem setRightBarButtonItems:
         @[[self editButtonItem], addButton] animated:animated];
    }
}

/**
 * セルの表示を更新する.
 * @param cell 対象のセル
 * @param indexPath セルのインデックス
 */
- (void)updateCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    KSLProblem *problem = pm.currentWorkbook.problems[indexPath.row];
    KSLProblemListCell *problemCell = (KSLProblemListCell *)cell;
    problemCell.titleLabel.text = problem.title;
    problemCell.sizeLabel.text = [problem sizeString];
    problemCell.difficultyLabel.text = [problem difficultyString];
    if (problem.status != KSLProblemStatusNotStarted) {
        problemCell.statusLabel.text = [problem statusString];
    } else {
        problemCell.statusLabel.text = @"";
    }
    
    if (problem.status == KSLProblemStatusSolved) {
        [self setCell:problemCell enabled:YES color:[UIColor blackColor]];
    } else if (!self.editing && problem.status == KSLProblemStatusEditing) {
        [self setCell:problemCell enabled:NO color:nil];
    } else {
        [self setCell:problemCell enabled:YES color:[UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0]];
    }
}

/**
 * 問題セルのenable/disableとenableの場合の色を設定する.
 * @param cell 対象の問題用セル
 * @param enabled enable/disable
 * @param color enabeの場合の文字色
 */
- (void)setCell:(KSLProblemListCell *)cell enabled:(BOOL)enabled color:(UIColor *)color
{
    cell.titleLabel.enabled = enabled;
    cell.sizeLabel.enabled = enabled;
    cell.difficultyLabel.enabled = enabled;
    cell.statusLabel.enabled = enabled;
    
    if (enabled) {
        cell.titleLabel.textColor = color;
        cell.sizeLabel.textColor = color;
        cell.difficultyLabel.textColor = color;
        cell.statusLabel.textColor = color;
    }
}

#pragma mark - プライベートメソッド（その他）

/**
 * その時点で画面で選択されている問題の配列を得る
 * @return その時点で画面で選択されている問題の配列
 */
- (NSArray *)selectedProblems
{
    NSMutableArray *problems = [NSMutableArray array];
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    NSArray *currProblems = pm.currentWorkbook.problems;
    for (NSIndexPath *path in [self.tableView indexPathsForSelectedRows]) {
        [problems addObject:currProblems[path.row]];
    }
    return problems;
}

@end
