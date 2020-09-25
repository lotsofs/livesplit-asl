/// Special thanks to Pitpo for helping me test the in-game timer: It's bad, do not use. 
/// Only works with some V1.00 No CD for now. V1.03 only works for load removal for now. 
/// Legit V1.00 will never work because there is no way of getting past that DRM anymore, to my knowledge. 
/// If you want me to add support for V1.01 V1.02 or whatever contact me twitch.tv/lotsofs

state("FarCry2") {
	int version103Steam : "Dunia.dll", 0xF940F0;
	int version103Gog : "Dunia.dll", 0xEED0F0;
	int version100 : "Dunia.dll", 0xEE3078;
}

state("FarCry2", "v1.03Steam") {
	bool isLoading : "Dunia.dll", 0x1645C4C;
}

state ("FarCry2", "v1.03Gog") {
		bool isLoading : "Dunia.dll", 0x159502C;
}

state("FarCry2", "v1.00") {
	bool isLoading : "Dunia.dll", 0x15833AC;		// Includes tiny loading screen before main loading screen when pressing continue in the main menu
	//bool isLoading : 0x11589954;		// Full screen loading screens only
	
	int isFinished : "Dunia.dll", 0x158660C, 0x84, 0x10;	// Outro cutscene where Reuben Oluwagembi takes pictures
	
	// I don't trust these next addresses
	byte missionsPassed : "Dunia.dll", 0x015824E4, 0x98, 0x8, 0xa4, 0x178;   // Missions passed excluding Buddy rescues
	int playerControl : "Dunia.dll", 0x0171D218, 0x250;		// Seems to be tied to when the player isn't locked in place (and can walk around). Set to 2 when looking up.
	int sessionTime : "Dunia.dll", 0x015A4774, 0x4, 0xc, 0x0, 0x50;    // Accurate enough to not start the timer 2 minutes early.
	
	// Unused
	//int isQuickSaving : "FarCry2.exe", 0x115453FC, 0x394; // Not working for some reason, whatever, just don't spam quicksave.
}

startup {
	settings.Add("simulatedIGT", true, "Simulate IGT");
	settings.SetToolTip("simulatedIGT", "Loadless timer will behave like the existing in-game timer, but more accurate. (This adds the intro cutscene time to the timer (477000 ms))");
	
	settings.Add("mainMissions", true, "Splits to split (unsupported for v1.03)");
	 settings.Add("act1", true, "Act 1", "mainMissions");
	  settings.Add("mission1", true, "Escape the town", "act1");
	  settings.Add("mission2", true, "Free the captive", "act1");
  	  settings.Add("mission3", true, "Exit the church (Tutorial)", "act1");
	  settings.Add("mission4", true, "Random order mission 1", "act1");
	  settings.Add("mission5", true, "Random order mission 2", "act1");
	  settings.Add("mission6", true, "Random order mission 3", "act1");
	  settings.Add("mission7", true, "Random order mission 4", "act1");
	  settings.Add("mission8", true, "Random order mission 5", "act1");
	  settings.Add("mission9", true, "Random order mission 6", "act1");
	  settings.SetToolTip("mission4", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.SetToolTip("mission5", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.SetToolTip("mission6", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.SetToolTip("mission7", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.SetToolTip("mission8", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.SetToolTip("mission9", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.Add("mission10", true, "Escape the Goka Falls Lodge", "act1");
	  settings.Add("mission11", true, "Defend Mike's place/the church", "act1");
	  settings.Add("mission12", true, "Get to shelter", "act1");
	  settings.Add("mission13", true, "Terminate faction leader", "act1");
	 settings.Add("act2", true, "Act 2", "mainMissions");
	  settings.Add("mission14", true, "Defend the barge", "act2");
	  settings.Add("mission15", true, "Go talk to stranded barge captain", "act2");
	  settings.Add("mission16", true, "Random order mission 7", "act2");
	  settings.Add("mission17", true, "Random order mission 8", "act2");
	  settings.Add("mission18", true, "Random order mission 9", "act2");
	  settings.Add("mission19", true, "Random order mission 10", "act2");
	  settings.Add("mission20", true, "Random order mission 11", "act2");
	  settings.Add("mission21", true, "Random order mission 12", "act2");
	  settings.SetToolTip("mission20", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.SetToolTip("mission21", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.SetToolTip("mission16", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.SetToolTip("mission17", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.SetToolTip("mission18", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.SetToolTip("mission19", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.Add("mission22", true, "Collect the diamonds", "act2");
	  settings.Add("mission23", true, "Escape the prison", "act2");
	  settings.Add("mission24", true, "Random order mission 13", "act2");
	 settings.Add("act3", true, "Act 3", "mainMissions");
	  settings.Add("mission25", true, "Random order mission 14", "act3");
	  settings.Add("mission26", true, "Random order mission 15", "act3");
	  settings.SetToolTip("mission24", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.SetToolTip("mission25", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.SetToolTip("mission26", "The order of these missions isn't fixed and is determined by a variety of factors");
	  settings.Add("mission27", true, "Go to the prison to meet the Jackal", "act3");
	  settings.Add("missionFinal", true, "Detonate the dynamite/Give the briefcase", "act3");
}

init {
	if (current.version103Steam == 18516) {
		version = "v1.03Steam";   
	}
	else if (current.version103Gog == 18516) {
		version = "v1.03Gog";   
	}
	else if (current.version100 == 18516) {
		version = "v1.00";
	}
	else {
		if (current.version103 == 0) {
			throw new Exception("game process not fully initialized yet");
		}
		else {
			version = "unrecognized";
		}
	}
}

start {
	if (version == "v1.03") { 
		return false;
	}

	vars.introGameTimeAdded = 0;
	if (current.playerControl != 0 && current.missionsPassed == 0 && !current.isLoading && current.sessionTime > 4000 ) {
		return true;
	}
}

split {
	if (version == "v1.03") { 
		return false;
	}

	if (current.isFinished == 1 && current.isFinished != old.isFinished && !current.isLoading && current.missionsPassed > 26){
		if (settings["missionFinal"]) {
			return true;
		}
	}
	// Main Missions 1-27/29
	if (current.missionsPassed > old.missionsPassed && current.missionsPassed < 34  && !current.isLoading) {
		if (settings["mission"+current.missionsPassed]) {
			//vars.introGameTimeAdded = 0;
			return true;
		}
	}

}

isLoading {
	return current.isLoading;
}

gameTime {
	if (vars.introGameTimeAdded == 0) {
		vars.introGameTimeAdded = 1; 
		// add GimeTime from the intro cutscene
		if (settings["simulatedIGT"]) {
			return TimeSpan.FromMilliseconds(477000);
		}
		else {
			return 0;
		}
	}
}

