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
    UserNestViewController	*userNest = [[UserNestViewController alloc] initWithAppID:@"674062da" completionHandler:^(Boolean loggedIn, NSDictionary *loginData) {
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

#import "UserNestViewController.h"
#import "UserNestNetwork.h"
