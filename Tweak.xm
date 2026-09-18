#import <UIKit/UIKit.h>

@interface ICNote : NSObject
@property (nonatomic, retain, readonly) NSDate *creationDate;
@property (nonatomic, retain, readonly) NSDate *modificationDate;
@end

@interface ICTextView : UITextView
@end

@interface ICNoteEditorViewController : UIViewController
@property (nonatomic, strong, readonly) ICNote *note;
@property (nonatomic, strong, readonly) ICTextView *textView;
@end

static UILabel *LXFindLabel(UIView *view) {
    if ([view isKindOfClass:[UILabel class]]) {
        return (UILabel *)view;
    }

    for (UIView *subview in view.subviews) {
        UILabel *label = LXFindLabel(subview);
        if (label != nil) {
            return label;
        }
    }
    return nil;
}

static NSString *LXFormatDate(NSDate *date) {
    if (date == nil) return @"";

    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"d MMMM yyyy HH:mm";
    });

    return [formatter stringFromDate:date];
}

static NSString *LXBuildFormattedDateString(ICNote *note) {
    if (!note || !note.creationDate || !note.modificationDate) return nil;

    NSString *creation = LXFormatDate(note.creationDate);
    NSString *modification = LXFormatDate(note.modificationDate);

    return [NSString stringWithFormat:@"Created: %@\nModified: %@", creation, modification];
}

static void LXUpdateDateLabel(ICNoteEditorViewController *controller) {
    if (controller == nil || controller.note == nil || controller.textView == nil) return;

    ICTextView *textView = controller.textView;
    if (![textView respondsToSelector:@selector(dateView)]) return;

    IMP imp = [textView methodForSelector:@selector(dateView)];
    if (imp == NULL) return;

    id (*func)(id, SEL) = (id (*)(id, SEL))imp;
    UIView *dateView = func(textView, @selector(dateView));
    if (dateView == nil) return;

    UILabel *dateLabel = LXFindLabel(dateView);
    if (dateLabel == nil) return;

    NSString *newText = LXBuildFormattedDateString(controller.note);
    if (!newText) return;

    dateLabel.numberOfLines = 0;
    dateLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    if (![dateLabel.text isEqualToString:newText]) {
        dateLabel.text = newText;
        [dateLabel sizeToFit];
        [dateView setNeedsLayout];
        [dateView layoutIfNeeded];
    }
}

%hook ICNoteEditorViewController

- (void)viewDidLayoutSubviews {
    %orig;
    if (self.view.window == nil) return;

    LXUpdateDateLabel(self);
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    __weak ICNoteEditorViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        LXUpdateDateLabel(weakSelf);
    });
}

%end

%hook ICTextView

- (double)dateLabelOverscroll {
    double r = %orig;
    return r * 2.5;
}

%end