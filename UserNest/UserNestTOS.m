//
//  UserNestTOS.m
//  UserNest
//
//  Created by Michael Burford on 2/25/14.
//  Copyright (c) 2014 Headlight Software, Inc. All rights reserved.
//

#import "UserNestTOS.h"
#import "UserNestBits.h"

@interface UserNestTOS ()

@end

@implementation UserNestTOS

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)dealloc {
	[tosWebView removeFromSuperview];
	[tosWebView release];
}
//https://secure.umsdb.net/s/usernest.com/signup?appId=3cf95443

- (void)loadView {
	if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
		self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	} else {
		CGRect    rc = [UIScreen mainScreen].applicationFrame;
		self.view = [[UIView alloc] initWithFrame:CGRectMake(rc.origin.y, rc.origin.x, rc.size.height, rc.size.width)];
	}
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.view.backgroundColor = [UIColor whiteColor];
	
	tosWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];
	tosWebView.delegate = self;
	tosWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[tosWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/legal/tos.html?appId=%@", self.userNestAppID]]]];
	[self.view addSubview:tosWebView];
}
- (void)changeSelector:(UISegmentedControl*)termsAndPrivacy {
	if (termsAndPrivacy.selectedSegmentIndex==0) {
		[tosWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/legal/tos.html?appId=%@", self.userNestAppID]]]];
	} else {
		[tosWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://secure.umsdb.net/api/v1/frontend/legal/privacy.html?appId=%@", self.userNestAppID]]]];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //self.navigationItem.title = NSLocalizedString(@"Terms of Service", nil);
	
	UISegmentedControl	*termsAndPrivacy = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"Terms", nil), NSLocalizedString(@"Privacy", nil)]];
	termsAndPrivacy.selectedSegmentIndex = 0;
	[termsAndPrivacy addTarget:self action:@selector(changeSelector:) forControlEvents:UIControlEventValueChanged];
	self.navigationItem.titleView = termsAndPrivacy;
	
	if (self.showCancel) {
		[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(clickDone:)] animated:YES];
	}
}

- (void)clickDone:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
	if (self.showAccept) {
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Accept", nil) style:UIBarButtonItemStyleDone target:self action:@selector(clickAccept:)] animated:YES];
	}
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	NSString* errorString = [NSString stringWithFormat:
                             @"<html><center><font size=+5 color='red'>An error occurred loading the Terms of Service:<br>%@</font></center></html>",
                             error.localizedDescription];
    [tosWebView loadHTMLString:errorString baseURL:nil];
}

- (void)clickAccept:(id)sender {
	if ([self.delegate respondsToSelector:@selector(userNestTOSAccepted)]) {
		[self.delegate performSelector:@selector(userNestTOSAccepted) withObject:nil];
	}
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
