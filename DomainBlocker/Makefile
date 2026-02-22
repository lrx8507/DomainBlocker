TARGET := iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DomainBlocker

DomainBlocker_FILES = Tweak.xm
DomainBlocker_FRAMEWORKS = UIKit Foundation
DomainBlocker_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

NO_SIGNING = 1

include $(THEOS_MAKE_PATH)/tweak.mk
