state("AoE2DE_s", "85614") {
	int gameTimer : "AoE2DE_s.exe", 0x3D5CEC4;			// AoE2DE_s.exe+3D5CEC4
	int victory :	"AoE2DE_s.exe", 0x3DD07D8, 0x5E8; 	// AoE2DE_s.exe+3DD07D8 +5E8
}

init {
	version = modules.First().FileVersionInfo.FileVersion;
	
	switch (version) {
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
	settings.SetToolTip("splitOnMapStartAfterWin", "Split when the next map begins. Only triggers if the previous map was a victory.");
	
	settings.Add("splitOnMapWin", true, "Split on map win");
	
	settings.Add("addLostTimeToLast", false, "Include Split for Lost Game Time at End");
	settings.SetToolTip("addLostTimeToLast", "With this enabled, when reaching the last split, all the game time lost due to resets is added to the last split's game time and then it splits (finishing the run). This keeps the main splits' functionality for reading IL times. If disabled, this lost time is not counted at all.");
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

update {
	if (vars.nextMapStarting == true && current.gameTimer > 5000) {
		// just something to mark this thing as not loading anymore in case it hasn't been done so by split() already
		vars.nextMapStarting = false;
	}
	if (old.victory == 6 && current.victory == 0) {
		// map finished loading, but hasn't started yet.
		vars.nextMapStarting = true;
	}
	
	if (timer.CurrentPhase == TimerPhase.NotRunning) {
		// timer stopped. reset values
		vars.totalGameTime = 0;
		vars.lostGameTime = 0;
		vars.lastSplitSplut = false;
		vars.nextMapStarting = false;
	}
	if (vars.lastSplitSplut && timer.CurrentSplitIndex < timer.Run.Count - 1) {
		// we undid the last two splits. Mark the last split as autosplittable again.
		vars.lastSplitSplut = false;
	}
}

isLoading {
	if (current.victory != 0 || vars.nextMapStarting == true) {
		return true;
	}
	else {
		return false;
	}
}

gameTime {
	// perform calculations
	if (old.victory == 0 && current.victory == 6) {
		// we just won. Dump the game time to a var so we can have cumulative game time.
		vars.totalGameTime += current.gameTimer;
	}
	else if (old.victory == 0 && (current.victory == 4 || current.victory == 7 || current.victory == 9)) {
		// If gamestate is 4 (resigned) or 7 (defeated) or 9 (loading a save), dump the current gametime to a 'lost time' variable
		vars.lostGameTime += current.gameTimer;
	}
	else if (current.gameTimer < old.gameTimer && current.gameTimer > 1000) {
		// When loading a save, remove restored game time from the time lost marked above, since it was not actually lost. 
		vars.lostGameTime -= current.gameTimer;
	}

	// return stuff
	if (current.victory == 6 && settings["addLostTimeToLast"] && timer.CurrentSplitIndex == timer.Run.Count - 1) {
		// we won the last map and the setting is enabled
		return TimeSpan.FromMilliseconds(vars.totalGameTime + vars.lostGameTime);
	}
	else if (vars.nextMapStarting == true) {
		// loading finished, but map hasn't started yet (eg. waiting for coop partner)
		return TimeSpan.FromMilliseconds(vars.totalGameTime);
	}
	else if (current.victory == 6) {
		// we won a map
		return TimeSpan.FromMilliseconds(vars.totalGameTime);
	}
	else {
		// ingame
		return TimeSpan.FromMilliseconds(vars.totalGameTime + current.gameTimer);
	}
}
