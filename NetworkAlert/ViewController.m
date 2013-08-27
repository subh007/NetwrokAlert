//
//  ViewController.m
//  NetworkAlert
//
//  Created by subh on 27/08/13.
//  Copyright (c) 2013 subh. All rights reserved.
//

#import "ViewController.h"
#import "Reachability.h"
#import "ALAlertBannerView.h"
#import "ALAlertBannerManager.h"

@interface ViewController ()
@property(nonatomic, retain) Reachability *wifi;
@end

@implementation ViewController
@synthesize wifi = _wifi;

- (void)dealloc {
    [_networkAvailLabel release];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [super dealloc];
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self){
        // initialize the reachability module
        _wifi = [Reachability reachabilityForLocalWiFi];
        [_wifi startNotifier];
        
        // register to receive the notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - notification Handler
- (void) reachabilityChanged:(NSNotification *)note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);

    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    //BOOL connectionRequired = [curReach connectionRequired];
    
    ALAlertBannerPosition position;
    ALAlertBannerStyle randomStyle;
    
    switch (netStatus)
    {
        case NotReachable:
            NSLog(@"wi fi is not available");
            [self.networkAvailLabel setBackgroundColor:[UIColor redColor]];
            [self.networkAvailLabel setText:@"wifi is not available"];
            
            position = ALAlertBannerPositionTop;
            randomStyle = ALAlertBannerStyleFailure;
            [[ALAlertBannerManager sharedManager] showAlertBannerInView:self.view style:randomStyle position:position title:@"Network Availability" subtitle:@"network is not available."];
            
            break;
        case ReachableViaWiFi:
            NSLog(@"reachable via wifi");
            [self.networkAvailLabel setBackgroundColor:[UIColor greenColor]];
            [self.networkAvailLabel setText:@"wifi is available"];
            position = ALAlertBannerPositionTop;
            randomStyle = ALAlertBannerStyleSuccess;
            [[ALAlertBannerManager sharedManager] showAlertBannerInView:self.view style:randomStyle position:position title:@"Network Availability" subtitle:@"network is not available."];
            break;
        case ReachableViaWWAN:
            NSLog(@"reachable iew wwam");
            [self.networkAvailLabel setBackgroundColor:[UIColor blueColor]];
            [self.networkAvailLabel setText:@"wifi is available"];
            break;
        default:
            break;
    }
}
@end
