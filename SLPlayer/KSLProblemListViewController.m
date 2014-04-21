//
//  KSLProblemListViewController.m
//  SLPlayer
//
//  Created by KO on 2014/02/02.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLProblemListViewController.h"
#import "KSLProblemEditViewController.h"
#import "KSLProblemManager.h"
#import "KSLWorkbook.h"
#import "KSLProblem.h"
#import "KLDBGUtil.h"
#import "KSLAppDelegate.h"

@interface KSLProblemListViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;

@end

@implementation KSLProblemListViewController
{
    KSLProblem *_editingProblem;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.editing = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    KSLAppDelegate *app = [UIApplication sharedApplication].delegate;
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    NSUInteger problemIndex;
    if (app.restoring) {
        if (app.lastProblem) {
            problemIndex = [pm.currentWorkbook.problems indexOfObject:app.lastProblem];
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:problemIndex inSection:0]
                                        animated:NO scrollPosition:UITableViewScrollPositionBottom];
        }
        
        if ([app.lastView isEqualToString:@"Play"]) {
            [self performSegueWithIdentifier:@"PlayProblem" sender:self];
        } else if ([app.lastView isEqualToString:@"Edit"]) {
            //TODO 編集ビューの状態保存は将来対応予定
            //self.editing = YES;
            //[self performSegueWithIdentifier:@"EditProblem" sender:self];
        }
        app.restoring = NO;
    } else if ([app.currentView isEqualToString:@"Play"]) {
        // Backボタンで戻った場合には、アクションは発生しないためここで処理
        problemIndex = [pm.currentWorkbook.problems indexOfObject:pm.currentProblem];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:problemIndex inSection:0];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self updateCell:cell atIndexPath:indexPath];
        
        pm.currentProblem = nil;
        app.currentView = @"List";
    }
}


- (IBAction)editClicked:(id)sender {
    if (self.tableView.editing) {
        [self.tableView setEditing:NO];
        self.editButton.title = @"Edit";
    } else {
        self.tableView.editing = true;
        self.editButton.title = @"Done";
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    return pm.currentWorkbook.problems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProblemCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                            forIndexPath:indexPath];
    [self updateCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)updateCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    KSLProblem *problem = pm.currentWorkbook.problems[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%ldX%ld　%@　%@", (long)problem.width,
                           (long)problem.height, [problem difficultyString], problem.title];
    if (problem.status == KSLProblemStatusSolved) {
        cell.textLabel.enabled = false;
    } else {
        cell.textLabel.enabled = true;
    }
    
    if (problem.elapsedSecond > 0) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [problem statusString]];
    } else {
        cell.detailTextLabel.text = @"";
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    KSLProblem *problem = pm.currentWorkbook.problems[indexPath.row];
    if (self.editing) {
        if (!(problem.status == KSLProblemStatusSolved ||
                problem.status == KSLProblemStatusSolving)) {
            [self performSegueWithIdentifier:@"EditProblem" sender:self];
        }
    } else {
        if (problem.status != KSLProblemStatusEditing) {
            [self performSegueWithIdentifier:@"PlayProblem" sender:self];
        }
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    KLDBGPrintMethodName(">>");
    KSLAppDelegate *app = [UIApplication sharedApplication].delegate;
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    
    if ([segue.identifier isEqualToString:@"PlayProblem"]) {
        KSLProblem *problem = pm.currentWorkbook.problems[[self.tableView indexPathForSelectedRow].row];
        pm.currentProblem = problem;
        app.currentView = @"Play";
    } else if ([segue.identifier isEqualToString:@"EditProblem"]) {
        UINavigationController *nc = (UINavigationController *)segue.destinationViewController;
        KSLProblemEditViewController *pev = (KSLProblemEditViewController *)nc.topViewController;
        KSLProblem *problem = pm.currentWorkbook.problems[[self.tableView indexPathForSelectedRow].row];
        pev.problem = [[KSLProblem alloc] initWithProblem:problem];
        pev.addNew = NO;
        pm.currentProblem = problem;
        app.currentView = @"Edit";
    } else if ([segue.identifier isEqualToString:@"AddProblem"]) {
        UINavigationController *nc = (UINavigationController *)segue.destinationViewController;
        KSLProblemEditViewController *pev = (KSLProblemEditViewController *)nc.visibleViewController;
        pev.problem = [[KSLProblem alloc] initWithWidth:10 andHeight:20 data:nil];
        pev.addNew = YES;
        app.currentView = @"Edit";
    }
}

//- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender
//{
//    if (action == @selector(cancelProblemEdit:)) {
//        return YES;
//    }
//    
//    KLDBGPrintMethodName(">>");
//    KLDBGPrint("%s", [[sender description] UTF8String]);
//    KSLProblemEditViewController *pev = (KSLProblemEditViewController *)fromViewController;
//    NSString *title = [pev.titleText.text
//                      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//    if ([title isEqualToString:@"未定"] || ![title length]) {
//        UIAlertView *alert = [[UIAlertView alloc]
//                                 initWithTitle:@"名称"
//                                 message:@"正しい名称を入力して下さい。"
//                                 delegate:nil cancelButtonTitle:nil
//                                 otherButtonTitles:@"了解", nil];
//        [alert show];
//        return NO;
//    }
//    NSInteger difficulty = [pev.difficultyText.text integerValue];
//    if (difficulty < 1 || difficulty > 9) {
//        UIAlertView *alert = [[UIAlertView alloc]
//                              initWithTitle:@"難易度"
//                              message:@"1桁の整数を入力して下さい。"
//                              delegate:nil cancelButtonTitle:nil
//                              otherButtonTitles:@"了解", nil];
//        [alert show];
//        return NO;
//    }
//    return YES;
//}

- (IBAction)doneProblemEdit:(UIStoryboardSegue *)segue
{
    KSLAppDelegate *app = [UIApplication sharedApplication].delegate;
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    
    KSLProblemEditViewController *pev = (KSLProblemEditViewController *)segue.sourceViewController;
    pev.problem.title = pev.titleText.text;
    pev.problem.difficulty = [pev.difficultyText.text integerValue];
    
    if (pev.addNew) {
        [pm.currentWorkbook addProblem:pev.problem withSave:YES];
        [self.tableView reloadData];
    } else {
        KSLProblem *problem = pm.currentProblem;
        [problem updateWithProblem:pev.problem];
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self updateCell:cell atIndexPath:indexPath];
    }
    pm.currentProblem = nil;
    app.currentView = @"List";
}

- (IBAction)cancelProblemEdit:(UIStoryboardSegue *)segue
{
    KSLAppDelegate *app = [UIApplication sharedApplication].delegate;
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    
    pm.currentProblem = nil;
    app.currentView = @"List";
}

@end
