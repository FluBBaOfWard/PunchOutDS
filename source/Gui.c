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
#include "ARMZ80/Version.h"
#include "ARM6502/Version.h"
#include "N2A03/Version.h"
#include "VLM5030/Version.h"

#define EMUVERSION "V0.4.1 2022-10-02"

static void uiDebug(void);

const fptr fnMain[] = {nullUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI};

const fptr fnList0[] = {uiDummy};
const fptr fnList1[] = {ui9, loadState, saveState, saveSettings, resetGame};
const fptr fnList2[] = {ui4, ui5, ui6, ui7, ui8};
const fptr fnList3[] = {uiDummy};
const fptr fnList4[] = {autoBSet, autoASet, controllerSet, swapABSet};
const fptr fnList5[] = {scalingSet, flickSet, gammaSet};
const fptr fnList6[] = {speedSet, autoStateSet, autoSettingsSet, autoNVRAMSet, autoPauseGameSet, powerSaveSet, screenSwapSet, sleepSet};
const fptr fnList7[] = {debugTextSet, bgrLayerSet, sprLayerSet};
const fptr fnList8[] = {coinASet, difficultSet, timeSet, demoSet, discountSet, serviceSet, copyrightSet};
const fptr fnList9[] = {quickSelectGame, quickSelectGame, quickSelectGame, quickSelectGame, quickSelectGame, quickSelectGame, quickSelectGame, quickSelectGame};
const fptr fnList10[] = {uiDummy};
const fptr *const fnListX[] = {fnList0, fnList1, fnList2, fnList3, fnList4, fnList5, fnList6, fnList7, fnList8, fnList9, fnList10};
const u8 menuXItems[] = {ARRSIZE(fnList0), ARRSIZE(fnList1), ARRSIZE(fnList2), ARRSIZE(fnList3), ARRSIZE(fnList4), ARRSIZE(fnList5), ARRSIZE(fnList6), ARRSIZE(fnList7), ARRSIZE(fnList8), ARRSIZE(fnList9), ARRSIZE(fnList10)};
const fptr drawUIX[] = {uiNullNormal, uiFile, uiOptions, uiAbout, uiController, uiDisplay, uiSettings, uiDebug, uiDipswitches, uiLoadGame, uiDummy};

u8 gGammaValue = 0;

char *const autoTxt[] = {"Off", "On", "With R"};
char *const speedTxt[] = {"Normal", "200%", "Max", "50%"};
char *const brighTxt[] = {"I", "II", "III", "IIII", "IIIII"};
char *const sleepTxt[] = {"5min", "10min", "30min", "Off"};
char *const ctrlTxt[] = {"1P", "2P"};
char *const dispTxt[] = {"Unscaled", "Scaled"};
char *const flickTxt[] = {"No Flicker", "Flicker"};

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
	openMenu();
}

/// This is called when going from emu to ui.
void enterGUI() {
}

/// This is called going from ui to emu.
void exitGUI() {
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

void uiFile() {
	setupMenu();
	drawMenuItem("Load Game");
	drawMenuItem("Load State");
	drawMenuItem("Save State");
	drawMenuItem("Save Settings");
	drawMenuItem("Reset Game");
	if (enableExit) {
		drawMenuItem("Quit Emulator");
	}
}

void uiOptions() {
	setupMenu();
	drawMenuItem("Controller");
	drawMenuItem("Display");
	drawMenuItem("Settings");
	drawMenuItem("Debug");
	drawMenuItem("DipSwitches");
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

	drawMenuText("PunchOutDS " EMUVERSION, 19, 0);
	drawMenuText("ARMZ80     " ARMZ80VERSION, 20, 0);
	drawMenuText("ARM6502    " ARM6502VERSION, 21, 0);
	drawMenuText("N2A03      " N2A03VERSION, 22, 0);
	drawMenuText("VLM5030    " VLM5030VERSION, 23, 0);
}

void uiController() {
	setupSubMenu("Controller Settings");
	drawSubItem("B Autofire:", autoTxt[autoB]);
	drawSubItem("A Autofire:", autoTxt[autoA]);
	drawSubItem("Controller:", ctrlTxt[(joyCfg>>29)&1]);
	drawSubItem("Swap A-B:  ", autoTxt[(joyCfg>>10)&1]);
}

void uiDisplay() {
	setupSubMenu("Display Settings");
	drawSubItem("Display:", dispTxt[gScaling]);
	drawSubItem("Scaling:", flickTxt[gFlicker]);
	drawSubItem("Gamma:", brighTxt[gGammaValue]);
}

void uiSettings() {
	setupSubMenu("Settings");
	drawSubItem("Speed:", speedTxt[(emuSettings>>6)&3]);
	drawSubItem("Autoload State:", autoTxt[(emuSettings>>2)&1]);
	drawSubItem("Autosave Settings:", autoTxt[(emuSettings>>9)&1]);
	drawSubItem("Autosave NVRAM:", autoTxt[(emuSettings>>10)&1]);
	drawSubItem("Autopause Game:", autoTxt[emuSettings&1]);
	drawSubItem("Powersave 2nd Screen:",autoTxt[(emuSettings>>1)&1]);
	drawSubItem("Emulator on Bottom:", autoTxt[(emuSettings>>8)&1]);
	drawSubItem("Autosleep:", sleepTxt[(emuSettings>>4)&3]);
}

void uiDebug() {
	setupSubMenu("Debug");
	drawSubItem("Debug Output:", autoTxt[gDebugSet&1]);
	drawSubItem("Disable Background:", autoTxt[gGfxMask&1]);
	drawSubItem("Disable Sprites:", autoTxt[(gGfxMask>>4)&1]);
	drawSubItem("Step Frame", NULL);
}

void uiDipswitches() {
	setupSubMenu("Dipswitch Settings");
	drawSubItem("Coin A:", coinTxt[gDipSwitch0 & 0xF]);
	drawSubItem("Difficulty:", diffTxt[gDipSwitch1 & 3]);
	drawSubItem("Time:", timeTxt[(gDipSwitch1>>2) & 3]);
	drawSubItem("Demo Sound:", autoTxt[(gDipSwitch1>>4) & 1]);
	drawSubItem("Discount:", autoTxt[(gDipSwitch1>>5) & 1]);
	drawSubItem("Service Mode:", autoTxt[(gDipSwitch1>>7) & 1]);
	drawSubItem("Copyright:", ninTxt[(gDipSwitch0>>7) & 1]);
}

void uiLoadGame() {
	setupSubMenu("Load Game");
	int i;
	for (i=0; i<ARRSIZE(punchoutGames); i++) {
		drawSubItem(punchoutGames[i].fullName, NULL);
	}
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

/// Swap A & B buttons
void swapABSet() {
	joyCfg ^= 0x400;
}

/// Turn on/off scaling
void scalingSet(){
	gScaling ^= 0x01;
	refreshGfx();
}

/// Change gamma (brightness)
void gammaSet() {
	gGammaValue++;
	if (gGammaValue > 4) gGammaValue=0;
	paletteInit(gGammaValue);
	paletteTxAll();					// Make new palette visible
	setupMenuPalette();
}

/// Turn on/off rendering of background
void bgrLayerSet(){
	gGfxMask ^= 0x03;
}
/// Turn on/off rendering of sprites
void sprLayerSet(){
	gGfxMask ^= 0x10;
}


/// Number of coins for credits
void coinASet() {
	int i = (gDipSwitch0+1) & 0xF;
	gDipSwitch0 = (gDipSwitch0 & ~0xF) | i;
}
/// Number of coins for credits
void coinBSet() {
	int i = (gDipSwitch0+0x10) & 0xF0;
	gDipSwitch0 = (gDipSwitch0 & ~0xF0) | i;
}
/// Game difficulty
void difficultSet() {
	int i = (gDipSwitch1+0x01) & 0x03;
	gDipSwitch1 = (gDipSwitch1 & ~0x03) | i;
}
void timeSet() {
	int i = (gDipSwitch1+0x04) & 0x0C;
	gDipSwitch1 = (gDipSwitch1 & ~0x0C) | i;
}
void discountSet() {
	gDipSwitch1 ^= 0x20;
}
/// Demo sound on/off
void demoSet() {
	gDipSwitch1 ^= 0x10;
}
void copyrightSet() {
	gDipSwitch0 ^= 0x80;
}
void serviceSet() {
	gDipSwitch1 ^= 0x80;
}
