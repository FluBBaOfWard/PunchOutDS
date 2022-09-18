#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

GAME_TITLE		:=	Punch-Out!!
GAME_SUBTITLE1	:=	Punch Out Arcade Emulator
GAME_SUBTITLE2	:=	www.ndsretro.com
GAME_ICON		:=	$(CURDIR)/../PunchOut.bmp

include $(DEVKITARM)/ds_rules

#---------------------------------------------------------------------------------
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# INCLUDES is a list of directories containing extra header files
#---------------------------------------------------------------------------------
TARGET		:=	$(shell basename $(CURDIR))
BUILD		:=	build
SOURCES		:=	source	\
				source/Shared \
				source/Shared/Unzip \
				source/ARMZ80 \
				source/ARM6502 \
				source/N2A03 \
				source/VLM5030
DATA		:=	data  
INCLUDES	:=	include
GRAPHICS	:=	graphics \
				source/Shared/graphics

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
ARCH	:=	-march=armv5te -mtune=arm946e-s -mthumb -mthumb-interwork
FLAGS	:=	-DARM9 -DNDS -DCPU_N2A03

CFLAGS	:=	-g -Wall -O2 \
			-fomit-frame-pointer \
			-ffast-math \
			$(ARCH)

CFLAGS	+=	$(INCLUDE) $(FLAGS)
CXXFLAGS	:= $(CFLAGS) -fno-exceptions -fno-rtti

ASFLAGS	:=	-g $(ARCH) $(INCLUDE) $(FLAGS)
LDFLAGS	=	-specs=ds_arm9.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

#---------------------------------------------------------------------------------
# any extra libraries we wish to link with the project
#---------------------------------------------------------------------------------
LIBS	:= -lfat -lmm9 -lnds9


#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS	:=	$(LIBNDS)

#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
					$(foreach dir,$(DATA),$(CURDIR)/$(dir)) \
					$(foreach dir,$(GRAPHICS),$(CURDIR)/$(dir))


export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
PNGFILES	:=	$(foreach dir,$(GRAPHICS),$(notdir $(wildcard $(dir)/*.png)))
BINFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

#---------------------------------------------------------------------------------
# use CXX for linking C++ projects, CC for standard C
#---------------------------------------------------------------------------------
ifeq ($(strip $(CPPFILES)),)
#---------------------------------------------------------------------------------
	export LD	:=	$(CC)
#---------------------------------------------------------------------------------
else
#---------------------------------------------------------------------------------
	export LD	:=	$(CXX)
#---------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------

export OFILES	:=	$(addsuffix .o,$(BINFILES)) \
					$(PNGFILES:.png=.o) \
					$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
					$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
					-I$(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

.PHONY: $(BUILD) clean

#---------------------------------------------------------------------------------
$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@make --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

#---------------------------------------------------------------------------------
clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).elf $(TARGET).nds $(TARGET).arm9 $(TARGET).ds.gba 


#---------------------------------------------------------------------------------
else

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
$(OUTPUT).nds	: 	$(OUTPUT).elf
$(OUTPUT).elf	:	$(OFILES)

#---------------------------------------------------------------------------------
%.pcx.o	:	%.pcx
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

#---------------------------------------------------------------------------------
%.s %.h	: %.png %.grit
#---------------------------------------------------------------------------------
	grit $< -fts -o$*


-include $(DEPENDS)

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------
