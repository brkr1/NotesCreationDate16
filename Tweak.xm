#import <UIKit/UIKit.h>

// Port of NotesCreationDate (originally by ludvigeriksson, iOS 13 fork by gilshahar7)
// for iOS 16 / rootless jailbreaks.
//
// Uses real declared @property accessors (confirmed via a genuine class-dump
// of ICNoteEditorViewController and ICNote on iOS 16), matching how the
// underlying private classes actually expose these values on this OS version.

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

	UIView *dateView = nil;
	if ([textView respondsToSelector:@selector(dateView)]) {
		IMP imp = [textView methodForSelector:@selector(dateView)];
		id (*func)(id, SEL) = (id (*)(id, SEL))imp;
		dateView = func(textView, @selector(dateView));
	}
	if (dateView == nil) {
		return;
	}

	UILabel *dateLabel = nil;
	for (UIView *subview in dateView.subviews) {
		if ([subview isKindOfClass:[UILabel class]]) {
			dateLabel = (UILabel *)subview;
			break;
		}
	}
	if (dateLabel == nil) {
		return;
	}

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[NSLocale currentLocale]];
	[dateFormatter setDateFormat:@"MMMM d, yyyy - h:mm a"];

	NSString *creationDateString = [dateFormatter stringFromDate:creationDate];
	NSString *modificationDateString = [dateFormatter stringFromDate:modificationDate];
	NSString *fullText = [NSString stringWithFormat:@"Created: %@\nModified: %@", creationDateString, modificationDateString];

	[dateLabel setNumberOfLines:0];
	[dateLabel setText:fullText];
	[dateView sizeToFit];
}

%end

%hook ICTextView

- (double)dateLabelOverscroll {
	double r = %orig;
	return r * 2;
}

%end
