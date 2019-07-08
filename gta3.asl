/// Made this for myself. If it doesn't work for you, tough luck :D

state("gta3")
{
	//int baseVariable : 0x35B388;	// Base of all variables
	
	//int base : "gta3.exe", 0x35B388 ;					// base
	int defaultWaitTime : "gta3.exe", 0x35B39C ;		// 5: always 250 except for fresh game boot (and 1 frame after loading?)
	
	int introMovieSkipped : "gta3.exe", 0x35C4E8;		// 1112: 0 = movie hasnt started, 1 = movie has started, 2 = skip button pressed
	
	int luigiDoorCutscene : "gta3.exe", 0x35B60C; 		//161: cutscene backdoor, used in other luigi missions starting cutscenes
	int joeyCutsceneActor : "gta3.exe", 0x35B5F0;		//154: joey's cutscene model
	
	int libertyCutsceneEnded : "gta3.exe", 0x35BA20; 	// 422
	int libertyCarEntered : "gta3.exe", 0x35CC14;		// 1571: actually one of the cop cars driving up, becomes non-zero when it spawns, which is when the car is entered
	int liberty8BallInHouse : "gta3.exe", 0x35CBA8;		// 1544
	int libertyPlayerInHouse : "gta3.exe", 0x35CBA4;	// 1543
	int libertyMistySpawned : "gta3.exe", 0x35CBD8;		// 1556: actually checks if player is in a car to pick up misty, but gets set to 1 first time when misty spawns
	int libertyMistySaidHi : "gta3.exe", 0x35CBCC;		// 1553
	int libertyMissionPassed : "gta3.exe", 0x35B75C;	// 245
	
	int dontSpankBatSpawn : "gta3.exe", 0x35CCA0;	// 1606
	int dontSpankBatPickupRemoved : "gta3.exe", 0x35CCB0;		// 1610
	int dontSpankCarEntered : "gta3.exe", 0x35CCCC;		// 1617
	int dontSpankPayNSprayUsed : "gta3.exe", 0x35CCBC;	// 1613
	int dontSpankMissionPassed : "gta3.exe", 0x35B76C; 	// 249
	
	int driveMistyCarEntered : "gta3.exe", 0x35CCD0;	// 1618
	int driveMistyMarkerEntered : "gta3.exe", 0x35CCD8;	// 1620
	int driveMistyMistyEnteredCar : "gta3.exe", 0x35CCD4;	// 1619
	int driveMistyMissionPassed : "gta3.exe", 0x35B770;	// 250
	
	
	//bool isLoading : "Dunia.dll", 0x15833AC;		// Includes tiny loading screen before main loading screen when pressing continue in the main menu
	//bool isLoading : 0x11589954;		// Full screen loading screens only
	//int isFinished : "Dunia.dll", 0x158660C, 0x84, 0x10;	// Outro cutscene where Reuben Oluwagembi takes pictures
		// I don't trust these next addresses
	//byte missionsPassed : "Dunia.dll", 0x015824E4, 0x98, 0x8, 0xa4, 0x178;   // Missions passed excluding Buddy rescues
	//int playerControl : "Dunia.dll", 0x0171D218, 0x250;		// Seems to be tied to when the player isn't locked in place (and can walk around). Set to 2 when looking up.
	//int sessionTime : "Dunia.dll", 0x015A4774, 0x4, 0xc, 0x0, 0x50;    // Accurate enough to not start the timer 2 minutes early.
	//int isQuickSaving : "FarCry2.exe", 0x115453FC, 0x394; // Not working for some reason, whatever, just don't spam quicksave.
}

startup
{	
	settings.Add("mainMissions", true, "Main missions");
	 settings.Add("introduction", true, "Introduction", "mainMissions");
	  settings.Add("introMovie", true, "Intro Movie", "introduction");
	   settings.Add("introMovieSkipped", true, "Intro Movie Skipped", "introMovie");
	  settings.Add("giveMeLiberty", true, "Give Me Liberty / Luigi's Girl", "introduction");
	   settings.Add("libertyCutsceneEnded", true, "Cutscene Ended", "giveMeLiberty");
	   settings.Add("libertyCarEntered", true, "Entered Kuruma", "giveMeLiberty");
	   settings.Add("libertyPlayerInHouse", true, "Entered Safehouse", "giveMeLiberty");
	   settings.Add("luigiDoorCutscene", true, "Started Luigi's Girls", "giveMeLiberty");
	   settings.Add("libertyMistySpawned", true, "Started Luigi's Girl", "giveMeLiberty");
	   settings.Add("libertyMistySaidHi", true, "Picked up Misty", "giveMeLiberty");
	   settings.Add("libertyMissionPassed", true, "Mission Passed", "giveMeLiberty");
	 settings.Add("luigi", true, "Luigi Missions", "mainMissions");
	  settings.Add("dontSpank", true, "Don't Spank My Bitch Up", "luigi");
	   settings.Add("dontSpankStarted", true, "Started", "dontSpank");
	   settings.Add("dontSpankBatSpawn", true, "Cutscene Skipped", "dontSpank");
	   settings.Add("dontSpankBatPickupRemoved", true, "Bat Picked Up / Dealer Dead", "dontSpank");
	   settings.Add("dontSpankCarEntered", true, "Car Entered", "dontSpank");
	   settings.Add("dontSpankPayNSprayUsed", true, "Pay N Spray Used", "dontSpank");
	   settings.Add("dontSpankMissionPassed", true, "Mission Passed", "dontSpank");
	  settings.Add("driveMisty", true, "Drive Misty For Me", "luigi");
       settings.Add("driveMistyStarted", true, "Started", "driveMisty");	  
       settings.Add("driveMistyCarEntered", true, "Car Entered", "driveMisty");	  
       settings.Add("driveMistyMarkerEntered", true, "Marker at Misty's House Entered", "driveMisty");	  
       settings.Add("driveMistyMistyEnteredCar", true, "Misty Entered Car", "driveMisty");	  
       settings.Add("driveMistyEndCutsceneStarted", true, "Final Cutscene Started", "driveMisty");	  
       settings.Add("driveMistyMissionPassed", true, "Mission Passed", "driveMisty");

}



//init
//{
//	//int moduleSize = modules.First().ModuleMemorySize;
//	//print("test" + moduleSize);			// This gives me the same number regardless of which version I start. Wtf
//}


start
{
	// new game from fresh boot (default wait time 0 > 250, intro movie skip 0 > 0) || new game from reset (default wait time 250 > 250, intro movie skip 2 > 0)
	if ((old.defaultWaitTime == 0 && current.defaultWaitTime == 250) || (old.introMovieSkipped == 2 && current.introMovieSkipped == 0)) {
		vars.introductionProgress = 0;
		vars.luigiProgress = 0;
		return true;
	}
}

	
	
split
{
	if (vars.introductionProgress < 5) {
		if (current.introMovieSkipped == 2 && current.introMovieSkipped != old.introMovieSkipped){
			if (settings["introMovieSkipped"]) {
				return true;
			}
		}
		if (current.libertyCutsceneEnded == 1 && current.libertyCutsceneEnded != old.libertyCutsceneEnded){
			if (settings["libertyCutsceneEnded"]) {
				return true;
			}
		}
		if (current.libertyCarEntered != 0 && current.libertyCarEntered != old.libertyCarEntered && vars.introductionProgress == 0) {
			vars.introductionProgress = 1;
			if (settings["libertyCarEntered"]) {
				return true;
			}
		}
		if (current.libertyPlayerInHouse == 2 && current.libertyPlayerInHouse != old.libertyPlayerInHouse){
			if (settings["libertyPlayerInHouse"]) {
				return true;
			}
		}
		if (current.luigiDoorCutscene != 0 && current.luigiDoorCutscene != old.luigiDoorCutscene && vars.introductionProgress == 1) {
			vars.introductionProgress = 2;
			if (settings["luigiDoorCutscene"]) {
				return true;
			}
		}
		if (current.libertyMistySpawned == 1 && current.libertyMistySpawned != old.libertyMistySpawned && vars.introductionProgress == 2){
			vars.introductionProgress = 3;
			if (settings["libertyMistySpawned"]) {
				return true;
			}
		}
		if (current.libertyMistySaidHi == 1 && current.libertyMistySaidHi != old.libertyMistySaidHi && vars.introductionProgress == 3){
			vars.introductionProgress = 4;
			if (settings["libertyMistySaidHi"]) {
				return true;
			}
		}
		if (current.libertyMissionPassed == 1 && current.libertyMissionPassed != old.libertyMissionPassed){
			vars.introductionProgress = 5;
			if (settings["libertyMissionPassed"]) {
				return true;
			}
		}
	}
	
	if (vars.luigiProgress < 99) {
		if (current.luigiDoorCutscene != old.luigiDoorCutscene && vars.introductionProgress == 5 && vars.luigiProgress == 0) {
			vars.luigiProgress = 1;
			if (settings["dontSpankStarted"]) {
				return true;
			}			
		}
		if (current.dontSpankBatSpawn != 0 && current.dontSpankBatSpawn != old.dontSpankBatSpawn && vars.luigiProgress == 1) {
			vars.luigiProgress = 2;
			if (settings["dontSpankBatSpawn"]) {
				return true;
			}
		}
		if (current.dontSpankBatPickupRemoved == 1 && current.dontSpankBatPickupRemoved != old.dontSpankBatPickupRemoved && vars.luigiProgress == 2) {
			vars.luigiProgress = 3;
			if (settings["dontSpankBatPickupRemoved"]) {
				return true;
			}
		}
		if (current.dontSpankCarEntered == 1 && current.dontSpankCarEntered != old.dontSpankCarEntered && vars.luigiProgress == 3) {
			vars.luigiProgress = 4;
			if (settings["dontSpankCarEntered"]) {
				return true;
			}
		}
		if (current.dontSpankPayNSprayUsed == 1 && current.dontSpankPayNSprayUsed != old.dontSpankPayNSprayUsed && vars.luigiProgress == 4) {
			vars.luigiProgress = 5;
			if (settings["dontSpankPayNSprayUsed"]) {
				return true;
			}
		}
		if (current.dontSpankMissionPassed == 1 && current.dontSpankMissionPassed != old.dontSpankMissionPassed){
			if (settings["dontSpankMissionPassed"]) {		
				return true;
			}
		}

		if (current.luigiDoorCutscene != old.luigiDoorCutscene && vars.luigiProgress == 5) {
			vars.luigiProgress = 6;
			if (settings["driveMistyStarted"]) {
				return true;
			}			
		}
		if (current.driveMistyCarEntered != 0 && current.driveMistyCarEntered != old.driveMistyCarEntered && vars.luigiProgress == 6) {
			vars.luigiProgress = 7;
			if (settings["driveMistyCarEntered"]) {
				return true;
			}
		}
		if (current.driveMistyMarkerEntered != 0 && current.driveMistyMarkerEntered != old.driveMistyMarkerEntered && vars.luigiProgress == 7) {
			vars.luigiProgress = 8;
			if (settings["driveMistyMarkerEntered"]) {
				return true;
			}
		}
		if (current.driveMistyMistyEnteredCar != 0 && current.driveMistyMistyEnteredCar != old.driveMistyMistyEnteredCar && vars.luigiProgress == 8) {
			vars.luigiProgress = 9;
			if (settings["driveMistyMistyEnteredCar"]) {
				return true;
			}
		}
		if (current.driveMistyMistyEnteredCar != 0 && current.driveMistyMistyEnteredCar != old.driveMistyMistyEnteredCar && vars.luigiProgress == 8) {
			vars.luigiProgress = 9;
			if (settings["driveMistyMistyEnteredCar"]) {
				return true;
			}
		}
		if (current.joeyCutsceneActor != old.joeyCutsceneActor && vars.luigiProgress == 9) {
			vars.luigiProgress = 10;
			if (settings["driveMistyEndCutsceneStarted"]) {
				return true;
			}			
		}
		if (current.driveMistyMissionPassed == 1 && current.driveMistyMissionPassed != old.driveMistyMissionPassed){
			if (settings["driveMistyMissionPassed"]) {		
				return true;
			}
		}


		
	}
}
	/*if (current.isFinished == 1 && current.isFinished != old.isFinished && !current.isLoading && current.missionsPassed > 26){
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

/*
isLoading
{
	//return current.isLoading;
}

gameTime
{
	if (vars.introGameTimeAdded == 0) {
		vars.introGameTimeAdded = 1; 
		// add GimeTime from the intro cutscene
		return TimeSpan.FromMilliseconds(477000);
	}
}


*/