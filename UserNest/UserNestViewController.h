/*
 UserNest.h
 Copyright (c) 2014 UserNest. All rights reserved.
 
 
 REQURES:
 Accelerate.framework
 
 
 USAGE:
    Create with a delegate; or create and set either delegate or blocks for getting login results.
 
 After creating, present normally:
    UserNestViewController	*userNest = [[UserNestViewController alloc] initWithAppID:@"YOUR_APP_ID" delegate:self];
    [self presentViewController:userNest animated:YES completion:nil];
 
 More advanced but even better, checking if they are already logged in:
    UserNest	*userNest = [[UserNestViewController alloc] initWithAppID:@"674062da" completionHandler:^(Boolean loggedIn, NSDictionary *loginData) {
        if (loggedIn) {
            [[[UIAlertView alloc] initWithTitle:@"Logged In!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Login Failed :(" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }];
 
    //Check if it's even needed!  Restores a previous session if they are already logged in.
    [userNest checkIsLoggedInCompletionHandler:^(Boolean loggedIn) {
        if (loggedIn) {
            //They are logged in already!
            [[[UIAlertView alloc] initWithTitle:@"Logged In!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            //Not logged in, present the UI to let them
            [self presentViewController:userNest animated:YES completion:nil];
        }
    }];

 
 ADVANCED:
   You can use a UIViewControllerTransitioningDelegate, but will need to add a background image.
   (The default UIViewControllerTransitioningDelegate uses a blurred image of the previous view.)

 
 */

#import <UIKit/UIKit.h>
#import "UserNestViewControllerDelegate.h"



@interface UserNestViewController : UIViewController

/*
 Main initialization.  You can use either a delegate or blocks to get responses
 */
- (id)initWithAppID:(NSString*)appID completionHandler:(void (^)(Boolean loggedIn, NSDictionary *loginData))completionHandler;
- (id)initWithAppID:(NSString*)appID delegate:(id<UserNestViewControllerDelegate>)unDelegate;

/*
 Check if a user is logged in from an earlier session
 */
- (void)checkIsLoggedIn;
- (void)checkIsLoggedInCompletionHandler:(void (^)(Boolean loggedIn))completionHandler;

- (void)logout;
- (void)logoutCompletionHandler:(void (^)(Boolean invalidatedSession))completionHandler;


/*
 Delegate you would have set in the init
 */
@property (nonatomic, assign) id<UserNestViewControllerDelegate> delegate;

@property (nonatomic, retain) NSString  *userNestAppID;
/*
 Session identifier returned by the UserNest server after a successful login
 */
@property (nonatomic, retain) NSString  *userNestSession;

/*
 Images to replace the default UI.
 All images should use [image resizableImageWithCapInsets:UIEdgeInsetsMake(x,x,x,x)]
 so they are properly resized as the UI changes
 */
@property (nonatomic, retain) UIImage	*backgroundImage;
@property (nonatomic, retain) UIImage	*cancelImage;
@property (nonatomic, retain) UIImage	*cancelImageHilighted;
@property (nonatomic, retain) UIImage	*loginImage;
@property (nonatomic, retain) UIImage	*loginImageHilighted;
@property (nonatomic, retain) UIColor   *textColor;
@property (nonatomic, retain) UIColor   *buttonTextColor;

@end
