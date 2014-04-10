//
//  KSLProblemViewController.m
//  SLPlayer
//
//  Created by KO on 2014/01/02.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLProblemPlayViewController.h"
#import "KSLProblemView.h"
#import "KSLBoard.h"
#import "KSLProblem.h"
#import "KSLPlayer.h"
#import "KSLProblemManager.h"
#import "UIAlertView+Blocks.h"

#pragma mark - エクステンション

@interface KSLProblemPlayViewController ()

// 拡大ビュー
@property (weak, nonatomic) IBOutlet KSLProblemView *zoomedView;

// クリアボタン
@property (weak, nonatomic) IBOutlet UIButton *clearButton;

// 固定ボタン
@property (weak, nonatomic) IBOutlet UIButton *fixButton;

// タイトル
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

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
    
    // ステップ実行中か
    BOOL _stepping;
    
    // プレイ開始時刻
    NSDate *_start;
    
    // プレイ開始時刻の経過秒数
    NSInteger _elapsed;
    
    // 経過時間の更新処理用のタイマー
    NSTimer *_timer;
}

#pragma mark - ビューのライフサイクル

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 本来awakeFromNibで設定するはずだが、そのタイミングでは何故かいずれもnil
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
    
    self.titleLabel.text = [NSString stringWithFormat:@"%@（★%ld）",
                            _player.problem.title, (long)_player.problem.difficulty];
    
    [self startPlay];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopPlay];
}

- (void)setBoard:(KSLBoard *)board
{
    _zoomedView.board = board;
}

/**
 * プレイを開始する.
 */
- (void)startPlay
{
    if (_player.problem.status == KSLProblemStatusSolved) {
        _player.problem.status = KSLProblemStatusNotStarted;
    }
    _elapsed = _player.problem.elapsedSecond;
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
            problem.elapsedSecond = _elapsed + (NSInteger)t;
            break;
            
        case KSLProblemStatusNotStarted:
            problem.status = KSLProblemStatusSolving;
            problem.elapsedSecond = (NSInteger)t;
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

//#pragma mark - ビューの回転
//
//- (NSUInteger)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationLandscapeRight | UIInterfaceOrientationLandscapeLeft;
//}
//
//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
//{
//    return UIInterfaceOrientationLandscapeRight;
//}

#pragma mark - KSLProblemViewDelegateの実装

- (void)stepBegan
{
    [_step removeAllObjects];
    _stepping = YES;
}

- (void)actionChanged:(NSInteger)newValue
{
    [_player changeAction:newValue];
    [self refreshBoard];
}

- (void)actionPerformed:(KSLAction *)action
{
    if (_stepping) {
        [_step addObject:action];
    } else {
        [_player addStep:[NSArray arrayWithObject:action]];
    }
    [self refreshBoard];
}

- (void)stepEnded
{
    [_player addStep:_step];
    _stepping = NO;
    
    if ([_player isFinished]) {
        // TODO 完成
        [_timer invalidate];
        
        KSLProblem *problem = _player.problem;
        NSDate *now = [NSDate date];
        NSTimeInterval t = [now timeIntervalSinceDate:_start];
        
        problem.status = KSLProblemStatusSolved;
        NSInteger sec = _elapsed + (NSInteger)t;
        problem.elapsedSecond = sec;
        NSString *msg = [NSString stringWithFormat:@"正解です。所要時間%@",
                         [self elapsedlabelString:sec]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"完成"
                                 message:msg delegate:nil cancelButtonTitle:nil
                                 otherButtonTitles:@"了解", nil];
        [alert show];
    }
}

- (void)undo
{
    [_player undo];
    [self refreshBoard];
}

#pragma mark - 各種アクション

/**
 * 初期化ボタン押下時
 */
- (IBAction)initClicked:(id)sender
{
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"いいえ" action:nil];
    RIButtonItem *deleteItem = [RIButtonItem itemWithLabel:@"はい" action:^{
        [_player clear];
        [self refreshBoard];
    }];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"初期化"
                        message:@"盤面を全て初期化してもよろしいですか？"
                                           cancelButtonItem:cancelItem
                                           otherButtonItems:deleteItem, nil];
    [alert show];
}

/**
 * 消去ボタン押下時
 */
- (IBAction)eraseClicked:(id)sender
{
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"いいえ" action:nil];
    RIButtonItem *deleteItem = [RIButtonItem itemWithLabel:@"はい" action:^{
        [_player erase];
        [self refreshBoard];
    }];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"消去"
                        message:@"固定されていない部分を消去してもよろしいですか？"
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
    _elapsedLabel.text = [self elapsedlabelString:sec];
}

/**
 * 経過時間表示ラベルの更新
 * @param timer 呼び出し元のタイマー
 */
- (NSString *)elapsedlabelString:(NSInteger)sec
{
    return [NSString stringWithFormat:@"%ld:%02ld:%02ld",
                      (long)(sec / 3600), (long)(sec % 3600) / 60, (long)(sec % 60)];
}

/**
 * 盤面のビューの更新
 */
- (void)refreshBoard
{
    [_zoomedView setNeedsDisplay];
}

@end
