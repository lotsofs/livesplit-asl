// https://github.com/lotsofs/livesplit-asl/blob/master/AoE2DE.asl

// Generate pointermap
// Pointerscan for this address
// Use saved pointermap

// victory:
// 0 = gameplay
// 4 = resigned
// 6 = victory
// 7 = defeated
// 9 = loading a save from pause menu

// If non-supported version, defaults to the top one in these states. So put these in order newest -> oldest.

state("AoE2DE_s", "90260") {
	int gameTimer : "AoE2DE_s.exe", 0x3D3D7E4; 			// "AoE2DE_s.exe"+03D3D7E4
	int victory : 	"AoE2DE_s.exe", 0x03DB0D88, 0x5E8;	// "AoE2DE_s.exe"+03DB0D88 +5E8
}

state("AoE2DE_s", "87863") {
	int gameTimer : "AoE2DE_s.exe", 0x03DDB5C0, 0x20;	// "AoE2DE_s.exe"+03DDB5C0 +20
	int victory : 	"AoE2DE_s.exe", 0x03DAFD78, 0x5E8;	// "AoE2DE_s.exe"+03DAFD78 +5E8
}

state("AoE2DE_s", "85614") {
	int gameTimer : "AoE2DE_s.exe", 0x3D5CEC4;			// AoE2DE_s.exe+3D5CEC4
	int victory :	"AoE2DE_s.exe", 0x3DD07D8, 0x5E8; 	// AoE2DE_s.exe+3DD07D8 +5E8
}

init {
	version = modules.First().FileVersionInfo.FileVersion;
	
	switch (version) {
		case "101.102.24724.0":
			version = "90260";	// July 26 2023 (Star Age Event)
			break;
		case "101.102.22327.0":
			version = "87863";	// June 28 Update (Minecraft Legends Event)
			break;
		case "101.102.20078.0":
			version = "85614";	// Return of Rome hotfix
			break;
		default:
			version = "Unsupported (" + version + "). Contact LotsOfS.";
			break;
	}	
}

startup {
	vars.totalGameTime = 0;
	vars.lostGameTime = 0;
	vars.lastSplitSplut = false;
	vars.nextMapStarting = false;
	
	settings.Add("splitOnMapStartAfterWin", false, "Split on next map start");
	settings.SetToolTip("splitOnMapStartAfterWin", "Split when the next map begins. Only triggers if the previous map was a victory. \nUseful for quarantaining realtime spent in menus to a separate split.");
	
	settings.Add("splitOnMapWin", true, "Split on map win");
	
	settings.Add("addLostTimeToLast", false, "Include Split for Lost Game Time at End");
	settings.SetToolTip("addLostTimeToLast", "With this enabled, when reaching the last split, all the game time lost due to restarting a level or reloading a save is added to the last split's game time and then it splits (finishing the run). \nThis is useful so that the gametime can still be read off an individual level's split to monitor for IL PBs without being padded out by lost time to resets.\nIf disabled, lost time is simply added to the respective level's split instead.");
}

split {
	if (vars.nextMapStarting == true && old.gameTimer == 0 && current.gameTimer > 0) {
		vars.nextMapStarting = false;
		if (settings["splitOnMapStartAfterWin"]) {
			return true;
		}
	}
	if (settings["splitOnMapWin"]) {
		if (old.victory == 0 && current.victory == 6) {
			return true;
		}
	}
	if (settings["addLostTimeToLast"] && !vars.lastSplitSplut) {
		if (current.victory == 6 && timer.CurrentSplitIndex == timer.Run.Count - 1) {
			vars.lastSplitSplut = true;
			return true;
		}
	}
}

start {
	if (old.gameTimer == 0 && current.gameTimer > 0) {
		return true;
	}
}

onReset {
	// timer stopped. reset values
	if (timer.CurrentPhase == TimerPhase.NotRunning) {
		vars.totalGameTime = 0;
		vars.lostGameTime = 0;
		vars.lastSplitSplut = false;
		vars.nextMapStarting = false;
	}
}

update {
	// Mark this thing as not loading anymore in case it hasn't been done so by split() already
	if (vars.nextMapStarting == true && current.gameTimer > 3000) {
		vars.nextMapStarting = false;
	}
	// The map finished loading, but hasn't started yet.
	if (old.victory != 0 && current.victory == 0) {
		vars.nextMapStarting = true;
	}
	// We undid the lost time dump split and its previous one. Mark the last split as autosplittable again.
	if (vars.lastSplitSplut && timer.CurrentPhase != TimerPhase.NotRunning && settings["addLostTimeToLast"] && timer.CurrentSplitIndex < timer.Run.Count - 1) {
		vars.lastSplitSplut = false;
	}
}

isLoading {
	// always return true since we're going 100% off ingame time anyway and we're not tracking actual loading times
	// avoid the centisecond count from jumping and resetting constantly
	return true;
}

gameTime {
	// victory:
	// 0 = gameplay
	// 4 = resigned
	// 6 = victory
	// 7 = defeated
	// 9 = loading a save from pause menu

	// perform calculations

	// We just won. Dump the game time to a var for cumulative game time
	if (old.victory == 0 && current.victory == 6) {
		vars.totalGameTime += current.gameTimer;
	}
	// If gamestate is 4 (resigned) or 7 (defeated) or 9 (loading a save), dump the current gametime to a var.
	// If the setting is enabled, dumpp it to a 'lost time' variable to be added back at the end. (Useful for comparing IL times)
	// Otherwise, just keep counting it for the total.
	else if (old.victory == 0 && (current.victory == 4 || current.victory == 7 || current.victory == 9)) {
		if (settings["addLostTimeToLast"]) {
			vars.lostGameTime += current.gameTimer;
		}
		else {
			vars.totalGameTime += current.gameTimer;
		}
	}
	// When loading a save, remove restored game time from the time lost marked above, since it was not actually lost. 
	else if (current.gameTimer < old.gameTimer && current.gameTimer > 1000) {
		if (settings["addLostTimeToLast"]) {
			vars.lostGameTime -= current.gameTimer;
		}
		else {
			vars.totalGameTime -= current.gameTimer;
		}
	}


	// return stuff

	// If we're on the last split and the setting for quarantaining lost time is enabled, add it back now
	if (settings["addLostTimeToLast"] && current.victory == 6 && timer.CurrentSplitIndex == timer.Run.Count - 1) {
		return TimeSpan.FromMilliseconds(vars.totalGameTime + vars.lostGameTime);
	}
	// loading finished, but map hasn't started yet (eg. waiting for coop partner)
	if (vars.nextMapStarting == true) {
		return TimeSpan.FromMilliseconds(vars.totalGameTime);
	}
	// a map just ended (fail/win) and the timer in game is now not running
	if (current.victory != 0) {
		return TimeSpan.FromMilliseconds(vars.totalGameTime);
	}
	// We're ingame.
	return TimeSpan.FromMilliseconds(vars.totalGameTime + current.gameTimer);
}
