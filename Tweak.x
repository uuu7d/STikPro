#import "TikTok.h"

// ============================================================================
// 1. Unmute Audio (إلغاء كتم الصوت)
// ============================================================================
%hook AWEAwemeStatusModel
- (void)setVideoMuteModel:(id)arg1 {
    %orig(nil);
}
%end

// ============================================================================
// 2. Force 1080p HD & HDR Uploads (رفع بجودة عالية)
// ============================================================================
%hook AWEVideoPublishSettingsViewModel
- (bool)enableHDPublish { return YES; }
%end

%hook AWEVideoRecordOutputParameter
- (bool)enableHDPublishSettingOn { return YES; }
%end

%hook IESMMParamModule
- (bool)enableHdrVsOptimization { return YES; }
- (bool)enableHDModeUpload { return YES; }
- (bool)enableHDRSetting { return YES; }
- (bool)enableHdr10bitExport { return YES; }
%end

%hook VECompileVTEncoderUnit
- (bool)enableHdrVsOpt { return YES; }
%end

%hook VEEffectProcess
- (bool)enableHdrVsOptimization { return YES; }
%end

%hook VECompileReaderUnit
- (bool)enableHdrVsOptimization { return YES; }
%end

%hook IESFiltersManager
- (bool)enableHdrVsOptimization { return YES; }
%end

%hook ACCRepoVideoInfoModel
- (bool)enableHDRNet { return YES; }
%end

%hook AWEVideoDraftModel
- (bool)enableHDRNet { return YES; }
%end

%hook AWEVideoNewPublishViewController
- (bool)enableHDPublish { return YES; }
%end

%hook AWEShoutoutsVideoPublishViewController
- (bool)enableHDPublish { return YES; }
%end

// ============================================================================
// 3. Download Stories - Videos & Photos (تحميل الستوري)
// ============================================================================
%group HooksTikTokStory

%hook TTKStoryDetailTableViewCell

- (void)configWithModel:(id)model {
    %orig;
    [self setupStoryDownloadButton];
}

- (void)configureWithModel:(id)model {
    %orig;
    [self setupStoryDownloadButton];
}

%new
- (void)setupStoryDownloadButton {
    if (![self viewWithTag:9003]) {
        UIButton *downloadStoryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        downloadStoryBtn.tag = 9003;
        
        UIImage *btnIcon = [UIImage systemImageNamed:@"square.and.arrow.down"];
        [downloadStoryBtn setImage:btnIcon forState:UIControlStateNormal];
        downloadStoryBtn.tintColor = [UIColor whiteColor];
        downloadStoryBtn.translatesAutoresizingMaskIntoConstraints = NO;
        
        [downloadStoryBtn addTarget:self action:@selector(handleStoryDownloadTap:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:downloadStoryBtn];

        [NSLayoutConstraint activateConstraints:@[
            [downloadStoryBtn.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:50],
            [downloadStoryBtn.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-15],
            [downloadStoryBtn.widthAnchor constraintEqualToConstant:35],
            [downloadStoryBtn.heightAnchor constraintEqualToConstant:35]
        ]];
    }
}

%new
- (void)handleStoryDownloadTap:(UIButton *)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *vc = [self viewController];
        if ([vc isKindOfClass:%c(TTKStoryDetailContainerViewController)]) {
            id storyModel = [vc valueForKey:@"_model"];
            
            // 1. التحقق أولاً إذا كان الستوري فيديو
            id videoModel = [storyModel valueForKey:@"_video"];
            id playURLModel = [videoModel valueForKey:@"_playURL"];
            NSArray *videoURLs = [playURLModel valueForKey:@"_originURLList"];
            
            if (videoURLs.count > 0 && [videoURLs.firstObject length] > 0) {
                NSURL *directURL = [NSURL URLWithString:videoURLs.firstObject];
                NSString *pathSave = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [directURL lastPathComponent]]];
                [self downloadFileFromURL:directURL saveToPath:pathSave];
                return;
            }
            
            // 2. التحقق إذا كان الستوري صورة
            id photoAlbum = [storyModel valueForKey:@"_photoAlbum"];
            NSArray *photos = [photoAlbum valueForKey:@"_photos"];
            
            if (photos.count > 0) {
                id firstPhoto = photos.firstObject;
                id originPhotoURL = [firstPhoto valueForKey:@"_originPhotoURL"];
                NSArray *photoURLs = [originPhotoURL valueForKey:@"_originURLList"];
                
                if (photoURLs.count > 0 && [photoURLs.firstObject length] > 0) {
                    NSURL *directURL = [NSURL URLWithString:photoURLs.firstObject];
                    NSString *pathSave = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", [directURL lastPathComponent]]];
                    [self downloadFileFromURL:directURL saveToPath:pathSave];
                }
            }
        }
    });
}

%new
- (void)downloadFileFromURL:(NSURL *)url saveToPath:(NSString *)path {
    NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (!error && location) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:path error:nil];
            [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:path] error:nil];
        }
    }];
    [task resume];
}

%end

%end // HooksTikTokStory

// ============================================================================
// Constructor
// ============================================================================
%ctor {
    // تفعيل الهوكات مباشرة بدون التحقق من Bundle ID
    %init(HooksTikTokStory);
    %init(_ungrouped);
}

