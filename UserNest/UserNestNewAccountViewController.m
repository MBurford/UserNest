//
//  UserNestNewAccount.m
//  UserNest
//
//  Copyright (c) 2014 Headlight Software, Inc. All rights reserved.
//

#import "UserNestNewAccountViewController.h"
#import "UserNestTOSViewController.h"
#import "UserNestNetwork.h"
#import "UserNestBits.h"

#define GRAYCOLOR 0.96

//Helper item, for table row content objects
@implementation UNAccountItem

+ (id)textNamed:(NSString*)desc placeholder:(NSString*)def optional:(Boolean)optional keyboardType:(UIKeyboardType)keyboardType nameEntry:(Boolean)nameEntry {
	UNAccountItem 	*item = [[[UNAccountItem alloc] init] autorelease];
	item.name = desc;
    item.optional = optional;
	
	item.textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 2, 280, 40)];
	item.textField.placeholder = def;
	item.textField.text = @"";
	item.textField.tag = 10;
	item.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    item.textField.borderStyle = UITextBorderStyleRoundedRect;
	if (nameEntry) {
	} else {
		item.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		item.textField.autocorrectionType = UITextAutocorrectionTypeNo;
	}
	item.textField.keyboardType = keyboardType;
	
	return item;
}
+ (id)textPasswordNamed:(NSString*)desc placeholder:(NSString*)def {
	UNAccountItem 	*item = [[[UNAccountItem alloc] init] autorelease];
	item.name = desc;
    item.optional = NO;

	item.textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 2, 280, 40)];
	item.textField.placeholder = def;
	item.textField.text = @"";
	item.textField.tag = 10;
	item.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    item.textField.borderStyle = UITextBorderStyleRoundedRect;
	item.textField.secureTextEntry = YES;
	
	return item;
}
+ (id)switchNamed:(NSString*)desc placeholder:(NSString*)def {
	UNAccountItem 	*item = [[[UNAccountItem alloc] init] autorelease];
	item.name = desc;
    item.placeholder = def;
    item.optional = NO;
	
	item.switchField = [[UISwitch alloc] initWithFrame:CGRectZero];
	item.switchField.tag = 10;
	
	return item;
}
+ (id)showTerms:(NSString*)message {
	UNAccountItem 	*item = [[[UNAccountItem alloc] init] autorelease];
	item.name = message;
    item.placeholder = message;
    item.optional = NO;
	return item;
}

@end


/////////////////////////////////////////////////////////////////////////////////////

@implementation UserNestNewAccountViewController {
	//Private local vars...
    UserNestNetwork *unNetwork;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        allSections = [[NSMutableArray array] retain];
    }
    return self;
}
- (id)init {
    self = [super init];
    if (self) {
        allSections = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)loadView {
	if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
		self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	} else {
		CGRect    rc = [UIScreen mainScreen].applicationFrame;
		self.view = [[UIView alloc] initWithFrame:CGRectMake(rc.origin.y, rc.origin.x, rc.size.height, rc.size.width)];
	}
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.view.backgroundColor = [UIColor whiteColor];
	
	self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:self.tableView];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
        self.view.frame = self.navigationController.view.bounds;
        self.tableView.frame = self.view.bounds;

        //Nicer rounded corners on the overlay
        [self.view superview].layer.cornerRadius = 10.0f;
        [self.view superview].layer.masksToBounds = YES;
        
        [self.navigationController.view superview].layer.cornerRadius = 10.0f;
        [self.navigationController.view superview].layer.masksToBounds = YES;
    }
    
    self.navigationItem.title = NSLocalizedString(@"New Account", nil);
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back",nil) style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.view.backgroundColor = [UIColor colorWithWhite:GRAYCOLOR alpha:1.0];
    self.tableView.backgroundColor = [UIColor colorWithWhite:GRAYCOLOR alpha:1.0];

    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(clickCancel:)] autorelease]];
}

- (void)addTextItem:(UNAccountItem*)item {
	//Doesn't have more than one section yet, but could later...
	if ([allSections count]==0) {
		[allSections addObject:[NSMutableArray array]];
	}
	
	NSMutableArray	*section = [allSections lastObject];
	
	if ([section count]>0 && item.textField) {
		UNAccountItem	*lastItem = [section lastObject];
		lastItem.textField.returnKeyType = UIReturnKeyNext;
	}
	
    if (item.textField) {
        item.textField.returnKeyType = UIReturnKeyDone;
        item.textField.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:item.textField];
    }
    if (item.switchField) {
        [item.switchField addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventValueChanged];
    }
	[section addObject:item];
}
- (void)textFieldDidChange:(NSNotification *)notification {
    [self checkIfTheyreDone];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textFieldIn {
	if (textFieldIn.returnKeyType==UIReturnKeyDone) {
		[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
		[textFieldIn resignFirstResponder];
	} else {
		NSMutableArray	*section = [allSections firstObject];  //TODO: Update this if ever more than one...
		Boolean			gotoNextOne=NO;
		for (int i=0; i<section.count; i++) {
			UNAccountItem *item = [section objectAtIndex:i];
			if (gotoNextOne) {
				[item.textField becomeFirstResponder];
                if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone) {
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                }
                [self checkIfTheyreDone];
				return YES;
			}
			//Next one in the loop is Next for keyboard focus.
			if (item.textField==textFieldIn) {
				gotoNextOne = YES;
			}
		}
	}
    [self checkIfTheyreDone];
    return YES;
}
- (void)changeSwitch:(UISwitch*)sender {
    [self checkIfTheyreDone];
}

- (void)checkIfTheyreDone {
    Boolean         theyAreDone=YES;
    NSMutableArray	*section = [allSections lastObject];
    for (UNAccountItem *item in section) {
        if (!item.optional) {
            if (item.textField && item.textField.text.length==0) {
                theyAreDone = NO;
            }
            if (item.switchField && !item.switchField.on) {
                theyAreDone = NO;
            }
        }
    }
    
    if (theyAreDone) {
        if (!self.navigationItem.rightBarButtonItem) {
            [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(clickDone:)] autorelease] animated:YES];
        }
    } else {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
    }
}

- (void)userNestTOSAccepted {
	NSMutableArray	*section = [allSections lastObject];
    for (UNAccountItem *item in section) {
		if (item.switchField) {
			item.switchField.on = YES;
		}
	}
    [self checkIfTheyreDone];
}

- (void)clickCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)clickDone:(id)sender {
    if (!unNetwork) {
		unNetwork = [[UserNestNetwork alloc] initWithUserNestAppID:self.userNestAppID session:self.userNestSession];
	}
	//Get fields into a Dictionary
	NSMutableDictionary	*newAccountData = [NSMutableDictionary new];
	
	
	NSMutableArray	*section = [allSections lastObject];
    for (UNAccountItem *item in section) {
		if (item.textField) {
			//Disable Fields while it's working too...
			item.textField.enabled = NO;
			[newAccountData setObject:item.textField.text forKey:item.name];
		} else if (item.switchField) {
			//Disable Fields while it's working too...
			item.switchField.enabled = NO;
			[newAccountData setObject:item.switchField.on ? @"YES" : @"NO" forKey:item.name];
		}
	}
	
	//Show working in place of the right button
	UIActivityIndicatorView		*working = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
	[working startAnimating];
	[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:working] autorelease] animated:YES];
	
	[unNetwork createAccount:newAccountData completionHandler:^(NSDictionary *data) {
        if (data) {
            [self newAccountSuccess:data];
        } else {
            [self newAccountFailed];
        }
    }];
}
- (void)newAccountSuccess:(NSDictionary*)data {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)newAccountFailed {
    //Re-enable fields so they can fix things
    NSMutableArray	*section = [allSections lastObject];
    for (UNAccountItem *item in section) {
        if (item.textField) {
            item.textField.enabled = YES;
        } else if (item.switchField) {
            item.switchField.enabled = YES;
        }
    }
    
    [self.navigationItem setRightBarButtonItem:nil animated:NO];
    [self checkIfTheyreDone];
}

// Table View ----------------------------------------------------------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [allSections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section<[allSections count]) {
        //Return +X so can scroll the bottom real row higher up the screen
        // A slight iPhone hack that's useful for keyboard not overlapping cells they're typing in the table.
        // Adjust a bit for different devices
        NSInteger   extra = 8;
        if ([UIScreen mainScreen].bounds.size.height==568) extra = 10;
		return [(NSMutableArray*)[allSections objectAtIndex:section] count] + extra;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)inTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [inTableView dequeueReusableCellWithIdentifier:@"UserNestNewAccount"];
    if (cell==nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UserNestNewAccount"] autorelease];
        //Not sure why it's needed...but helps them be right on iPad.
        cell.bounds = CGRectMake(cell.bounds.origin.x, cell.bounds.origin.y, inTableView.bounds.size.width, cell.bounds.size.height);
	}
	
    cell.backgroundColor = [UIColor colorWithWhite:GRAYCOLOR alpha:1.0];
    cell.contentView.backgroundColor = [UIColor colorWithWhite:GRAYCOLOR alpha:1.0];
	
	//For re-using cells...
	UIView *oldViewInCell = (UIView*)[cell viewWithTag:10];
	if (oldViewInCell) [oldViewInCell removeFromSuperview];
	
    if (indexPath.row>=[(NSMutableArray*)[allSections objectAtIndex:indexPath.section] count]) {
        //Padding rows
        cell.textLabel.text = @"";
    } else {
        UNAccountItem	*unItem = (UNAccountItem*)[(NSMutableArray*)[allSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        if (unItem.textField) {
            unItem.textField.frame = CGRectMake(20, 4, cell.bounds.size.width-40, cell.bounds.size.height-8);
            cell.textLabel.text = @"";
            [cell addSubview:unItem.textField];
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else if (unItem.switchField) {
            unItem.switchField.frame = CGRectMake(cell.bounds.size.width-(30+unItem.switchField.bounds.size.width), (cell.bounds.size.height-unItem.switchField.bounds.size.height)/2,
                                                  unItem.switchField.bounds.size.width, unItem.switchField.bounds.size.height);
            [cell addSubview:unItem.switchField];
            cell.textLabel.text = unItem.placeholder;
            cell.textLabel.textColor = self.navigationController.view.tintColor;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
	
    return cell;
}

- (void)tableView:(UITableView *)inTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[inTableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row>=[(NSMutableArray*)[allSections objectAtIndex:indexPath.section] count]) {
        return;
    }

	UNAccountItem	*unItem = (UNAccountItem*)[(NSMutableArray*)[allSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if (unItem.switchField) {
        UserNestTOSViewController     *showTOS = [[UserNestTOSViewController alloc] init];
        showTOS.userNestAppID = self.userNestAppID;
		showTOS.delegate = self;
        [self.navigationController pushViewController:showTOS animated:YES];
    }
}

- (NSIndexPath *)tableView:(UITableView *)inTableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row>=[(NSMutableArray*)[allSections objectAtIndex:indexPath.section] count]) {
        return nil;
    }
	UNAccountItem	*unItem = (UNAccountItem*)[(NSMutableArray*)[allSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if (unItem.textField) {
        return nil;
    }
    return indexPath;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
