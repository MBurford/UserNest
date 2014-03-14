//
//  UserNestNewAccount.h
//  UserNest
//
//  Copyright (c) 2014 Headlight Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserNestTOSViewController.h"

@interface UNAccountItem : NSObject

@property (retain, nonatomic) UITextField	*textField;
@property (retain, nonatomic) UISwitch      *switchField;
@property (retain, nonatomic) NSString      *placeholder;
@property (retain, nonatomic) NSString		*name;
@property (assign, nonatomic) Boolean       optional;

+ (id)textNamed:(NSString*)desc placeholder:(NSString*)def optional:(Boolean)optional keyboardType:(UIKeyboardType)keyboardType nameEntry:(Boolean)nameEntry;
+ (id)textPasswordNamed:(NSString*)desc placeholder:(NSString*)def;
+ (id)switchNamed:(NSString*)desc placeholder:(NSString*)def;
+ (id)showTerms:(NSString*)message;

@end


@interface UserNestNewAccountViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UserNestTOSDelegate> {
	NSMutableArray		*allSections;
}

@property (nonatomic, retain) NSString  *userNestAppID;
@property (nonatomic, retain) NSString  *userNestSession;

@property (nonatomic, retain) id        delegate;

@property (unsafe_unretained, nonatomic) IBOutlet UITableView *tableView;

- (void)addTextItem:(UNAccountItem*)item;

- (void)newAccountSuccess;
- (void)newAccountFailed;

@end
