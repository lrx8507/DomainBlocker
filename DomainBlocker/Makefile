TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DomainBlocker

DomainBlocker_FILES = Tweak.xm
DomainBlocker_FRAMEWORKS = UIKit Foundation
DomainBlocker_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

# === 关键修复：在 Makefile 中直接禁用签名 ===
NO_SIGNING = 1

include $(THEOS_MAKE_PATH)/tweak.mk
