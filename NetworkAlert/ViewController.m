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
@end

@implementation ViewController

- (void)dealloc {
    [_networkAvailLabel release];
    [super dealloc];
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self){
        
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

@end
