TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DomainBlocker

DomainBlocker_FILES = Tweak.xm
DomainBlocker_FRAMEWORKS = UIKit Foundation
DomainBlocker_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

DomainBlocker_CODESIGN_FLAGS = -S-

include $(THEOS_MAKE_PATH)/tweak.mk
