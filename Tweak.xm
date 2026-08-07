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

static NSString *LXDebugPath(void) {
    return [NSHomeDirectory() stringByAppendingPathComponent:
            @"Documents/NotesCreationDate16_debug.txt"];
}

static void LXDebugLog(NSString *line) {
    @try {
        NSString *path = LXDebugPath();

        NSString *timestamped =
            [NSString stringWithFormat:@"%@ %@\n",
             [NSDate date], line];

        NSFileManager *fm = [NSFileManager defaultManager];

        if (![fm fileExistsAtPath:path]) {
            [fm createFileAtPath:path contents:nil attributes:nil];
        }

        NSFileHandle *handle =
            [NSFileHandle fileHandleForWritingAtPath:path];

        if (handle != nil) {
            [handle seekToEndOfFile];

            [handle writeData:
                [timestamped dataUsingEncoding:NSUTF8StringEncoding]];

            [handle closeFile];
        }
    }
    @catch (NSException *exception) {
    }
}

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

static BOOL LXIsNotesDateLabel(UILabel *label) {
    UIView *view = label;

    while (view != nil) {
        if ([NSStringFromClass([view class])
             isEqualToString:@"ICNoteEditorDateView"]) {
            return YES;
        }

        view = view.superview;
    }

    return NO;
}

%hook UILabel

- (void)setText:(NSString *)text {
    if (LXIsNotesDateLabel(self)) {
        LXDebugLog(
            [NSString stringWithFormat:
                @"========== DATE LABEL setText ==========\n"
                @"label = %@\n"
                @"new text = %@\n"
                @"frame = %@\n"
                @"numberOfLines = %ld\n"
                @"superview = %@",
                self,
                text,
                NSStringFromCGRect(self.frame),
                (long)self.numberOfLines,
                self.superview]
        );

        NSArray *symbols =
            [NSThread callStackSymbols];

        LXDebugLog(
            [NSString stringWithFormat:
                @"CALL STACK:\n%@",
                [symbols componentsJoinedByString:@"\n"]]
        );
    }

    %orig;
}

%end

%hook ICNoteEditorViewController

- (void)viewDidLayoutSubviews {
    %orig;

    if (self.view.window == nil) {
        return;
    }

    ICNote *note = self.note;

    if (note == nil) {
        return;
    }

    NSDate *creationDate = note.creationDate;
    NSDate *modificationDate = note.modificationDate;

    LXDebugLog(
        [NSString stringWithFormat:
            @"ICNoteEditorViewController layout - "
            @"creation=%@ modification=%@",
            creationDate,
            modificationDate]
    );

    ICTextView *textView = self.textView;

    if (textView == nil) {
        return;
    }

    if (![textView respondsToSelector:@selector(dateView)]) {
        return;
    }

    IMP imp =
        [textView methodForSelector:@selector(dateView)];

    id (*func)(id, SEL) =
        (id (*)(id, SEL))imp;

    UIView *dateView =
        func(textView, @selector(dateView));

    if (dateView == nil) {
        return;
    }

    UILabel *dateLabel =
        LXFindLabel(dateView);

    if (dateLabel == nil) {
        return;
    }

    LXDebugLog(
        [NSString stringWithFormat:
            @"CURRENT DATE LABEL after layout: "
            @"text=%@ frame=%@ lines=%ld",
            dateLabel.text,
            NSStringFromCGRect(dateLabel.frame),
            (long)dateLabel.numberOfLines]
    );
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    LXDebugLog(@"ICNoteEditorViewController viewDidAppear");
}

%end

%hook ICTextView

- (double)dateLabelOverscroll {
    double r = %orig;

    LXDebugLog(
        [NSString stringWithFormat:
            @"dateLabelOverscroll original=%f",
            r]
    );

    return r * 2;
}

%end
