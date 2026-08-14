TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TOOL_NAME = VirtualCamDaemon
VirtualCamDaemon_FILES = main.m
VirtualCamDaemon_CFLAGS = -fobjc-arc
VirtualCamDaemon_FRAMEWORKS = Foundation CoreMedia CoreVideo AVFoundation UIKit
VirtualCamDaemon_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/tool.mk
