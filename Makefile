THEOS_PACKAGE_SCHEME = rootless
TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VirtualCam
VirtualCam_FILES = Tweak.xm VCHUDWindow.m FrameStore.m VCDaemonClient.m
VirtualCam_CFLAGS = -fobjc-arc -Wno-error -Wno-implicit-enum-enum-cast
VirtualCam_FRAMEWORKS = UIKit AVFoundation CoreMedia CoreVideo

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += VirtualCamDaemon
include $(THEOS_MAKE_PATH)/aggregate.mk
