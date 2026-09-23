TARGET := iphone:clang:latest:14.0
ARCHS = arm64
INSTALL_TYPE := rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WheeDownloader

WheeDownloader_FILES = Tweak.x
WheeDownloader_CFLAGS = -fobjc-arc
WheeDownloader_FRAMEWORKS = UIKit Foundation AVFoundation Photos

include $(THEOS_MAKE_PATH)/tweak.mk
