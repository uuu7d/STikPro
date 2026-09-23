#import "TikTok.h"

%group WheeUniversalDownloader

%hook TTKRichContentPlayerViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [self setupStoryDownloadButton];
}

%new
- (void)setupStoryDownloadButton {
    // منع تكرار إضافة الزر إذا كان موجوداً بالفعل
    if ([self.view viewWithTag:9003]) {
        return;
    }

    UIButton *downloadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    downloadBtn.tag = 9003;
    
    // تصميم زر تحميل أنيق مع خلفية ضبابية دائريّة
    UIImage *btnIcon = [UIImage systemImageNamed:@"arrow.down.circle.fill"];
    [downloadBtn setImage:btnIcon forState:UIControlStateNormal];
    downloadBtn.tintColor = [UIColor whiteColor];
    downloadBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    downloadBtn.layer.cornerRadius = 20.0;
    downloadBtn.clipsToBounds = YES;
    downloadBtn.translatesAutoresizingMaskIntoConstraints = NO;
    
    [downloadBtn addTarget:self action:@selector(handleStoryDownloadTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:downloadBtn];

    // قيود التموضع (Constraints)
    [NSLayoutConstraint activateConstraints:@[
        [downloadBtn.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:50],
        [downloadBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [downloadBtn.widthAnchor constraintEqualToConstant:40],
        [downloadBtn.heightAnchor constraintEqualToConstant:40]
    ]];
}

%new
- (void)handleStoryDownloadTap:(UIButton *)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // ====================================================================
        // المستوى 1: السحب المباشر من الذاكرة (ACCImageMediaContainerView)
        // ====================================================================
        for (UIView *subview in self.view.subviews) {
            if ([subview isKindOfClass:NSClassFromString(@"ACCImageMediaContainerView")]) {
                ACCImageMediaContainerView *imageContainer = (ACCImageMediaContainerView *)subview;
                UIImage *imageToSave = imageContainer.coverImage;
                if (!imageToSave && imageContainer.coverImageView) {
                    imageToSave = imageContainer.coverImageView.image;
                }
                
                if (imageToSave) {
                    UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil);
                    NSLog(@"[WheeDownloader] Success: Saved image directly from RAM!");
                    return;
                }
            }
        }

        // ====================================================================
        // استخراج كائن البيانات الأساسي (AwemeModel)
        // ====================================================================
        id model = nil;
        @try { model = [self valueForKey:@"awemeModel"]; } @catch (NSException *e) {}
        if (!model) { @try { model = [self valueForKey:@"model"]; } @catch (NSException *e) {} }

        if (!model) {
            NSLog(@"[WheeDownloader] Error: Unable to fetch awemeModel.");
            return;
        }

        // ====================================================================
        // المستوى 2: التنزيل المباشر للسيرفر (AWEMediaDownloader)
        // ====================================================================
        id videoModel = nil;
        @try { videoModel = [model valueForKey:@"video"]; } @catch (NSException *e) {}
        if (!videoModel) { @try { videoModel = [model valueForKey:@"_video"]; } @catch (NSException *e) {} }
        
        id playURLModel = nil;
        if (videoModel) {
            @try { playURLModel = [videoModel valueForKey:@"playURL"]; } @catch (NSException *e) {}
            if (!playURLModel) { @try { playURLModel = [videoModel valueForKey:@"_playURL"]; } @catch (NSException *e) {} }
        }
        
        NSArray *videoURLs = nil;
        if (playURLModel) {
            @try { videoURLs = [playURLModel valueForKey:@"originURLList"]; } @catch (NSException *e) {}
            if (!videoURLs) { @try { videoURLs = [playURLModel valueForKey:@"_originURLList"]; } @catch (NSException *e) {} }
        }

        // إذا وُجد رابط فيديو صالح
        if (videoURLs.count > 0 && [videoURLs.firstObject length] > 0) {
            NSString *videoURL = videoURLs.firstObject;
            
            // إظهار واجهة التنزيل الأصلية
            [ClassFromString(@"AWEMediaDownloader") _showLoadingView];
            
            [ClassFromString(@"AWEMediaDownloader") downloadVideoToAlbumWithURLString:videoURL completion:^(id result, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ClassFromString(@"AWEMediaDownloader") _dismissLoadingView];
                    if (!error) {
                        NSLog(@"[WheeDownloader] Success: Video saved to album via AWEMediaDownloader!");
                    } else {
                        NSLog(@"[WheeDownloader] Error saving video: %@", error);
                    }
                });
            }];
            return;
        }

        // ====================================================================
        // المستوى 3: خط التراجع للألبومات والرسائل (AWEIMMediaDownloader & Options)
        // ====================================================================
        AWEIMMediaDownloaderOptions *options = [[NSClassFromString(@"AWEIMMediaDownloaderOptions") alloc] init];
        options.model = model;
        options.needsSaveToAlbum = YES;
        options.willBlockUserInteraction = NO;

        // استغلال AWEIMMediaUtility للتأكد من جاهزية مسارات التخزين المؤقت
        NSString *tempPath = [ClassFromString(@"AWEIMMediaUtility") mediaDataTempDirectory];
        NSLog(@"[WheeDownloader] Using temp directory: %@", tempPath);

        [ClassFromString(@"AWEMediaDownloader") _showLoadingView];

        [ClassFromString(@"AWEIMMediaDownloader") requestDMMediaWithOptions:options completion:^(id result, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [ClassFromString(@"AWEMediaDownloader") _dismissLoadingView];
                if (!error) {
                    NSLog(@"[WheeDownloader] Success: Saved via AWEIMMediaDownloader!");
                } else {
                    NSLog(@"[WheeDownloader] Fallback download error: %@", error);
                }
            });
        }];
    });
}

%end

%end // group WheeUniversalDownloader

%ctor {
    %init(WheeUniversalDownloader);
    %init(_ungrouped);
}
