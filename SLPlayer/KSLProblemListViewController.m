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
    if (app.restoring) {
        int problemIndex;
        if (app.lastProblem) {
            problemIndex = [pm.currentWorkbook.problems indexOfObject:app.lastProblem];
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:problemIndex inSection:0]
                                        animated:NO scrollPosition:UITableViewScrollPositionBottom];
        }
        if ([app.lastView isEqualToString:@"Play"]) {
            // TODO Segueの実行
        } else if ([app.lastView isEqualToString:@"Edit"]) {
            self.editing = YES;
            // TODO Segueの実行
        }
        app.restoring = NO;
    } else if ([app.currentView isEqualToString:@"Play"]) {
        // 戻り時の処理
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
    
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    KSLProblem *problem = pm.currentWorkbook.problems[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %dX%d %@ %@", problem.title, problem.width,
                       problem.height, [problem difficultyString], [problem statusString]];
    
    int finishedCount = problem.elapsedSeconds.count - (problem.status == KSLProblemStatusSolving ? 1 : 0);
    if (finishedCount) {
        cell.detailTextLabel.text = [NSMutableString stringWithFormat:@"%@ %@", [problem evaluationString],
                                     [problem elapsedTimeString]];
    } else {
        cell.detailTextLabel.text = @"";
    }
    
    return cell;
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
    if (self.editing) {
        [self performSegueWithIdentifier:@"EditProblem" sender:self];
    } else {
        [self performSegueWithIdentifier:@"PlayProblem" sender:self];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    KLDBGPrintMethodName(">>");
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    if ([segue.identifier isEqualToString:@"PlayProblem"]) {
        KSLProblem *problem = pm.currentWorkbook.problems[[self.tableView indexPathForSelectedRow].row];
        pm.currentProblem = problem;
    } else if ([segue.identifier isEqualToString:@"EditProblem"]) {
        UINavigationController *nc = (UINavigationController *)segue.destinationViewController;
        KSLProblemEditViewController *pev = (KSLProblemEditViewController *)nc.topViewController;
        KSLProblem *problem = pm.currentWorkbook.problems[[self.tableView indexPathForSelectedRow].row];
        pev.problem = [[KSLProblem alloc] initWithProblem:problem];
        pev.addNew = NO;
    } else if ([segue.identifier isEqualToString:@"AddProblem"]) {
        UINavigationController *nc = (UINavigationController *)segue.destinationViewController;
        KSLProblemEditViewController *pev = (KSLProblemEditViewController *)nc.visibleViewController;
        pev.problem = [[KSLProblem alloc] initWithWidth:10 andHeight:20 data:nil];
        pev.addNew = YES;
    }
}

- (IBAction)doneProblemEdit:(UIStoryboardSegue *)segue
{
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    KSLProblemEditViewController *pev = (KSLProblemEditViewController *)segue.sourceViewController;
    if (pev.addNew) {
        [pm.currentWorkbook addProblem:pev.problem withSave:YES];
        [((UITableView *)self.view) reloadData];
    } else {
        KSLProblem *problem = pm.currentProblem;
        [problem updateWithProblem:pev.problem];
        // TODO 行の更新
        pm.currentProblem = nil;
        // TODO currentView
    }
}

- (IBAction)cancelProblemEdit:(UIStoryboardSegue *)segue
{
    // TODO currentView, currentProblem
}

@end
