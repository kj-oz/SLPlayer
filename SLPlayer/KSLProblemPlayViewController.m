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
#import "KSLHelpViewController.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"

#pragma mark - エクステンション

@interface KSLProblemPlayViewController ()

// 拡大ビュー
@property (weak, nonatomic) IBOutlet KSLProblemView *problemView;

// タイトル
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

// 経過時間表示ラベル
@property (weak, nonatomic) IBOutlet UILabel *elapsedLabel;

// 問題名称表示部のビュー（タップイベントを拾うためにアウトレット化）
@property (weak, nonatomic) IBOutlet UIView *titleView;

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

    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    KSLProblem *problem = pm.currentProblem;
    _player = [[KSLPlayer alloc] initWithProblem:problem];
    _step = [NSMutableArray array];
    
    // 本来awakeFromNibで設定するはずだが、そのタイミングでは何故かいずれもnil
    _problemView.delegate = self;
    _problemView.mode = _player.problem.status == KSLProblemStatusSolved ?
                                KSLProblemViewModeScroll : KSLProblemViewModeInputLine;
    
    // アプリケーションライフサイクルの通知受信
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(applicationDidEnterBackground) name:@"applicationDidEnterBackground" object:nil];
    [nc addObserver:self selector:@selector(applicationWillEnterForeground) name:@"applicationWillEnterForeground" object:nil];
    
    [self setBoard:_player.board];
//    [self.titleView addGestureRecognizer:[[UITapGestureRecognizer alloc]
//                                          initWithTarget:self action:@selector(titleTapped:)]];
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
    _player = nil;
}

#pragma mark - プライベートメソッッド

/**
 * 表示する盤面をセットする.
 * @param board 盤面
 */
- (void)setBoard:(KSLBoard *)board
{
    _problemView.board = board;
}

/**
 * プレイを開始する.
 */
- (void)startPlay
{
    if (_player.problem.status == KSLProblemStatusSolved) {
        return;
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
    if (_player.problem.status != KSLProblemStatusSolved) {
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
    
    KSLLoopStatus loopStatus = [_player isLoopFinished];
    if (loopStatus == KSLLoopFinished) {
        [_timer invalidate];
        
        KSLProblem *problem = _player.problem;
        NSDate *now = [NSDate date];
        NSTimeInterval t = [now timeIntervalSinceDate:_start];
        
        problem.status = KSLProblemStatusSolved;
        NSInteger sec = _elapsed + (NSInteger)t;
        problem.elapsedSecond = sec;
        [_player fix];
        
        NSString *msg = [NSString stringWithFormat:@"正解です。所要時間%@",
                         [self elapsedlabelString:sec]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"完成"
                                 message:msg delegate:nil cancelButtonTitle:nil
                                 otherButtonTitles:@"了解", nil];
        [alert show];
    } else if (loopStatus == KSLLoopCellError) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ループエラー"
                                message:@"条件に合致しないセルがあります。" delegate:nil cancelButtonTitle:nil
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
 * 問題名部分のタップ
 */
- (IBAction)helpClicked:(id)sender
{
    [self initClicked:sender];
}

/**
 * アクションボタン押下
 */
- (IBAction)actionClicked:(id)sender {
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"キャンセル" action:nil];
    RIButtonItem *initItem = [RIButtonItem itemWithLabel:@"初期化" action:^{
        [self initClicked:sender];
    }];
    if (_player.problem.status == KSLProblemStatusSolved) {
        initItem = nil;
    }
    RIButtonItem *eraseItem = [RIButtonItem itemWithLabel:@"未固定部消去" action:^{
        [self eraseClicked:sender];
    }];
    RIButtonItem *fixItem = [RIButtonItem itemWithLabel:@"固定" action:^{
        [self fixClicked:sender];
    }];

    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"操作"
                                    cancelButtonItem:cancelItem
                                    destructiveButtonItem:initItem
                                    otherButtonItems:fixItem, eraseItem, nil];
    [sheet showInView:self.view];
}

/**
 * アクションシートの初期化ボタン押下
 */
- (IBAction)initClicked:(id)sender
{
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"いいえ" action:nil];
    RIButtonItem *deleteItem = [RIButtonItem itemWithLabel:@"はい" action:^{
        _player.problem.resetCount++;
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
 * アクションシートの消去ボタン押下
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
 * アクションシートの固定ボタン押下
 */
- (IBAction)fixClicked:(id)sender
{
    _player.problem.fixCount++;
    [_player fix];
    [self refreshBoard];
}


#pragma mark - セグエ関係

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowPlayHelp"]) {
        KSLHelpViewController *hv = (KSLHelpViewController *)segue.destinationViewController;
        NSBundle *bundle = [NSBundle mainBundle];
        NSURL *url = [bundle URLForResource:@"playview" withExtension:@"html" subdirectory:@"www"];
        hv.url = url;
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
    [_problemView setNeedsDisplay];
}

@end
