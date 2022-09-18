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

#define EMUVERSION "V0.4.1 2022-09-18"

const fptr fnMain[] = {nullUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI};

const fptr fnList0[] = {uiDummy};
const fptr fnList1[] = {ui8, loadState, saveState, saveSettings, resetGame};
const fptr fnList2[] = {ui4, ui5, ui6, ui7};
const fptr fnList3[] = {uiDummy};
const fptr fnList4[] = {autoBSet, autoASet, controllerSet, swapABSet};
const fptr fnList5[] = {scalingSet, flickSet, gammaSet, bgrLayerSet, sprLayerSet};
const fptr fnList6[] = {speedSet, autoStateSet, autoSettingsSet, autoNVRAMSet, autoPauseGameSet, powerSaveSet, screenSwapSet, debugTextSet, sleepSet};
const fptr fnList7[] = {coinASet, difficultSet, timeSet, demoSet, discountSet, serviceSet, copyrightSet};
const fptr fnList8[] = {quickSelectGame, quickSelectGame, quickSelectGame, quickSelectGame, quickSelectGame, quickSelectGame, quickSelectGame, quickSelectGame};
const fptr fnList9[] = {uiDummy};
const fptr *const fnListX[] = {fnList0, fnList1, fnList2, fnList3, fnList4, fnList5, fnList6, fnList7, fnList8, fnList9};
const u8 menuXItems[] = {ARRSIZE(fnList0), ARRSIZE(fnList1), ARRSIZE(fnList2), ARRSIZE(fnList3), ARRSIZE(fnList4), ARRSIZE(fnList5), ARRSIZE(fnList6), ARRSIZE(fnList7), ARRSIZE(fnList8), ARRSIZE(fnList9)};
const fptr drawUIX[] = {uiNullNormal, uiFile, uiOptions, uiAbout, uiController, uiDisplay, uiSettings, uiDipswitches, uiLoadGame, uiDummy};
const u8 menuXBack[] = {0,0,0,0,2,2,2,2,1,8};

u8 gGammaValue = 0;

char *const autoTxt[] = {"Off","On","With R"};
char *const speedTxt[] = {"Normal","200%","Max","50%"};
char *const sleepTxt[] = {"5min","10min","30min","Off"};
char *const brighTxt[] = {"I","II","III","IIII","IIIII"};
char *const ctrlTxt[] = {"1P","2P"};
char *const dispTxt[] = {"Unscaled","Scaled"};
char *const flickTxt[] = {"No Flicker","Flicker"};

char *const coinTxt[] = {
	"1 Coin 1 Credit","2 Coin 1 Credits","1 Coin 2 Credits","1 Coin 1 Credit",
	"1 Coin 2 Credits","1 Coin 3 Credits","1 Coin 4 Credits","1 Coin 6 Credits",
	"1 Coin 2 Credits (2)","1 Coin 2 Credits","1 Coin 5 Credits","4 Coins 1 Credit",
	"3 Coins 1 Credit","1 Coin 3 Credits (2)","5 Coins 1 Credit","Free Play"};
char *const diffTxt[] = {"Easy","Medium","Hard","Hardest"};
char *const timeTxt[] = {"Longest","Long","Short","Shortest"};
char *const ninTxt[] = {"Nintendo","Nintendo of America"};


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
		setSelectedMenu(9);
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
	drawMenuItem("DipSwitches");
}

void uiAbout() {
	cls(1);
	drawTabs();
	drawText(" Select:    Insert coin",4,0);
	drawText(" Start:     Service coin",5,0);
	drawText(" Left/Rigt: Dodge",6,0);
	drawText(" Up/Down:   Hand positions",7,0);
	drawText(" Y:         Left punch",8,0);
	drawText(" X:         Right punch",9,0);
	drawText(" A:         Super punch",10,0);
	drawText(" B:         Duck (Joystick up)",11,0);

	drawText(" PunchOutDS " EMUVERSION, 19, 0);
	drawText(" ARMZ80     " ARMZ80VERSION, 20, 0);
	drawText(" ARM6502    " ARM6502VERSION, 21, 0);
	drawText(" N2A03      " N2A03VERSION, 22, 0);
	drawText(" VLM5030    " VLM5030VERSION, 23, 0);
}

void uiController() {
	setupSubMenu(" Controller Settings");
	drawSubItem("B Autofire: ", autoTxt[autoB]);
	drawSubItem("A Autofire: ", autoTxt[autoA]);
	drawSubItem("Controller: ", ctrlTxt[(joyCfg>>29)&1]);
	drawSubItem("Swap A-B:   ", autoTxt[(joyCfg>>10)&1]);
}

void uiDisplay() {
	setupSubMenu(" Display Settings");
	drawSubItem("Display: ", dispTxt[gScaling]);
	drawSubItem("Scaling: ", flickTxt[gFlicker]);
	drawSubItem("Gamma: ", brighTxt[gGammaValue]);
	drawSubItem("Disable Background: ", autoTxt[gGfxMask&1]);
	drawSubItem("Disable Sprites: ", autoTxt[(gGfxMask>>4)&1]);
}

void uiSettings() {
	setupSubMenu(" Settings");
	drawSubItem("Speed: ", speedTxt[(emuSettings>>6)&3]);
	drawSubItem("Autoload State: ", autoTxt[(emuSettings>>2)&1]);
	drawSubItem("Autosave Settings: ", autoTxt[(emuSettings>>9)&1]);
	drawSubItem("Autosave NVRAM: ", autoTxt[(emuSettings>>10)&1]);
	drawSubItem("Autopause Game: ", autoTxt[emuSettings&1]);
	drawSubItem("Powersave 2nd Screen: ",autoTxt[(emuSettings>>1)&1]);
	drawSubItem("Emulator on Bottom: ", autoTxt[(emuSettings>>8)&1]);
	drawSubItem("Debug Output: ", autoTxt[gDebugSet&1]);
	drawSubItem("Autosleep: ", sleepTxt[(emuSettings>>4)&3]);
}

void uiDipswitches() {
	setupSubMenu(" Dipswitch Settings");
	drawSubItem("Coin A: ", coinTxt[g_dipSwitch0 & 0xF]);
	drawSubItem("Difficulty: ", diffTxt[g_dipSwitch1 & 3]);
	drawSubItem("Time: ", timeTxt[(g_dipSwitch1>>2) & 3]);
	drawSubItem("Demo Sound: ", autoTxt[(g_dipSwitch1>>4) & 1]);
	drawSubItem("Discount: ", autoTxt[(g_dipSwitch1>>5) & 1]);
	drawSubItem("Service Mode: ", autoTxt[(g_dipSwitch1>>7) & 1]);
	drawSubItem("Copyright: ", ninTxt[(g_dipSwitch0>>7) & 1]);
}

void uiLoadGame() {
	setupSubMenu(" Load game");
	drawMenuItem(" Punch-Out!! (Rev B)");
	drawMenuItem(" Punch-Out!! (Rev A)");
	drawMenuItem(" Punch-Out!! (Japan)");
	drawMenuItem(" Punch-Out!! (Italian bootleg)");
	drawMenuItem(" Super Punch-Out!! (Rev B)");
	drawMenuItem(" Super Punch-Out!! (Rev A)");
	drawMenuItem(" Super Punch-Out!! (Japan)");
	drawMenuItem(" Arm Wrestling");
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
	int i = (g_dipSwitch0+1) & 0xF;
	g_dipSwitch0 = (g_dipSwitch0 & ~0xF) | i;
}
/// Number of coins for credits
void coinBSet() {
	int i = (g_dipSwitch0+0x10) & 0xF0;
	g_dipSwitch0 = (g_dipSwitch0 & ~0xF0) | i;
}
/// Game difficulty
void difficultSet() {
	int i = (g_dipSwitch1+0x01) & 0x03;
	g_dipSwitch1 = (g_dipSwitch1 & ~0x03) | i;
}
void timeSet() {
	int i = (g_dipSwitch1+0x04) & 0x0C;
	g_dipSwitch1 = (g_dipSwitch1 & ~0x0C) | i;
}
void discountSet() {
	g_dipSwitch1 ^= 0x20;
}
/// Demo sound on/off
void demoSet() {
	g_dipSwitch1 ^= 0x10;
}
void copyrightSet() {
	g_dipSwitch0 ^= 0x80;
}
void serviceSet() {
	g_dipSwitch1 ^= 0x80;
}
