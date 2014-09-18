//
//  KSLHelpViewController.h
//  SLPlayer
//
//  Created by KO on 2014/09/12.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * ヘルプ表示画面のコントローラ
 */
@interface KSLHelpViewController : UIViewController <UIWebViewDelegate>

// 表示するHTMLファイルへのURL
@property (nonatomic, strong) NSURL *url;

@end
