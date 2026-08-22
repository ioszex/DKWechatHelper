TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e

ifeq ($(SCHEME),roothide)
export THEOS_PACKAGE_SCHEME = roothide
else ifeq ($(SCHEME),rootless)
export THEOS_PACKAGE_SCHEME = rootless
else
unexport THEOS_PACKAGE_SCHEME
endif

ifeq ($(GITHUB_ACTIONS),true)
export INSTALL = 0
export FINALPACKAGE = 1
endif

export DEBUG = 0
INSTALL_TARGET_PROCESSES = WeChat

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = dkhelper

# Logos 主 hook；勿加入 Logos/dkhelperDylib.mm（Logos 会从 .xm 自动生成）
DKHELPER_CORE_SRC = \
	Logos/dkhelperDylib.xm \
	dkhelperDylib.m \
	DKHelperSettingController.m \
	DKLaunchViewController.m \
	DKGroupFilterController.m \
	DKCleanFriendsController.m \
	MyUtils/DKHelper.m \
	MyUtils/DKHelperConfig.m \
	MyUtils/DKLaunchHelper.m \
	MyUtils/NSArray+Utils.m \
	AntiAntiDebug/AntiAntiDebug.m \
	fishhook/fishhook.c

# QGVAPlayer（聊天背景 VAP 动画）
DKHELPER_QGVA_SRC = $(shell find QGVAPlayer/class -name '*.m')

# MonkeyDev 调试组件，默认不编进包（依赖 Cycript / 体积大）
ifeq ($(MONKEYDEV),1)
DKHELPER_DEBUG_SRC = \
	Config/MDConfigManager.m \
	Config/MDCycriptManager.m \
	Config/MDMethodTrace.m \
	Trace/OCMethodTrace.m \
	Trace/OCSelectorTrampolines.mm \
	Tools/LLDBTools.mm
ifneq (,$(filter arm64,$(ARCHS)))
DKHELPER_DEBUG_SRC += Trace/a1a2-selectortramps-arm64.s
endif
endif

$(TWEAK_NAME)_FILES = \
	$(DKHELPER_CORE_SRC) \
	$(DKHELPER_QGVA_SRC) \
	$(DKHELPER_DEBUG_SRC)

# 不直接编译 .metal：Theos 无默认 Metal 规则；运行时走 QGHWDMetalShaderSourceDefine.h 内嵌 shader 兜底

$(TWEAK_NAME)_CFLAGS = -fobjc-arc -w
$(TWEAK_NAME)_CFLAGS += -I$(THEOS_PROJECT_DIR)/wechatHeaders
$(TWEAK_NAME)_CFLAGS += -I$(THEOS_PROJECT_DIR)/MyUtils
$(TWEAK_NAME)_CFLAGS += -I$(THEOS_PROJECT_DIR)/Config
$(TWEAK_NAME)_CFLAGS += -I$(THEOS_PROJECT_DIR)/Trace
$(TWEAK_NAME)_CFLAGS += -I$(THEOS_PROJECT_DIR)/Tools
$(TWEAK_NAME)_CFLAGS += -I$(THEOS_PROJECT_DIR)/fishhook
$(TWEAK_NAME)_CFLAGS += -I$(THEOS_PROJECT_DIR)/AntiAntiDebug
$(TWEAK_NAME)_CFLAGS += -I$(THEOS_PROJECT_DIR)/QGVAPlayer/Shaders
# QGVAPlayer 头文件分散在多层子目录（Models/Views/Utils 等）
$(TWEAK_NAME)_CFLAGS += $(patsubst %,-I%,$(shell find $(THEOS_PROJECT_DIR)/QGVAPlayer/class -type d))

# CaptainHook 头文件：可 git clone https://github.com/hookmaster/CaptainHook 到 vendor/CaptainHook
ifneq (,$(wildcard $(THEOS_PROJECT_DIR)/vendor/CaptainHook/CaptainHook.h))
$(TWEAK_NAME)_CFLAGS += -I$(THEOS_PROJECT_DIR)/vendor/CaptainHook
else ifneq (,$(wildcard $(THEOS)/vendor/include/CaptainHook/CaptainHook.h))
$(TWEAK_NAME)_CFLAGS += -I$(THEOS)/vendor/include/CaptainHook
endif

$(TWEAK_NAME)_LDFLAGS = -lz -lc++
$(TWEAK_NAME)_LIBRARIES = substrate
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation CoreMotion AVFoundation QuartzCore OpenGLES GLKit Metal MetalKit VideoToolbox

$(TWEAK_NAME)_LOGOS_DEFAULT_GENERATOR = internal
export THEOS_STRICT_LOGOS = 0
export ERROR_ON_WARNINGS = 0

include $(THEOS_MAKE_PATH)/tweak.mk

clean::
	@rm -rf .theos packages
