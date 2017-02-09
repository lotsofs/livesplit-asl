state("Sam2") {
	int version2080 : "Core.dll", 0xB6C68;
	int version2070 : "Core.dll", 0xB5C68;
}	

state("Sam2", "252822") {
	bool isLoading : "Core.dll", 0xBF120;
}

state("Sam2", "269486") {
	bool isLoading : "Core.dll", 0xBF120;
}

state("Sam2", "65824") {
	bool isLoading : "Core.dll", 0xBE120;
}



init {
	if (current.version2080 == 252822) {
		version = "252822";
	}
	if (current.version2080 == 269486) {
		version = "269486";
	}
	if (current.version2070 == 65824) {
		version = "65824";
	}
}


isLoading {
		return current.isLoading;
}

