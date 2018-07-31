#import "DDYKeyboardView.h"
#import "DDYKeyboardConfig.h"
#import "DDYKeyboardTextView.h"
#import "DDYCameraController.h"
#import "DDYAuthorityManager.h"
#import "DDYVoiceView.h"
#import "DDYPhotoView.h"
#import "DDYShakeView.h"
#import "DDYRedBagView.h"
#import "DDYGifView.h"
#import "DDYEmojiView.h"
#import "DDYMoreView.h"

static inline NSString *imgName(NSString *imgName) {return [NSString stringWithFormat:@"DDYKeyboard.bundle/%@", imgName];}

@interface DDYKeyboardView ()<UITextViewDelegate>
/** 输入框 */
@property (nonatomic, strong) DDYKeyboardTextView *textView;
/** 输入框背景视图 */
@property (nonatomic, strong) UIImageView *textBgView;
/** 按钮数组 */
@property (nonatomic, strong) NSMutableArray *buttonArray;
/** 当前选择的按钮 */
@property (nonatomic, strong) UIButton *currentButton;

/** 语音视图 */
@property (nonatomic, strong) DDYVoiceView *voiceView;
/** 相册视图 */
@property (nonatomic, strong) DDYPhotoView *photoView;
/** 相机视图 */
@property (nonatomic, strong) UIView *videoView;
/** 抖窗视图 */
@property (nonatomic, strong) UIView *shakeView;
/** gif视图 */
@property (nonatomic, strong) UIView *gifView;
/** 红包视图 */
@property (nonatomic, strong) UIView *redView;
/** 表情视图 */
@property (nonatomic, strong) UIView *emojiView;
/** 更多视图 */
@property (nonatomic, strong) UIView *moreView;
/** 键盘高度 */
@property (nonatomic, assign) CGFloat keyboardH;

@end

@implementation DDYKeyboardView

- (DDYKeyboardTextView *)textView {
    if (!_textView) {
        _textView = [DDYKeyboardTextView viewWithFrame:CGRectMake(0, (kbTextViewH-20)/2., self.textBgView.ddy_W, 20)];
        
        __weak __typeof (self)weakSelf = self;
        [_textView setAutoHeightBlock:^(CGFloat height) {
            __strong __typeof (weakSelf)strongSelf = weakSelf;
            [strongSelf setNeedsLayout];
            [strongSelf layoutIfNeeded];
        }];
    }
    return _textView;
}

- (UIImageView *)textBgView {
    if (!_textBgView) {
        _textBgView = [[UIImageView alloc] initWithFrame:CGRectMake(kbTextViewMargin, kbTextViewTop, DDYSCREENW-2*kbTextViewMargin, kbTextViewH)];
        _textBgView.layer.borderColor = DDY_Small_Black.CGColor;
        _textBgView.layer.borderWidth = 0.6;
        _textBgView.backgroundColor = [UIColor whiteColor];
        _textBgView.userInteractionEnabled = YES;
    }
    return _textBgView;
}

- (NSMutableArray *)buttonArray {
    if (!_buttonArray) {
        _buttonArray = [NSMutableArray array];
    }
    return _buttonArray;
}

- (DDYVoiceView *)voiceView {
    if (!_voiceView) {
        _voiceView = [DDYVoiceView voiceViewWithFrame:CGRectMake(0, 0, DDYSCREENW, kbInputViewH)];
    }
    return _voiceView;
}

- (DDYPhotoView *)photoView {
    if (!_photoView) {
        _photoView = [DDYPhotoView voiceViewWithFrame:CGRectMake(0, 0, DDYSCREENW, kbInputViewH)];
    }
    return _photoView;
}

+ (instancetype)keyboardTypeQQAllState:(DDYKeyboardState)allState {
    return [[self alloc] initWithAllState:allState];
}

- (instancetype)initWithAllState:(DDYKeyboardState)allState {
    if (self = [super init]) {
        [self addSubview:self.textBgView];
        [self.textBgView addSubview:self.textView];
        [self layoutButtonWithAllState:allState];
        [self layoutIfNeeded];
        [self addNotification];
        self.backgroundColor = DDYRGBA(250., 250., 250., 1.);
    }
    return self;
}

#pragma mark 布局选择按钮
- (void)layoutButtonWithAllState:(DDYKeyboardState)allState {
    if (allState & DDYKeyboardStateVoice) {
        [self.buttonArray addObject:[self buttonImg:imgName(@"voiceN") selectedImg:imgName(@"voiceS") tag:DDYKeyboardStateVoice]];
    }
    if (allState & DDYKeyboardStatePhoto) {
        [self.buttonArray addObject:[self buttonImg:imgName(@"photoN") selectedImg:imgName(@"photoS") tag:DDYKeyboardStatePhoto]];
    }
    if (allState & DDYKeyboardStateVideo) {
        [self.buttonArray addObject:[self buttonImg:imgName(@"videoN") selectedImg:imgName(@"videoS") tag:DDYKeyboardStateVideo]];
    }
    if (allState & DDYKeyboardStateShake) {
        [self.buttonArray addObject:[self buttonImg:imgName(@"shakeN") selectedImg:imgName(@"shakeS") tag:DDYKeyboardStateShake]];
    }
    if (allState & DDYKeyboardStateGif) {
        [self.buttonArray addObject:[self buttonImg:imgName(@"gifN") selectedImg:imgName(@"gifS") tag:DDYKeyboardStateGif]];
    }
    if (allState & DDYKeyboardStateRedBag) {
        [self.buttonArray addObject:[self buttonImg:imgName(@"redN") selectedImg:imgName(@"redS") tag:DDYKeyboardStateRedBag]];
    }
    if (allState & DDYKeyboardStateEmoji) {
        [self.buttonArray addObject:[self buttonImg:imgName(@"emojiN") selectedImg:imgName(@"emojiS") tag:DDYKeyboardStateEmoji]];
    }
    if (allState & DDYKeyboardStateMore) {
        [self.buttonArray addObject:[self buttonImg:imgName(@"moreN") selectedImg:imgName(@"moreS") tag:DDYKeyboardStateMore]];
    }
}

- (UIButton *)buttonImg:(NSString *)img selectedImg:(NSString *)imgS tag:(NSUInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:img] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:imgS] forState:UIControlStateSelected];
    [button addTarget:self action:@selector(handleButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [button setFrame:CGRectMake(0, 0, 30, 30)];
    [button setTag:tag];
    [self addSubview:button];
    return button;
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

#pragma mark - KeyboardNotification
- (void)keyboardWillShow:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat keyboardH = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    if (self.keyboardH != 0) {
        self.ddy_Bottom = CGRectGetHeight(self.superview.bounds) - keyboardH;
    }
    [UIView animateWithDuration:duration animations:^{
        self.ddy_Bottom = CGRectGetHeight(self.superview.bounds) - keyboardH;
    } completion:^(BOOL finished) {
        self.keyboardH = keyboardH;NSLog(@"键盘弹出 %f", keyboardH);
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSLog(@"键盘收回");
    [UIView animateWithDuration:duration animations:^{
        self.ddy_Bottom = self.superview.ddy_H - DDYSafeInsets(self.superview).bottom;
    } completion:^(BOOL finished) {
        self.keyboardH = 0;
    }];
}

- (void)changeKeyboardState:(DDYKeyboardState)state {
    if (self.keyboardState == state) {
        return;
    }
    
    switch (state) {
        case DDYKeyboardStateSystem:
        {
            [self.textView becomeFirstResponder];
            self.textView.inputView = nil;
            [self.textView reloadInputViews];
        }
            break;
        case DDYKeyboardStateVoice:
        {
            [self.textView becomeFirstResponder];
            self.textView.inputView = self.voiceView;
            [self.textView reloadInputViews];
        }
            break;
        case DDYKeyboardStatePhoto:
        {
            [self.textView becomeFirstResponder];
            self.textView.inputView = self.photoView;
            [self.textView reloadInputViews];
        }
            break;
        case DDYKeyboardStateVideo:
        {
            self.currentButton.selected = NO;
            [self presentCameraViewController];
        }
            break;
        case DDYKeyboardStateGif:
        {
            
        }
            break;
        case DDYKeyboardStateShake:
        {
            
        }
            break;
        case DDYKeyboardStateRedBag:
        {
            
        }
            break;
        case DDYKeyboardStateEmoji:
        {
            
        }
            break;
        case DDYKeyboardStateMore:
        {
            
        }
            break;
        case DDYKeyboardStateNone:
        default:
        {
            self.textView.inputView = nil;
            [self.textView resignFirstResponder];
        }
            break;
    }
}

- (void)handleButtonClick:(UIButton *)button {
    if (self.currentButton == button && self.currentButton.selected) {
        self.currentButton.selected = NO;
        return;
    }
    self.currentButton.selected = NO;
    self.currentButton = button;
    self.currentButton.selected = YES;
    [self changeKeyboardState:(DDYKeyboardState)button.tag];
}

- (void)presentCameraViewController {
    [DDYAuthorityManager ddy_AudioAuthAlertShow:YES success:^{
        [DDYAuthorityManager ddy_CameraAuthAlertShow:YES success:^{
            DDYCameraController *cameraVC = [DDYCameraController new];
            [cameraVC setTakePhotoBlock:^(UIImage *image, UIViewController *vc) {
                [vc dismissViewControllerAnimated:YES completion:^{   }];
            }];
            [[self ddy_GetResponderViewController] presentViewController:cameraVC animated:YES completion:^{ }];
        } fail:^(AVAuthorizationStatus authStatus) { }];
    } fail:^(AVAuthorizationStatus authStatus) { }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // 输入框布局
    if (self.textView.ddy_H + 6 > kbTextViewH) {
        self.textBgView.ddy_H = self.textView.ddy_H + 6;
    } else {
        self.textBgView.ddy_H = kbTextViewH;
    }
    self.textView.ddy_CenterY = self.textBgView.ddy_H/2.;
    
    // 按钮布局
    UIButton *currentButton = nil;
    CGFloat buttonMargin = (DDYSCREENW - kbButtonWH * self.buttonArray.count) / (self.buttonArray.count + 1.);
    for (UIButton *button in self.buttonArray) {
        button.ddy_Top = self.textView.ddy_Bottom + kbButtonTop;
        button.ddy_Left = (currentButton ? currentButton.ddy_Right : 0) + buttonMargin;
        currentButton = button;
    }
    
    // 整体高度
    self.ddy_H = kbTextViewTop + self.textView.ddy_H + kbButtonTop + kbButtonWH + kbButtonBottom;
    if (self.superview) {
        self.ddy_Bottom = self.superview.ddy_H - (self.keyboardH == 0 ? DDYSafeInsets(self.superview).bottom : self.keyboardH);
    }
}

#pragma mark - 响应链
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if ([view isKindOfClass:[UITextView class]]) {
        [self changeKeyboardState:DDYKeyboardStateSystem];
    }
    return view;
}

@end
