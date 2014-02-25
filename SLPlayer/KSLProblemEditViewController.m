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
#import "KSLBoardOverallView.h"
#import "KSLBoardZoomedView.h"

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

// 評価入力欄
@property (weak, nonatomic) IBOutlet UITextField *evaluationText;

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
    // 全てKSLProblemViewDelegateのプロパティ用変数
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
}

- (void)setZoomedArea:(CGRect)zoomedArea
{
    _zoomedArea = zoomedArea;
    [_overallView setNeedsDisplay];
    [_zoomedView setNeedsDisplay];
}

- (IBAction)cameraClicked:(id)sender
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera sender:sender];
}

- (IBAction)pictureClicked:(id)sender
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary sender:sender];
}

- (IBAction)createClicked:(id)sender
{
    
}
- (IBAction)checkClicked:(id)sender {
}
- (IBAction)panClicked:(id)sender
{
    _zoomedView.mode = KSLProblemViewModeScroll;
}
- (IBAction)inputClicked:(id)sender
{
    _zoomedView.mode = KSLProblemViewModeInputNumber;
}
- (IBAction)undoClicked:(id)sender {
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType sender:(id)sender
{
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        imagePickerController.sourceType = sourceType;
        imagePickerController.delegate = self;
        UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imgPicker.delegate = self;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker
                    didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    // 画像認識
    KSLProblemDetector *ir = [KSLProblemDetector new];
    KSLProblem *problem = [ir detectProblemFromImage:image];
    if (!problem) {
        // TODO 認識エラーのメッセージの表示
        return;
    }

    // 問題チェック
    KSLSolver *solver = [[KSLSolver alloc] initWithBoard:[[KSLBoard alloc] initWithProblem:problem]];
    NSError *error;
    if (![solver solveWithError:&error]) {
        switch (error.code) {
            case KSLSolverErrorNoLoop:
                // TODO メッセージ表示
            case KSLSolverErrorMultipleLoops:
                // TODO メッセージ表示
                return;
        }
        problem.status = KSLProblemStatusEditing;
    }
    self.problem = problem;
    [self setBoard:[[KSLBoard alloc] initWithProblem:problem]];
    [self updateProblemInfo];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)updateProblemInfo
{
    _titleText.text = _problem.title;
    _sizeLabel.text = [NSString stringWithFormat:@"サイズ：%d X %d", _problem.width, _problem.height];
    _difficultyText.text = [NSString stringWithFormat:@"%d", _problem.difficulty];
    _statusLabel.text = _problem.statusString;
    _evaluationText.text = [NSString stringWithFormat:@"%d", _problem.evaluation];
    _elapsedLabel.text = _problem.elapsedTimeString;
    
    if (!_addNew) {
        
    }
}

@end
