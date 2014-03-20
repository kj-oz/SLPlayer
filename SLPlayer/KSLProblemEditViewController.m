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
#import "KSLBoardOverallView.h"
#import "KSLBoardZoomedView.h"
#import "UIAlertView+Blocks.h"

#pragma mark - エクステンション

@interface KSLProblemEditViewController ()

// 全体ビュー
@property (weak, nonatomic) IBOutlet KSLBoardOverallView *overallView;

// 拡大ビュー
@property (weak, nonatomic) IBOutlet KSLBoardZoomedView *zoomedView;

// 問題名称入力欄
@property (weak, nonatomic) IBOutlet UITextField *titleText;

// 難易度入力欄
@property (weak, nonatomic) IBOutlet UITextField *difficultyText;

// 評価選択セグメント
@property (weak, nonatomic) IBOutlet UISegmentedControl *evaluationSegmentedCtrl;

// 盤面サイズ表示ラベル
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;

// 状態表示ラベル
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

// 経過時間表示ラベル
@property (weak, nonatomic) IBOutlet UILabel *elapsedLabel;

// 撮影ボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;

// 既存の写真からの選択ボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pictureButton;

// 新規作成ボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *createButton;

// 問題が正しいかどうかのチェックのボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *checkButton;

// モード選択セグメント
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeSegmentedCtrl;

// アンドゥボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *undoButton;

@end


#pragma mark - 実装

@implementation KSLProblemEditViewController
{
    // プレイヤ・オブジェクト
    KSLPlayer *_player;
    
    // 直前のアクション
    KSLAction *_lastAction;
    
    // 以下KSLProblemViewDelegateのプロパティ用変数
    // 盤面オブジェクト
    KSLBoard *_board;
    
    // 問題座標系での拡大領域
    CGRect _zoomedArea;
    
    // 問題座標系での問題の全領域
    CGRect _problemArea;
}

// プロトコルのプロパティの内部変数は自動設定してくれない
@synthesize board = _board;
@synthesize zoomedArea = _zoomedArea;
@synthesize problemArea = _problemArea;


#pragma mark - ビューのライフサイクル

// このビューは、バックグラウンドにまわっても特に何の対処もしない.
// バックグランド中にアプリケーションが終了した場合、キャンセルされた場合と同様の結果となる.

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 本来awakeFromNibで設定するはずだが、そのタイミングでは何故かいずれもnil
    _overallView.delegate = self;
    _zoomedView.delegate = self;
    _zoomedView.mode = KSLProblemViewModeScroll;
    
    self.title = _addNew ? @"新規追加" : _problem.title;
    [self setBoard:[[KSLBoard alloc] initWithProblem:_problem]];
    [self updateProblemInfo];
}

#pragma mark - ビューの回転

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationLandscapeRight | UIInterfaceOrientationLandscapeLeft;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeRight;
}

#pragma mark - KSLProblemViewDelegateの実装

- (void)setBoard:(KSLBoard *)board
{
    _board = board;
    _problemArea = CGRectMake(-KSLPROBLEM_MARGIN, -KSLPROBLEM_MARGIN,
                              board.width + 2 * KSLPROBLEM_MARGIN, board.height + 2 * KSLPROBLEM_MARGIN);
    CGFloat zoomedW = _zoomedView.frame.size.width / KSLPROBLEM_MINIMUM_PITCH;
    CGFloat zoomedH = _zoomedView.frame.size.height / KSLPROBLEM_MINIMUM_PITCH;
    CGRect zoomArea = CGRectMake(-KSLPROBLEM_MARGIN, -KSLPROBLEM_MARGIN, zoomedW, zoomedH);
    [self setZoomedArea:zoomArea];
    
    _lastAction = nil;
}

- (void)setZoomedArea:(CGRect)zoomedArea
{
    _zoomedArea = zoomedArea;
    [_overallView setNeedsDisplay];
    [_zoomedView setNeedsDisplay];
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
 * 新規作成ボタン押下時
 */
- (IBAction)createClicked:(id)sender
{
    UIAlertView *alert = nil;
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
 * モード選択セグメント変更時
 */
- (IBAction)modeChanged:(id)sender
{
    switch (self.modeSegmentedCtrl.selectedSegmentIndex) {
        case 0:
            _zoomedView.mode = KSLProblemViewModeScroll;
            break;
        case 1:
            _zoomedView.mode = KSLProblemViewModeInputNumber;
            break;
    }
}

/**
 * アンドゥボタン押下時
 */
- (IBAction)undoClicked:(id)sender
{
    if (_player.currentIndex >= 0) {
        [_player undo];
        _lastAction = nil;
        [self refreshBoard];
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
    KSLSolver *solver = [[KSLSolver alloc] initWithBoard:[[KSLBoard alloc] initWithProblem:problem]];
    NSError *error;
    if (![solver solveWithError:&error]) {
        [self showProblemCheckMessage:error];
        problem.status = KSLProblemStatusEditing;
    }
    self.problem = problem;
    [self setBoard:[[KSLBoard alloc] initWithProblem:problem]];
    [self updateProblemInfo];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - ヘルパメソッド群

/**
 * 問題情報の表示内容の更新
 */
- (void)updateProblemInfo
{
    _titleText.text = _problem.title;
    _sizeLabel.text = [NSString stringWithFormat:@"%ld X %ld", _problem.width, _problem.height];
    _difficultyText.text = [NSString stringWithFormat:@"%ld", _problem.difficulty];
    _statusLabel.text = _problem.statusString;
    _evaluationSegmentedCtrl.selectedSegmentIndex = _problem.evaluation - 1;
    _elapsedLabel.text = _problem.elapsedTimeString;
    
    if (!_addNew) {
        self.cameraButton.enabled = NO;
        self.pictureButton.enabled = NO;
        self.createButton.enabled = NO;
        self.modeSegmentedCtrl.enabled = NO;
    }
    if (_problem.status != KSLProblemStatusEditing) {
        self.checkButton.enabled = NO;
    }
}

/**
 * 盤面のビューの更新
 */
- (void)refreshBoard
{
    [_overallView setNeedsDisplay];
    [_zoomedView setNeedsDisplay];
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
