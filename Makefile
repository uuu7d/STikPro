THEOS ?= ./theos
TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e
INSTALL_TARGET_PROCESSES := TikTok

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := STikPro

STikPro_FILES := Tweak.x
STikPro_CFLAGS := -fobjc-arc

include $(THEOS_MAKEPATH)/tweak.mk
