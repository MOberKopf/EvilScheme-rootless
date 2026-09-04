export THEOS_PACKAGE_SCHEME := rootless
export ARCHS := arm64 arm64e
export TARGET := iphone:clang:latest:15.0

# Anchor to this Makefile's own directory: THEOS_PROJECT_DIR is inherited
# from the top-level make when built via aggregate, so it cannot be used here.
_THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = EvilSchemePrefs

SAUCE = $(shell find src -name "*.m") $(shell find L0Prefs -name "*.m")
HEADERS = $(shell find src -name "*.h") $(shell find L0Prefs -name "*.h")

EvilSchemePrefs_FILES = $(SAUCE)
EvilSchemePrefs_HEADERS = $(HEADERS)
EvilSchemePrefs_INSTALL_PATH = /Library/PreferenceBundles
EvilSchemePrefs_FRAMEWORKS = UIKit
EvilSchemePrefs_PRIVATE_FRAMEWORKS = Preferences
EvilSchemePrefs_EXTRA_FRAMEWORKS += EvilKit
EvilSchemePrefs_CFLAGS = -fobjc-arc
# Same as top-level Makefile: EvilKit.framework is built first (see CI),
# Prefs lives one directory deeper, hence ../EvilKit.
EvilSchemePrefs_CFLAGS += -F$(_THIS_DIR)/../EvilKit
EvilSchemePrefs_LDFLAGS += -F$(_THIS_DIR)/../EvilKit
# L0Prefs helper lib uses pre-iOS-15 APIs (e.g. UIApplication.windows);
# theos builds with -Werror, so don't fail on deprecation warnings.
EvilSchemePrefs_CFLAGS += -Wno-error=deprecated-declarations

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/EvilSchemePrefs.plist$(ECHO_END)
