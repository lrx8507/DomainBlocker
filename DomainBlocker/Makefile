TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DomainBlocker

DomainBlocker_FILES = Tweak.xm
DomainBlocker_FRAMEWORKS = UIKit Foundation
DomainBlocker_CFLAGS = -fobjc-arc

# 禁用代码签名，由 CI 脚本后续处理或 TrollStore 自动处理
DomainBlocker_CODESIGN_FLAGS = -S-

include $(THEOS_MAKE_PATH)/tweak.mk
