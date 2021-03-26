state("Sam2") {
	int version2080 : "Core.dll", 0xB6C68;
	int version2070 : "Core.dll", 0xB5C68;
}	

state("Sam2", "591918") {
	bool isLoading : "Core.dll", 0xBF120;
	int chapter : "Sam2Game.dll", 0x3F15C8;		// 2.090
}

state("Sam2", "252822") {
	bool isLoading : "Core.dll", 0xBF120;
	int chapter : "Sam2Game.dll", 0x3C31FC;		// untested, unused game version
}

state("Sam2", "269486") {
	bool isLoading : "Core.dll", 0xBF120;
	int chapter : "Sam2Game.dll", 0x3C31FC;
}

state("Sam2", "65824") {
	bool isLoading : "Core.dll", 0xBE120;
	int chapter : "Sam2Game.dll", 0x3C31FC;		// needs finding, dont have this game version anymore
}


init {
	if (current.version2080 == 591918) {
		version = "591918";
	}
	if (current.version2080 == 252822) {
		version = "252822";
	}
	if (current.version2080 == 269486) {
		version = "269486";
	}
	if (current.version2070 == 65824) {
		version = "65824";
	}
	else {
		if (current.version2080 == 0) {
			throw new Exception("game process not fully initialized yet");
		}
		else if (current.version2070 == 0) {
			throw new Exception("game process not fully initialized yet");
		}
	}
}

exit {
	vars.chapter = 0;
}

isLoading {
	return current.isLoading;
}

split {
	if (current.chapter > vars.chapter) {
		vars.chapter = vars.chapter + 1;
		return true;
	}
}

start {
	vars.chapter = current.chapter;
	return current.chapter != old.chapter;
}
