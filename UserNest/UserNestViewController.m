//
//  UserNest.m
//  UserNest
//
//  Copyright (c) 2014 UserNest. All rights reserved.
//

#import "UserNestViewController.h"
#import "UserNestNetwork.h"
#import "BlurBehindTransition.h"
#import "UserNestTOSViewController.h"
#import "UserNestNewAccountViewController.h"
#import "UserNestBits.h"

/////////////////////////////////////////////////////////////////////////////
typedef NS_ENUM(NSInteger, UNViewType) {
    UNViewNormal,
    UNViewLoggingIn,
    UNViewForgot,
    UNViewNewAccount,
};

#define UN_WIDTH 290
#define UN_HEIGHT 225

/////////////////////////////////////////////////////////////////////////////
@interface UserNestViewController (Private) <UITextFieldDelegate, UserNestTOSDelegate>

@end


/////////////////////////////////////////////////////////////////////////////
@implementation UserNestViewController {
	//Private local vars...
    UserNestNetwork *unNetwork;
    NSDictionary    *accountPolicy;
	
	void (^completionHandlerBlock)(Boolean loggedIn, NSDictionary *loginData);
    
    //UI Elements
	UIImageView		*background;
	UILabel			*titleMessage;
	UITextField		*username;
	UITextField		*password;
	
	UIButton		*forgot;
	UIButton		*forgotSend;
	UIButton		*newAcct;
	UIButton		*privacy;

	UIButton		*cancel;
	UIButton		*login;
	
	UIActivityIndicatorView	*workingSpinner;
	
	UNViewType		viewType;
}

/////////////////////////////////////////////////////////////////////////////

- (id)initWithAppID:(NSString*)appID completionHandler:(void (^)(Boolean loggedIn, NSDictionary *loginData))completionHandler {
	//Check for AppID blank
	if (appID.length==0) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No App ID", nil)
															  message:NSLocalizedString(@"AppID must be provided", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
		return nil;
	}
	
	self = [super initWithNibName:@"UserNestViewController" bundle:nil];
	if (self) {
		self.userNestAppID = [appID retain];
		
		completionHandlerBlock = [completionHandler copy];

		id <UIViewControllerTransitioningDelegate> transitionDelegate = [[BlurBehindTransitioningDelegate alloc] init];
		self.transitioningDelegate = transitionDelegate;

	}
	return self;
}
- (id)initWithAppID:(NSString*)appID delegate:(id<UserNestViewControllerDelegate>)unDelegate {
	//Check for AppID blank
	if (appID.length==0) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No App ID", nil)
															  message:NSLocalizedString(@"AppID must be provided", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
		return nil;
	}

	self = [super initWithNibName:@"UserNestViewController" bundle:nil];
	if (self) {
		self.userNestAppID = [appID retain];
		
		id <UIViewControllerTransitioningDelegate> transitionDelegate = [[BlurBehindTransitioningDelegate alloc] init];
		self.transitioningDelegate = transitionDelegate;

		self.delegate = unDelegate;
	}
	return self;
}
- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

//SETUP VIEWS---------------------------------------------------------------

- (void)loadView {
	NSLog(@"userNest:loadView");
	if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
		self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	} else {
		CGRect    rc = [UIScreen mainScreen].applicationFrame;
		self.view = [[UIView alloc] initWithFrame:CGRectMake(rc.origin.y, rc.origin.x, rc.size.height, rc.size.width)];
	}
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.view.backgroundColor = [UIColor clearColor];
}
- (void)viewDidLoad {
	NSLog(@"userNest:viewDidLoad");
    [super viewDidLoad];
	
	CGRect    rc = self.view.bounds;
	
	background = [[UIImageView alloc] initWithFrame:CGRectMake(rc.size.width/2 - UN_WIDTH/2, rc.size.height/2 - UN_HEIGHT/2, UN_WIDTH, UN_HEIGHT)];
	background.userInteractionEnabled = YES;
    background.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
	if (self.backgroundImage) {
		background.image = self.backgroundImage;
		background.backgroundColor = [UIColor clearColor];
	} else {
		[background.layer setCornerRadius:10];
		background.backgroundColor = [UIColor whiteColor];
        background.clipsToBounds = YES;
	}
	[self.view addSubview:background];
	
	titleMessage = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, UN_WIDTH-40, 26)];
	titleMessage.textColor = self.textColor ? self.textColor : [UIColor blackColor];
	titleMessage.text = NSLocalizedString(@"Please Log In", "");
	titleMessage.textAlignment = NSTextAlignmentCenter;
	[background addSubview:titleMessage];
	
	username = [[UITextField alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(titleMessage.frame)+8, UN_WIDTH-40, 34)];
	username.placeholder = NSLocalizedString(@"Email", "");
	username.delegate = self;
	username.clearButtonMode = UITextFieldViewModeWhileEditing;
    //Will change for username type after getting the Policy
    username.keyboardType = UIKeyboardTypeEmailAddress;
    username.autocorrectionType = UITextAutocorrectionTypeNo;
    username.autocapitalizationType = UITextAutocapitalizationTypeNone;
	username.returnKeyType = UIReturnKeyNext;
	username.borderStyle = UITextBorderStyleRoundedRect;
	//If they logged in successfully before, show that username/email.
	if ([[UserNestKeychain stringForKey:@"lastLoginName"] length]>0) {
		username.text = [UserNestKeychain stringForKey:@"lastLoginName"];
	}
	[background addSubview:username];

	password = [[UITextField alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(username.frame)+4, UN_WIDTH-40, 34)];
	password.placeholder = NSLocalizedString(@"Password", "");
	password.secureTextEntry = YES;
	password.delegate = self;
	password.clearButtonMode = UITextFieldViewModeWhileEditing;
	password.returnKeyType = UIReturnKeyDone;
	password.borderStyle = UITextBorderStyleRoundedRect;
	[background addSubview:password];

	float		middleBtnWidth = (UN_WIDTH - 20)/3;
	
	forgot = [[UIButton buttonWithType:UIButtonTypeSystem] retain];
	forgot.frame = CGRectMake(5, UN_HEIGHT-(64+30), middleBtnWidth, 44);
	forgot.titleLabel.adjustsFontSizeToFitWidth = YES;
	forgot.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    if (self.buttonTextColor) {
        forgot.titleLabel.textColor = self.buttonTextColor;
    }
	[forgot setTitle:NSLocalizedString(@"Forgot?", "") forState:UIControlStateNormal];
	[forgot addTarget:self action:@selector(clickForgot:) forControlEvents:UIControlEventTouchUpInside];
	[background addSubview:forgot];

	privacy = [[UIButton buttonWithType:UIButtonTypeSystem] retain];
	privacy.frame = CGRectMake(middleBtnWidth*2 + 15, UN_HEIGHT-(64+30), middleBtnWidth, 44);
	privacy.titleLabel.adjustsFontSizeToFitWidth = YES;
	privacy.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    if (self.buttonTextColor) {
        privacy.titleLabel.textColor = self.buttonTextColor;
    }
	[privacy setTitle:NSLocalizedString(@"Privacy?", "") forState:UIControlStateNormal];
	[privacy addTarget:self action:@selector(clickPrivacy:) forControlEvents:UIControlEventTouchUpInside];
	[background addSubview:privacy];

	newAcct = [[UIButton buttonWithType:UIButtonTypeSystem] retain];
	newAcct.frame = CGRectMake(middleBtnWidth*1 + 10, UN_HEIGHT-(64+30), middleBtnWidth, 44);
	newAcct.titleLabel.adjustsFontSizeToFitWidth = YES;
	newAcct.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    if (self.buttonTextColor) {
        newAcct.titleLabel.textColor = self.buttonTextColor;
    }
	[newAcct setTitle:NSLocalizedString(@"New Account?", "") forState:UIControlStateNormal];
	[newAcct addTarget:self action:@selector(clickNewAccount:) forControlEvents:UIControlEventTouchUpInside];
	[background addSubview:newAcct];
	

	
	cancel = [[UIButton buttonWithType:UIButtonTypeSystem] retain];
    cancel.frame = CGRectMake(20, UN_HEIGHT-64, UN_WIDTH/2-30, 44);
	if (self.cancelImage) {
		[cancel setBackgroundImage:self.cancelImage forState:UIControlStateNormal];
		if (self.cancelImageHilighted) {
			[cancel setBackgroundImage:self.cancelImageHilighted forState:UIControlStateHighlighted];
		} else {
            cancel.showsTouchWhenHighlighted = YES;
		}
	} else {
        [cancel setBackgroundImage:[UIImage userNestLeftButtonImage:NO] forState:UIControlStateNormal];
        [cancel setBackgroundImage:[UIImage userNestLeftButtonImage:YES] forState:UIControlStateHighlighted];
	}
    if (self.buttonTextColor) {
        cancel.titleLabel.textColor = self.buttonTextColor;
    }
	[cancel setTitle:NSLocalizedString(@"Cancel", "") forState:UIControlStateNormal];
	[cancel addTarget:self action:@selector(clickCancelLogin:) forControlEvents:UIControlEventTouchUpInside];
	[background addSubview:cancel];
	
	login = [[UIButton buttonWithType:UIButtonTypeSystem] retain];
    login.frame = CGRectMake(UN_WIDTH/2+10, UN_HEIGHT-64, UN_WIDTH/2-30, 44);
	if (self.loginImage) {
		[login setBackgroundImage:self.loginImage forState:UIControlStateNormal];
		if (self.loginImageHilighted) {
			[login setBackgroundImage:self.loginImageHilighted forState:UIControlStateHighlighted];
		} else {
            login.showsTouchWhenHighlighted = YES;
        }
	} else {
        [login setBackgroundImage:[UIImage userNestRightButtonImage:NO] forState:UIControlStateNormal];
        [login setBackgroundImage:[UIImage userNestRightButtonImage:YES] forState:UIControlStateHighlighted];
	}
	login.titleLabel.adjustsFontSizeToFitWidth = YES;
	login.titleLabel.minimumScaleFactor = 0.0;
    if (self.buttonTextColor) {
        login.titleLabel.textColor = self.buttonTextColor;
    }
	[login setTitle:NSLocalizedString(@"Login", "") forState:UIControlStateNormal];
	[login addTarget:self action:@selector(clickLogin:) forControlEvents:UIControlEventTouchUpInside];
	[background addSubview:login];
	
	forgotSend = [[UIButton buttonWithType:UIButtonTypeSystem] retain];
    forgotSend.frame = CGRectMake(UN_WIDTH/2+10, UN_HEIGHT-64, UN_WIDTH/2-30, 44);
	if (self.loginImage) {
		[forgotSend setBackgroundImage:self.loginImage forState:UIControlStateNormal];
		if (self.loginImageHilighted) {
			[forgotSend setBackgroundImage:self.loginImageHilighted forState:UIControlStateHighlighted];
		} else {
            forgotSend.showsTouchWhenHighlighted = YES;
		}
	} else {
        [forgotSend setBackgroundImage:[UIImage userNestRightButtonImage:NO] forState:UIControlStateNormal];
        [forgotSend setBackgroundImage:[UIImage userNestRightButtonImage:YES] forState:UIControlStateHighlighted];
	}
	forgotSend.titleLabel.adjustsFontSizeToFitWidth = YES;
	forgotSend.titleLabel.minimumScaleFactor = 0.0;
    if (self.buttonTextColor) {
        forgotSend.titleLabel.textColor = self.buttonTextColor;
    }
	[forgotSend setTitle:NSLocalizedString(@"Reset", "") forState:UIControlStateNormal];
	[forgotSend addTarget:self action:@selector(clickForgotSend:) forControlEvents:UIControlEventTouchUpInside];
	[background addSubview:forgotSend];
	forgotSend.enabled = NO;
	forgotSend.alpha = 0.0;
	
	
	workingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	workingSpinner.tintColor = [UIColor darkGrayColor];
	workingSpinner.hidesWhenStopped = YES;
	workingSpinner.center = CGPointMake(UN_WIDTH/2, CGRectGetMaxY(password.frame)+30);
	[background addSubview:workingSpinner];
	
	
	//Need to know about keyboard changes, so the size/position can move to fit better on various devices
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:username];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:password];
    
    [self transformToNormal:0];
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
    if (accountPolicy) {
        [self transformToNormal:0.0];
    } else {
        if (!unNetwork) {
            unNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:self.userNestAppID session:self.userNestSession];
        }
        [unNetwork getAccountPolicyCompletionHandler:^(NSDictionary *policy) {
            [self gotAccountPolicy:policy];
        }];
    }
}
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

//MAIN STUFF---------------------------------------------------------------

- (void)clickCancelLogin:(id)sender {
	if (viewType==UNViewForgot) {
		[self transformToNormal:0.33];
		[username resignFirstResponder];
	} else {
		[self loginFail];
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}
- (void)clickForgot:(id)sender {
	[self transformToForgot:0.33];
}
- (void)clickForgotSend:(id)sender {
	if (username.text.length==0) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter Email Address", nil)
															  message:NSLocalizedString(@"You must enter an Email Address", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
		return;
	}
	
	//Start the process
    [unNetwork resetPasswordWithEmail:username.text completionHandler:^(Boolean reset) {
        if (reset) {
            [self passwordResetSuccess];
        } else {
            [self passwordResetFail];
        }
    }];

	[self transformToNormal:0.33];
}
- (void)clickNewAccount:(id)sender {
    if (!accountPolicy) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry", nil)
															  message:NSLocalizedString(@"Unable to get new account policies", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
        [self transformToNormal:0.33];
        return;
    }
    if (![accountPolicy[@"acceptNewSignup"] boolValue]) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry", nil)
															  message:NSLocalizedString(@"New accounts are not being accepted", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
        [self transformToNormal:0.33];
        return;
    }
    
	UserNestNewAccountViewController	*newAccount = [[[UserNestNewAccountViewController alloc] initWithNibName:@"UserNestNewAccountViewController" bundle:nil] autorelease];
    newAccount.userNestAppID = self.userNestAppID;
	
	/*
     {"appId":"674062da",
     "passwordValidation":"Weak",
     "acceptNewSignup":true,
     "sessionLengthMin":3600,
     "handoffMode":"inhouse",
     "allowPwReset":true,
     "usernameType":"email",
     "acceptNewLogin":true,
     "explicitAgree":true,
     "accountIdType":"Hex",
     "accountIdMin":6,
     "accountIdMax":12,
     "requirePassword":true,
     "includeFields":{
     "email":"Required",
     "username":"None",
     "firstname":"Optional",
     "lastname":"Optional"
     },
     "requireCaptcha":false}
     */
    
	//This would need to be update if new fields are added (like Age)
	//If there get to be many more, could be a plist or something to convert "lastname" to human friendly "Last Name"
	//Only a few, so does them in code...
    NSDictionary *includeFields = accountPolicy[@"includeFields"];
	if ([includeFields[@"username"] isEqualToString:@"Required"] || [includeFields[@"username"] isEqualToString:@"Optional"]) {
        //Full text, in case translations would be different somehow...
        NSString    *placeholder = ([includeFields[@"username"] isEqualToString:@"Optional"] ?
                                    NSLocalizedString(@"Username (Optional)", nil) :
                                    NSLocalizedString(@"Username", nil));
        [newAccount addTextItem:[UNAccountItem textNamed:@"username"
                                             placeholder:placeholder
                                                optional:[includeFields[@"username"] isEqualToString:@"Optional"]
                                            keyboardType:UIKeyboardTypeDefault nameEntry:YES]];
    }
    
    if ([includeFields[@"email"] isEqualToString:@"Required"] || [includeFields[@"email"] isEqualToString:@"Optional"]) {
        //Full text, in case translations would be different somehow...
        NSString    *placeholder = ([includeFields[@"email"] isEqualToString:@"Optional"] ?
                                    NSLocalizedString(@"Email (Optional)", nil) :
                                    NSLocalizedString(@"Email", nil));
        [newAccount addTextItem:[UNAccountItem textNamed:@"email"
                                             placeholder:placeholder
                                                optional:[includeFields[@"email"] isEqualToString:@"Optional"]
                                            keyboardType:UIKeyboardTypeEmailAddress nameEntry:NO]];
    }
    
    if ([includeFields[@"firstname"] isEqualToString:@"Required"] || [includeFields[@"firstname"] isEqualToString:@"Optional"]) {
        //Full text, in case translations would be different somehow...
        NSString    *placeholder = ([includeFields[@"firstname"] isEqualToString:@"Optional"] ?
                                    NSLocalizedString(@"First Name (Optional)", nil) :
                                    NSLocalizedString(@"First Name", nil));
        [newAccount addTextItem:[UNAccountItem textNamed:@"firstname"
                                             placeholder:placeholder
                                                optional:[includeFields[@"firstname"] isEqualToString:@"Optional"]
                                            keyboardType:UIKeyboardTypeDefault nameEntry:YES]];
    }
    
    if ([includeFields[@"lastname"] isEqualToString:@"Required"] || [includeFields[@"lastname"] isEqualToString:@"Optional"]) {
        //Full text, in case translations would be different somehow...
        NSString    *placeholder = ([includeFields[@"lastname"] isEqualToString:@"Optional"] ?
                                    NSLocalizedString(@"Last Name (Optional)", nil) :
                                    NSLocalizedString(@"Last Name", nil));
        [newAccount addTextItem:[UNAccountItem textNamed:@"lastname"
                                             placeholder:placeholder
                                                optional:[includeFields[@"lastname"] isEqualToString:@"Optional"]
                                            keyboardType:UIKeyboardTypeDefault nameEntry:YES]];
    }
    
    if ([accountPolicy[@"requirePassword"] boolValue]) {
        [newAccount addTextItem:[UNAccountItem textPasswordNamed:@"password" placeholder:NSLocalizedString(@"Password", nil)]];
        [newAccount addTextItem:[UNAccountItem textPasswordNamed:@"confirmpassword" placeholder:NSLocalizedString(@"Confirm Password", nil)]];
    }
    
    if ([accountPolicy[@"explicitAgree"] boolValue]) {
        [newAccount addTextItem:[UNAccountItem switchNamed:@"tosResponse" placeholder:NSLocalizedString(@"Agree to Terms of Service", nil)]];
    } else {
        [newAccount addTextItem:[UNAccountItem showTerms:NSLocalizedString(@"View Terms of Service", nil)]];
    }
	
	//! "requireCaptcha" may not be true.  Not sure how to handle captchas from within the app...
    
	UINavigationController	*nav = [[[UINavigationController alloc] initWithRootViewController:newAccount] autorelease];
	nav.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentViewController:nav animated:YES completion:nil];
}
- (void)clickPrivacy:(id)sender {
	UserNestTOSViewController     *showTOS = [[UserNestTOSViewController alloc] init];
	showTOS.userNestAppID = self.userNestAppID;
	showTOS.showAccept = NO;
	showTOS.showCancel = YES;

	UINavigationController	*nav = [[[UINavigationController alloc] initWithRootViewController:showTOS] autorelease];
	nav.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentViewController:nav animated:YES completion:nil];
}

- (void)clickLogin:(id)sender {
	if (username.text.length==0) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter Email Address", nil)
															  message:NSLocalizedString(@"You must enter an Email Address", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
		return;
	}
	if (password.text.length==0) {
		UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter Password", nil)
															  message:NSLocalizedString(@"You must enter a Password", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
		return;
	}
	viewType = UNViewLoggingIn;
	[self transformToWorking:0.33 message:NSLocalizedString(@"Logging In...", "")];
	[username resignFirstResponder];
	[password resignFirstResponder];
    
    if (!unNetwork) {
        unNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:self.userNestAppID session:self.userNestSession];
    }
    [unNetwork loginWithUser:username.text password:password.text completionHandler:^(NSDictionary *data) {
        if (data) {
            [self loginSuccess:data];
        } else {
            //Does NOT call fail. Shows errors about what was wrong in unNetwork; they can fix and try again
            //[self loginFail];
            [self transformToNormal:0.33];
        }
    }];
}
- (void)logout {
    if (!unNetwork) {
        unNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:self.userNestAppID session:self.userNestSession];
    }
 
    [unNetwork logoutCompletionHandler:^(Boolean invalidated) {
        [self loggedOut:invalidated];
    }];
}
- (void)logoutCompletionHandler:(void (^)(Boolean invalidatedSession))completionHandler {
    if (!unNetwork) {
        unNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:self.userNestAppID session:self.userNestSession];
    }
	[unNetwork logoutCompletionHandler:^(Boolean invalidated) {
        [self loggedOut:invalidated];
		completionHandler(invalidated);
    }];
}


//RESPONSES---------------------------------------------------------------

- (void)loginSuccess:(NSDictionary*)loginData {
    if (self.userNestSession.length==0) {
        NSDictionary *sessionData = loginData[@"session"];
        if (sessionData) {
            self.userNestSession = sessionData[@"id"];
        }
    }
	[UserNestKeychain setString:self.userNestSession forKey:@"sessionID"];
	[UserNestKeychain setString:username.text forKey:@"lastLoginName"];
	
	if ([self.delegate respondsToSelector:@selector(userNestLoginSuccessUserData:)]) {
		[self.delegate userNestLoginSuccessUserData:loginData];
	}
	if (completionHandlerBlock) {
		completionHandlerBlock(YES, loginData);
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}
- (void)loginFail {
	[UserNestKeychain setString:@"" forKey:@"sessionID"];
	
	if ([self.delegate respondsToSelector:@selector(userNestLoginFailed)]) {
		[self.delegate userNestLoginFailed];
	}
	if (completionHandlerBlock) {
		completionHandlerBlock(NO, nil);
	}
}
- (void)gotAccountPolicy:(NSDictionary*)policy {
    accountPolicy = [policy retain];
    
    [self transformToNormal:0.33];
}

- (void)passwordResetSuccess {
    UIAlertView		*errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil)
                                                          message:NSLocalizedString(@"Check your email for password reset instructions", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}
- (void)passwordResetFail {
    //Failing shows messages as part of that
}
- (void)loggedOut:(Boolean)invalidated {
    [UserNestKeychain setString:@"" forKey:@"sessionID"];
    self.userNestSession = nil;
    if ([self.delegate respondsToSelector:@selector(userNestLogout:)]) {
		[self.delegate userNestLogout:invalidated];
	}
}


//TRANSFORMS, reshapes the UI so things fit nicely---------------------------------------------------------------
- (void)changeTitle:(NSString*)newTitle duration:(float)duration {
	if ([newTitle isEqualToString:titleMessage.text]) {
		return;
	}
	[UIView animateWithDuration:duration/2 animations:^{
		titleMessage.alpha = 0.0;
	} completion:^(BOOL finished) {
		titleMessage.text = newTitle;
		[UIView animateWithDuration:duration/2 animations:^{
			titleMessage.alpha = 1.0;
		}];
	}];
}

- (void)transformToNormal:(float)duration {
	viewType = UNViewNormal;

	CGRect    rc = self.view.bounds;
	[UIView animateWithDuration:duration animations:^{
		login.frame = CGRectMake(UN_WIDTH/2, UN_HEIGHT-44, UN_WIDTH/2, 45);
		forgotSend.frame = login.frame;
		cancel.frame = CGRectMake(0, UN_HEIGHT-44, UN_WIDTH/2, 45);
		background.frame = CGRectMake(rc.size.width/2 - UN_WIDTH/2, rc.size.height/2 - UN_HEIGHT/2, UN_WIDTH, UN_HEIGHT);

		forgot.alpha = 1.0;
		privacy.alpha = 1.0;
		newAcct.alpha = 1.0;
		login.alpha = 1.0;
		username.alpha = 1.0;
		password.alpha = 1.0;
		forgotSend.alpha = 0.0;
	} completion:^(BOOL finished) {
	}];

	[workingSpinner stopAnimating];
	[self changeTitle:NSLocalizedString(@"Please Log In", "") duration:duration];

	username.returnKeyType = UIReturnKeyNext;
	password.returnKeyType = UIReturnKeyDone;

	forgot.enabled = YES;
	privacy.enabled = YES;
	forgotSend.enabled = YES;
	newAcct.enabled = YES;
	login.enabled = YES;
	cancel.enabled = YES;
	username.enabled = YES;
	password.enabled = YES;

	//Change to the right thing...
	if ([accountPolicy[@"usernameType"] isEqualToString:@"username"]) {
        //Change for Username type...assumes default is Emails
        username.placeholder = NSLocalizedString(@"Username", "");
        username.keyboardType = UIKeyboardTypeDefault;
        username.autocorrectionType = UITextAutocorrectionTypeNo;
        username.autocapitalizationType = UITextAutocapitalizationTypeNone;
		username.returnKeyType = UIReturnKeyNext;
    } else {
		username.placeholder = NSLocalizedString(@"Email", "");
		username.keyboardType = UIKeyboardTypeEmailAddress;
		username.autocorrectionType = UITextAutocorrectionTypeNo;
		username.autocapitalizationType = UITextAutocapitalizationTypeNone;
		username.returnKeyType = UIReturnKeyNext;
	}
}

- (void)transformToForgot:(float)duration {
	CGRect		rc = self.view.bounds;
	float		forgotHeight = UN_HEIGHT - 70;

	viewType = UNViewForgot;

	[UIView animateWithDuration:duration animations:^{
		login.frame = CGRectMake(UN_WIDTH/2, forgotHeight-44, UN_WIDTH/2, 45);
		forgotSend.frame = login.frame;
		cancel.frame = CGRectMake(0, forgotHeight-44, UN_WIDTH/2, 45);
		login.frame = forgotSend.frame;
		background.frame = CGRectMake(rc.size.width/2 - UN_WIDTH/2, rc.size.height/2 - UN_HEIGHT/2, UN_WIDTH, forgotHeight);
		
		forgot.alpha = 0.0;
		privacy.alpha = 0.0;
		newAcct.alpha = 0.0;
		login.alpha = 0.0;
		username.alpha = 1.0;
		password.alpha = 0.0;
		forgotSend.alpha = 1.0;
	}];
	
	[workingSpinner stopAnimating];
	[self changeTitle:NSLocalizedString(@"Reset Password", "") duration:duration];
	
	//Always want email for forgot
	username.returnKeyType = UIReturnKeyDone;
	username.placeholder = NSLocalizedString(@"Email", "");
	username.keyboardType = UIKeyboardTypeEmailAddress;
	username.autocorrectionType = UITextAutocorrectionTypeNo;
	username.autocapitalizationType = UITextAutocapitalizationTypeNone;

	forgot.enabled = NO;
	privacy.enabled = NO;
	forgotSend.enabled = YES;
	newAcct.enabled = NO;
	login.enabled = NO;
	username.enabled = YES;
	password.enabled = NO;
}

- (void)transformToNewAccountWorking:(float)duration {
	CGRect    rc = self.view.bounds;
	[UIView animateWithDuration:duration animations:^{
		//login.frame = CGRectMake(UN_WIDTH/2+10, UN_HEIGHT-64, UN_WIDTH/2-30, 44);
		cancel.frame = CGRectMake(0, UN_HEIGHT-44, UN_WIDTH, 44);
		background.frame = CGRectMake(rc.size.width/2 - UN_WIDTH/2, rc.size.height/2 - UN_HEIGHT/2, UN_WIDTH, UN_HEIGHT);
		
		forgot.alpha = 0.0;
		privacy.alpha = 0.0;
		newAcct.alpha = 0.0;
		login.alpha = 0.0;
		forgotSend.alpha = 0.0;
		
	} completion:^(BOOL finished) {
	}];
	
	workingSpinner.center = CGPointMake(UN_WIDTH/2, CGRectGetMaxY(password.frame)+30);
	[workingSpinner startAnimating];
	[self changeTitle:NSLocalizedString(@"Creating Account...", "")  duration:duration];
	
	forgot.enabled = NO;
	privacy.enabled = NO;
	forgotSend.enabled = NO;
	newAcct.enabled = NO;
	login.enabled = NO;
	username.enabled = NO;
	password.enabled = NO;
}

/*- (void)transformToStartupWorking:(float)duration {
	CGRect    rc = self.view.bounds;
    float     startupHeight = UN_HEIGHT/2;
	[UIView animateWithDuration:duration animations:^{
		cancel.frame = CGRectMake(UN_WIDTH/2 - (UN_WIDTH/2-30)/2, startupHeight-64, UN_WIDTH/2-30, 44);
		background.frame = CGRectMake(rc.size.width/2 - UN_WIDTH/2, rc.size.height/2 - UN_HEIGHT/2, UN_WIDTH, startupHeight);
		
		forgot.alpha = 0.0;
		login.alpha = 0.0;
		newAcct.alpha = 0.0;
        username.alpha = 0.0;
        password.alpha = 0.0;
		forgotSend.alpha = 0.0;
		
	}];
	
	workingSpinner.center = CGPointMake(UN_WIDTH/2, CGRectGetMaxY(titleMessage.frame)+30);
	[workingSpinner startAnimating];
	[self changeTitle:NSLocalizedString(@"Loading...", "")  duration:duration];
	
	forgot.enabled = NO;
	forgotSend.enabled = NO;
	newAcct.enabled = NO;
	login.enabled = NO;
	username.enabled = NO;
	password.enabled = NO;
}*/
- (void)transformToWorking:(float)duration message:(NSString*)message {
	CGRect    rc = self.view.bounds;
	[UIView animateWithDuration:duration animations:^{
		//login.frame = CGRectMake(UN_WIDTH/2+10, UN_HEIGHT-64, UN_WIDTH/2-30, 44);
		cancel.frame = CGRectMake(0, UN_HEIGHT-44, UN_WIDTH, 44);
		background.frame = CGRectMake(rc.size.width/2 - UN_WIDTH/2, rc.size.height/2 - UN_HEIGHT/2, UN_WIDTH, UN_HEIGHT);
		
		forgot.alpha = 0.0;
		privacy.alpha = 0.0;
		newAcct.alpha = 0.0;
		login.alpha = 0.0;
		forgotSend.alpha = 0.0;
		
	}];
	
	workingSpinner.center = CGPointMake(UN_WIDTH/2, CGRectGetMaxY(password.frame)+30);
	[workingSpinner startAnimating];
	[self changeTitle:message  duration:duration];
	
	forgot.enabled = NO;
	privacy.enabled = NO;
	forgotSend.enabled = NO;
	newAcct.enabled = NO;
	login.enabled = NO;
	username.enabled = NO;
	password.enabled = NO;
}

- (void)transformToKeyboardShowing:(float)duration {
	CGRect		rc = self.view.bounds;
	float		moveUp = 0;
	float		kbdHeight = UN_HEIGHT - 40;
	
	if (self.view.bounds.size.height==568) moveUp = 30;
	if (self.view.bounds.size.height==480) moveUp = 60;
	if (self.view.bounds.size.width==568) moveUp = 65;
	if (self.view.bounds.size.width==480) moveUp = 65;
	if (self.view.bounds.size.width==1024) moveUp = 60;
	
	Boolean		portrait = (self.view.bounds.size.height>self.view.bounds.size.width);
	
	if (viewType==UNViewNormal) {
		[UIView animateWithDuration:duration animations:^{
			login.frame = CGRectMake(UN_WIDTH/2, kbdHeight-44, UN_WIDTH/2, 44);
			cancel.frame = CGRectMake(0, kbdHeight-44, UN_WIDTH/2, 44);
			background.frame = CGRectMake(rc.size.width/2 - UN_WIDTH/2, rc.size.height/2 - (UN_HEIGHT/2+moveUp), UN_WIDTH, kbdHeight);
			
			forgot.alpha = 0.0;
			privacy.alpha = 0.0;
			newAcct.alpha = 0.0;
		}];
		
		forgot.enabled = NO;
		privacy.enabled = YES;
		newAcct.enabled = NO;
	} else 	if (viewType==UNViewNewAccount) {
		kbdHeight = UN_HEIGHT;
		moveUp += (portrait ? 40 : 20);
		
		[UIView animateWithDuration:duration animations:^{
			//login.frame = CGRectMake(UN_WIDTH/2+10, kbdHeight-64, UN_WIDTH/2-30, 44);
			//cancel.frame = CGRectMake(20, kbdHeight-64, UN_WIDTH/2-30, 44);
			background.frame = CGRectMake(rc.size.width/2 - UN_WIDTH/2, rc.size.height/2 - (UN_HEIGHT/2+moveUp), UN_WIDTH, kbdHeight);
		}];

	} else if (viewType==UNViewForgot) {
		float		forgotHeight = UN_HEIGHT - 70;
		[UIView animateWithDuration:duration animations:^{
			background.frame = CGRectMake(rc.size.width/2 - UN_WIDTH/2, rc.size.height/2 - (UN_HEIGHT/2+moveUp), UN_WIDTH, forgotHeight);
		}];
	}
}

//KEYBOARD & TEXT HANDLING---------------------------------------------------------------

- (void)keyboardWillShow:(NSNotification *)notification {
	[self transformToKeyboardShowing:[(NSNumber*)[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
}
- (void)keyboardWillHide:(NSNotification *)notification {
	if (viewType==UNViewNormal) {
		[self transformToNormal:[(NSNumber*)[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
	} else if (viewType==UNViewForgot) {
		[self transformToForgot:[(NSNumber*)[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
	}
}
- (void)textFieldDidChange:(NSNotification *)notification {
/*	if (username.text.length==0 && password.text.length==0) {
		[login setTitle:NSLocalizedString(@"Create New", "") forState:UIControlStateNormal];
	} else if (username.text.length>0 && password.text.length==0) {
		[login setTitle:NSLocalizedString(@"Forgot Password?", "") forState:UIControlStateNormal];
	} else {
		[login setTitle:NSLocalizedString(@"Login", "") forState:UIControlStateNormal];
	}*/
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField==username && viewType==UNViewForgot) {
		[username resignFirstResponder];
	} else if (textField==username) {
		[password becomeFirstResponder];
	} else if (textField==password) {
		[password resignFirstResponder];
	}
	return YES;
}

//USER UTILITIES

- (void)checkIsLoggedIn {
	//So could restore a sessionID and see if it is still logged in
	if (self.userNestSession.length==0) {
		self.userNestSession = [UserNestKeychain stringForKey:@"sessionID"];
	}
	if (self.userNestSession.length==0) {
		if ([self.delegate respondsToSelector:@selector(userNestIsLoggedIn:)]) {
			[self.delegate userNestIsLoggedIn:NO];
		}
		return;
	}
	if (!unNetwork) {
		unNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:self.userNestAppID session:self.userNestSession];
	}
	[unNetwork checkLoggedInCompletionHandler:^(Boolean loggedIn) {
		if ([self.delegate respondsToSelector:@selector(userNestIsLoggedIn:)]) {
			[self.delegate userNestIsLoggedIn:loggedIn];
		}
		//NOT logged in, clear session things
		if (!loggedIn) {
			[UserNestKeychain setString:@"" forKey:@"sessionID"];
			self.userNestSession = nil;
		}
	}];
}
- (void)checkIsLoggedInCompletionHandler:(void (^)(Boolean loggedIn))loggedInBlock {
	//So could restore a sessionID and see if it is still logged in
	if (self.userNestSession.length==0) {
		self.userNestSession = [UserNestKeychain stringForKey:@"sessionID"];
	}
	if (self.userNestSession.length==0) {
		loggedInBlock(NO);
		return;
	}
	if (!unNetwork) {
		unNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:self.userNestAppID session:self.userNestSession];
	}
	[unNetwork checkLoggedInCompletionHandler:^(Boolean loggedIn) {
		//NOT logged in, clear session things
		if (!loggedIn) {
			[UserNestKeychain setString:@"" forKey:@"sessionID"];
			self.userNestSession = nil;
		}
		loggedInBlock(loggedIn);
	}];
}


@end









