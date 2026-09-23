#import <UIKit/UIKit.h>

@interface UIView (StoryViewController)
- (UIViewController *)viewController;
@end

@interface TTKStoryDetailTableViewCell : UITableViewCell
- (UIViewController *)viewController;

// تصريح عن الدوال الجديدة لتفادي خطأ المترجم (no visible @interface)
- (void)setupStoryDownloadButton;
- (void)handleStoryDownloadTap:(UIButton *)sender;
- (void)downloadFileFromURL:(NSURL *)url saveToPath:(NSString *)path;
@end

@interface AWEAwemeStatusModel : NSObject
- (void)setVideoMuteModel:(id)arg1;
@end
