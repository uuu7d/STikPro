#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// ============================================================================
// 1. حاوية الصور الفورية (RAM Extraction)
// ============================================================================
@interface ACCImageMediaContainerView : UIView
@property (nonatomic, strong) UIImage *coverImage;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) id publishModel;
@end

// ============================================================================
// 2. المحمل الرئيسي للفيديوهات والواجهات الرسمية (Public Video Downloader & UI)
// ============================================================================
@interface AWEMediaDownloader : NSObject
+ (void)_showLoadingView;
+ (void)_dismissLoadingView;
+ (void)downloadVideoToAlbumWithURLString:(NSString *)urlString completion:(void (^)(id result, NSError *error))completion;
+ (void)downloadVideoWithURLString:(NSString *)urlString completion:(void (^)(id result, NSError *error))completion;
@end

// ============================================================================
// 3. كائن خيارات التحميل المتقدم (Advanced Download Options)
// ============================================================================
@interface AWEIMMediaDownloaderOptions : NSObject
@property (nonatomic, strong) id model; // AWEAwemeModel
@property (nonatomic, copy) NSIndexSet *awemeImageIndicesToDownload;
@property (nonatomic, strong) id assetModel;
@property (nonatomic, assign) BOOL needsSaveToAlbum;
@property (nonatomic, assign) BOOL willBlockUserInteraction;
@property (nonatomic, assign) BOOL shouldDisableTapticEngine;
@property (nonatomic, assign) unsigned long long mediaDownloadType;
@property (nonatomic, assign) unsigned long long downloadReason;
@property (nonatomic, assign) double loadingIndicatorShowDelay;
@end

// ============================================================================
// 4. المحمل المتقدم للوسائط والألبومات والرسائل الخاصة (DM & Private Downloader)
// ============================================================================
@interface AWEIMMediaDownloader : NSObject
+ (void)requestDMMediaWithOptions:(AWEIMMediaDownloaderOptions *)options completion:(void (^)(id result, NSError *error))completion;
@end

// ============================================================================
// 5. أدوات المعالجة والتخزين المؤقت (Media Utilities)
// ============================================================================
@interface AWEIMMediaUtility : NSObject
+ (NSString *)mediaDataTempDirectory;
+ (void)getCoverImageWithAVAsset:(AVAsset *)asset completion:(void (^)(UIImage *coverImage))completion;
+ (void)saveImageInMediaFolder:(UIImage *)image completion:(void (^)(NSString *savedPath, NSError *error))completion;
+ (void)saveJPEGDataInMediaFolder:(NSData *)imageData completion:(void (^)(NSString *savedPath, NSError *error))completion;
@end

// ============================================================================
// 6. المشغل الرئيسي لعرض المحتوى والستوري (Target View Controller)
// ============================================================================
@interface TTKRichContentPlayerViewController : UIViewController
- (void)setupStoryDownloadButton;
- (void)handleStoryDownloadTap:(UIButton *)sender;
@end
