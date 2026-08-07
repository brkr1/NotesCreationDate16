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

// Armazena a referência do Controller visível para uso na interceptação do UILabel
static __weak ICNoteEditorViewController *currentController = nil;

static NSString *LXFormatDate(NSDate *date) {
    if (date == nil) return @"";

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"d MMMM yyyy HH:mm";

    return [formatter stringFromDate:date];
}

static UILabel *LXFindLabel(UIView *view) {
    if ([view isKindOfClass:[UILabel class]]) {
        return (UILabel *)view;
    }
    for (UIView *subview in view.subviews) {
        UILabel *label = LXFindLabel(subview);
        if (label != nil) return label;
    }
    return nil;
}

static BOOL LXIsNotesDateLabel(UILabel *label) {
    UIView *view = label;
    while (view != nil) {
        if ([NSStringFromClass([view class]) isEqualToString:@"ICNoteEditorDateView"]) {
            return YES;
        }
        view = view.superview;
    }
    return NO;
}

static NSString *LXBuildFormattedString(ICNote *note) {
    if (!note || !note.creationDate || !note.modificationDate) return nil;
    
    NSString *creation = LXFormatDate(note.creationDate);
    NSString *modification = LXFormatDate(note.modificationDate);
    
    return [NSString stringWithFormat:@"Created: %@\nModified: %@", creation, modification];
}

static void LXUpdateDateLabel(ICNoteEditorViewController *controller) {
    if (controller == nil) return;
    
    ICNote *note = controller.note;
    ICTextView *textView = controller.textView;
    if (note == nil || textView == nil) return;

    if (![textView respondsToSelector:@selector(dateView)]) return;

    IMP imp = [textView methodForSelector:@selector(dateView)];
    if (imp == NULL) return;

    id (*func)(id, SEL) = (id (*)(id, SEL))imp;
    UIView *dateView = func(textView, @selector(dateView));
    if (dateView == nil) return;

    UILabel *dateLabel = LXFindLabel(dateView);
    if (dateLabel == nil) return;

    NSString *newText = LXBuildFormattedString(note);
    if (!newText) return;

    dateLabel.numberOfLines = 0;
    
    // Evita loop infinito se o texto já for exatamente o mesmo
    if (![dateLabel.text isEqualToString:newText]) {
        dateLabel.text = newText;
    }

    [dateLabel sizeToFit];
    
    // Ajusta a altura da view da data para comportar as 2 linhas sem truncar
    CGRect frame = dateView.frame;
    if (frame.size.height < dateLabel.frame.size.height) {
        frame.size.height = dateLabel.frame.size.height + 10.0;
        dateView.frame = frame;
    }

    [dateView setNeedsLayout];
    [dateView layoutIfNeeded];
}

%hook UILabel

- (void)setText:(NSString *)text {
    if (LXIsNotesDateLabel(self)) {
        if (currentController && currentController.note) {
            NSString *customText = LXBuildFormattedString(currentController.note);
            if (customText && ![text isEqualToString:customText]) {
                self.numberOfLines = 0;
                %orig(customText);
                
                [self sizeToFit];
                UIView *dateView = self.superview;
                if (dateView) {
                    CGRect frame = dateView.frame;
                    if (frame.size.height < self.frame.size.height) {
                        frame.size.height = self.frame.size.height + 10.0;
                        dateView.frame = frame;
                    }
                }
                return;
            }
        }
    }
    %orig(text);
}

%end

%hook ICNoteEditorViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    currentController = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        LXUpdateDateLabel(self);
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    if (currentController == self) {
        currentController = nil;
    }
}

- (void)viewDidLayoutSubviews {
    %orig;
    if (self.view.window == nil) return;
    currentController = self;
    LXUpdateDateLabel(self);
}

%end

%hook ICTextView

- (double)dateLabelOverscroll {
    // Aumenta o espaço reservado para a label no topo do editor
    return %orig * 2.5;
}

%end