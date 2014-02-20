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
//#import "KSLSolver.h"
#import "KSLProblem.h"
#import "KSLPlayer.h"
#import "KSLProblemManager.h"

@interface KSLProblemPlayViewController ()
@property (weak, nonatomic) IBOutlet KSLBoardOverallView *overallView;
@property (weak, nonatomic) IBOutlet KSLBoardZoomedView *zoomedView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *clearButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *fixButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *panButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *inputButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *eraseButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *undoButton;
@property (weak, nonatomic) IBOutlet UILabel *difficultyLabel;
@property (weak, nonatomic) IBOutlet UILabel *elapsedLabel;

@end

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

@synthesize board = _board;
@synthesize zoomedArea = _zoomedArea;
@synthesize problemArea = _problemArea;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
}

- (void)viewDidLoad
{
    KLDBGPrintMethodName(">>");
    [super viewDidLoad];
    
    // 本来awakeFromNibで設定するはずだが、そのタイミングでは何故かいずれもnil
    _overallView.delegate = self;
    _zoomedView.delegate = self;
    _zoomedView.mode = KSLProblemViewModeInputLine;
    
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    KSLProblem *problem = pm.currentProblem;
    _player = [[KSLPlayer alloc] initWithProblem:problem];
    _step = [NSMutableArray array];
    
    [self setBoard:_player.board];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.title = _player.problem.title;
    self.difficultyLabel.text = _player.problem.difficultyString;
    
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

- (void)viewWillDisappear:(BOOL)animated
{
    KLDBGPrintMethodName(">>");
    [super viewWillDisappear:animated];
    
    [_timer invalidate];
    
    KSLProblem *problem = _player.problem;
    NSDate *now = [NSDate date];
    NSTimeInterval t = [now timeIntervalSinceDate:_start];
    switch (problem.status) {
        case KSLProblemStatusSolving:
            [problem updateElapsedSecond:_elapsed + (int)t];
            break;
            
        case KSLProblemStatusNotStarted:
            problem.status = KSLProblemStatusSolving;
            [problem addElapsedSecond:(int)t];
            break;
            
        default:
            break;
    }
    
    [_player save];
    [_player.problem save];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationLandscapeRight | UIInterfaceOrientationLandscapeLeft;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeRight;
}

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

- (void)stepBegan
{
    [_step removeAllObjects];
}

- (void)actionPerformed:(KSLAction *)action
{
    [_step addObject:action];
    [_overallView setNeedsDisplay];
    [_zoomedView setNeedsDisplay];
}

- (void)stepEnded
{
    [_player addStep:_step];
}

- (IBAction)clearClicked:(id)sender {
}
- (IBAction)fixClicked:(id)sender {
}
- (IBAction)panClicked:(id)sender
{
    _zoomedView.mode = KSLProblemViewModeScroll;
}
- (IBAction)inputClicked:(id)sender
{
    _zoomedView.mode = KSLProblemViewModeInputLine;
}
- (IBAction)eraseClicked:(id)sender
{
    _zoomedView.mode = KSLProblemViewModeErase;
}
- (IBAction)undoClicked:(id)sender {
}

- (void)updateElapsedlabel:(NSTimer *)timer
{
    NSDate *now = [NSDate date];
    NSTimeInterval t = [now timeIntervalSinceDate:_start];
    
    NSInteger sec = _elapsed + (int)t;
    NSString *time = [NSString stringWithFormat:@"%d:%02d:%02d", sec / 3600, (sec % 3600) / 60, sec % 60];
    _elapsedLabel.text = time;
}

@end
