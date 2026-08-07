#import <UIKit/UIKit.h>

// Port of NotesCreationDate (originally by ludvigeriksson, iOS 13 fork by gilshahar7)
// for iOS 16 / rootless jailbreaks.

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

// Writes into the app's own sandboxed Documents folder (always writable by
// MobileNotes itself, unlike SpringBoard's much stricter sandbox).
static void LXDebugLog(NSString *line) {
    @try {
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/NotesCreationDate16_debug.txt"];
        NSString *timestamped = [NSString stringWithFormat:@"%@ %@\n", [NSDate date], line];
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
    } @catch (NSException *e) {
        // best effort
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

	LXDebugLog(@"updateDateLabel: entered");

	ICNote *note = self.note;
	if (note == nil) {
		LXDebugLog(@"note is nil");
		return;
	}
	LXDebugLog([NSString stringWithFormat:@"note = %@", note]);

	NSDate *creationDate = note.creationDate;
	NSDate *modificationDate = note.modificationDate;
	LXDebugLog([NSString stringWithFormat:@"creationDate = %@ / modificationDate = %@", creationDate, modificationDate]);
	if (creationDate == nil || modificationDate == nil) {
		return;
	}

	ICTextView *textView = self.textView;
	if (textView == nil) {
		LXDebugLog(@"textView is nil");
		return;
	}
	LXDebugLog([NSString stringWithFormat:@"textView = %@, respondsToSelector(dateView) = %d", textView, [textView respondsToSelector:@selector(dateView)]]);

	UIView *dateView = nil;
	if ([textView respondsToSelector:@selector(dateView)]) {
		IMP imp = [textView methodForSelector:@selector(dateView)];
		id (*func)(id, SEL) = (id (*)(id, SEL))imp;
		dateView = func(textView, @selector(dateView));
	}
	if (dateView == nil) {
		LXDebugLog(@"dateView is nil");
		return;
	}
	LXDebugLog([NSString stringWithFormat:@"dateView = %@, subviews = %@", dateView, dateView.subviews]);

	UILabel *dateLabel = nil;
	for (UIView *subview in dateView.subviews) {
		if ([subview isKindOfClass:[UILabel class]]) {
			dateLabel = (UILabel *)subview;
			break;
		}
	}
	if (dateLabel == nil) {
		LXDebugLog([NSString stringWithFormat:@"no UILabel found among dateView's %lu subviews", (unsigned long)dateView.subviews.count]);
		return;
	}
	LXDebugLog([NSString stringWithFormat:@"dateLabel found: %@, current text = %@", dateLabel, dateLabel.text]);

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[NSLocale currentLocale]];
	[dateFormatter setDateFormat:@"MMMM d, yyyy - h:mm a"];

	NSString *creationDateString = [dateFormatter stringFromDate:creationDate];
	NSString *modificationDateString = [dateFormatter stringFromDate:modificationDate];
	NSString *fullText = [NSString stringWithFormat:@"Created: %@\nModified: %@", creationDateString, modificationDateString];

	[dateLabel setNumberOfLines:0];
	[dateLabel setText:fullText];
	[dateView sizeToFit];

	LXDebugLog([NSString stringWithFormat:@"SUCCESS: set label text to \"%@\"", fullText]);
}

%end

%hook ICTextView

- (double)dateLabelOverscroll {
	double r = %orig;
	return r * 2;
}

%end
