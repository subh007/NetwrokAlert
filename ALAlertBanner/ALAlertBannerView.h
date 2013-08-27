/**
 ALAlertBanner.h
 
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

#import <UIKit/UIKit.h>

typedef enum {
    ALAlertBannerStyleSuccess = 0,
    ALAlertBannerStyleFailure,
    ALAlertBannerStyleNotify,
    ALAlertBannerStyleAlert,
} ALAlertBannerStyle;

typedef enum {
    ALAlertBannerPositionTop = 0,
    ALAlertBannerPositionBottom,
    ALAlertBannerPositionUnderNavBar,
} ALAlertBannerPosition;

typedef enum {
    ALAlertBannerStateShowing = 0,
    ALAlertBannerStateHiding,
    ALAlertBannerStateMovingForward,
    ALAlertBannerStateMovingBackward,
    ALAlertBannerStateVisible,
    ALAlertBannerStateNotVisible
} ALAlertBannerState;

@class ALAlertBannerView;
@protocol ALAlertBannerViewDelegate <NSObject>
@required
-(void)alertBannerWillShow:(ALAlertBannerView*)alertBanner inView:(UIView*)view;
-(void)alertBannerDidShow:(ALAlertBannerView*)alertBanner inView:(UIView*)view;
-(void)alertBannerWillHide:(ALAlertBannerView*)alertBanner inView:(UIView*)view;
-(void)alertBannerDidHide:(ALAlertBannerView*)alertBanner inView:(UIView*)view;
-(void)hideAlertBanner:(ALAlertBannerView*)alertBanner;
@end

@interface ALAlertBannerView : UIView

@property (nonatomic, readonly) ALAlertBannerStyle style;
@property (nonatomic, readonly) ALAlertBannerPosition position;
@property (nonatomic, readonly) ALAlertBannerState state;

@property (nonatomic, readonly, strong) UIView *parentView;

/**
 INTERNAL DETAILS BELOW.
 
 Used by ALAlertBannerManager only. Every time you call one of them directly, I'll be forced to watch a Channing Tatum movie. Don't do that to me bro.
 */

@property (nonatomic, weak) id <ALAlertBannerViewDelegate> delegate;

@property (nonatomic) BOOL isScheduledToHide;
@property (nonatomic) BOOL allowTapToDismiss;

@property (nonatomic) BOOL showShadow;
@property (nonatomic) NSTimeInterval showAnimationDuration;
@property (nonatomic) NSTimeInterval hideAnimationDuration;
@property (nonatomic) CGFloat bannerOpacity;

+(ALAlertBannerView*)alertBannerForView:(UIView*)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString*)title subtitle:(NSString*)subtitle;
-(void)show;
-(void)hide;
-(void)push:(CGFloat)distance forward:(BOOL)forward;
-(void)updateSizeAndSubviewsAnimated:(BOOL)animated;
-(void)updatePositionAfterRotationWithY:(CGFloat)yPos animated:(BOOL)animated;

@end


