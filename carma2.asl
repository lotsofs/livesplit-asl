state("CARMA2_HW") {
	int pedsKilled : "CARMA2_HW.EXE", 0x3447CC
	// total peds = CARMA2_HW.EXE+3447D4
}

startup {
	vars.pedsKilled = 0;
}

update {
	if (timer.CurrentPhase == TimerPhase.NotRunning) {
		vars.pedsKilled = 0;
	}
}

split {
	if (current.pedsKilled > vars.pedsKilled) {
		vars.pedsKilled = vars.pedsKilled + 1;
		return true;
	}		
}
