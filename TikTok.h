#import <UIKit/UIKit.h>

// التصريح عن الكلاسات التي أظهرتها أداة FLEX
@interface TTKRichContentPlayerViewController : UIViewController
- (void)setupStoryDownloadButton;
- (void)handleStoryDownloadTap:(UIButton *)sender;
- (void)downloadFileFromURL:(NSURL *)url saveToPath:(NSString *)path;
@end

@interface AWEAwemeStatusModel : NSObject
- (void)setVideoMuteModel:(id)arg1;
@end
