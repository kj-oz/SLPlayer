//
//  KSLAddProblemViewController.m
//  SLPlayer
//
//  Created by KO on 2014/01/04.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLProblemEditViewController.h"
#import "KSLProblemDetector.h"
#import "KSLBoard.h"
#import "KSLSolver.h"
#import "KSLProblem.h"
#import "KSLPlayer.h"
#import "KSLProblemView.h"
#import "KSLHelpViewController.h"
#import "UIAlertView+Blocks.h"

#pragma mark - エクステンション

@interface KSLProblemEditViewController ()

// 拡大ビュー
@property (weak, nonatomic) IBOutlet KSLProblemView *problemView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;

// 状態表示ラベル
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

// 撮影ボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;

// 既存の写真からの選択ボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pictureButton;

// 新規作成ボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *createButton;

// 問題が正しいかどうかのチェックのボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *checkButton;

// ヘルプボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *helpButton;

@end


#pragma mark - 実装

@implementation KSLProblemEditViewController
{
    // プレイヤ・オブジェクト
    KSLPlayer *_player;
    
    // 直前のアクション
    KSLAction *_lastAction;    
}

#pragma mark - ビューのライフサイクル

// このビューは、バックグラウンドにまわっても特に何の対処もしない.
// バックグランド中にアプリケーションが終了した場合、キャンセルされた場合と同様の結果となる.

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _player = [[KSLPlayer alloc] initWithProblem:_problem];

    // 本来awakeFromNibで設定するはずだが、そのタイミングでは何故かいずれもnil
    _problemView.delegate = self;
    _problemView.mode = _problem.status == KSLProblemStatusEditing ?
                KSLProblemViewModeInputNumber : KSLProblemViewModeScroll;
    
    self.title = _addNew ? @"新規追加" : _problem.title;
    [self setBoard:_player.board];
    [self updateProblemInfo];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _player = nil;
}

#pragma mark - プライベートメソッド

- (void)setBoard:(KSLBoard *)board
{
    _problemView.board = board;
}

- (void)actionPerformed:(KSLAction *)action
{
    if (action.target == _lastAction.target) {
        
    }
    // TODO 直前のアクションとtargetが同じならまとめる
    //[_step addObject:action];
}

#pragma mark - 各種アクション

/**
 * 撮影ボタン押下時
 */
- (IBAction)cameraClicked:(id)sender
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera sender:sender];
}

/**
 * 画像選択ボタン押下時
 */
- (IBAction)pictureClicked:(id)sender
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary sender:sender];
}

/**
 * 新規作成ボタン押下時
 */
- (IBAction)createClicked:(id)sender
{
    __block UIAlertView *alert = nil;
    __block NSString *badInput = nil;
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"キャンセル" action:nil];
    RIButtonItem *deleteItem = [RIButtonItem itemWithLabel:@"生成" action:^{
        NSInteger w = 0;
        NSInteger h = 0;
        NSString *input = [alert textFieldAtIndex:0].text;
        NSCharacterSet *cs = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        NSArray *parts = [input componentsSeparatedByCharactersInSet:cs];
        if (!parts || [parts count] < 2) {
            badInput = input;
        } else {
            w = [parts[0] intValue];
            h = [parts[1] intValue];
            if (!w || !h) {
                badInput = input;
            }
        }
        [alert dismissWithClickedButtonIndex:1 animated:YES];
        
        if (badInput) {
            UIAlertView *subAlert = [[UIAlertView alloc]
                                     initWithTitle:@"入力エラー"
                                     message:@"問題の大きさが不正です。"
                                     delegate:nil cancelButtonTitle:nil
                                     otherButtonTitles:@"了解", nil];
            [subAlert show];
        } else {
            int *data = calloc(w * h, sizeof(int));
            for (NSInteger i = 0, n = w * h; i < n; i++) {
                data[i] = -1;
            }
            
            KSLProblem *problem = [[KSLProblem alloc] initWithWidth:w andHeight:h data:data];
            self.problem = problem;
            [self setBoard:[[KSLBoard alloc] initWithProblem:problem]];
            [self updateProblemInfo];
        }
    }];
    alert = [[UIAlertView alloc] initWithTitle:@"新規問題"
                                        message:@"問題の大きさを 整数x整数 の形式で入力して下さい。"
                                        cancelButtonItem:cancelItem
                                        otherButtonItems:deleteItem, nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

/**
 * チェックボタン押下時
 */
- (IBAction)checkClicked:(id)sender
{
    KSLSolver *solver = [[KSLSolver alloc] initWithBoard:[[KSLBoard alloc] initWithProblem:_problem]];
    NSError *error;
    if ([solver solveWithError:&error]) {
        _problem.status = KSLProblemStatusNotStarted;
    }
    [self showProblemCheckMessage:error];
    
    [self updateProblemInfo];
}

/**
 * ヘルプボタン押下時
 */
- (IBAction)helpClicked:(id)sender {
    
}

/**
 * 完了ボタン押下時
 */
- (IBAction)doneClicked:(id)sender
{
    NSString *title = [self.titleText.text
                       stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([title isEqualToString:@"未定"] || ![title length]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"名称"
                              message:@"正しい名称を入力して下さい。"
                              delegate:nil cancelButtonTitle:nil
                              otherButtonTitles:@"了解", nil];
        [alert show];
        return;
    }
    NSInteger difficulty = [self.difficultyText.text integerValue];
    if (difficulty < 1 || difficulty > 10) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"難易度"
                              message:@"10までの整数を入力して下さい。"
                              delegate:nil cancelButtonTitle:nil
                              otherButtonTitles:@"了解", nil];
        [alert show];
        return;
    }
    [self performSegueWithIdentifier:@"DoneEditProblem" sender:self];
}

#pragma mark - セグエ関係

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowEditHelp"]) {
        KSLHelpViewController *hv = (KSLHelpViewController *)segue.destinationViewController;
        NSBundle *bundle = [NSBundle mainBundle];
        NSURL *url = [bundle URLForResource:@"editview" withExtension:@"html" subdirectory:@"www"];
        hv.url = url;
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
                    didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    // 画像認識
    KSLProblemDetector *ir = [KSLProblemDetector new];
    KSLProblem *problem = [ir detectProblemFromImage:image];
    if (!problem) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"認識エラー"
                        message:@"問題を認識できませんでした。" delegate:nil
                        cancelButtonTitle:nil otherButtonTitles:@"了解", nil];
        [alert show];
        return;
    }

    // 問題チェック
    [problem dump];
    KSLSolver *solver = [[KSLSolver alloc] initWithBoard:[[KSLBoard alloc] initWithProblem:problem]];
    NSError *error;
    if (![solver solveWithError:&error]) {
        [self showProblemCheckMessage:error];
        problem.status = KSLProblemStatusEditing;
    }
    self.problem = problem;
    _player = [[KSLPlayer alloc] initWithProblem:_problem];
    [self setBoard:_player.board];
    [self updateProblemInfo];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - ヘルパメソッド群

/**
 * イメージピッカーを表示する.
 * @param sourceType イメージピッカーのタイプ（撮影、ライブラリ）
 * @param sender イベント発生元
 */
- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType sender:(id)sender
{
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        imagePickerController.sourceType = sourceType;
        imagePickerController.delegate = self;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

/**
 * 問題情報の表示内容の更新
 */
- (void)updateProblemInfo
{
    _titleText.text = _problem.title;
    _difficultyText.text = [NSString stringWithFormat:@"%ld", (long)_problem.difficulty];
    _statusLabel.text = _addNew ? _problem.sizeString : [NSString stringWithFormat:@"%@　　%@",
                                                         _problem.sizeString, _problem.statusString];
    
    if (!_addNew) {
        NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self.toolBar items]];
        NSMutableArray *removeItems = [NSMutableArray array];
        for (UIBarButtonItem *item in items) {
            if (item == self.cameraButton || item == self.pictureButton ||
                    item == self.createButton) {
                [removeItems addObject:item];
            }
        }
        [items removeObjectsInArray:removeItems];
        [self.toolBar setItems:items];
//        self.cameraButton.enabled = NO;
//        self.pictureButton.enabled = NO;
//        self.createButton.enabled = NO;
    }
    if (_problem.status != KSLProblemStatusEditing) {
        self.checkButton.enabled = NO;
    }
    _problemView.mode = _problem.status == KSLProblemStatusEditing ?
                KSLProblemViewModeInputNumber : KSLProblemViewModeScroll;
    [self refreshBoard];
}

/**
 * 盤面のビューの更新
 */
- (void)refreshBoard
{
    [_problemView setNeedsDisplay];
}

/**
 * 問題が完成しているかチェックした結果を、アラートに表示する
 * @param error エラーコード、問題が完成している場合はnil;
 */
- (void)showProblemCheckMessage:(NSError *)error
{
    UIAlertView *alert = nil;
    if (error) {
        switch (error.code) {
            case KSLSolverErrorNoLoop:
                alert = [[UIAlertView alloc] initWithTitle:@"不完全な問題"
                                                   message:@"解答が存在しません。" delegate:nil
                                         cancelButtonTitle:nil otherButtonTitles:@"了解", nil];
                break;
            case KSLSolverErrorMultipleLoops:
                alert = [[UIAlertView alloc] initWithTitle:@"不完全な問題"
                                                   message:@"複数の解答が存在します。" delegate:nil
                                         cancelButtonTitle:nil otherButtonTitles:@"了解", nil];
                break;
        }
    } else {
        alert = [[UIAlertView alloc] initWithTitle:@"問題の完成"
                                           message:@"問題が完成しました。" delegate:nil
                                 cancelButtonTitle:nil otherButtonTitles:@"了解", nil];
    }
    [alert show];
}

@end
