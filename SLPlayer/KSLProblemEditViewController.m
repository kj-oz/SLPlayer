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

@interface KSLProblemEditViewController ()

@property (weak, nonatomic) IBOutlet KSLBoardOverallView *overallView;
@property (weak, nonatomic) IBOutlet KSLBoardZoomedView *zoomedView;
@property (weak, nonatomic) IBOutlet UITextField *titleText;
@property (weak, nonatomic) IBOutlet UITextField *difficultyText;
@property (weak, nonatomic) IBOutlet UITextField *evaluationText;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *elapsedLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pictureButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *createButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *checkButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *panButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *inputButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *undoButton;

@end

@implementation KSLProblemEditViewController
{
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

- (id)initWithCoder:(NSCoder *)aDecoder
{
    return [super initWithCoder:aDecoder];
}

- (void)awakeFromNib
{
    KLDBGPrintMethodName(">>");
}

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
    KLDBGPrintMethodName(">>");
}

- (void)viewDidAppear:(BOOL)animated
{
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

@end
