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
- (void)updateDateLabel;
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

%hook ICNoteEditorViewController

- (void)viewDidLayoutSubviews {
    %orig;

    if (self.view.window == nil) {
        return;
    }

    [self updateDateLabel];

    __weak typeof(self) weakSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (strongSelf != nil && strongSelf.view.window != nil) {
            [strongSelf updateDateLabel];
        }
    });

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;

            if (strongSelf != nil && strongSelf.view.window != nil) {
                [strongSelf updateDateLabel];
            }
        }
    );
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    [self updateDateLabel];

    __weak typeof(self) weakSelf = self;

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;

            if (strongSelf != nil && strongSelf.view.window != nil) {
                [strongSelf updateDateLabel];
            }
        }
    );
}

%new

- (void)updateDateLabel {
    if (self.view.window == nil) {
        return;
    }

    ICNote *note = self.note;

    if (note == nil) {
        return;
    }

    NSDate *creationDate = note.creationDate;
    NSDate *modificationDate = note.modificationDate;

    if (creationDate == nil || modificationDate == nil) {
        return;
    }

    ICTextView *textView = self.textView;

    if (textView == nil) {
        return;
    }

    if (![textView respondsToSelector:@selector(dateView)]) {
        return;
    }

    IMP imp = [textView methodForSelector:@selector(dateView)];

    id (*func)(id, SEL) = (id (*)(id, SEL))imp;

    UIView *dateView = func(textView, @selector(dateView));

    if (dateView == nil) {
        return;
    }

    UILabel *dateLabel = LXFindLabel(dateView);

    if (dateLabel == nil) {
        return;
    }

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

    [dateFormatter setLocale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:@"MMMM d, yyyy - h:mm a"];

    NSString *creationDateString =
        [dateFormatter stringFromDate:creationDate];

    NSString *modificationDateString =
        [dateFormatter stringFromDate:modificationDate];

    NSString *fullText =
        [NSString stringWithFormat:
            @"Created: %@\nModified: %@",
            creationDateString,
            modificationDateString];

    [dateLabel setNumberOfLines:2];
    [dateLabel setText:fullText];

    [dateLabel sizeToFit];
    [dateView sizeToFit];
}

%end
