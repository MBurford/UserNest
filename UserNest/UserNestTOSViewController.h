//
//  UserNestTOS.h
//  UserNest
//
//  Copyright (c) 2014 Headlight Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserNestTOS;

@protocol UserNestTOSDelegate <NSObject>
@optional
- (void)userNestTOSAccepted;
- (void)userNestTOSFailed;
- (void)userNestTOSDeclined;

@end


@interface UserNestTOSViewController : UIViewController <UIWebViewDelegate> {
	UIWebView	*tosWebView;
}

@property (nonatomic, retain) NSString  *userNestAppID;
@property (nonatomic, assign) Boolean	showAccept;
@property (nonatomic, assign) Boolean	showCancel;

@property (nonatomic, assign) id<UserNestTOSDelegate> delegate;

@end
