THEOS_PACKAGE_SCHEME = rootless
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VirtualCam
VirtualCam_FILES = Tweak.xm VCHUDWindow.m FrameStore.m VCDaemonClient.m
VirtualCam_CFLAGS = -fobjc-arc
VirtualCam_FRAMEWORKS = UIKit AVFoundation CoreMedia CoreVideo
VirtualCam_PRIVATE_FRAMEWORKS = SpringBoard

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += VirtualCamDaemon
include $(THEOS_MAKE_PATH)/aggregate.mk
