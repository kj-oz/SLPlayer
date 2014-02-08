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
    
    // 最後に開いていたドキュメントを得る
    pm.currentWorkbook = pm.workbooks[0];
    NSString* lastWorkbook = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastWorkbook"];
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
                pm.currentProblem = problem;
                break;
            }
        }
    }

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
    
    // カレントの本棚の情報も標準の設定ファイルに保存する
    [[NSUserDefaults standardUserDefaults] setValue:pm.currentWorkbook.title forKey:@"lastWorkbook"];
}

@end
