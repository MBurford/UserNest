/*
 UserNest.h
 Copyright (c) 2014 UserNest. All rights reserved.
 */

#import <UIKit/UIKit.h>



@class UserNestViewController;

@protocol UserNestViewControllerDelegate <NSObject>
@optional

/*
 Delegate handlers for main login process.
 Failed is called when they cancel the login dialog;
    (it is not called for mistyped passwords or things where they can retry.)
 */
- (void)userNestLoginSuccessUserData:(NSDictionary*)userData;
- (void)userNestLoginFailed;

/*
 Handler for checkIsLoggedIn.
 */
- (void)userNestIsLoggedIn:(Boolean)loggedIn;

/*
 Handler for logout.
 The App itself is ALWAYS logged out and session ID is deleted from the Keychain
 This indicates whether the session it had been using could be invalidated on the server as well
 (Network connection issues might cause it to fail to invalidate the session on the server)
 */
- (void)userNestLogout:(Boolean)invalidatedSession;

@end

