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

static void LXDebugLog(NSString *line) {
    @try {
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:
                          @"Documents/NotesCreationDate16_debug.txt"];

        NSString *timestamped =
            [NSString stringWithFormat:@"%@ %@\n", [NSDate date], line];

        NSFileManager *fm = [NSFileManager defaultManager];

        if (![fm fileExistsAtPath:path]) {
            [fm createFileAtPath:path contents:nil attributes:nil];
        }

        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];

        if (handle != nil) {
            [handle seekToEndOfFile];
            [handle writeData:[timestamped dataUsingEncoding:NSUTF8StringEncoding]];
            [handle closeFile];
        }
    }
    @catch (NSException *e) {
    }
}

static void LXDumpViewHierarchy(UIView *view, NSInteger level) {
    if (view == nil) {
        return;
    }

    NSMutableString *indent = [NSMutableString string];

    for (NSInteger i = 0; i < level; i++) {
        [indent appendString:@"  "];
    }

    NSString *className = NSStringFromClass([view class]);

    NSString *text = @"";

    if ([view isKindOfClass:[UILabel class]]) {
        text = [NSString stringWithFormat:@" text=%@", [(UILabel *)view text]];
    }
    else if ([view isKindOfClass:[UITextView class]]) {
        text = [NSString stringWithFormat:@" text=%@", [(UITextView *)view text]];
    }
    else if ([view isKindOfClass:[UIButton class]]) {
        text = [NSString stringWithFormat:@" title=%@", [(UIButton *)view titleForState:UIControlStateNormal]];
    }

    LXDebugLog([NSString stringWithFormat:
                @"%@%@ frame=%@ hidden=%d alpha=%f%@",
                indent,
                className,
                NSStringFromCGRect(view.frame),
                view.hidden,
                view.alpha,
                text]);

    for (UIView *subview in view.subviews) {
        LXDumpViewHierarchy(subview, level + 1);
    }
}

%hook ICNoteEditorViewController

- (void)viewDidLayoutSubviews {
    %orig;

    if (self.view.window == nil) {
        return;
    }

    [self updateDateLabel];
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    [self updateDateLabel];
}

%new

- (void)updateDateLabel {
    if (self.view.window == nil) {
        return;
    }

    LXDebugLog(@"========================================");
    LXDebugLog(@"updateDateLabel: entered");

    ICNote *note = self.note;

    if (note == nil) {
        LXDebugLog(@"note is nil");
        return;
    }

    NSDate *creationDate = note.creationDate;
    NSDate *modificationDate = note.modificationDate;

    LXDebugLog([NSString stringWithFormat:
                @"creationDate = %@ / modificationDate = %@",
                creationDate,
                modificationDate]);

    ICTextView *textView = self.textView;

    if (textView == nil) {
        LXDebugLog(@"textView is nil");
        return;
    }

    LXDebugLog([NSString stringWithFormat:
                @"textView = %@",
                textView]);

    if (![textView respondsToSelector:@selector(dateView)]) {
        LXDebugLog(@"textView does NOT respond to dateView");
        return;
    }

    IMP imp = [textView methodForSelector:@selector(dateView)];

    id (*func)(id, SEL) = (id (*)(id, SEL))imp;

    UIView *dateView = func(textView, @selector(dateView));

    if (dateView == nil) {
        LXDebugLog(@"dateView is nil");
        return;
    }

    LXDebugLog([NSString stringWithFormat:
                @"dateView = %@",
                dateView]);

    LXDebugLog(@"--- BEGIN DATE VIEW HIERARCHY ---");

    LXDumpViewHierarchy(dateView, 0);

    LXDebugLog(@"--- END DATE VIEW HIERARCHY ---");
}

%end

