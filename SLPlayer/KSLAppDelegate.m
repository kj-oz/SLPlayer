//
//  KSLAppDelegate.m
//  SLPlayer
//
//  Created by KO on 2014/02/02.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLAppDelegate.h"
#import "KSLProblemManager.h"
#import "KSLWorkbook.h"
#import "KSLProblem.h"

@implementation UIViewController (OrientationFix)

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

@end

@implementation UIImagePickerController (OrientationFix)

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

@end

@implementation KSLAppDelegate

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // データを読み込む
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    [pm load];
    
    // 前回起動時の状態を得る
    _lastView = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastView"];
    
    pm.currentWorkbook = pm.workbooks[0];
    NSString *lastWorkbook = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastWorkbook"];
    if (lastWorkbook) {
        for (KSLWorkbook *book in pm.workbooks) {
            if ([book.title isEqualToString:lastWorkbook]) {
                pm.currentWorkbook = book;
                break;
            }
        }
    }
    
    NSString* lastProblem = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastProblem"];
    if (lastProblem) {
        for (KSLProblem *problem in pm.currentWorkbook.problems) {
            if ([problem.uid isEqualToString:lastProblem]) {
                _lastProblem = problem;
                break;
            }
        }
    }
    
    _restoring = YES;

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    NSNotification* n = [NSNotification notificationWithName:@"applicationWillResignActive" object:self];
    [[NSNotificationCenter defaultCenter] postNotification:n];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSNotification* n = [NSNotification notificationWithName:@"applicationDidEnterBackground" object:self];
    [[NSNotificationCenter defaultCenter] postNotification:n];

    [self saveData];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSNotification* n = [NSNotification notificationWithName:@"applicationWillEnterForeground" object:self];
    [[NSNotificationCenter defaultCenter] postNotification:n];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSNotification* n = [NSNotification notificationWithName:@"applicationDidBecomeActive" object:self];
    [[NSNotificationCenter defaultCenter] postNotification:n];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self saveData];
}

- (void)saveData
{
    KSLProblemManager *pm = [KSLProblemManager sharedManager];
    KSLProblem *currentProblem = pm.currentProblem;
    if (currentProblem) {
        [[NSUserDefaults standardUserDefaults] setValue:currentProblem.uid forKey:@"lastProblem"];
        [currentProblem saveToFile:pm.currentWorkbookDir];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastProblem"];
    }
    
    // カレントの問題集の情報も標準の設定ファイルに保存する
    [[NSUserDefaults standardUserDefaults] setValue:pm.currentWorkbook.title forKey:@"lastWorkbook"];
    [[NSUserDefaults standardUserDefaults] setValue:_currentView forKey:@"lastView"];
}

@end
