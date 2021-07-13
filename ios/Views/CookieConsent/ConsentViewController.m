//
//  ConsentViewController.m
//  XCDYouTubeKit iOS Demo
//
//  Created by Ekin Celik on 11/04/2021.
//  Copyright © 2021 Cédric Luthi. All rights reserved.
//

#import "ConsentViewController.h"


@interface ConsentViewController ()


@end

@implementation ConsentViewController

@synthesize webView;
@synthesize transparentView;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	webView = [[WKWebView alloc] init];
	webView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	webView.navigationDelegate = self;
	[self.view addSubview:webView];
	[self consentFunctionWithHtmlData:self.htmlData];
	
}

-(void)consentFunctionWithHtmlData:(NSString *)htmlData {
	
	[self.webView loadHTMLString:htmlData baseURL:nil];
	[self fillCircularLayer];

}

-(void)fillCircularLayer {
	
	int radius = 40;
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) cornerRadius:0];
	UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(self.view.frame.size.width-80, 30, 2.0*radius, 2.0*radius) cornerRadius:radius];
	[path appendPath:circlePath];
	[path setUsesEvenOddFillRule:YES];

	transparentView = [[UIView alloc]init];
	transparentView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	transparentView.backgroundColor = [UIColor clearColor];
	[self.view addSubview:transparentView];
	CAShapeLayer *fillLayer = [CAShapeLayer layer];
	fillLayer.path = path.CGPath;
	fillLayer.fillRule = kCAFillRuleEvenOdd;
	fillLayer.fillColor = [UIColor blackColor].CGColor;
	fillLayer.opacity = 0.75;
	[transparentView.layer addSublayer:fillLayer];
	UILabel* messageLabel = [[UILabel alloc]init];
	messageLabel.frame = CGRectMake(50, 70, self.view.frame.size.width-100, 300);
	messageLabel.text = @"Hi. Youtube has noticed that you haven't accepted their cookies, and has blocked your access to Youtube. In order to get past the Cookie warning, you'll need to sign in to your Google Account (You can't just accept the cookies, you need to sign in). You'll only need to do this once.";
	messageLabel.textColor = [UIColor whiteColor];
	messageLabel.font = [UIFont fontWithName:@"HelveticaNeue" size: 16];
	messageLabel.numberOfLines = 0;
	messageLabel.textAlignment = NSTextAlignmentCenter;
	[transparentView addSubview:messageLabel];
	UIButton* okButton = [[UIButton alloc]initWithFrame:CGRectMake((self.view.frame.size.width-200)/2, 350, 200, 40)];
	[transparentView addSubview:okButton];
	[okButton setTitle:@"OK" forState:UIControlStateNormal];
	[okButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	okButton.layer.borderColor = [[UIColor whiteColor] CGColor];
	okButton.layer.borderWidth = 1.0;
	[okButton addTarget:self action:@selector(okButtonAct:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)okButtonAct:(id)sender {
	[transparentView removeFromSuperview];
}

// MARK: - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
	NSString* urlString = navigationAction.request.URL.absoluteString;
	if (urlString != nil) {
		if ([urlString containsString:@"/accounts/SetSID"]) {
			decisionHandler(WKNavigationActionPolicyAllow);
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				[self dismissViewControllerAnimated:true completion:nil];
			});
			return;
		}
	}

	decisionHandler(WKNavigationActionPolicyAllow);
	  
}

@end
