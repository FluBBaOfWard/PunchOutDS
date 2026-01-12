#include <nds.h>

#include "Gui.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Shared/FileHelper.h"
#include "Main.h"
#include "FileHandling.h"
#include "Cart.h"
#include "Gfx.h"
#include "io.h"
#include "cpu.h"
#include "PunchOut.h"
#include "ARMZ80/Version.h"
#include "RP2A03/ARM6502/Version.h"
#include "RP2A03/Version.h"
#include "VLM5030/Version.h"

#define EMUVERSION "V0.4.1 2026-01-12"

static void scalingSet(void);
static const char *getScalingText(void);
static void controllerSet(void);
static const char *getControllerText(void);
static void swapABSet(void);
static const char *getSwapABText(void);
static void bgrLayerSet(void);
static const char *getBgrLayerText(void);
static void sprLayerSet(void);
static const char *getSprLayerText(void);
static void coinASet(void);
const char *getCoinAText(void);
static void difficultSet(void);
const char *getDifficultText(void);
static void timeSet(void);
const char *getTimeText(void);
static void demoSet(void);
const char *getDemoText(void);
static void discountSet(void);
const char *getDiscountText(void);
static void serviceSet(void);
const char *getServiceText(void);
static void copyrightSet(void);
const char *getcopyrightText(void);

//static void gammaChange(void);

static void ui11(void);

const MItem dummyItems[] = {
	{"", uiDummy}
};
const MItem fileItems[] = {
	{"Load Game", ui9},
	{"Load State", loadState},
	{"Save State", saveState},
	{"Save Settings", saveSettings},
	{"Reset Game", resetGame},
	{"Quit Emulator", ui11},
};
const MItem optionItems[] = {
	{"Controller", ui4},
	{"Display", ui5},
	{"DipSwitches", ui6},
	{"Settings", ui7},
	{"Debug", ui8},
};
const MItem ctrlItems[] = {
	{"B Autofire:", autoBSet, getAutoBText},
	{"A Autofire:", autoASet, getAutoAText},
	{"Controller:", controllerSet, getControllerText},
	{"Swap A-B:  ", swapABSet, getSwapABText},
};
const MItem displayItems[] = {
	{"Display:", scalingSet, getScalingText},
	{"Scaling:", flickSet, getFlickText},
	{"Gamma:", gammaSet, getGammaText},
};
const MItem dipItems[] = {
	{"Coin A:", coinASet, getCoinAText},
	{"Difficulty:", difficultSet, getDifficultText},
	{"Time:", timeSet, getTimeText},
	{"Demo Sound:", demoSet, getDemoText},
	{"Discount:", discountSet, getDiscountText},
	{"Service Mode:", serviceSet, getServiceText},
	{"Copyright:", copyrightSet, getcopyrightText},
};
const MItem setItems[] = {
	{"Speed:", speedSet, getSpeedText},
	{"Autoload State:", autoStateSet, getAutoStateText},
	{"Autosave Settings:", autoSettingsSet, getAutoSettingsText},
	{"Autosave NVRAM:", saveNVRAMSet, getSaveNVRAMText},
	{"Autopause Game:", autoPauseGameSet, getAutoPauseGameText},
	{"Powersave 2nd Screen:", powerSaveSet, getPowerSaveText},
	{"Emulator on Bottom:", screenSwapSet, getScreenSwapText},
	{"Autosleep:", sleepSet, getSleepText},
};
const MItem debugItems[] = {
	{"Debug Output:", debugTextSet, getDebugText},
	{"Disable Background:", bgrLayerSet, getBgrLayerText},
	{"Disable Sprites:", sprLayerSet, getSprLayerText},
	{"Step Frame", stepFrame},
};
const MItem fnList9[ARRSIZE(punchoutGames)] = {
	{"",quickSelectGame}, {"",quickSelectGame}, {"",quickSelectGame}, {"",quickSelectGame}, {"",quickSelectGame}, {"",quickSelectGame}, {"",quickSelectGame}, {"",quickSelectGame},
};
const MItem quitItems[] = {
	{"Yes ", exitEmulator},
	{"No ", backOutOfMenu},
};

const Menu menu0 = MENU_M("", uiNullNormal, dummyItems);
Menu menu1 = MENU_M("", uiAuto, fileItems);
const Menu menu2 = MENU_M("", uiAuto, optionItems);
const Menu menu3 = MENU_M("", uiAbout, dummyItems);
const Menu menu4 = MENU_M("Controller Settings", uiAuto, ctrlItems);
const Menu menu5 = MENU_M("Display Settings", uiAuto, displayItems);
const Menu menu6 = MENU_M("Dipswitch Settings", uiAuto, dipItems);
const Menu menu7 = MENU_M("Settings", uiAuto, setItems);
const Menu menu8 = MENU_M("Debug", uiAuto, debugItems);
const Menu menu9 = MENU_M("Load Game", uiLoadGame, fnList9);
const Menu menu10 = MENU_M("", uiDummy, dummyItems);
const Menu menu11 = MENU_M("Quit Emulator?", uiAuto, quitItems);

const Menu *const menus[] = {&menu0, &menu1, &menu2, &menu3, &menu4, &menu5, &menu6, &menu7, &menu8, &menu9, &menu10, &menu11 };

char *const ctrlTxt[] = {"1P", "2P"};
char *const dispTxt[] = {"Unscaled", "Scaled"};

char *const coinTxt[] = {
	"1 Coin 1 Credit","2 Coin 1 Credits","1 Coin 2 Credits","1 Coin 1 Credit",
	"1 Coin 2 Credits","1 Coin 3 Credits","1 Coin 4 Credits","1 Coin 6 Credits",
	"1 Coin 2 Credits (2)","1 Coin 2 Credits","1 Coin 5 Credits","4 Coins 1 Credit",
	"3 Coins 1 Credit","1 Coin 3 Credits (2)","5 Coins 1 Credit","Free Play"};
char *const diffTxt[] = {"Easy", "Medium", "Hard", "Hardest"};
char *const timeTxt[] = {"Longest", "Long", "Short", "Shortest"};
char *const ninTxt[] = {"Nintendo", "Nintendo of America"};


void setupGUI() {
	emuSettings = AUTOPAUSE_EMULATION | MAIN_ON_BOTTOM;
	keysSetRepeat(25, 4);	// delay, repeat.
	menu1.itemCount = ARRSIZE(fileItems) - (enableExit?0:1);
	openMenu();
}

/// This is called when going from emu to ui.
void enterGUI() {
}

/// This is called going from ui to emu.
void exitGUI() {
}

void autoLoadGame(void) {
	ui9();
	quickSelectGame();
}

void quickSelectGame(void) {
	while (loadGame(selected)) {
		ui10();
		if (!browseForFileType(FILEEXTENSIONS)) {
			backOutOfMenu();
			return;
		}
	}
	closeMenu();
}

void uiNullNormal() {
//	uiNullDefault();
}

void uiAbout() {
	cls(1);
	drawTabs();
	drawMenuText("Select:    Insert coin", 4, 0);
	drawMenuText("Start:     Service coin", 5, 0);
	drawMenuText("Left/Rigt: Dodge", 6, 0);
	drawMenuText("Up/Down:   Hand positions", 7, 0);
	drawMenuText("Y:         Left punch", 8, 0);
	drawMenuText("X:         Right punch", 9, 0);
	drawMenuText("A:         Super punch", 10, 0);
	drawMenuText("B:         Duck (Joystick up)", 11, 0);

	char s[10];
	int2Str(coinCounter0, s);
	drawStrings("CoinCounter1:", s, 1, 15, 0);
	int2Str(coinCounter1, s);
	drawStrings("CoinCounter2:", s, 1, 16, 0);

	drawMenuText("PunchOutDS   " EMUVERSION, 19, 0);
	drawMenuText("ARMZ80       " ARMZ80VERSION, 20, 0);
	drawMenuText("ARM6502      " ARM6502VERSION, 21, 0);
	drawMenuText("RP2A03       " RP2A03VERSION, 22, 0);
	drawMenuText("VLM5030      " VLM5030VERSION, 23, 0);
}

void uiLoadGame() {
	setupSubMenuText();
	int i;
	for (i=0; i<ARRSIZE(punchoutGames); i++) {
		drawSubItem(punchoutGames[i].fullName, NULL);
		if (i > menuYOffset + 10) {
			break;
		}
	}
}

void ui11() {
	enterMenu(11);
}

void nullUINormal(int key) {
	if (key & KEY_TOUCH) {
		openMenu();
	}
}

void nullUIDebug(int key) {
	if (key & KEY_TOUCH) {
		openMenu();
	}
}

void resetGame() {
	loadCart(romNum,0);
}


//---------------------------------------------------------------------------------
/// Switch between Player 1 & Player 2 controls
void controllerSet() {				// See io.s: refreshEMUjoypads
	joyCfg ^= 0x20000000;
}
const char *getControllerText() {
	return ctrlTxt[(joyCfg>>29)&1];
}

/// Swap A & B buttons
void swapABSet() {
	joyCfg ^= 0x400;
}
const char *getSwapABText() {
	return autoTxt[(joyCfg>>10)&1];
}

/// Turn on/off scaling
void scalingSet(){
	gScaling ^= SCALED;
	refreshGfx();
}
const char *getScalingText() {
	return dispTxt[gScaling];
}

/// Turn on/off rendering of background
void bgrLayerSet(){
	gGfxMask ^= 0x03;
}
const char *getBgrLayerText() {
	return autoTxt[gGfxMask&1];
}
/// Turn on/off rendering of sprites
void sprLayerSet(){
	gGfxMask ^= 0x10;
}
const char *getSprLayerText() {
	return autoTxt[(gGfxMask>>4)&1];
}


/// Number of coins for credits
void coinASet() {
	int i = (gDipSwitch0+1) & 0xF;
	gDipSwitch0 = (gDipSwitch0 & ~0xF) | i;
}
const char *getCoinAText() {
	return coinTxt[gDipSwitch0 & 0xF];
}
/// Game difficulty
void difficultSet() {
	int i = (gDipSwitch1+0x01) & 0x03;
	gDipSwitch1 = (gDipSwitch1 & ~0x03) | i;
}
const char *getDifficultText() {
	return diffTxt[gDipSwitch1 & 3];
}
void timeSet() {
	int i = (gDipSwitch1+0x04) & 0x0C;
	gDipSwitch1 = (gDipSwitch1 & ~0x0C) | i;
}
const char *getTimeText() {
	return timeTxt[(gDipSwitch1>>2) & 3];
}
/// Demo sound on/off
void demoSet() {
	gDipSwitch1 ^= 0x10;
}
const char *getDemoText() {
	return autoTxt[(gDipSwitch1>>4) & 1];
}
void discountSet() {
	gDipSwitch1 ^= 0x20;
}
const char *getDiscountText() {
	return autoTxt[(gDipSwitch1>>5) & 1];
}
void serviceSet() {
	gDipSwitch1 ^= 0x80;
}
const char *getServiceText() {
	return autoTxt[(gDipSwitch1>>7) & 1];
}
void copyrightSet() {
	gDipSwitch0 ^= 0x80;
}
const char *getcopyrightText() {
	return ninTxt[(gDipSwitch0>>7) & 1];
}
