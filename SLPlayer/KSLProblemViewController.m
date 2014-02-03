//
//  KSLProblemViewController.m
//  SLPlayer
//
//  Created by KO on 2014/01/02.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLProblemViewController.h"
#import "KSLOverallView.h"
#import "KSLProblemView.h"
#import "KLDBGUtil.h"

@interface KSLProblemViewController ()
@property (weak, nonatomic) IBOutlet KSLOverallView *overallView;
@property (weak, nonatomic) IBOutlet KSLProblemView *zoomedView;

@end

@implementation KSLProblemViewController
{
    KSLBoard *_board;
    CGRect _zoomedArea;
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
    _overallView.delegate = self;
    _zoomedView.delegate = self;
    _zoomedView.mode = KSLProblemViewModeScroll;
    KLDBGPrintMethodName("> ");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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

@end
