//
//  KSLProblemViewController.m
//  SLPlayer
//
//  Created by KO on 2014/01/02.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLProblemPlayViewController.h"
#import "KSLBoardOverallView.h"
#import "KSLBoardZoomedView.h"
#import "KSLBoard.h"
#import "KSLProblem.h"
#import "KSLPlayer.h"
#import "KSLProblemManager.h"
#import "UIAlertView+Blocks.h"

#pragma mark - エクステンション

@interface KSLProblemPlayViewController ()

// 全体ビュー
@property (weak, nonatomic) IBOutlet KSLBoardOverallView *overallView;

// 拡大ビュー
@property (weak, nonatomic) IBOutlet KSLBoardZoomedView *zoomedView;

// クリアボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *clearButton;

// 固定ボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *fixButton;

// モード選択セグメント
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeSegmentedCtrl;

// アンドゥボタン
@property (weak, nonatomic) IBOutlet UIBarButtonItem *undoButton;

// 難易度表示ラベル
@property (weak, nonatomic) IBOutlet UILabel *difficultyLabel;

// 経過時間表示ラベル
@property (weak, nonatomic) IBOutlet UILabel *elapsedLabel;

@end


#pragma mark - 実装

@implementation KSLProblemPlayViewController
{
    // プレイヤ・オブジェクト
    KSLPlayer *_player;
    
    // 1ステップ分の複数のアクションを保持する配列、同じ配列を使い回す.
    NSMutableArray *_step;
    
    // プレイ開始時刻
    NSDate *_start;
    
    // プレイ開始時刻の経過秒数
    NSInteger _elapsed;
    
    // 経過時間の更新処理用のタイマー
    NSTimer *_timer;

    // 以下、KSLProblemViewDelegateのプロパティ用変数
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 本来awakeFromNibで設定するはずだが、そのタイミングでは何故かいずれもnil
    _overallView.delegate = self;
    _zoomedView.delegate = self;
    _zoomedView.mode = KSLProblemViewModeInputLine;
    
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    KSLProblem *problem = pm.currentProblem;
    _player = [[KSLPlayer alloc] initWithProblem:problem];
    _step = [NSMutableArray array];
    
    // アプリケーションライフサイクルの通知受信
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(applicationDidEnterBackground) name:@"applicationDidEnterBackground" object:nil];
    [nc addObserver:self selector:@selector(applicationWillEnterForeground) name:@"applicationWillEnterForeground" object:nil];
    
    [self setBoard:_player.board];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.title = _player.problem.title;
    self.difficultyLabel.text = _player.problem.difficultyString;
    
    [self startPlay];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopPlay];
}

/**
 * プレイを開始する.
 */
- (void)startPlay
{
    if (_player.problem.status == KSLProblemStatusSolved) {
        _player.problem.status = KSLProblemStatusNotStarted;
    }
    _elapsed = _player.problem.status == KSLProblemStatusNotStarted ? 0 :
                ((NSNumber *)[_player.problem.elapsedSeconds lastObject]).intValue;
    _start = [NSDate date];
    [self updateElapsedlabel:nil];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                            target:self selector:@selector(updateElapsedlabel:) userInfo:nil repeats:YES];
}

/**
 * プレイを中断する.
 */
- (void)stopPlay
{
    [_timer invalidate];
    
    KSLProblem *problem = _player.problem;
    NSDate *now = [NSDate date];
    NSTimeInterval t = [now timeIntervalSinceDate:_start];
    switch (problem.status) {
        case KSLProblemStatusSolving:
            [problem updateElapsedSecond:_elapsed + (NSInteger)t];
            break;
            
        case KSLProblemStatusNotStarted:
            problem.status = KSLProblemStatusSolving;
            [problem addElapsedSecond:(NSInteger)t];
            break;
            
        default:
            break;
    }
    
    [_player save];
    [_player.problem save];
}

/**
 * アプリケーションがバックグラウンドにまわる通知への処理
 */
- (void)applicationDidEnterBackground
{
    [self stopPlay];
}

/**
 * アプリケーションがフォアグラウンドに戻る通知への処理
 */
- (void)applicationWillEnterForeground
{
    [self startPlay];
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
    [self refreshBoard];
}

- (void)stepBegan
{
    [_step removeAllObjects];
}

- (void)actionPerformed:(KSLAction *)action
{
    [_step addObject:action];
    [self refreshBoard];
}

- (void)stepEnded
{
    [_player addStep:_step];
}

#pragma mark - 各種アクション

/**
 * クリアボタン押下時
 */
- (IBAction)clearClicked:(id)sender
{
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"いいえ" action:nil];
    RIButtonItem *deleteItem = [RIButtonItem itemWithLabel:@"はい" action:^{
        [_player clear];
        [self refreshBoard];
    }];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"クリア"
                        message:@"盤面をクリアしてもよろしいですか？"
                                               cancelButtonItem:cancelItem
                                               otherButtonItems:deleteItem, nil];
    [alert show];
}

/**
 * 固定ボタン押下時
 */
- (IBAction)fixClicked:(id)sender
{
    [_player fix];
    [self refreshBoard];
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
            _zoomedView.mode = KSLProblemViewModeInputLine;
            break;
        case 2:
            _zoomedView.mode = KSLProblemViewModeErase;
            break;
    }
}

/**
 * アンドゥボタン押下時
 */
- (IBAction)undoClicked:(id)sender
{
    if (_player.currentIndex == _player.steps.count - 1) {
        [_player undo];
        [self refreshBoard];
    }
}

#pragma mark - ヘルパメソッド群

/**
 * 経過時間表示ラベルの更新
 * @param timer 呼び出し元のタイマー
 */
- (void)updateElapsedlabel:(NSTimer *)timer
{
    NSDate *now = [NSDate date];
    NSTimeInterval t = [now timeIntervalSinceDate:_start];
    
    NSInteger sec = _elapsed + (NSInteger)t;
    NSString *time = [NSString stringWithFormat:@"%ld:%02ld:%02ld", sec / 3600, (sec % 3600) / 60, sec % 60];
    _elapsedLabel.text = time;
}

/**
 * 盤面のビューの更新
 */
- (void)refreshBoard
{
    [_overallView setNeedsDisplay];
    [_zoomedView setNeedsDisplay];
}

@end
