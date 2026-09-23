#import "TikTok.h"

// ============================================================================
// 1. Unmute Audio
// ============================================================================
%hook AWEAwemeStatusModel
- (void)setVideoMuteModel:(id)arg1 {
    %orig(nil);
}
%end

// ============================================================================
// 2. Force 1080p HD & HDR Uploads
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
// 3. Download Stories (Hooking TTKRichContentPlayerViewController)
// ============================================================================
%group HooksTikTokStory

%hook TTKRichContentPlayerViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [self setupStoryDownloadButton];
}

%new
- (void)setupStoryDownloadButton {
    if (![self.view viewWithTag:9003]) {
        UIButton *downloadStoryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        downloadStoryBtn.tag = 9003;
        
        UIImage *btnIcon = [UIImage systemImageNamed:@"square.and.arrow.down"];
        [downloadStoryBtn setImage:btnIcon forState:UIControlStateNormal];
        downloadStoryBtn.tintColor = [UIColor whiteColor];
        downloadStoryBtn.translatesAutoresizingMaskIntoConstraints = NO;
        
        [downloadStoryBtn addTarget:self action:@selector(handleStoryDownloadTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:downloadStoryBtn];

        [NSLayoutConstraint activateConstraints:@[
            [downloadStoryBtn.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:50],
            [downloadStoryBtn.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-15],
            [downloadStoryBtn.widthAnchor constraintEqualToConstant:35],
            [downloadStoryBtn.heightAnchor constraintEqualToConstant:35]
        ]];
    }
}

%new
- (void)handleStoryDownloadTap:(UIButton *)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        id model = nil;
        @try { model = [self valueForKey:@"awemeModel"]; } @catch (NSException *e) {}
        if (!model) { @try { model = [self valueForKey:@"model"]; } @catch (NSException *e) {} }
        if (!model) { @try { model = [self valueForKey:@"_model"]; } @catch (NSException *e) {} }
        
        if (model) {
            // 1. استخراج فيديو الستوري
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
            
            if (videoURLs.count > 0 && [videoURLs.firstObject length] > 0) {
                NSURL *directURL = [NSURL URLWithString:videoURLs.firstObject];
                NSString *pathSave = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"story_%@.mp4", [[NSUUID UUID] UUIDString]]];
                [self downloadFileFromURL:directURL saveToPath:pathSave];
                return;
            }
            
            // 2. استخراج صورة الستوري
            id photoAlbum = nil;
            @try { photoAlbum = [model valueForKey:@"photoAlbum"]; } @catch (NSException *e) {}
            if (!photoAlbum) { @try { photoAlbum = [model valueForKey:@"_photoAlbum"]; } @catch (NSException *e) {} }
            
            NSArray *photos = nil;
            if (photoAlbum) {
                @try { photos = [photoAlbum valueForKey:@"photos"]; } @catch (NSException *e) {}
                if (!photos) { @try { photos = [photoAlbum valueForKey:@"_photos"]; } @catch (NSException *e) {} }
            }
            
            if (photos.count > 0) {
                id firstPhoto = photos.firstObject;
                id originPhotoURL = nil;
                @try { originPhotoURL = [firstPhoto valueForKey:@"originPhotoURL"]; } @catch (NSException *e) {}
                if (!originPhotoURL) { @try { originPhotoURL = [firstPhoto valueForKey:@"_originPhotoURL"]; } @catch (NSException *e) {} }
                
                NSArray *photoURLs = nil;
                if (originPhotoURL) {
                    @try { photoURLs = [originPhotoURL valueForKey:@"originURLList"]; } @catch (NSException *e) {}
                    if (!photoURLs) { @try { photoURLs = [originPhotoURL valueForKey:@"_originURLList"]; } @catch (NSException *e) {} }
                }
                
                if (photoURLs.count > 0 && [photoURLs.firstObject length] > 0) {
                    NSURL *directURL = [NSURL URLWithString:photoURLs.firstObject];
                    NSString *pathSave = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"story_%@.jpg", [[NSUUID UUID] UUIDString]]];
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
            
            // حفظ تلقائي في ألبوم الصور
            if ([path hasSuffix:@".mp4"]) {
                UISaveVideoAtPathToSavedPhotosAlbum(path, nil, nil, nil);
            } else if ([path hasSuffix:@".jpg"]) {
                UIImage *image = [UIImage imageWithContentsOfFile:path];
                if (image) {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                }
            }
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
    %init(HooksTikTokStory);
    %init(_ungrouped);
}
