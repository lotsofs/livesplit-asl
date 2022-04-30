/// Simple script 
state("AoE2DE_s") {
	int version59165 : "AoE2DE_s.exe", 0xE08D94;	// AoE2DE_s.exe+E08D94
	int version61321 : "AoE2DE_s.exe", 0x3ACFF58;	// AoE2DE_s.exe+3ACFF58
}

state("AoE2DE_s", "59165") {
	int gameTimer : "AoE2DE_s.exe", 0x3C2FB7C; // AoE2DE_s.exe+3C2FB7C
	int victory : "AoE2DE_s.exe", 0x3CAA318; // AoE2DE_s.exe+3CAA318
}

state("AoE2DE_s", "61321") {
	int gameTimer : "AoE2DE_s.exe", 0x39F54AC; // AoE2DE_s.exe+39F54AC
	int victory : "AoE2DE_s.exe", 0x3A67A78; // AoE2DE_s.exe+3ACFF58
}

init {
	if (false) { }
	else if (current.version59165 == 59165) { version = "59165"; }	// February '22
	else if (current.version61321 == 61321) { version = "61321"; }	// April '22 (Dynasties of India Update)
	else if (current.version61321 == 61591) { version = "61321"; }	// 	Hotfix (April '22)
	else { 
		throw new Exception("Either the game is still booting, or this is a different game. Sort it out yourself."); 
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
	if (settings["splitOnMapStartAfterWin"] && old.gameTimer == 0 && current.gameTimer > 0) {
		vars.nextMapStarting = false;
		return true;
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
	if (vars.nextMapStarting == true && current.gameTimer > 200) {
		vars.nextMapStarting = false;
	}
	if (old.victory == 6 && current.victory == 0) {
		vars.nextMapStarting = true;
	}
	
	if (timer.CurrentPhase == TimerPhase.NotRunning) {
		vars.totalGameTime = 0;
		vars.lostGameTime = 0;
	}
	if (vars.lastSplitSplut && timer.CurrentSplitIndex < timer.Run.Count - 1) {
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
		return TimeSpan.FromMilliseconds(vars.totalGameTime + vars.lostGameTime);
	}
	else if (vars.nextMapStarting == true) {
		return TimeSpan.FromMilliseconds(vars.totalGameTime);
	}
	else if (current.victory == 6) {
		return TimeSpan.FromMilliseconds(vars.totalGameTime);
	}
	else {
		return TimeSpan.FromMilliseconds(vars.totalGameTime + current.gameTimer);
	}
}
