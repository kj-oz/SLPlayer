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

@end

@implementation KSLProblemPlayViewController
{
    KSLPlayer *_player;
    
    NSMutableArray *_step;
    
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
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib
{
}

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
    
    self.title = problem.title;
    [self setBoard:_player.board];

    KLDBGPrintMethodName(">>");
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


@end
