#import <UIKit/UIKit.h>

@interface ICTextView : UITextView
@end

%hook ICTextView

- (double)dateLabelOverscroll {
    double r = %orig;
    return r * 2.5;
}

%end
