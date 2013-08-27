/**
 ALAlertBanner.m

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

#import "ALAlertBannerView.h"
#import <QuartzCore/QuartzCore.h>

static NSString * const kShowAlertBannerKey = @"showAlertBannerKey";
static NSString * const kHideAlertBannerKey = @"hideAlertBannerKey";
static NSString * const kMoveAlertBannerKey = @"moveAlertBannerKey";
static CGFloat const kMargin = 10.f;
static CGFloat const kNavigationBarHeight = 44.f;
static CGFloat const kStatusBarHeight = 20.f;

static CGFloat const kRotationDurationIphone = 0.3f;
static CGFloat const kRotationDurationIPad = 0.4f;

#define DEVICE_ANIMATION_DURATION UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? kRotationDurationIPad : kRotationDurationIphone;

# pragma mark -
# pragma mark Helper Categories

//referenced from http://stackoverflow.com/questions/11598043/get-slightly-lighter-and-darker-color-from-uicolor
@implementation UIColor (LightAndDark)
- (UIColor *)darkerColor
{
    float h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b * 0.75
                               alpha:a];
    return nil;
}
@end

@interface ALAlertBannerView ()

@property (nonatomic, assign) ALAlertBannerStyle style;
@property (nonatomic, assign) ALAlertBannerPosition position;
@property (nonatomic, assign) ALAlertBannerState state;

@property (nonatomic, assign) NSTimeInterval fadeInDuration;
@property (nonatomic, assign) NSTimeInterval fadeOutDuration;

@property (nonatomic, readonly) BOOL isAnimating;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIImageView *statusImageView;

@property (nonatomic, strong) UIView *parentView;
@property (nonatomic, assign) CGRect parentFrameUponCreation;

-(void)commonInit;
-(void)setInitialLayout;

@end

@implementation ALAlertBannerView

@synthesize style = _style;
@synthesize position = _position;
@synthesize state = _state;
@synthesize fadeInDuration = _fadeInDuration;
@synthesize fadeOutDuration = _fadeOutDuration;
@synthesize isAnimating = _isAnimating;
@synthesize titleLabel = _titleLabel;
@synthesize subtitleLabel = _subtitleLabel;
@synthesize statusImageView = _statusImageView;
@synthesize parentView = _parentView;
@synthesize parentFrameUponCreation = _parentFrameUponCreation;


//@synthesize style = _style, position = _position, state = _state, parentView = _parentView;

/**
 INTERNAL DETAILS BELOW.
 
 Used by ALAlertBannerManager only. Every time you call one of them directly, I'll be forced to watch a Channing Tatum movie. Don't do that to me bro.
 */

@synthesize delegate = _delegate;
@synthesize isScheduledToHide = _isScheduledToHide;
@synthesize allowTapToDismiss = _allowTapToDismiss;
@synthesize showShadow = _showShadow;
@synthesize showAnimationDuration = _showAnimationDuration;
@synthesize hideAnimationDuration = _hideAnimationDuration;
@synthesize bannerOpacity = _bannerOpacity;

- (id)init
{
    self = [super init];
    if (self) {
        
        [self commonInit];
        
    }
    return self;
}

# pragma mark Initializer Helpers

-(void)commonInit
{
    self.userInteractionEnabled = YES;
    self.alpha = 0.f;
    self.layer.shadowOpacity = 0.5f;
    _fadeOutDuration = 0.2f;
        
    _statusImageView = [[UIImageView alloc] init];
    [self addSubview:_statusImageView];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13.f];
    _titleLabel.textColor = [UIColor colorWithWhite:1.f alpha:0.9f];
    _titleLabel.textAlignment = NSTextAlignmentLeft;
    _titleLabel.numberOfLines = 1;
    _titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
//    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _titleLabel.layer.shadowOffset = CGSizeMake(0, -1);
    _titleLabel.layer.shadowOpacity = 0.3f;
    _titleLabel.layer.shadowRadius = 0.f;
    [self addSubview:_titleLabel];
    
    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.backgroundColor = [UIColor clearColor];
    _subtitleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10.f];
    _subtitleLabel.textColor = [UIColor colorWithWhite:1.f alpha:0.9f];
    _subtitleLabel.textAlignment = NSTextAlignmentLeft;
    _subtitleLabel.numberOfLines = 0;
    _subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _subtitleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _subtitleLabel.layer.shadowOffset = CGSizeMake(0, -1);
    _subtitleLabel.layer.shadowOpacity = 0.3f;
    _subtitleLabel.layer.shadowRadius = 0.f;
    [self addSubview:_subtitleLabel];    
}

# pragma mark Custom Setters & Getters

-(void)setStyle:(ALAlertBannerStyle)style
{
    _style = style;
    
    switch (style) {
        case ALAlertBannerStyleSuccess:
            self.statusImageView.image = [UIImage imageNamed:@"bannerSuccess.png"];
            break;
            
        case ALAlertBannerStyleFailure:
            self.statusImageView.image = [UIImage imageNamed:@"bannerFailure.png"];
            break;
            
        case ALAlertBannerStyleNotify:
            self.statusImageView.image = [UIImage imageNamed:@"bannerNotify.png"];
            break;
            
        case ALAlertBannerStyleAlert:
            self.statusImageView.image = [UIImage imageNamed:@"bannerAlert.png"];
            
            //tone the shadows down a little for the yellow background
            self.titleLabel.layer.shadowOpacity = 0.2;
            self.subtitleLabel.layer.shadowOpacity = 0.2;
            
            break;
    }    
}

-(void)setShowShadow:(BOOL)showShadow
{
    _showShadow = showShadow;
    
    CGFloat oldShadowRadius = self.layer.shadowRadius;
    CGFloat newShadowRadius;
    
    if (showShadow)
    {
        newShadowRadius = 3.f;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, self.position == ALAlertBannerPositionBottom ? -1 : 1);
        CGRect shadowPath = CGRectMake(self.bounds.origin.x - kMargin, self.bounds.origin.y, self.bounds.size.width + kMargin*2, self.bounds.size.height);
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:shadowPath].CGPath;
        
        self.fadeInDuration = 0.15f;
    }
    
    else
    {
        newShadowRadius = 0.f;
        self.layer.shadowRadius = 0.f;
        self.layer.shadowOffset = CGSizeZero;
        self.fadeInDuration = 0.f;
    }
    
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.layer.shadowRadius = newShadowRadius;
    
    CABasicAnimation *fadeShadow = [CABasicAnimation animationWithKeyPath:@"shadowRadius"];
    fadeShadow.fromValue = [NSNumber numberWithFloat:oldShadowRadius];
    fadeShadow.toValue = [NSNumber numberWithFloat:newShadowRadius];
    fadeShadow.duration = self.fadeOutDuration;
    [self.layer addAnimation:fadeShadow forKey:@"shadowRadius"];
}

-(BOOL)isAnimating
{
    return (self.state == ALAlertBannerStateShowing ||
            self.state == ALAlertBannerStateHiding ||
            self.state == ALAlertBannerStateMovingForward ||
            self.state == ALAlertBannerStateMovingBackward);
}

# pragma mark Class Methods

+(ALAlertBannerView*)alertBannerForView:(UIView*)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString*)title subtitle:(NSString*)subtitle
{
    ALAlertBannerView *alertBanner = [[ALAlertBannerView alloc] init];
    BOOL isSuperviewKindOfWindow = ([view isKindOfClass:[UIWindow class]]);
    
    if (!isSuperviewKindOfWindow && position == ALAlertBannerPositionUnderNavBar)
        [[NSException exceptionWithName:@"Bad ALAlertBannerStyle For View Type" reason:@"ALAlertBannerPositionUnderNavBar should only be used if you are presenting the alert banner on the AppDelegate window. Use ALAlertBannerPositionTop or ALAlertBannerPositionBottom for normal UIViews" userInfo:nil] raise];
    
    alertBanner.titleLabel.text = title;
    alertBanner.subtitleLabel.text = subtitle;
    alertBanner.style = style;
    alertBanner.position = position;
    alertBanner.state = ALAlertBannerStateNotVisible;
    alertBanner.parentView = view;
    
    [view addSubview:alertBanner];
    
    [alertBanner setInitialLayout];
    [alertBanner updateSizeAndSubviewsAnimated:NO];
    
    return alertBanner;
}

# pragma mark Instance Methods

-(void)show
{
    if (!CGRectEqualToRect(self.parentFrameUponCreation, self.parentView.bounds))
    {
        //if view size changed since this banner was created, reset layout
        [self setInitialLayout];
        [self updateSizeAndSubviewsAnimated:NO];
    }
    
    [self.delegate alertBannerWillShow:self inView:self.parentView];
    
    self.state = ALAlertBannerStateShowing;
    
    double delayInSeconds = self.fadeInDuration;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.position == ALAlertBannerPositionUnderNavBar)
        {
            //animate mask
            CGPoint currentPoint = self.layer.mask.position;
            CGPoint newPoint = CGPointMake(0, -self.frame.size.height);
            
            self.layer.mask.position = newPoint;
            
            CABasicAnimation *moveMaskUp = [CABasicAnimation animationWithKeyPath:@"position"];
            moveMaskUp.fromValue = [NSValue valueWithCGPoint:currentPoint];
            moveMaskUp.toValue = [NSValue valueWithCGPoint:newPoint];
            moveMaskUp.duration = self.showAnimationDuration;
            moveMaskUp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            
            [self.layer.mask addAnimation:moveMaskUp forKey:@"position"];
        }
        
        CGPoint oldPoint = self.layer.position;
        CGFloat yCoord = oldPoint.y;
        switch (self.position) {
            case ALAlertBannerPositionTop:
            case ALAlertBannerPositionUnderNavBar:
                yCoord += self.frame.size.height;
                break;
            case ALAlertBannerPositionBottom:
                yCoord -= self.frame.size.height;
                break;
        }
        CGPoint newPoint = CGPointMake(oldPoint.x, yCoord);
        
        self.layer.position = newPoint;
        
        CABasicAnimation *moveLayer = [CABasicAnimation animationWithKeyPath:@"position"];
        moveLayer.fromValue = [NSValue valueWithCGPoint:oldPoint];
        moveLayer.toValue = [NSValue valueWithCGPoint:newPoint];
        moveLayer.duration = self.showAnimationDuration;
        moveLayer.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        moveLayer.delegate = self;
        [moveLayer setValue:kShowAlertBannerKey forKey:@"anim"];
        
        [self.layer addAnimation:moveLayer forKey:@"position"];
    });
    
    [UIView animateWithDuration:self.fadeInDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.alpha = self.bannerOpacity;
    } completion:nil];
}

-(void)hide
{
    [self.delegate alertBannerWillHide:self inView:self.parentView];
    
    self.state = ALAlertBannerStateHiding;
    
    if (self.position == ALAlertBannerPositionUnderNavBar)
    {
        CGPoint currentPoint = self.layer.mask.position;
        CGPoint newPoint = CGPointZero;
        
        self.layer.mask.position = newPoint;
        
        CABasicAnimation *moveMaskDown = [CABasicAnimation animationWithKeyPath:@"position"];
        moveMaskDown.fromValue = [NSValue valueWithCGPoint:currentPoint];
        moveMaskDown.toValue = [NSValue valueWithCGPoint:newPoint];
        moveMaskDown.duration = self.hideAnimationDuration;
        moveMaskDown.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        
        [self.layer.mask addAnimation:moveMaskDown forKey:@"position"];
    }
    
    CGPoint oldPoint = self.layer.position;
    CGFloat yCoord = oldPoint.y;
    switch (self.position) {
        case ALAlertBannerPositionTop:
        case ALAlertBannerPositionUnderNavBar:
            yCoord -= self.frame.size.height;
            break;
        case ALAlertBannerPositionBottom:
            yCoord += self.frame.size.height;
            break;
    }
    CGPoint newPoint = CGPointMake(oldPoint.x, yCoord);
    
    self.layer.position = newPoint;
    
    CABasicAnimation *moveLayer = [CABasicAnimation animationWithKeyPath:@"position"];
    moveLayer.fromValue = [NSValue valueWithCGPoint:oldPoint];
    moveLayer.toValue = [NSValue valueWithCGPoint:newPoint];
    moveLayer.duration = self.hideAnimationDuration;
    moveLayer.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    moveLayer.delegate = self;
    [moveLayer setValue:kHideAlertBannerKey forKey:@"anim"];
    
    [self.layer addAnimation:moveLayer forKey:@"position"];
}

-(void)push:(CGFloat)distance forward:(BOOL)forward
{    
    self.state = (forward ? ALAlertBannerStateMovingForward : ALAlertBannerStateMovingBackward);
    
    CGFloat distanceToPush = distance;
    if (self.position == ALAlertBannerPositionBottom)
        distanceToPush *= -1;
    
    CALayer *activeLayer = self.isAnimating ? (CALayer*)[self.layer presentationLayer] : self.layer;
    
    CGPoint oldPoint = activeLayer.position;
    CGPoint newPoint = CGPointMake(oldPoint.x, (self.layer.position.y - oldPoint.y)+oldPoint.y+distanceToPush);
    
    self.layer.position = newPoint;
    
    CABasicAnimation *moveLayer = [CABasicAnimation animationWithKeyPath:@"position"];
    moveLayer.fromValue = [NSValue valueWithCGPoint:oldPoint];
    moveLayer.toValue = [NSValue valueWithCGPoint:newPoint];
    moveLayer.duration = forward ? self.showAnimationDuration : self.hideAnimationDuration;
    moveLayer.timingFunction = forward ? [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut] : [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    moveLayer.delegate = self;
    [moveLayer setValue:kMoveAlertBannerKey forKey:@"anim"];
    
    [self.layer addAnimation:moveLayer forKey:@"position"];
}

# pragma mark Touch Recognition

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.state == ALAlertBannerStateVisible && self.allowTapToDismiss)
        [self.delegate hideAlertBanner:self];
}

# pragma mark Private Methods

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{    
    if ([[anim valueForKey:@"anim"] isEqualToString:kShowAlertBannerKey] && flag)
    {
        [self.delegate alertBannerDidShow:self inView:self.parentView];
        self.state = ALAlertBannerStateVisible;
    }
    
    else if ([[anim valueForKey:@"anim"] isEqualToString:kHideAlertBannerKey] && flag)
    {
        [UIView animateWithDuration:self.fadeOutDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.alpha = 0.f;
        } completion:^(BOOL finished) {
            self.state = ALAlertBannerStateNotVisible;
            [self.delegate alertBannerDidHide:self inView:self.parentView];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [self removeFromSuperview];
        }];
    }
    
    else if ([[anim valueForKey:@"anim"] isEqualToString:kMoveAlertBannerKey] && flag)
    {
        self.state = ALAlertBannerStateVisible;
    }
}

-(void)didMoveToSuperview
{
    //TODO transform view for uiwindow
}

-(void)setInitialLayout
{
    self.layer.anchorPoint = CGPointMake(0, 0);
    
    UIView *parentView = self.parentView;
    self.parentFrameUponCreation = parentView.bounds;
    BOOL isSuperviewKindOfWindow = ([parentView isKindOfClass:[UIWindow class]]);
    
    CGSize maxLabelSize = CGSizeMake(parentView.bounds.size.width - (kMargin*3) - self.statusImageView.image.size.width, CGFLOAT_MAX);
    CGFloat titleLabelHeight = self.titleLabel.font.pointSize + 2.f;
    CGFloat subtitleLabelHeight = [self.subtitleLabel.text sizeWithFont:self.subtitleLabel.font constrainedToSize:maxLabelSize lineBreakMode:self.subtitleLabel.lineBreakMode].height;
    CGFloat heightForSelf = titleLabelHeight + subtitleLabelHeight + (self.subtitleLabel.text == nil ? kMargin*2 : kMargin*2.5);
    
    CGRect frame = CGRectMake(0, 0, parentView.bounds.size.width, heightForSelf);
    CGFloat initialYCoord = 0.f;
    switch (self.position) {
        case ALAlertBannerPositionTop:
            initialYCoord = -heightForSelf;
            if (isSuperviewKindOfWindow) initialYCoord += kStatusBarHeight;
            break;
        case ALAlertBannerPositionBottom:
            initialYCoord = parentView.bounds.size.height;
            break;
        case ALAlertBannerPositionUnderNavBar:
            initialYCoord = -heightForSelf + kNavigationBarHeight + kStatusBarHeight;
            break;
    }
    frame.origin.y = initialYCoord;
    self.frame = frame;
    
    //if position is under the nav bar, add a mask
    if (self.position == ALAlertBannerPositionUnderNavBar)
    {
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        CGRect maskRect = CGRectMake(0, frame.size.height, frame.size.width, parentView.bounds.size.height); //give the mask enough height so it doesn't clip the shadow
        CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
        maskLayer.path = path;
        CGPathRelease(path);
        
        self.layer.mask = maskLayer;
        self.layer.mask.position = CGPointZero;
    }
}

-(void)updateSizeAndSubviewsAnimated:(BOOL)animated
{
    CGSize maxLabelSize = CGSizeMake(self.parentView.bounds.size.width - (kMargin*3) - self.statusImageView.image.size.width, CGFLOAT_MAX);
    CGFloat titleLabelHeight = self.titleLabel.font.pointSize + 2.f;
    CGFloat subtitleLabelHeight = [self.subtitleLabel.text sizeWithFont:self.subtitleLabel.font constrainedToSize:maxLabelSize lineBreakMode:self.subtitleLabel.lineBreakMode].height;
    CGFloat heightForSelf = titleLabelHeight + subtitleLabelHeight + (self.subtitleLabel.text == nil ? kMargin*2 : kMargin*2.5);
    
    CFTimeInterval boundsAnimationDuration = DEVICE_ANIMATION_DURATION;
        
    CGRect oldBounds = self.layer.bounds;
    CGRect newBounds = oldBounds;
    newBounds.size = CGSizeMake(self.parentView.frame.size.width, heightForSelf);
    self.layer.bounds = newBounds;
    
    if (animated)
    {
        CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        boundsAnimation.fromValue = [NSValue valueWithCGRect:oldBounds];
        boundsAnimation.toValue = [NSValue valueWithCGRect:newBounds];
        boundsAnimation.duration = boundsAnimationDuration;
        [self.layer addAnimation:boundsAnimation forKey:@"bounds"];
    }
    
    if (animated)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:boundsAnimationDuration];
    }
    
    self.statusImageView.frame = CGRectMake(kMargin, (self.frame.size.height/2) - (self.statusImageView.image.size.height/2), self.statusImageView.image.size.width, self.statusImageView.image.size.height);
    self.titleLabel.frame = CGRectMake(self.statusImageView.frame.origin.x + self.statusImageView.frame.size.width + kMargin, kMargin, maxLabelSize.width, titleLabelHeight);
    self.subtitleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + kMargin/2, maxLabelSize.width, subtitleLabelHeight);
    
    if (animated)
        [UIView commitAnimations];
    
    if (self.showShadow)
    {
        CGRect oldShadowPath = CGPathGetPathBoundingBox(self.layer.shadowPath);
        CGRect newShadowPath = CGRectMake(self.bounds.origin.x - kMargin, self.bounds.origin.y, self.bounds.size.width + kMargin*2, self.bounds.size.height);
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:newShadowPath].CGPath;
        
        if (animated)
        {
            CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
            shadowAnimation.fromValue = (id)[UIBezierPath bezierPathWithRect:oldShadowPath].CGPath;
            shadowAnimation.toValue = (id)[UIBezierPath bezierPathWithRect:newShadowPath].CGPath;
            shadowAnimation.duration = boundsAnimationDuration;
            [self.layer addAnimation:shadowAnimation forKey:@"shadowPath"];
        }
    }
}

-(void)updatePositionAfterRotationWithY:(CGFloat)yPos animated:(BOOL)animated
{    
    CFTimeInterval positionAnimationDuration = kRotationDurationIphone; 

    BOOL isAnimating = self.isAnimating;
    CALayer *activeLayer = isAnimating ? (CALayer*)self.layer.presentationLayer : self.layer;
    NSString *currentAnimationKey = nil;
    CAMediaTimingFunction *timingFunction = nil;
    
    if (isAnimating)
    {
        CABasicAnimation *currentAnimation;
        if (self.state == ALAlertBannerStateShowing) {
            currentAnimation = (CABasicAnimation*)[self.layer animationForKey:kShowAlertBannerKey];
            currentAnimationKey = kShowAlertBannerKey;
        } else if (self.state == ALAlertBannerStateHiding) {
            currentAnimation = (CABasicAnimation*)[self.layer animationForKey:kHideAlertBannerKey];
            currentAnimationKey = kHideAlertBannerKey;
        } else if (self.state == ALAlertBannerStateMovingBackward || self.state == ALAlertBannerStateMovingForward) {
            currentAnimation = (CABasicAnimation*)[self.layer animationForKey:kMoveAlertBannerKey];
            currentAnimationKey = kMoveAlertBannerKey;
        } else
            return;

        CFTimeInterval remainingAnimationDuration = currentAnimation.duration - (CACurrentMediaTime() - currentAnimation.beginTime);
        timingFunction = currentAnimation.timingFunction;
        positionAnimationDuration = remainingAnimationDuration;
        
        [self.layer removeAnimationForKey:currentAnimationKey];
    }

    if (self.state == ALAlertBannerStateHiding || self.state == ALAlertBannerStateMovingBackward)
    {
        switch (self.position) {
            case ALAlertBannerPositionTop:
            case ALAlertBannerPositionUnderNavBar:
                yPos -= self.layer.bounds.size.height;
                break;
                
            case ALAlertBannerPositionBottom:
                yPos += self.layer.bounds.size.height;
                break;
        }
    }
    CGPoint oldPos = activeLayer.position;
    CGPoint newPos = CGPointMake(oldPos.x, yPos);
    self.layer.position = newPos;
    
    if (animated)
    {        
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.fromValue = [NSValue valueWithCGPoint:oldPos];
        positionAnimation.toValue = [NSValue valueWithCGPoint:newPos];
        
        //because the banner's location is relative to the height of the screen when in the bottom position, we should just immediately set it's position upon rotation events. this will prevent any ill-timed animations due to the presentation layer's position at the time of rotation
        if (self.position == ALAlertBannerPositionBottom)
            positionAnimationDuration = DEVICE_ANIMATION_DURATION;
        
        positionAnimation.duration = positionAnimationDuration;
        positionAnimation.timingFunction = timingFunction == nil ? [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear] : timingFunction;
        
        if (currentAnimationKey != nil)
        {
            //hijack the old animation's key value
            positionAnimation.delegate = self;
            [positionAnimation setValue:currentAnimationKey forKey:@"anim"];
        }
        
        [self.layer addAnimation:positionAnimation forKey:currentAnimationKey];
    }
}

-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *fillColor;
    switch (self.style) {
        case ALAlertBannerStyleSuccess:
            fillColor = [UIColor colorWithRed:(77/255.0) green:(175/255.0) blue:(67/255.0) alpha:1.f];
            break;
        case ALAlertBannerStyleFailure:
            fillColor = [UIColor colorWithRed:(173/255.0) green:(48/255.0) blue:(48/255.0) alpha:1.f];
            break;
        case ALAlertBannerStyleNotify:
            fillColor = [UIColor colorWithRed:(48/255.0) green:(110/255.0) blue:(173/255.0) alpha:1.f];
            break;
        case ALAlertBannerStyleAlert:
            fillColor = [UIColor colorWithRed:(211/255.0) green:(209/255.0) blue:(100/255.0) alpha:1.f];
            break;
    }
    
    NSArray *colorsArray = [NSArray arrayWithObjects:(id)[fillColor CGColor], (id)[[fillColor darkerColor] CGColor], nil];
    CGColorSpaceRef colorSpace =  CGColorSpaceCreateDeviceRGB();
    const CGFloat locations[2] = {0.0, 1.0};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colorsArray, locations);
    
    CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(0, self.bounds.size.height), 0);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6].CGColor);
    CGContextFillRect(context, CGRectMake(0, rect.size.height - 1.f, rect.size.width, 1.f));
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, rect.size.width, 1.f));
}

@end