#import "TikTok.h"
#import <Photos/Photos.h>

%group WheeUniversalDownloader

%hook TTKRichContentPlayerViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [self setupStoryDownloadButton];
}

%new
- (void)setupStoryDownloadButton {
    if ([self.view viewWithTag:9003]) {
        return;
    }

    UIButton *downloadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    downloadBtn.tag = 9003;
    
    UIImage *btnIcon = [UIImage systemImageNamed:@"arrow.down.circle.fill"];
    [downloadBtn setImage:btnIcon forState:UIControlStateNormal];
    downloadBtn.tintColor = [UIColor whiteColor];
    downloadBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    downloadBtn.layer.cornerRadius = 20.0;
    downloadBtn.clipsToBounds = YES;
    downloadBtn.translatesAutoresizingMaskIntoConstraints = NO;
    
    [downloadBtn addTarget:self action:@selector(handleStoryDownloadTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:downloadBtn];

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
        
        // 1. استخراج كائن البيانات AwemeModel
        id model = nil;
        @try { model = [self valueForKey:@"awemeModel"]; } @catch (NSException *e) {}
        if (!model) { @try { model = [self valueForKey:@"model"]; } @catch (NSException *e) {} }

        if (!model) {
            NSLog(@"[WheeDownloader] Error: Model is nil.");
            return;
        }

        // -------------------------------------------------------------
        // أ) معالجة الصور بأعلى جودة متوفرة (Photo Posts & Carousels)
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
            
            // البحث عن رابط الصورة الأصلي بأعلى دقة
            NSArray *urlList = nil;
            @try { urlList = [imageObj valueForKey:@"downloadURLList"]; } @catch (NSException *e) {}
            if (!urlList || urlList.count == 0) {
                @try { urlList = [imageObj valueForKey:@"originURLList"]; } @catch (NSException *e) {}
            }
            if (!urlList || urlList.count == 0) {
                @try { urlList = [imageObj valueForKey:@"urlList"]; } @catch (NSException *e) {}
            }

            if (urlList && urlList.count > 0) {
                NSString *highResImgURL = urlList.firstObject;
                [self downloadAndSaveHDImage:highResImgURL];
                return;
            }
        }

        // خط تراجع احتياطي للصور من الذاكرة في حال عدم العثور على رابط مباشر
        for (UIView *subview in self.view.subviews) {
            if ([subview isKindOfClass:NSClassFromString(@"ACCImageMediaContainerView")]) {
                ACCImageMediaContainerView *imageContainer = (ACCImageMediaContainerView *)subview;
                UIImage *imageToSave = imageContainer.coverImage ?: imageContainer.coverImageView.image;
                if (imageToSave) {
                    UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil);
                    return;
                }
            }
        }

        // -------------------------------------------------------------
        // ب) معالجة الفيديو بأعلى معدل بت ودقة (Highest Bitrate / HD Video)
        // -------------------------------------------------------------
        id videoModel = nil;
        @try { videoModel = [model valueForKey:@"video"]; } @catch (NSException *e) {}

        if (videoModel) {
            NSString *bestVideoURL = nil;

            // 1. تجربة الرابط الأصلي المباشر للتحميل Uncompressed Download URL
            id downloadURLModel = nil;
            @try { downloadURLModel = [videoModel valueForKey:@"downloadURL"]; } @catch (NSException *e) {}
            if (downloadURLModel) {
                NSArray *dlURLs = nil;
                @try { dlURLs = [downloadURLModel valueForKey:@"originURLList"]; } @catch (NSException *e) {}
                if (!dlURLs) { @try { dlURLs = [downloadURLModel valueForKey:@"urlList"]; } @catch (NSException *e) {} }
                if (dlURLs.count > 0) bestVideoURL = dlURLs.firstObject;
            }

            // 2. البحث عن أعلى دقة Bitrate متوفرة (1080p / High Quality Stream)
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

            // 3. التراجع لرابط المشاهدة الأصلي في حال عدم وجود الرابط الأعلى
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

            // تنفيذ تحميل وتخزين الفيديو بأفضل دقة
            if (bestVideoURL && bestVideoURL.length > 0) {
                [self downloadAndSaveHDVideo:bestVideoURL];
                return;
            }
        }
    });
}

%new
- (void)downloadAndSaveHDImage:(NSString *)urlString {
    [NSClassFromString(@"AWEMediaDownloader") _showLoadingView];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSClassFromString(@"AWEMediaDownloader") _dismissLoadingView];
            if (data && !error) {
                UIImage *image = [UIImage imageWithData:data];
                if (image) {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                    NSLog(@"[WheeDownloader] HD Image Saved Successfully!");
                }
            }
        });
    }];
    [task resume];
}

%new
- (void)downloadAndSaveHDVideo:(NSString *)urlString {
    [NSClassFromString(@"AWEMediaDownloader") _showLoadingView];

    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error || !location) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSClassFromString(@"AWEMediaDownloader") _dismissLoadingView];
            });
            return;
        }

        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Whee_%@.mp4", [[NSUUID UUID] UUIDString]]];
        NSURL *destinationURL = [NSURL fileURLWithPath:tempPath];
        
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:destinationURL error:nil];

        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(tempPath)) {
            UISaveVideoAtPathToSavedPhotosAlbum(tempPath, self, @selector(video:didFinishSavingWithError:contextInfo:), NULL);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSClassFromString(@"AWEMediaDownloader") _dismissLoadingView];
            });
        }
    }];
    [task resume];
}

%new
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSClassFromString(@"AWEMediaDownloader") _dismissLoadingView];
        [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
        if (!error) {
            NSLog(@"[WheeDownloader] HD Video Saved Successfully!");
        }
    });
}

%end

%end // group WheeUniversalDownloader

%ctor {
    %init(WheeUniversalDownloader);
    %init(_ungrouped);
}
