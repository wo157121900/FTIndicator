//
//  FTToastIndicator.m
//  FTIndicatorDemo
//
//  Created by liufengting on 16/7/26.
//  Copyright © 2016年 liufengting. All rights reserved.
//

#import "FTToastIndicator.h"

#define kFTScreenWidth    [UIScreen mainScreen].bounds.size.width
#define kFTScreenHeight   [UIScreen mainScreen].bounds.size.height

#pragma mark - FTToastIndicator

@interface FTToastIndicator ()

@property (nonatomic, strong)FTToastIndicatorView *toastView;
@property (nonatomic, assign)UIBlurEffectStyle indicatorStyle;
@property (nonatomic, strong)NSString *toastMessage;
@property (nonatomic, strong)NSTimer *dismissTimer;
@property (nonatomic, assign)BOOL isDuringAnimation;
@property (nonatomic, assign)BOOL isCurrentlyOnScreen;

@end

@implementation FTToastIndicator

#pragma mark - class methods

+(FTToastIndicator *)sharedInstance
{
    static FTToastIndicator *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[FTToastIndicator alloc] init];
    });
    return shared;
}

+(void)setToastIndicatorStyleToDefaultStyle
{
    [self sharedInstance].indicatorStyle = UIBlurEffectStyleLight;
}

+(void)setToastIndicatorStyle:(UIBlurEffectStyle)style
{
    [self sharedInstance].indicatorStyle = style;
}

+(void)showToastMessage:(NSString *)toastMessage
{
    [[self sharedInstance] showToastMessage:toastMessage];
}

+(void)dismiss
{
    [[self sharedInstance] dismiss];
}

#pragma mark - instance methods

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onChangeStatusBarOrientationNotification:)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onKeyboardWillChangeFrame:)
                                                     name:UIKeyboardWillChangeFrameNotification
                                                   object:nil];
    }
    return self;
}

-(FTToastIndicatorView *)toastView
{
    if (!_toastView) {
        _toastView = [[FTToastIndicatorView alloc] initWithFrame:CGRectZero];
    }
    return _toastView;
}

-(void)showToastMessage:(NSString *)toastMessage
{
    self.toastMessage = toastMessage;
    self.isCurrentlyOnScreen = NO;

    if (self.isDuringAnimation) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kFTToastDefaultAnimationDuration * 1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self adjustIndicatorFrame];
        });
    }else{
        [self adjustIndicatorFrame];
    }
}

-(void)dismiss
{
    [self stopDismissTimer];
    [self dismissingToastView];
}

-(void)adjustIndicatorFrame
{
    self.toastView.alpha = 1;
    self.toastView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);

    CGSize toastSize = [self.toastView getFrameForToastViewWithMessage:self.toastMessage];
    
    [self.toastView setFrame:CGRectMake((kFTScreenWidth - toastSize.width)/2, kFTScreenHeight - [self keyboardHeight] - kFTToastToBottom - toastSize.height, toastSize.width, toastSize.height)];
    [self.toastView showToastMessage:self.toastMessage withStyle:self.indicatorStyle];
    
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.toastView];
    
    self.toastView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4, 0.4);
    
    [self startShowingToastView];
}

-(void)onChangeStatusBarOrientationNotification:(NSNotification *)notification
{
    if (self.isCurrentlyOnScreen) {
        [self adjustIndicatorFrame];
    }
}

-(void)onKeyboardWillChangeFrame:(NSNotification *)notification
{
    if (self.isCurrentlyOnScreen) {
        NSDictionary *userInfo = [notification userInfo];
        CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        NSTimeInterval animationDuration;
        [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
        CGRect originRect = self.toastView.frame;
        CGFloat y = MIN(kFTScreenHeight, keyboardRect.origin.y) - kFTToastToBottom - originRect.size.height;
        [UIView animateWithDuration:animationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.toastView setFrame:CGRectMake(originRect.origin.x, y, originRect.size.width, originRect.size.height)];
                         }completion:^(BOOL finished) {
                             
                         }];
    }
}

- (CGFloat)keyboardHeight
{
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]){
        if ([[testWindow class] isEqual:[UIWindow class]] == NO){
            for (UIView *possibleKeyboard in [testWindow subviews]){
                if ([[possibleKeyboard description] hasPrefix:@"<UIPeripheralHostView"]){
                    return possibleKeyboard.bounds.size.height;
                }else if ([[possibleKeyboard description] hasPrefix:@"<UIInputSetContainerView"]){
                    for (UIView *hostKeyboard in [possibleKeyboard subviews]){
                        if ([[hostKeyboard description] hasPrefix:@"<UIInputSetHost"]){
                            return hostKeyboard.frame.size.height;
                        }
                    }
                }
            }
        }
    }
    return 0;
}


-(void)startDismissTimer
{
    [self stopDismissTimer];
    
    CGFloat timeInterval = self.toastMessage.length * 0.04 + 0.5;
    _dismissTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                     target:self
                                                   selector:@selector(dismissingToastView)
                                                   userInfo:nil
                                                    repeats:NO];
}

-(void)stopDismissTimer
{
    if (_dismissTimer) {
        [_dismissTimer invalidate];
        _dismissTimer = nil;
    }
}

-(void)startShowingToastView
{
    self.isDuringAnimation = YES;
    self.toastView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4, 0.4);
    [UIView animateWithDuration:kFTToastDefaultAnimationDuration
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         self.toastView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
                         
                     } completion:^(BOOL finished) {
                         if (finished) {
                             self.isDuringAnimation = NO;
                             if (!self.isCurrentlyOnScreen) {
                                 [self startDismissTimer];
                             }
                             self.isCurrentlyOnScreen = YES;
                         }
                     }];
}

-(void)dismissingToastView
{
    self.isDuringAnimation = YES;
    [UIView animateWithDuration:kFTToastDefaultAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         self.toastView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4, 0.4);
                         
                     } completion:^(BOOL finished) {
                         if(finished){
                             self.isDuringAnimation = NO;
                             self.isCurrentlyOnScreen = NO;
                             [self.toastView removeFromSuperview];
                         }
                     }];
}

@end

#pragma mark - FTToastIndicatorView

@interface FTToastIndicatorView ()

@property (strong, nonatomic) NSString *message;
@property (strong, nonatomic) UILabel *messageLabel;

@end

@implementation FTToastIndicatorView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.layer.cornerRadius = kFTToastCornerRadius;
        self.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    }
    return self;
}

#pragma mark - getters

-(UILabel *)messageLabel
{
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.numberOfLines = 0;
        _messageLabel.textColor = kFTToastDefaultTextColor;
        _messageLabel.font = kFTToastDefaultFont;
        [self.contentView addSubview:_messageLabel];
    }
    return _messageLabel;
}

-(UIColor *)getTextColorWithStyle:(UIBlurEffectStyle)style
{
    switch (style) {
        case UIBlurEffectStyleDark:
            return kFTToastDefaultTextColor_ForDarkStyle;
            break;
        default:
            return kFTToastDefaultTextColor;
            break;
    }
}

#pragma mark - main methods

-(void)showToastMessage:(NSString *)toastMessage withStyle:(UIBlurEffectStyle)style
{
    self.effect = [UIBlurEffect effectWithStyle:style];
    
    self.message = toastMessage;
    self.messageLabel.textColor = [self getTextColorWithStyle:style];
    self.messageLabel.text = toastMessage;

    CGSize labelSize = [self getFrameForToastLabelWithMessage:toastMessage];
    CGSize viewSize = [self getFrameForToastViewWithMessage:toastMessage];
    CGRect rect = CGRectMake((viewSize.width - labelSize.width)/2, (viewSize.height - labelSize.height)/2, labelSize.width, labelSize.height);
    self.messageLabel.frame = rect;
}

#pragma mark - getFrameForToastLabelWithMessage

-(CGSize )getFrameForToastLabelWithMessage:(NSString *)toastMessage
{
    CGRect textSize = [toastMessage boundingRectWithSize:CGSizeMake(kFTToastMaxWidth - kFTToastMargin_X*2, MAXFLOAT)
                                                 options:(NSStringDrawingUsesFontLeading | NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin)
                                              attributes:@{NSFontAttributeName : kFTToastDefaultFont}
                                                 context:nil];
    CGSize size = CGSizeMake(textSize.size.width, MIN(textSize.size.height ,kFTToastMaxHeight - kFTToastMargin_Y*2));
    return size;
}

#pragma mark - getFrameForToastViewWithMessage

-(CGSize )getFrameForToastViewWithMessage:(NSString *)toastMessage
{
    CGSize textSize = [self getFrameForToastLabelWithMessage:toastMessage];
    CGSize size = CGSizeMake(MIN(textSize.width + kFTToastMargin_X*2 , kFTToastMaxWidth), MIN(textSize.height + kFTToastMargin_Y*2 ,kFTToastMaxHeight));
    return size;
}

@end