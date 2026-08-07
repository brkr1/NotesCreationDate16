ARCHS = arm64 arm64e

ifeq ($(THEOS_PACKAGE_SCHEME), rootless)
    TARGET := iphone:clang:latest:15.0
    TARGET_OS_DEPLOYMENT_VERSION = 15.0
    # On Linux builds (no real Xcode available) we point at a manually
    # downloaded SDK. On macOS with real Xcode installed, THEOS_SDKS_PATH
    # or Xcode's own SDKs are used automatically instead - don't override
    # SYSROOT there, or Theos won't be able to find a real Xcode SDK.
    ifneq ($(wildcard $(THEOS)/sdks/iPhoneOS15.6.sdk),)
        SYSROOT=$(THEOS)/sdks/iPhoneOS15.6.sdk
        SDKVERSION = 15.6
        INCLUDE_SDKVERSION = 15.6
    endif
else
    TARGET := iphone:clang:latest:13.0
    TARGET_OS_DEPLOYMENT_VERSION = 13.0
endif

# Uncomment before release to remove build number
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NotesCreationDate16

NotesCreationDate16_FILES = Tweak.xm
NotesCreationDate16_CFLAGS = -fobjc-arc
NotesCreationDate16_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileNotes"
