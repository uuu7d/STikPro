#import "TikTok.h"
#import <Photos/Photos.h>
#import <AudioToolbox/AudioToolbox.h>

// ============================================================================
// 1. واجهة تنبيهات احترافية داخلية (WheeHUD)
// ============================================================================
@interface WheeHUD : UIView
+ (void)showInView:(UIView *)parentView text:(NSString *)text icon:(NSString *)iconName isSpinning:(BOOL)spin duration:(NSTimeInterval)duration;
+ (void)showSuccessInView:(UIView *)parentView text:(NSString *)text;
+ (void)showErrorInView:(UIView *)parentView text:(NSString *)text;
+ (void)showLoadingInView:(UIView *)parentView text:(NSString *)text;
+ (void)dismissFromView:(UIView *)parentView;
@end

@implementation WheeHUD

+ (void)showInView:(UIView *)parentView text:(NSString *)text icon:(NSString *)iconName isSpinning:(BOOL)spin duration:(NSTimeInterval)duration {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissFromView:parentView];

        UIView *hud = [[UIView alloc] init];
        hud.tag = 9901;
        hud.translatesAutoresizingMaskIntoConstraints = NO;
        hud.layer.cornerRadius = 22.0;
        hud.clipsToBounds = YES;

        UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
        blur.frame = hud.bounds;
        blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [hud addSubview:blur];

        UIStackView *stack = [[UIStackView alloc] init];
        stack.axis = UILayoutConstraintAxisHorizontal;
        stack.alignment = UIStackViewAlignmentCenter;
        stack.spacing = 10;
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        [hud addSubview:stack];

        if (spin) {
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
            indicator.color = [UIColor whiteColor];
            [indicator startAnimating];
            [stack addArrangedSubview:indicator];
        } else if (iconName) {
            UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:iconName]];
            imgView.tintColor = [UIColor whiteColor];
            imgView.contentMode = UIViewContentModeScaleAspectFit;
            [imgView.widthAnchor constraintEqualToConstant:20].active = YES;
            [imgView.heightAnchor constraintEqualToConstant:20].active = YES;
            [stack addArrangedSubview:imgView];
        }

        UILabel *lbl = [[UILabel alloc] init];
        lbl.text = text;
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        [stack addArrangedSubview:lbl];

        [parentView addSubview:hud];

        [NSLayoutConstraint activateConstraints:@[
            [hud.topAnchor constraintEqualToAnchor:parentView.safeAreaLayoutGuide.topAnchor constant:15],
            [hud.centerXAnchor constraintEqualToAnchor:parentView.centerXAnchor],
            [hud.heightAnchor constraintEqualToConstant:44],
            [stack.leadingAnchor constraintEqualToAnchor:hud.leadingAnchor constant:16],
            [stack.trailingAnchor constraintEqualToAnchor:hud.trailingAnchor constant:-16],
            [stack.centerYAnchor constraintEqualToAnchor:hud.centerYAnchor]
        ]];

        hud.alpha = 0.0;
        hud.transform = CGAffineTransformMakeTranslation(0, -20);
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:0 animations:^{
            hud.alpha = 1.0;
            hud.transform = CGAffineTransformIdentity;
        } completion:nil];

        if (duration > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissFromView:parentView];
            });
        }
    });
}

+ (void)showLoadingInView:(UIView *)parentView text:(NSString *)text {
    [self showInView:parentView text:text icon:nil isSpinning:YES duration:0];
}

+ (void)showSuccessInView:(UIView *)parentView text:(NSString *)text {
    [self showInView:parentView text:text icon:@"checkmark.circle.fill" isSpinning:NO duration:2.0];
}

+ (void)showErrorInView:(UIView *)parentView text:(NSString *)text {
    [self showInView:parentView text:text icon:@"exclamationmark.triangle.fill" isSpinning:NO duration:2.5];
}

+ (void)dismissFromView:(UIView *)parentView {
    UIView *existing = [parentView viewWithTag:9901];
    if (existing) {
        [UIView animateWithDuration:0.25 animations:^{
            existing.alpha = 0.0;
            existing.transform = CGAffineTransformMakeTranslation(0, -20);
        } completion:^(BOOL finished) {
            [existing removeFromSuperview];
        }];
    }
}

@end

// ============================================================================
// 2. إعلانات الفئات والربط مع Controller
// ============================================================================
@interface TTKRichContentPlayerViewController (WheeDownloader)
- (void)setupStoryDownloadButton;
- (void)handleStoryDownloadTap:(UIButton *)sender;
- (void)downloadAndSaveHDImage:(NSString *)urlString;
- (void)downloadAndSaveHDVideo:(NSString *)urlString;
- (void)saveImageToPhotos:(UIImage *)image;
- (UIImage *)extractVisibleImageFromView:(UIView *)view;
- (void)triggerHapticFeedback:(NSInteger)type;
@end

%group WheeUniversalDownloader

%hook TTKRichContentPlayerViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [self setupStoryDownloadButton];
}

%new
- (void)setupStoryDownloadButton {
    if ([self.view viewWithTag:9003]) return;

    // إنشاء زر بلمسة زجاجية مدرعة (Glassmorphic Button)
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
    blurView.tag = 9003;
    blurView.layer.cornerRadius = 22.0;
    blurView.clipsToBounds = YES;
    blurView.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *downloadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *btnIcon = [UIImage systemImageNamed:@"arrow.down.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightMedium]];
    [downloadBtn setImage:btnIcon forState:UIControlStateNormal];
    downloadBtn.tintColor = [UIColor whiteColor];
    downloadBtn.translatesAutoresizingMaskIntoConstraints = NO;

    // إشارات اللمس والحركة (Animations & Touches)
    [downloadBtn addTarget:self action:@selector(handleStoryDownloadTap:) forControlEvents:UIControlEventTouchUpInside];
    [downloadBtn addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [downloadBtn addTarget:self action:@selector(buttonTouchUp:) forControlEvents:UIControlEventTouchUpOutside];

    [blurView.contentView addSubview:downloadBtn];
    [self.view addSubview:blurView];

    [NSLayoutConstraint activateConstraints:@[
        [downloadBtn.topAnchor constraintEqualToAnchor:blurView.contentView.topAnchor],
        [downloadBtn.bottomAnchor constraintEqualToAnchor:blurView.contentView.bottomAnchor],
        [downloadBtn.leadingAnchor constraintEqualToAnchor:blurView.contentView.leadingAnchor],
        [downloadBtn.trailingAnchor constraintEqualToAnchor:blurView.contentView.trailingAnchor],

        [blurView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:45],
        [blurView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [blurView.widthAnchor constraintEqualToConstant:44],
        [blurView.heightAnchor constraintEqualToConstant:44]
    ]];
}

%new
- (void)buttonTouchDown:(UIButton *)btn {
    UIView *parent = btn.superview.superview;
    [UIView animateWithDuration:0.15 animations:^{
        parent.transform = CGAffineTransformMakeScale(0.88, 0.88);
    }];
}

%new
- (void)buttonTouchUp:(UIButton *)btn {
    UIView *parent = btn.superview.superview;
    [UIView animateWithDuration:0.15 animations:^{
        parent.transform = CGAffineTransformIdentity;
    }];
}

%new
- (void)triggerHapticFeedback:(NSInteger)type {
    if (type == 0) { // Medium Impact
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [gen impactOccurred];
    } else if (type == 1) { // Success
        UINotificationFeedbackGenerator *gen = [[UINotificationFeedbackGenerator alloc] init];
        [gen notificationOccurred:UINotificationFeedbackTypeSuccess];
    } else if (type == 2) { // Error
        UINotificationFeedbackGenerator *gen = [[UINotificationFeedbackGenerator alloc] init];
        [gen notificationOccurred:UINotificationFeedbackTypeError];
    }
}

%new
- (void)handleStoryDownloadTap:(UIButton *)sender {
    UIView *parent = sender.superview.superview;
    [UIView animateWithDuration:0.15 animations:^{ parent.transform = CGAffineTransformIdentity; }];

    [self triggerHapticFeedback:0];

    dispatch_async(dispatch_get_main_queue(), ^{
        id model = nil;
        @try { model = [self valueForKey:@"awemeModel"]; } @catch (NSException *e) {}
        if (!model) { @try { model = [self valueForKey:@"model"]; } @catch (NSException *e) {} }

        // -------------------------------------------------------------
        // أ) معالجة التنزيل للصور (Photo Mode / Carousel)
        // -------------------------------------------------------------
        NSArray *imagesArray = nil;
        @try { imagesArray = [model valueForKey:@"images"]; } @catch (NSException *e) {}
        if (!imagesArray || imagesArray.count == 0) {
            id imagePostInfo = nil;
            @try { imagePostInfo = [model valueForKey:@"imagePostInfo"]; } @catch (NSException *e) {}
            if (imagePostInfo) {
                @try { imagesArray = [imagePostInfo valueForKey:@"images"]; } @catch (NSException *e) {}
            }
        }

        if (imagesArray && imagesArray.count > 0) {
            NSInteger currentIndex = 0;
            @try {
                NSNumber *idx = [self valueForKey:@"currentIndex"];
                if (idx) currentIndex = [idx integerValue];
            } @catch (NSException *e) {}

            if (currentIndex >= imagesArray.count) currentIndex = 0;

            id imageObj = imagesArray[currentIndex];
            NSArray *urlList = nil;
            @try { urlList = [imageObj valueForKey:@"downloadURLList"]; } @catch (NSException *e) {}
            if (!urlList || urlList.count == 0) {
                @try { urlList = [imageObj valueForKey:@"originURLList"]; } @catch (NSException *e) {}
            }
            if (!urlList || urlList.count == 0) {
                @try { urlList = [imageObj valueForKey:@"urlList"]; } @catch (NSException *e) {}
            }

            if (urlList && urlList.count > 0) {
                [self downloadAndSaveHDImage:urlList.firstObject];
                return;
            }
        }

        // خط تراجع ذكي: التقاط الصورة مباشرة من الشاشة في حال لم يتوفر رابط
        UIImage *screenImage = [self extractVisibleImageFromView:self.view];
        if (screenImage) {
            [self saveImageToPhotos:screenImage];
            return;
        }

        // -------------------------------------------------------------
        // ب) معالجة التنزيل للفيديو (HD Video)
        // -------------------------------------------------------------
        id videoModel = nil;
        @try { videoModel = [model valueForKey:@"video"]; } @catch (NSException *e) {}

        if (videoModel) {
            NSString *bestVideoURL = nil;

            // البحث عن رابط التحميل الأصلي غير المضغوط
            id downloadURLModel = nil;
            @try { downloadURLModel = [videoModel valueForKey:@"downloadURL"]; } @catch (NSException *e) {}
            if (downloadURLModel) {
                NSArray *dlURLs = nil;
                @try { dlURLs = [downloadURLModel valueForKey:@"originURLList"]; } @catch (NSException *e) {}
                if (!dlURLs) { @try { dlURLs = [downloadURLModel valueForKey:@"urlList"]; } @catch (NSException *e) {} }
                if (dlURLs.count > 0) bestVideoURL = dlURLs.firstObject;
            }

            // البحث عن أعلى Bitrate
            if (!bestVideoURL) {
                NSArray *bitrateList = nil;
                @try { bitrateList = [videoModel valueForKey:@"bitrateModels"]; } @catch (NSException *e) {}
                if (!bitrateList) { @try { bitrateList = [videoModel valueForKey:@"bitrate"]; } @catch (NSException *e) {} }

                if (bitrateList && bitrateList.count > 0) {
                    id highestBitrateObj = bitrateList.firstObject;
                    long long maxBitrate = 0;
                    for (id bModel in bitrateList) {
                        long long b = 0;
                        @try { b = [[bModel valueForKey:@"bitrate"] longLongValue]; } @catch (NSException *e) {}
                        if (b > maxBitrate) {
                            maxBitrate = b;
                            highestBitrateObj = bModel;
                        }
                    }
                    
                    id playAddr = nil;
                    @try { playAddr = [highestBitrateObj valueForKey:@"playAddr"]; } @catch (NSException *e) {}
                    if (playAddr) {
                        NSArray *bURLs = nil;
                        @try { bURLs = [playAddr valueForKey:@"originURLList"]; } @catch (NSException *e) {}
                        if (!bURLs) { @try { bURLs = [playAddr valueForKey:@"urlList"]; } @catch (NSException *e) {} }
                        if (bURLs.count > 0) bestVideoURL = bURLs.firstObject;
                    }
                }
            }

            if (!bestVideoURL) {
                id playURLModel = nil;
                @try { playURLModel = [videoModel valueForKey:@"playURL"]; } @catch (NSException *e) {}
                if (playURLModel) {
                    NSArray *playURLs = nil;
                    @try { playURLs = [playURLModel valueForKey:@"originURLList"]; } @catch (NSException *e) {}
                    if (!playURLs) { @try { playURLs = [playURLModel valueForKey:@"urlList"]; } @catch (NSException *e) {} }
                    if (playURLs.count > 0) bestVideoURL = playURLs.firstObject;
                }
            }

            if (bestVideoURL && bestVideoURL.length > 0) {
                [self downloadAndSaveHDVideo:bestVideoURL];
                return;
            }
        }

        [WheeHUD showErrorInView:self.view text:@"تعذر العثور على ملف الوسائط!"];
        [self triggerHapticFeedback:2];
    });
}

%new
- (void)downloadAndSaveHDImage:(NSString *)urlString {
    [WheeHUD showLoadingInView:self.view text:@"جاري تحميل الصورة..."];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 TikTok/30.0.0" forHTTPHeaderField:@"User-Agent"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data && !error) {
                UIImage *image = [UIImage imageWithData:data];
                if (image) {
                    [self saveImageToPhotos:image];
                    return;
                }
            }
            
            // في حال فشل التحميل عبر الشبكة بسبب الحظر، استخراج الصورة المباشرة من الشاشة
            UIImage *screenImage = [self extractVisibleImageFromView:self.view];
            if (screenImage) {
                [self saveImageToPhotos:screenImage];
            } else {
                [WheeHUD showErrorInView:self.view text:@"فشل تحميل الصورة!"];
                [self triggerHapticFeedback:2];
            }
        });
    }];
    [task resume];
}

%new
- (void)saveImageToPhotos:(UIImage *)image {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [WheeHUD showSuccessInView:self.view text:@"تم حفظ الصورة بنجاح!"];
                [self triggerHapticFeedback:1];
            } else {
                [WheeHUD showErrorInView:self.view text:@"خطأ في الحفظ بألبوم الصور!"];
                [self triggerHapticFeedback:2];
            }
        });
    }];
}

%new
- (UIImage *)extractVisibleImageFromView:(UIView *)view {
    if ([view isKindOfClass:[UIImageView class]]) {
        UIImageView *imgView = (UIImageView *)view;
        if (imgView.image && imgView.bounds.size.width > 120 && imgView.bounds.size.height > 120) {
            return imgView.image;
        }
    }
    for (UIView *subview in view.subviews) {
        UIImage *found = [self extractVisibleImageFromView:subview];
        if (found) return found;
    }
    return nil;
}

%new
- (void)downloadAndSaveHDVideo:(NSString *)urlString {
    [WheeHUD showLoadingInView:self.view text:@"جاري تحميل الفيديو بأعلى جودة..."];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 TikTok/30.0.0" forHTTPHeaderField:@"User-Agent"];

    NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error || !location) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [WheeHUD showErrorInView:self.view text:@"فشل تنزيل ملف الفيديو!"];
                [self triggerHapticFeedback:2];
            });
            return;
        }

        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Whee_%@.mp4", [[NSUUID UUID] UUIDString]]];
        NSURL *destinationURL = [NSURL fileURLWithPath:tempPath];
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:destinationURL error:nil];

        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:destinationURL];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
                if (success) {
                    [WheeHUD showSuccessInView:self.view text:@"تم حفظ الفيديو بنجاح!"];
                    [self triggerHapticFeedback:1];
                } else {
                    [WheeHUD showErrorInView:self.view text:@"خطأ أثناء نقل الفيديو للبوم الصور!"];
                    [self triggerHapticFeedback:2];
                }
            });
        }];
    }];
    [task resume];
}

%end

%end // group WheeUniversalDownloader

%ctor {
    %init(WheeUniversalDownloader);
    %init(_ungrouped);
}
