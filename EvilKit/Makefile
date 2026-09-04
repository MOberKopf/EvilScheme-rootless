export THEOS_PACKAGE_SCHEME := rootless
export ARCHS := arm64 arm64e
export TARGET := iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

SAUCE = $(shell find src -name '*.m')
HEADERS = $(shell find src -name '*.h')

FRAMEWORK_NAME = EvilKit
EvilKit_FILES = $(SAUCE)
EvilKit_PUBLIC_HEADERS = $(HEADERS)
EvilKit_INSTALL_PATH = /Library/Frameworks
# NOTE: GeoServices intentionally NOT linked: EVKMapItemUnwrapperPortion
# uses GEOMapItemStorage purely via the ObjC runtime (forward @interface),
# and the GeoServices framework binary is not present in the Xcode SDK,
# which breaks linking. At runtime on-device the class resolves normally.
EvilKit_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/framework.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
