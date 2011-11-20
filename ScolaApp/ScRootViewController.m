//
//  ScRootViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScRootViewController.h"

#import "FBConnect.h"

#import "ScAppDelegate.h"
#import "ScAppEnv.h"
#import "ScLogging.h"
#import "ScRestConnection.h"

#define kSoundbitTypewriter @"typewriter.caf"


@implementation ScRootViewController

@synthesize scolaLabel;
@synthesize loginLabel;
@synthesize facebookLoginButton;
@synthesize googleLoginButton;
@synthesize showInfoButton;

@synthesize fetchedResultsController;


#pragma mark - Internal methods

- (void)scolaSplash:(id)sender
{
    [NSThread sleepForTimeInterval:1.0];
    
    [typewriter1 play];
    [scolaLabel performSelectorOnMainThread:@selector(setText:)
                                 withObject:@"."
                              waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.2];
    [typewriter2 play];
    [scolaLabel performSelectorOnMainThread:@selector(setText:)
                                 withObject:@".."
                              waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.4];
    [typewriter1 play];
    [scolaLabel performSelectorOnMainThread:@selector(setText:)
                                 withObject:@"..s"
                              waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.3];
    [typewriter2 play];
    [scolaLabel performSelectorOnMainThread:@selector(setText:)
                                 withObject:@"..sc"
                              waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.4];
    [typewriter1 play];
    [scolaLabel performSelectorOnMainThread:@selector(setText:)
                                 withObject:@"..sco"
                              waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.3];
    [typewriter2 play];
    [scolaLabel performSelectorOnMainThread:@selector(setText:)
                                 withObject:@"..scol"
                              waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.6];
    [typewriter1 play];
    [scolaLabel performSelectorOnMainThread:@selector(setText:)
                                 withObject:@"..scola"
                              waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.4];
    [typewriter2 play];
    [scolaLabel performSelectorOnMainThread:@selector(setText:)
                                 withObject:@"..scola."
                              waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.2];
    [typewriter1 play];
    [scolaLabel performSelectorOnMainThread:@selector(setText:)
                                 withObject:@"..scola.."
                              waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:1.0];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    
    // Obtain UI strings from backend
    ScRestConnection *serverConnection = [[ScRestConnection alloc] initWithStringHandler];
    serverConnection.delegate = self;
    [serverConnection performRequest:@"strings/nb"];

    // Hide login widgets until strings have been received
    [self loginLabel].hidden = YES;
    [self facebookLoginButton].hidden = YES;
    [self googleLoginButton].hidden = YES;
    [self showInfoButton].hidden = YES;
    
    scolaLabel.text = @"";
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Set up the 'typewriter' instances for the splash screen
    NSURL *URL = [NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:kSoundbitTypewriter]];
    
    NSError *error;
    typewriter1 = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:&error];
    typewriter2 = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:&error];
    
    if (typewriter1 && typewriter2) {
        [typewriter1 prepareToPlay];
        [typewriter2 prepareToPlay];
    } else {
        ScLogWarning(@"Error initialising audio: %@", error);
    }
    
    // Run splash thread
    [[[NSThread alloc] initWithTarget:self
                             selector:@selector(scolaSplash:)
                               object:nil] start];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - IBAction implementations

- (IBAction)logInWithFacebook:(id)sender
{
    [(ScAppDelegate *)[[UIApplication sharedApplication] delegate] logInWithFacebook];
}


- (IBAction)logInWithGoogle:(id)sender
{
    [(ScAppDelegate *)[[UIApplication sharedApplication] delegate] logInWithGoogle];
}


- (IBAction)logOut:(id)sender
{
    // TODO: Where to put the logout button?
    [(ScAppDelegate *)[[UIApplication sharedApplication] delegate] logOut];
}


- (IBAction)showInfo:(id)sender
{
    // TODO
}


#pragma mark - ScRestConnectionDelegate implementations

- (void)willSendRequest:(NSURLRequest *)request
{
    ScLogDebug(@"Will send HTTP request: %@", request);
}


- (void)didReceiveResponse:(NSURLResponse *)response
{
    ScLogDebug(@"Received HTTP response: %@", response);
}


- (void)finishedReceivingData:(NSData *)data
{
    ScLogDebug(@"Finished receiving data. Data = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    NSError *error;
    NSDictionary *dataAsDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    if (!dataAsDictionary) {
        ScLogError(@"Error converting from JSON data: %@", error);
    } else {
        ScLogDebug(@"Parsed JSON type is %@", [dataAsDictionary class]);
        NSArray *keyValueArray = [[[dataAsDictionary objectForKey:@"root"] objectForKey:@"strings"] objectForKey:@"entry"];
        ScLogDebug(@"Key/value array: %@", keyValueArray);
        
        NSMutableDictionary *strings = [[NSMutableDictionary alloc] init];
        
        for (int i = 0; i < [keyValueArray count]; i++) {
            NSDictionary *keyValuePair = [keyValueArray objectAtIndex:i];
            [strings setObject:[keyValuePair objectForKey:@"value"] forKey:[keyValuePair objectForKey:@"key"]];
        }
        
        [self loginLabel].text = [strings valueForKey:@"strLoginWith"];
        
        // Hide login widgets if valid access token exists
        [self loginLabel].hidden = [ScAppEnv env].isLoggedIn;
        [self facebookLoginButton].hidden = [ScAppEnv env].isLoggedIn;
        [self googleLoginButton].hidden = [ScAppEnv env].isLoggedIn;
        [self showInfoButton].hidden = [ScAppEnv env].isLoggedIn;
    }
}

@end
