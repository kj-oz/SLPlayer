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
@property (weak, nonatomic) IBOutlet UITextField *nameText;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sizeLabel;
@property (weak, nonatomic) IBOutlet UITextField *difficultyText;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *statusLabel;
@property (weak, nonatomic) IBOutlet UITextField *evaluationText;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *elapsedLabel;

@end

@implementation KSLProblemEditViewController
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

- (id)initWithCoder:(NSCoder *)aDecoder
{
    KLDBGPrintMethodName("> ");
    KLDBGPrint(">  (%p %p)\n", _overallView, _zoomedView);
    return [super initWithCoder:aDecoder];
}

- (void)awakeFromNib
{
    _overallView.delegate = self;
    _zoomedView.delegate = self;
    _zoomedView.mode = KSLProblemViewModeScroll;
    KLDBGPrintMethodName("> ");
    KLDBGPrint(">  (%p %p)\n", _overallView, _zoomedView);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 本来awakeFromNibで設定するはずだが、そのタイミングでは何故かいずれもnil
    _overallView.delegate = self;
    _zoomedView.delegate = self;
    _zoomedView.mode = KSLProblemViewModeScroll;
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
    CGRect zoomArea = CGRectMake(-1, -1, _zoomedView.frame.size.width / KSLPROBLEM_MINIMUM_PITCH - 1,
                                 _zoomedView.frame.size.height / KSLPROBLEM_MINIMUM_PITCH - 1);
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

- (IBAction)selectClicked:(id)sender
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary sender:sender];
}

- (IBAction)newClicked:(id)sender
{
    
}
- (IBAction)checkClicked:(id)sender {
}
- (IBAction)panClicked:(id)sender {
}
- (IBAction)numberClicked:(id)sender {
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
    self.problem = problem;
    
    // 問題チェック
    [self setBoard:[[KSLBoard alloc] initWithProblem:problem]];
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
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
