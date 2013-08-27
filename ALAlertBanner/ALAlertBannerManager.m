/**
 ALAlertBannerManager.m
 
 Created by Anthony Lobianco on 8/12/13.
 Copyright (c) 2013 Anthony Lobianco. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 **/

#import "ALAlertBannerManager.h"
#import "Reachability.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

# pragma mark -
# pragma mark Categories for Convenience

@interface UIView (Convenience)
@property (nonatomic, strong) NSMutableArray *alertBanners;
@end

@implementation UIView (Convenience)
@dynamic alertBanners;
-(void)setAlertBanners:(NSMutableArray *)alertBanners
{
    objc_setAssociatedObject(self, @selector(alertBanners), alertBanners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(NSMutableArray *)alertBanners
{
    NSMutableArray *alertBannersArray = objc_getAssociatedObject(self, @selector(alertBanners));
    if (alertBannersArray == nil)
    {
        alertBannersArray = [NSMutableArray new];
        [self setAlertBanners:alertBannersArray];
    }
    return alertBannersArray;
}
@end

@interface ALAlertBannerManager () <ALAlertBannerViewDelegate>

@property (nonatomic) dispatch_semaphore_t topPositionSemaphore;
@property (nonatomic) dispatch_semaphore_t bottomPositionSemaphore;
@property (nonatomic) dispatch_semaphore_t navBarPositionSemaphore;
@property (nonatomic, strong) NSMutableArray *bannerViews;
@property(nonatomic, retain) Reachability *wifi;


-(void)didRotate:(NSNotification *)note;

@end

@implementation ALAlertBannerManager

@synthesize wifi = _wifi;

+(ALAlertBannerManager *)sharedManager
{
    static ALAlertBannerManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[ALAlertBannerManager alloc] init];
    });
    return sharedManager;
}

-(id)init
{
    self = [super init];
    if (self) {
        
        //let's make sure only one animation happens at a time
        _topPositionSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_topPositionSemaphore);
        _bottomPositionSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_bottomPositionSemaphore);
        _navBarPositionSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_navBarPositionSemaphore);
        
        _bannerViews = [NSMutableArray new];
        _secondsToShow = 3.5f;
        _showAnimationDuration = 0.25f;
        _hideAnimationDuration = 0.2f;
        _allowTapToDismiss = YES;
        _bannerOpacity = 0.93f;
        
        //TODO
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
        
        /// initialize the reachability module
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

-(void)showAlertBannerInView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title subtitle:(NSString *)subtitle
{
    ALAlertBannerView *alertBanner = [ALAlertBannerView alertBannerForView:view style:style position:position title:title subtitle:subtitle];
    alertBanner.delegate = self;
    alertBanner.tag = arc4random_uniform(SHRT_MAX);
    alertBanner.showAnimationDuration = self.showAnimationDuration;
    alertBanner.hideAnimationDuration = self.hideAnimationDuration;
    alertBanner.allowTapToDismiss = self.allowTapToDismiss;
    alertBanner.isScheduledToHide = NO;
    alertBanner.bannerOpacity = self.bannerOpacity;
    
    //keep track of all views we've added banners to, to deal with rotation events and hideAllAlertBanners
    if (![self.bannerViews containsObject:view])
        [self.bannerViews addObject:view];
    
    [self showAlertBanner:alertBanner];
}

-(void)showAlertBanner:(ALAlertBannerView*)alertBanner
{
    dispatch_semaphore_t semaphore;
    switch (alertBanner.position) {
        case ALAlertBannerPositionTop:
            semaphore = self.topPositionSemaphore;
            break;
        case ALAlertBannerPositionBottom:
            semaphore = self.bottomPositionSemaphore;
            break;
        case ALAlertBannerPositionUnderNavBar:
            semaphore = self.navBarPositionSemaphore;
            break;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertBanner show];
            
            if (self.secondsToShow > 0)
                [self performSelector:@selector(hideAlertBanner:) withObject:alertBanner afterDelay:self.secondsToShow];
        });
    });
}

# pragma mark -
# pragma mark Delegate Methods

-(void)hideAlertBanner:(ALAlertBannerView *)alertBanner
{
    if (alertBanner.isScheduledToHide)
        return;
    
    [NSOperation cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAlertBanner:) object:alertBanner];
    
    alertBanner.isScheduledToHide = YES;
    
    dispatch_semaphore_t semaphore;
    switch (alertBanner.position) {
        case ALAlertBannerPositionTop:
            semaphore = self.topPositionSemaphore;
            break;
        case ALAlertBannerPositionBottom:
            semaphore = self.bottomPositionSemaphore;
            break;
        case ALAlertBannerPositionUnderNavBar:
            semaphore = self.navBarPositionSemaphore;
            break;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertBanner hide];
        });
    });
}

-(void)alertBannerWillShow:(ALAlertBannerView *)alertBanner inView:(UIView*)view
{
    NSMutableArray *bannersArray = view.alertBanners;
    for (ALAlertBannerView *banner in bannersArray)
        if (banner.position == alertBanner.position)
            [banner push:alertBanner.frame.size.height forward:YES];
    
    [bannersArray addObject:alertBanner];
    NSArray *bannersInSamePosition = [bannersArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", alertBanner.position]];
    alertBanner.showShadow = (bannersInSamePosition.count > 1 ? NO : YES);
}

-(void)alertBannerDidShow:(ALAlertBannerView *)alertBanner inView:(UIView *)view
{
    dispatch_semaphore_t semaphore;
    switch (alertBanner.position) {
        case ALAlertBannerPositionTop:
            semaphore = self.topPositionSemaphore;
            break;
        case ALAlertBannerPositionBottom:
            semaphore = self.bottomPositionSemaphore;
            break;
        case ALAlertBannerPositionUnderNavBar:
            semaphore = self.navBarPositionSemaphore;
            break;
    }
    dispatch_semaphore_signal(semaphore);
}

-(void)alertBannerWillHide:(ALAlertBannerView *)alertBanner inView:(UIView *)view
{
    NSMutableArray *bannersArray = view.alertBanners;
    NSArray *bannersInSamePosition = [bannersArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", alertBanner.position]];
    NSUInteger index = [bannersInSamePosition indexOfObject:alertBanner];
    if (index != NSNotFound && index > 0)
    {
        NSArray *bannersToPush = [bannersInSamePosition subarrayWithRange:NSMakeRange(0, index)];

        for (ALAlertBannerView *banner in bannersToPush)
            [banner push:-alertBanner.frame.size.height forward:NO];
    }
    
    else if (index == 0)
    {
        if (bannersInSamePosition.count > 1)
        {
            ALAlertBannerView *nextAlertBanner = (ALAlertBannerView*)[bannersInSamePosition objectAtIndex:1];
            [nextAlertBanner setShowShadow:YES];
        }
        
        [alertBanner setShowShadow:NO];
    }
}

-(void)alertBannerDidHide:(ALAlertBannerView *)alertBanner inView:(UIView *)view
{
    NSMutableArray *bannersArray = view.alertBanners;
    dispatch_semaphore_t semaphore;
    switch (alertBanner.position) {
        case ALAlertBannerPositionTop:
            semaphore = self.topPositionSemaphore;
            break;
        case ALAlertBannerPositionBottom:
            semaphore = self.bottomPositionSemaphore;
            break;
        case ALAlertBannerPositionUnderNavBar:
            semaphore = self.navBarPositionSemaphore;
            break;
    }
    [bannersArray removeObject:alertBanner];
    dispatch_semaphore_signal(semaphore);
}

# pragma mark -
# pragma mark Instance Methods

-(NSArray *)alertBannersInView:(UIView *)view
{
    /*
    NSMutableArray *arrayOfBanners = [[NSMutableArray alloc] init];
    for (UIView *subview in view.subviews)
        if ([subview isKindOfClass:[ALAlertBannerView class]])
            [arrayOfBanners addObject:(ALAlertBannerView*)subview];
     */
    
    return [NSArray arrayWithArray:view.alertBanners];
}

-(void)hideAlertBannersInView:(UIView *)view
{
    for (ALAlertBannerView *alertBanner in [self alertBannersInView:view])
        [self hideAlertBanner:alertBanner];
}

-(void)hideAllAlertBanners
{
    for (UIView *view in self.bannerViews)
        [self hideAlertBannersInView:view];
}

# pragma mark -
# pragma mark Private Methods

-(void)didRotate:(NSNotification *)note
{    
    for (UIView *view in self.bannerViews)
    {
        NSArray *topBanners = [view.alertBanners filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", ALAlertBannerPositionTop]];
        CGFloat topYCoord = 0.f;
        for (ALAlertBannerView *alertBanner in [topBanners reverseObjectEnumerator])
        {
            [alertBanner updateSizeAndSubviewsAnimated:YES];
            [alertBanner updatePositionAfterRotationWithY:topYCoord animated:YES];
            topYCoord += alertBanner.layer.bounds.size.height;
        }
        
        NSArray *bottomBanners = [view.alertBanners filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", ALAlertBannerPositionBottom]];
        CGFloat bottomYCoord = view.bounds.size.height;
        for (ALAlertBannerView *alertBanner in [bottomBanners reverseObjectEnumerator])
        {
            //update frame size before animating to new position
            [alertBanner updateSizeAndSubviewsAnimated:YES];
            bottomYCoord -= alertBanner.layer.bounds.size.height;
            [alertBanner updatePositionAfterRotationWithY:bottomYCoord animated:YES];
        }
        
        //TODO rotation for UIWindow
    }
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
        {
            NSLog(@"wi fi is not available");
//            [self.networkAvailLabel setBackgroundColor:[UIColor redColor]];
//            [self.networkAvailLabel setText:@"wifi is not available"];
            
            position = ALAlertBannerPositionTop;
            randomStyle = ALAlertBannerStyleFailure;
            UIView *view = [_navCtrl topViewController].view;
            [[ALAlertBannerManager sharedManager] showAlertBannerInView:view style:randomStyle position:position title:@"Network Availability" subtitle:@"network is not available."];
        }
            break;
        case ReachableViaWiFi:
        {
            NSLog(@"reachable via wifi");
//            [self.networkAvailLabel setBackgroundColor:[UIColor greenColor]];
//            [self.networkAvailLabel setText:@"wifi is available"];
            position = ALAlertBannerPositionTop;
            randomStyle = ALAlertBannerStyleSuccess;
            UIView *view = [_navCtrl topViewController].view;
            [[ALAlertBannerManager sharedManager] showAlertBannerInView:view style:randomStyle position:position title:@"Network Availability" subtitle:@"network is available."];
        }
            break;
        case ReachableViaWWAN:
            NSLog(@"reachable iew wwam");
//            [self.networkAvailLabel setBackgroundColor:[UIColor blueColor]];
//            [self.networkAvailLabel setText:@"wifi is available"];
            break;
        default:
            break;
    }
}


#pragma mark -

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    _wifi = nil;
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

@end
