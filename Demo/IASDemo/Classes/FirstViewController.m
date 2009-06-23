//
//  FirstViewController.m
//  IASDemo
//
//  Created by Miklós Fazekas on 6/20/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "FirstViewController.h"

#import "IASSettingsController.h"


@implementation FirstViewController

- (void)defaultsChanged:(NSNotification*)notification
{
    // defaults changed
}

- (void)observeDefaults:(NSUserDefaults*)defaults
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self observeDefaults:[NSUserDefaults standardUserDefaults]];
}

- (void)_settingsFinished:(NSUserDefaults*)defaults
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)showSettings
{
    IASSettingsController* settingsController = [[[IASSettingsController alloc] init] autorelease];
    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:settingsController];
    navigationController.topViewController.navigationItem.prompt = @"Set login/password";
    navigationController.topViewController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(_settingsFinished:)] autorelease];
    navigationController.topViewController.navigationItem.hidesBackButton = NO;
    [self presentModalViewController:navigationController animated:YES]; 
    
}

- (void)_showAlert:(id)sender
{
    UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:@"No login/password" message:@"please specify a nonempty login/password" delegate:self cancelButtonTitle:0 otherButtonTitles:@"OK",0] autorelease];
    [alert show];
}

- (void)showNoLoginPasswordAlert
{
    [self showSettings];
    [self performSelector:@selector(_showAlert:) withObject:self afterDelay:0.0];
}

- (void)loadData:(NSUserDefaults*)defaults
{
    loginField.text = [defaults stringForKey:@"name_preference"];
    passwordField.text = [defaults stringForKey:@"password_preference"];
    
    if (loginField.text.length == 0 || passwordField.text.length == 0) {
        [self showNoLoginPasswordAlert];
    }
}    

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadData:[NSUserDefaults standardUserDefaults]];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
