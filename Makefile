export THEOS_PACKAGE_SCHEME := rootless
export ARCHS := arm64
export TARGET := iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ZZ_EvilScheme
ZZ_EvilScheme_FILES = EvilScheme.x
ZZ_EvilScheme_CFLAGS = -fobjc-arc
ZZ_EvilScheme_PRIVATE_FRAMEWORKS = UserActivity CoreServices
ZZ_EvilScheme_EXTRA_FRAMEWORKS += EvilKit
# EvilKit is built as a subproject; allow the compiler/linker to find the
# just-built EvilKit.framework before it is installed anywhere.
ZZ_EvilScheme_CFLAGS += -F$(THEOS_PROJECT_DIR)/EvilKit
ZZ_EvilScheme_LDFLAGS += -F$(THEOS_PROJECT_DIR)/EvilKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "sbreload || killall -9 SpringBoard"

SUBPROJECTS += EvilKit
SUBPROJECTS += Prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
