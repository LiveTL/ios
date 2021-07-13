//
//  ConsentViewController.h
//  XCDYouTubeKit iOS Demo
//
//  Created by Ekin Celik on 11/04/2021.
//  Copyright © 2021 Cédric Luthi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ConsentViewController : UIViewController  <WKNavigationDelegate> {
	
}
@property (nonatomic , strong) NSString* htmlData;
@property(nonatomic, readonly) WKWebView *webView;
@property (nonatomic , strong) UIView *transparentView;
-(void)consentFunctionWithHtmlData:(NSString *)htmlData;


@end

NS_ASSUME_NONNULL_END
