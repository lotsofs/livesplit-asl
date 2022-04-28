/// Simple script 
state("AoE2DE_s") {
	int version59165 : "AoE2DE_s.exe", 0xE08D94;
	int version61321 : "AoE2DE_s.exe", 0x3ACFF58;
}

state("AoE2DE_s", "59165") {
	int gameTimer : "AoE2DE_s.exe", 0x3C2FB7C;
	int victory : "AoE2DE_s.exe", 0x3CAA318;
}

state("AoE2DE_s", "61321") {
	int gameTimer : "AoE2DE_s.exe", 0x39F54AC;
	int victory : "AoE2DE_s.exe", 0x3A67A78;
}

init {
	if (false) { }
	else if (current.version59165 == 59165) { version = "59165"; }
	else if (current.version61321 == 61321) { version = "61321"; }
	else { 
		throw new Exception("Either the game is still booting, or this is a different game. Sort it out yourself."); 
	}
}

startup {
	vars.totalGameTime = 0;
}

update {
	if (timer.CurrentPhase == TimerPhase.NotRunning) {
		vars.totalGameTime = 0;
	}
}

isLoading {
	if (current.victory != 0) {
		return true;
	}
	else {
		return false;
	}
}

gameTime {
	if (old.victory == 0 && current.victory == 6) {
		vars.totalGameTime += current.gameTimer;
		return TimeSpan.FromMilliseconds(vars.totalGameTime);
	}
	else if (current.victory == 6) {
		return TimeSpan.FromMilliseconds(vars.totalGameTime);
	}
	else {
		return TimeSpan.FromMilliseconds(vars.totalGameTime + current.gameTimer);
	}
}
