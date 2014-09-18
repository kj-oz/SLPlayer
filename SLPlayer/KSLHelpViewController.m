//
//  KSLHelpViewController.m
//  SLPlayer
//
//  Created by KO on 2014/09/12.
//  Copyright (c) 2014年 KO. All rights reserved.
//

#import "KSLHelpViewController.h"

@interface KSLHelpViewController ()

// HTML表示用Webビュー
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation KSLHelpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _webView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    KLDBGPrint("%s", [_url description].UTF8String);
    if (_url) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:_url]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UIWebDelegate 

- (BOOL) webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];
    if (!url.isFileURL)
    {
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
            return NO;
        }
    }
    return YES;
}
@end
