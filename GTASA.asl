/* This is originally by Tduva:
 * https://github.com/tduva/LiveSplit-ASL/blob/master/GTASA.asl
 *
 * Github doesn't let me fork individual files, so I have to do it like this
 * instead...
 * /

/*
 * All addresses defined in this script are relative to the module, so without
 * the 0x400000 or whatever the module address is (different for more recent
 * Steam version). Compatibility for the most recent Steam version has not
 * been kept up to date. This was the version referred to as just "Steam" in 
 * this code and did not seem to include the v3.00 and v1.01 versions in its 
 * definition. 
 *
 * Most addresses are for the 1.0 version (unless noted otherwise). All global
 * variables seem to work in all versions if you apply the appropriate version
 * offset. Global variables refers to variables that are written in the mission
 * script as $1234. Other addresses have to be manually corrected for the Steam
 * version.
 *
 * Formula for global variable ($x) to address y (in decimal):
 * y = 6592864 + (x * 4)
 * 0d6592864 = 0x649960
 *
 * All splits are only split once per reset (so if you load an earlier Save and
 * revert splits, it won't split them again). This is mostly because this
 * behaviour makes sense: If you move back through the splits manually, you
 * should also split those splits manually. It is however also required for
 * the "Split at start of missions" section, which splits based on the current
 * first thread and would most likely split several times otherwise.
 */

state("gta_sa")
{
	int version_100_EU : 0x4245BC;
	int version_100_US : 0x42457C;
	int version_101_EU : 0x42533C;
	int version_101_US : 0x4252FC;
	int version_300_Steam : 0x45EC4A;
	int version_101_Steam : 0x45DEDA;
}

// Detect .exe of a Steam version (notice the "-" instead of "_")
state("gta-sa")
{
	int version_100_EU : 0x4245BC;
	int version_100_US : 0x42457C;
	int version_101_EU : 0x42533C;
	int version_101_US : 0x4252FC;
	int version_300_Steam : 0x45EC4A;
	int version_101_Steam : 0x45DEDA;
}

startup
{
	//=============================================================================
	// Memory Addresses
	//=============================================================================
	// There are more memory addresses defined in `init` in the "Version Detection"
	// and "Memory Watcher" sections.

	// Collectibles
	//=============
	/*
	 * First Address: 1.0
	 * Second Address: Steam
	 * 
	 * Collectible type acts as setting ID, so don't change it.
	 */
	vars.collectibles = new Dictionary<string,List<int>> {
		{"Photos",	new List<int> {0x7791BC, 0x80C3E4}},
		{"Tags",	new List<int> {0x69AD74, 0x71258C}},
		{"Oysters",	new List<int> {0x7791EC, 0x80C414}},
		{"Horseshoes", 	new List<int> {0x7791E4, 0x80C40C}},
		{"Stunts (Completed)", new List<int> {0x779064, 0x80C28C}}
	};

	// Missions
	//=========
	/*
	 * Memory addresses and the associated values and missions.
	 *
	 * Commenting out missions may interfere with custom splits that
	 * refer to their status (MissionPassed-function).
	 *
	 * Mission names defined here also act as setting IDs, so don't change
	 * them.
	 */
	vars.missions = new Dictionary<int, Dictionary<int, string>> {
		{0x64A060, new Dictionary<int, string> { // $INTRO_TOTAL_PASSED_MISSIONS
			{1, "Big Smoke"},
			{2, "Ryder"}
		}},
		{0x64A070, new Dictionary<int, string> { // $SWEET_TOTAL_PASSED_MISSIONS
			{1, "Tagging up Turf"},
			{2, "Cleaning the Hood"},
			{3, "Drive-Thru"},
			{4, "Nines and AKs"},
			{5, "Drive-By"},
			{6, "Sweet's Girl"},
			{7, "Cesar Vialpando"},
			{8, "Doberman"},
			{9, "Los Sepulcros"}
		}},
		{0x64A078, new Dictionary<int, string> { // $SMOKE_TOTAL_PASSED_MISSIONS
			{1, "OG Loc"},
			{2, "Running Dog"},
			{3, "Wrong Side of the Tracks"},
			{4, "Just Business"}
		}},
		{0x64A074, new Dictionary<int, string> { // $RYDER_TOTAL_PASSED_MISSIONS
			{1, "Home Invasion"},
			{2, "Catalyst"},
			{3, "Robbing Uncle Sam"}
		}},
		{0x64A088, new Dictionary<int, string> { // $LS_FINAL_TOTAL_PASSED_MISSIONS
			{1, "Reuniting the Families"},
			{2, "The Green Sabre"}
		}},
		{0x64A080, new Dictionary<int, string> { // $CRASH_LS_TOTAL_PASSED_MISSIONS
			{1, "Burning Desire"},
			{2, "Gray Imports"}
		}},
		{0x64A07C, new Dictionary<int, string> { // $OG_LOC_TOTAL_PASSED_MISSIONS
			{1, "Life's a Beach"},
			{2, "Madd Dogg's Rhymes"},
			{3, "Management Issues"},
			{4, "House Party (Cutscene)"},
			{5, "House Party"}
		}},
		{0x64A084, new Dictionary<int, string> { // $MISSION_LOWRIDER_PASSED
			{1, "High Stakes Lowrider"}
		}}, 
		{0x64A114, new Dictionary<int, string> { // $MISSION_BADLANDS_PASSED
			{1, "Badlands"}
		}},
		{0x64A490, new Dictionary<int, string> { // $MISSION_TANKER_COMMANDER_PASSED
			{1, "Tanker Commander"}
		}},
		{0x64A48C, new Dictionary<int, string> { // $MISSION_SMALL_TOWN_BANK_PASSED
			{1, "Small Town Bank"}
		}},
		{0x64A488, new Dictionary<int, string> { // $MISSION_LOCAL_LIQUOR_STORE_PASSED
			{1, "Local Liquor Store"}
		}},
		{0x64A494, new Dictionary<int, string> { // $ALL_CATALINA_MISSIONS_PASSED (not aptly named variable)
			{1, "Against All Odds"}
		}},
		{0x64BB2C, new Dictionary<int, string> { // $2163
			{1, "King in Exile"}
		}},
		{0x64A10C, new Dictionary<int, string> { // $TRUTH_TOTAL_PASSED_MISSIONS
			{1, "Body Harvest"},
			{2, "Are You Going To San Fierro?"}
		}},
		{0x64A110, new Dictionary<int, string> { // $CESAR_TOTAL_PASSED_MISSIONS
			{5, "Wu Zi Mu"}, // 2 = race ongoing, 3 = race finished prefadeout, 4 = cutscene
			{10, "Farewell, My Love"} // 7 = race ongoing, 8 = race finished prefadeout, 9 = cutscene
		}},
        {0x64BDC8, new Dictionary<int, string> { // $RACES_WON_NUMBER (first 3 Races are in a fixed order due to missions)
			// {2, "Wu Zi Mu"},
			// {3, "Farewell, My Love"},
			{25, "All Races Won"}
		}},
		{0x64A1D4, new Dictionary<int, string> { // $GARAGE_TOTAL_PASSED_MISSIONS
			{1, "Wear Flowers in your Hair"},
			{2, "Deconstruction"}
		}},
		{0x64A1DC, new Dictionary<int, string> { // $WUZIMU_TOTAL_PASSED_MISSIONS
			{1, "Mountain Cloud Boys"},
			{2, "Ran Fa Li"},
			{3, "Lure"},
			{4, "Amphibious Assault"},
			{5, "The Da Nang Thang"}
		}},
		{0x64A1E4, new Dictionary<int, string> { // $SYNDICATE_TOTAL_PASSED_MISSIONS
			{1, "Photo Opportunity"},
			{2, "Jizzy (Cutscene)"},
			{3, "Jizzy"},
			{4, "T-Bone Mendez"},
			{5, "Mike Toreno"},
			{6, "Outrider"},
			{7, "Ice Cold Killa"},
			{8, "Pier 69"},
			{9, "Toreno's Last Flight"},
			{10, "Yay Ka-Boom-Boom"}
		}},
		{0x64A1E8, new Dictionary<int, string> { // $CRASH_SF_TOTAL_PASSED_MISSIONS
			{1, "555 WE TIP"},
			{2, "Snail Trail"}
		}},
		{0x64A2A4, new Dictionary<int, string> { // $TORENO_TOTAL_PASSED_MISSIONS
			{1, "Monster"},
			{2, "Highjack"},
			{3, "Interdiction"},
			{4, "Verdant Meadows"},
			{5, "Learning to Fly"},
			{6, "N.O.E."},
			{7, "Stowaway"},
			{8, "Black Project"},
			{9, "Green Goo"}
		}},
		{0x64A1D8, new Dictionary<int, string> { // $ZERO_TOTAL_PASSED_MISSIONS
			{1, "Air Raid"},
			{2, "Supply Lines..."},
			{3, "New Model Army"}
		}},
		{0x64A1E0, new Dictionary<int, string> { // $STEAL_TOTAL_PASSED_MISSIONS
			{1, "Zeroing In"},
			{2, "Test Drive"},
			{3, "Customs Fast Track"},
			{4, "Puncture Wounds"}
		}},
		{0x64A2B4, new Dictionary<int, string> { // $CASINO_TOTAL_PASSED_MISSIONS
			{1, "Fender Ketchup"},
			{2, "Explosive Situation"},
			{3, "You've Had Your Chips"},
			{4, "Don Peyote"},
			{5, "Intensive Care"},
			{6, "The Meat Business"},
			{7, "Fish in a Barrel"},
			{8, "Freefall"},
			{9, "Saint Mark's Bistro"}
		}},
		{0x64A2B8, new Dictionary<int, string> { // $598 (CRASH_LV)
			{1, "Misappropriation"},
			{2, "High Noon"}
		}},
		{0x64A2BC, new Dictionary<int, string> { // $599 (Madd Dogg)
			{1, "Madd Dogg"}
		}},
		{0x64A2C0, new Dictionary<int, string> { // $HEIST_TOTAL_PASSED_MISSIONS
			{1, "Architectural Espionage"},
			{2, "Key to her Heart"},
			{3, "Dam and Blast"},
			{4, "Cop Wheels"},
			{5, "Up, Up and Away!"},
			{6, "Breaking the Bank at Caligula's"}
		}},
		{0x64A328, new Dictionary<int, string> { // $MANSION_TOTAL_PASSED_MISSIONS
			{1, "A Home in the Hills"},
			{2, "Vertical Bird"},
			{3, "Home Coming"},
			{4, "Cut Throat Business"}
		}},
		{0x64A32C, new Dictionary<int, string> { // $GROVE_TOTAL_PASSED_MISSIONS
			{1, "Beat Down on B Dup"},
			{2, "Grove 4 Life"}
		}},
		{0x64A334, new Dictionary<int, string> { // $RIOT_TOTAL_PASSED_MISSIONS
			{1, "Riot"},
			{2, "Los Desperados"},
			{3, "End of the Line Part 1"},
			{4, "End of the Line Part 2"},
			{5, "End of the Line Part 3"} // After credits
		}},
		{0x6518DC, new Dictionary<int, string> { // $TRUCKING_TOTAL_PASSED_MISSIONS
			{1, "Trucking 1"},
			{2, "Trucking 2"},
			{3, "Trucking 3"},
			{4, "Trucking 4"},
			{5, "Trucking 5"},
			{6, "Trucking 6"},
			{7, "Trucking 7"},
			{8, "Trucking 8"}
		}},
		{6592864 + (8171 * 4), new Dictionary<int, string> { // $QUARRY_TOTAL_PASSED_MISSIONS
			{1, "Quarry 1"},
			{2, "Quarry 2"},
			{3, "Quarry 3"},
			{4, "Quarry 4"},
			{5, "Quarry 5"},
			{6, "Quarry 6"},
			{7, "Quarry 7"}
		}},
		{0x64A9C4, new Dictionary<int, string> { // $CURRENT_WANTED_LIST (Export)
			{1, "Export List 1"},
			{2, "Export List 2"}
		}},
		{0x64ABE0, new Dictionary<int, string> { // $ALL_CARS_COLLECTED_FLAG
			{1, "Export List 3"}
		}},
		{6592864 + (1861 * 4), new Dictionary<int, string> { // $1861
			{1, "Pistol Round 1"},
			{2, "Pistol Round 2"},
			{3, "Pistol Round 3"},
			{4, "Micro SMG Round 1"},
			{5, "Micro SMG Round 2"},
			{6, "Micro SMG Round 3"},
			{7, "Shotgun Round 1"},
			{8, "Shotgun Round 2"},
			{9, "Shotgun Round 3"},
			{10, "AK47 Round 1"},
			{11, "AK47 Round 2"},
			{12, "AK47 Round 3"},
		}},
	};

	// Other Missions
	//===============
	// Addresses that are responsible for a single mission each.
	//
	vars.missions2 = new Dictionary<string, Dictionary<int, string>> {
		// Flight School not here because it is a Story Mission
		{"Schools", new Dictionary<int, string> {
			{6592864 + (87 * 4), "Pilot School"},	// $MISSION_LEARNING_TO_FLY_PASSED
			{6592864 + (86 * 4), "Driving School"},	// $MISSION_BACK_TO_SCHOOL_PASSED
			{6592864 + (1969 * 4), "Boat School"},	// $MISSION_BOAT_SCHOOL_PASSED
			{6592864 + (2201 * 4), "Bike School"},	// $MISSION_DRIVING_SCHOOL_PASSED (actually Bike School)
		}},
		{"Vehicle Submissions", new Dictionary<int, string> {
			{0x64B0A4, "Firefighter"},	// $1489 (directly goes to 2 when complete)
			{0x64B0A0, "Vigilante"},	// $1488
			{0x64B0AC, "Taxi Driver"},	// $MISSION_TAXI_PASSED ($1491)
			{0x64B09C, "Paramedic"},	// $1487
			{0x64B87C, "Pimping"},		// $MISSION_PIMPING_PASSED ($1991)
			{0x651A20, "Freight Level 1"},	// $8240
			{0x651A1C, "Freight Level 2"},	// $8239 (goes to 2 at the end of the level)
		}},
		{"Properties", new Dictionary<int, string> {
			{0x64B2B0, "Zero (RC Shop Bought)"},
			{0x64A4CC, "Santa Maria Beach (Safehouse)"},
			{0x64A4D0, "Rockshore West (Safehouse)"},
			{0x64A4D4, "Fort Carson (Safehouse)"},
			{0x64A4D8, "Prickle Pine (Safehouse)"},
			{0x64A4DC, "Whitewood Estate (Safehouse)"},
			{0x64A4E0, "Palomino Creek (Safehouse)"},
			{0x64A4E4, "Redsands West (Safehouse)"},
			{0x64A4E8, "Verdant Bluffs (Safehouse)"},
			{0x64A4EC, "Calton Heights (Safehouse)"},
			{0x64A4F0, "Mulholland (Safehouse)"},
			{0x64A4F4, "Paradiso (Safehouse)"},
			{0x64A4F8, "Hashbury (Safehouse)"},
			{0x64A4FC, "Verona Beach (Safehouse)"},
			{0x64A500, "Pirates In Men's Pants (Hotel Suite)"},
			{0x64A504, "The Camel's Toe (Hotel Suite)"},
			{0x64A508, "Chinatown (Safehouse)"},
			{0x64A50C, "Whetstone (Safehouse)"},
			{0x64A510, "Doherty (Safehouse)"},
			{0x64A514, "Queens (Hotel Suite)"},
			{0x64A518, "Angel Pine (Safehouse)"},
			{0x64A51C, "El Quebrados (Safehouse)"},
			{0x64A520, "Tierra Robada (Safehouse)"},
			{0x64A524, "Dillimore (Safehouse)"},
			{0x64A528, "Jefferson (Safehouse)"},
			{0x64A52C, "Old Venturas Strip (Hotel Suite)"},
			{0x64A530, "The Clown's Pocket (Hotel Suite)"},
			{0x64A534, "Creek (Safehouse)"},
			{0x64A538, "Willowfield (Safehouse)"},
			{0x64A53C, "Blueberry (Safehouse)"},
		}},
		{"Freight", new Dictionary<int, string> {
			{0x651A20, "Freight Level 1"},	// $8240
			{0x651A1C, "Freight Level 2"},	// $8239 (goes to 2 at the end of the level)
		}},
		{"Gym Moves", new Dictionary<int, string> {
			{0x6518C4, "Los Santos Gym Moves"}, 	// $8153
			{0x6518C8, "San Fierro Gym Moves"}, 	// $8154
			{0x6518D8, "Las Venturas Gym Moves"}, 	// $8158
		}},
		{"Challenges", new Dictionary<int, string> {
			{0x64C510, "NRG-500 Stunt Challenge"}, 	// $2796
			{0x64C50C, "BMX Stunt Challenge"},	// $2795
			{0x64EBC0, "Shooting Range Complete"}, 	// $5272
			{0x649AC8, "Kickstart"}, 		// $MISSION_KICKSTART_PASSED ($90)
			{0x64B7B4, "Blood Ring"}, 		// $MISSION_BLOODRING_PASSED ($1941)
			{0x64BDB4, "8-Track"},			// streetraces 25
			{0xA4BDB8, "Dirt Track"},		// streetraces 26
		}},	
		{"Valet", new Dictionary<int, string> {
			{0x64B710, "Valet Parking"}, 	// $1900
		}},
		{"Courier", new Dictionary<int, string> {
			{0x64B880, "Los Santos Courier"}, 	// $MISSION_COURIER_LS_PASSED ($1992)
			{0x64B884, "Las Venturas Courier"}, 	// $MISSION_COURIER_LV_PASSED ($1993)
			{0x64B888, "San Fierro Courier"}, 	// $MISSION_COURIER_SF_PASSED ($1994)
		}},
		{"Streetraces", new Dictionary<int, string> {
			// Races addresses are based on the global variable $RACES_WON ($2300), which
			// is an array. The number in the comment is the $RACE_INDEX ($352).
			
			// Races that are already done during story missions:
			// Lowrider Race (0), Badlands A (7), Badlands B (8)
			{0x64BD50, "Lowrider Race"},    // 0
			{0x64BD54, "Little Loop"},		// 1
			{0x64BD58, "Backroad Wanderer"}, 	// 2
			{0x64BD5C, "City Circuit"},		// 3
			{0x64BD60, "Vinewood"},		// 4
			{0x64BD64, "Freeway (Race)"},		// 5
			{0x64BD68, "Into the Country"},		// 6
			{0x64BD6C, "Badlands A"},           // 7
			{0x64BD70, "Badlands B"},           // 8
			{0x64BD74, "Dirtbike Danger"},		// 9
			{0x64BD78, "Bandito County"},		// 10
			{0x64BD7C, "Go-Go Karting"},		// 11
			{0x64BD80, "San Fierro Fastlane"}, 	// 12
			{0x64BD84, "San Fierro Hills"},		// 13
			{0x64BD88, "Country Endurance"}, 	// 14
			{0x64BD8C, "SF to LV"},			// 15
			{0x64BD90, "Dam Rider"},		// 16
			{0x64BD94, "Desert Tricks"},		// 17
			{0x64BD98, "LV Ringroad"},		// 18
			{0x64BD9C, "World War Ace"},		// 19
			{0x64BDA0, "Barnstorming"},		// 20
			{0x64BDA4, "Military Service"}, 	// 21
			{0x64BDA8, "Chopper Checkpoint"}, 	// 22
			{0x64BDAC, "Whirly Bird Waypoint"},	// 23
			{0x64BDB0, "Heli Hell"},		// 24
		}},
	};
	
	// Mission Levels
	//===============
	// These variables are not persistent
	vars.missions3 = new Dictionary<int, Dictionary<int, string>> {
		{6592864 + (8213 * 4), new Dictionary<int, string> { // $8213 Firefighter Level
			{1, "Firefighter started for the first time"},
		}},
		{6592864 + (8211 * 4), new Dictionary<int, string> { // $8211 ($PARAMEDIC_MISSION_LEVEL) Paramedic Level
			{1, "Paramedic started for the first time"},
		}},
		{6592864 + (8227 * 4), new Dictionary<int, string> { // $8227 Vigilante Level
			{1, "Vigilante started for the first time"},
		}},
		{6592864 + (180 * 4), new Dictionary<int, string> { // $180 ($TOTAL_PASSENGERS_DROPPEDOFF) Taxi Fares Done
			{1, "1 Taxi Fare dropped off"},
		}},
		{0x779168, new Dictionary<int, string> { // Pimping level stat (ID 210)?
		}},
		{6592864 + (1952 * 4), new Dictionary<int, string> { // $FLIGHT_SCHOOL_CONTESTS_PASSED (starts off at 1)
			{2, "Takeoff"},
			{4, "Land Plane"},
			{6, "Circle Airstrip"},
			{7, "Circle Airstrip and Land"},
			{8, "Helicopter Takeoff"},
			{9, "Land Helicopter"},
			{10, "Destroy Targets"},
			{11, "Loop-the-Loop"},
			{12, "Barrel Roll"},
			// Parachute Onto Target not included because this variable does not update upon completing it. Use the school finish var
		}},
		{6592864 + (8189 * 4), new Dictionary<int, string> { // $8189 (starts off at 1)
			{2, "Basic Seamanship"},
			{3, "Plot a Course"},
			{4, "Fresh Slalom"},
			{5, "Flying Fish"},
			// Land, Sea and Air not included because this variable does not update upon completing it. Use the school finish var
		}},
	};


	for (int i = 2; i < 13; i++) { vars.missions3[6592864 + (8213 * 4)].Add(i, "Firefighter level " + (i-1).ToString()); }
	for (int i = 2; i < 13; i++) { vars.missions3[6592864 + (8211 * 4)].Add(i, "Paramedic level " + (i-1).ToString()); }
	for (int i = 2; i < 13; i++) { vars.missions3[6592864 + (8227 * 4)].Add(i, "Vigilante level " + (i-1).ToString()); }
	for (int i = 2; i < 50; i++) { vars.missions3[6592864 + (180 * 4)].Add(i, i.ToString() + " Taxi Fares dropped off"); }
	for (int i = 1; i <= 10; i++) { vars.missions3[0x779168].Add(i, "Pimping level " + i.ToString()); }

	// Misc boolean values
	//====================
	vars.missions4 = new Dictionary<int, string> {
		{ 6592864 + (162 * 4), "pimping_started" },
		{ 6592864 + (54 * 4), "itb_grovestreethome" }, // $HELP_INTRO_SHOWN
		{ 6592864 + (161 * 4), "freight_started" },
		{ 6592864 + (1883 * 4), "valet_started" },
	};

	// Import/Export
	//==============
	vars.exportLists = new Dictionary<int, List<string>> {
		{0, new List<string> {
			"Buffalo", "Sentinel", "Infernus", "Camper", "Admiral",
			"Patriot", "Sanchez", "Stretch", "Feltzer", "Remington"
		}},
		{1, new List<string> {
			"Cheetah", "Rancher", "Stallion", "Tanker", "Comet",
			"Slamvan", "Blista Compact", "Stafford", "Sabre", "FCR-900"
		}},
		{2, new List<string> {
			"Banshee", "Super GT", "Journey", "Huntley", "BF Injection",
			"Blade", "Freeway", "Mesa", "ZR-350", "Euros"
		}}
	};

	// Street Races
	//=============
	// Completion of the races themselves is done by missions2, but for per-checkpoint
	// splits we need to know how many checkpoints are in each race. Checkpoint count
	// starts at 0 during the countdown and changes to 1 when the countdown ends. So
	// Little Loop actually only has 10 checkpoints if counted visually. A race ends
	// upon collecting the final checkpoint so we don't need to check for that one as
	// it's already being splut by the race completed tracker.
	vars.streetrace_checkpointcounts = new Dictionary<string, int> {
		{"Lowrider Race", 12}, // 0
		{"Little Loop", 11}, // 1
		{"Backroad Wanderer", 19}, // 2
		{"City Circuit", 19}, // 3
		{"Vinewood", 21}, // 4
		{"Freeway (Race)", 23}, // 5
		{"Into the Country", 27}, // 6
		{"Badlands A", 31}, // 7
		{"Badlands B", 33}, // 8
		{"Dirtbike Danger", 19}, // 9
		{"Bandito County", 20}, // 10
		{"Go-Go Karting", 16}, // 11
		{"San Fierro Fastlane", 16}, // 12
		{"San Fierro Hills", 41}, // 13
		{"Country Endurance", 42}, // 14
		{"SF to LV", 27}, // 15
		{"Dam Rider", 25}, // 16
		{"Desert Tricks", 27}, // 17
		{"LV Ringroad", 21}, // 18
		{"World War Ace", 35}, // 19
		{"Barnstorming", 62}, // 20
		{"Military Service", 70}, // 21
		{"Chopper Checkpoint", 27}, // 22
		{"Whirly Bird Waypoint", 27}, // 23
		{"Heli Hell", 28}, // 24
		{"8-Track", 8},			// 25
		{"Dirt Track", 14},		// 26
	};

	// Deathwarps
	//===========
	// Deathwarps. Key = mission passed before the warp. Value = A list of possible
	// missions after the warp. A list instead of just a single string to be able 
	// to accomodate different routes. Warps will be satisfied if the player dies
	// while Key is passed but any Value is not. Mission names must be exact.
	vars.deathWarps = new Dictionary<string, List<string>> {
		{"Badlands", new List<string> {"Tanker Commander"}},
		{"King in Exile", new List<string> {"Small Town Bank"}},
		
		{"Jizzy (Cutscene)", new List<string> {"Jizzy"}},
		{"Jizzy", new List<string> {"Mountain Cloud Boys"}},
		{"Mike Toreno", new List<string> {"Lure"}},
		{"Lure", new List<string> {"Paramedic"}},
		{"The Da Nang Thang", new List<string> {"Yay Ka-Boom-Boom"}},

		{"Stretch", new List<string> {"Infernus"}},
		{"Export List 1", new List<string> {"Rancher"}},
		{"Comet", new List<string> {"Stafford"}},
		{"BF Injection", new List<string> {"Shooting Range Complete"}},
		{"Freeway", new List<string> {"Taxi Driver"}},

		{"Trucking 7", new List<string> {"Madd Dogg"}},
		{"Dam and Blast", new List<string> {"Quarry"}},
		{"Up, Up and Away!", new List<string> {"World War Ace"}},
		{"Barnstorming", new List<string> {"Saint Mark's Bistro"}},
	};

	vars.bustedWarps = new Dictionary<string, List<string>> {
		{"Badlands", new List<string> {"Tanker Commander"}},
		{"King in Exile", new List<string> {"Small Town Bank"}},
	};

	// Thread Start
	//=============
	// Split when a certain thread was started, usually when a mission was started.
	//
	vars.startMissions = new Dictionary<string, string> {
		// {"grove2", "GT #1"},	// Grove 4 Life
		// {"manson5", "GT #2"},	// Cut Throat Business
		{"steal", "Wang Cars (Showroom Bought)"},
		{"planes", "Plane Flight"},
		{"psch", "Verdant Meadows (Safehouse)"},
		{"desert5", "Pilot School Started"},
		{"dskool", "Driving School Started"},
		{"bskool", "Bike School Started"},
		{"boat", "Boat School Started"},
		{"blood", "Blood Ring Started"},
		{"kicksta", "Kickstart Started"},
	};

	#region utility

	//=============================================================================
	// Utility Functions
	//=============================================================================

	/*
	 * Easier debug output.
	 */
	Action<string> DebugOutput = (text) => {
		print("[GTASA Autosplitter] "+text);
	};
	vars.DebugOutput = DebugOutput;

	//=============================================================================
	// State keeping
	//=============================================================================

	// Already split splits during this attempt (until timer reset)
	vars.split = new List<string>();

	// Track timer phase
	vars.PrevPhase = null;

	// Timestamp when the last load occured (load means loading from a save
	// and such, not load screens)
	vars.lastLoad = 0;

	// Timestamp when the last split was executed (to prevent double-splits)
	vars.lastSplit = 0;

	//=============================================================================
	// Settings
	//=============================================================================
	// Settings are mostly added manually (not directly from the mission definition)
	// so they can be manually sorted (the usual mission order).

	// Setting Functions
	//==================

	// Check if the given string is the name of a mission as defined in vars.missions
	Func<string, bool> missionPresent = m => {
		foreach (var item in vars.missions)
		{
			foreach (var item2 in item.Value)
			{
				if (item2.Value == m)
				{
					return true;
				}
			}
		}
		foreach (var item in vars.missions2)
		{
			foreach (var item2 in item.Value)
			{
				if (item2.Value == m)
				{
					return true;
				}
			}
		}
		vars.DebugOutput("Mission not found: "+m);
		return false;
	};

	Func<string, bool> mission4Present = m => {
		foreach (var item in vars.missions4)
		{
			if (item.Value == m)
			{
				return true;
			}
		}
		vars.DebugOutput("Mission not found: "+m);
		return false;
	};

/*
	Func<Dictionary<int, Dictionary<int, string>>, string, bool> missionPresent2 = (d, m) => {
		foreach (var item in d)
		{
			foreach (var item2 in item.Value)
			{
				if (item2.Value == m)
				{
					return true;
				}
			}
		}
		return false;
	};
*/
	// Function to add a list of missions (including check if they are a mission)
	Action<string, List<string>> addMissionList = (parent, missions) => {
		foreach (var mission in missions) {
			if (missionPresent(mission)) {
				settings.Add(mission, true, mission, parent);
			}
		}
	};

	// Add missions from vars.missions (also add parent/header)
	//
	// header: only label
	// section: used for parent setting
	// missions: key for vars.missions (address)
	Action<string, int, string> addMissionsHeader = (section, missions, header) => {
		var parent = section+"Missions";
		settings.Add(parent, true, header);
		foreach (var item in vars.missions[missions]) {
			var mission = item.Value;
			if (missionPresent(mission)) {
				settings.Add(mission, true, mission, parent);
			}
		}
	};

	// Add missions from vars.missions2 (to existing parent)
	//
	// missions: existing parent setting, key for vars.missions2
	// defaultValue: default value for all added settings
	Action<string, bool> addMissions2 = (missions, defaultValue) => {
		var parent = missions;
		foreach (var item in vars.missions2[missions]) {
			var mission = item.Value;
			settings.Add(mission, defaultValue, mission, parent);
		}
	};

	// Adds missions from vars.missions2 (also add parent/header)
	//
	// header: only label
	// missions: parent setting name, key for vars.missions2
	// defaultValue: default value for all added settings
	Action<string, bool, string> addMissions2Header = (missions, defaultValue, header) => {
		var parent = missions;
		settings.Add(parent, defaultValue, header);
		addMissions2(missions, defaultValue);
	};

	Action<int, string> addMissions3 = (missions, handle) => {
		var parent = handle;
		foreach (var item in vars.missions3[missions]) {
			var mission = item.Value;
			settings.Add(mission, false, mission, parent);
		}
	};

	Action<int, string, string> addMissions3Header = (missions, handle, header) => {
		settings.Add(handle, true, header);
		addMissions3(missions, handle);
	};

	// Add a single mission (checking if it's a mission)
	Action<string, bool, string> addMissionCustom = (mission, defaultValue, label) => {
		if (missionPresent(mission)) {
			settings.Add(mission, defaultValue, label);
		}
	};

	// Add a single mission (checking if it's a mission)
	Action<string, bool, string, string> addMission4Custom = (mission, defaultValue, label, parent) => {
		if (mission4Present(mission)) {
			settings.Add(mission, defaultValue, label, parent);
		}
	};

	// Add a single mission, with default values (checking if it's a mission)
	Action<string> addMission = (mission) => {
		if (missionPresent(mission)) {
			settings.Add(mission);
		}
	};

	#endregion

    #region Main Missions

	// Main Missions
	//==============
	settings.Add("Missions", true, "Story Missions Completion");
	settings.SetToolTip("Missions", "Split upon the completion of these story missions (missions marked permanently on the minimap until completion)");

	settings.CurrentDefaultParent = "Missions";
	settings.Add("LS", true, "Los Santos");
	settings.Add("BL", true, "Badlands");
	settings.Add("SF", true, "San Fierro");
	settings.Add("Desert", true);
	settings.Add("LV", true, "Las Venturas");
	settings.Add("RTLS", true, "Return to Los Santos");
	settings.CurrentDefaultParent = "LS";
	settings.Add("LS_Intro", true, "Intro");
	settings.Add("LS_Sweet", true, "Sweet");
	settings.Add("LS_Smoke", true, "Big Smoke");
	settings.Add("LS_Ogloc", true, "OG Loc");
	settings.Add("LS_Ryder", true, "Ryder");
	settings.Add("LS_Crash", true, "C.R.A.S.H.");
	settings.Add("LS_Cesar", true, "Cesar");
	settings.Add("LS_Final", true, "Finale");
	settings.CurrentDefaultParent = "BL";
	settings.Add("BL_Intro", true, "Trailer Park");
	settings.Add("BL_Catalina", true, "Catalina");
	settings.Add("BL_Cesar", true, "Cesar");
	settings.Add("BL_Truth", true, "The Truth");
	settings.CurrentDefaultParent = "SF";
	settings.Add("SF_Main", true, "Garage / Syndicate");
	settings.Add("SF_Wuzimu", true, "Woozie");
	settings.Add("SF_Zero", true, "Zero");
	settings.CurrentDefaultParent = "Desert";
	settings.Add("D_Toreno", true, "Toreno");
	settings.Add("D_WangCars", true, "Wang Cars");
	settings.CurrentDefaultParent = "LV";
	settings.Add("LV_AirStrip", true, "Air Strip");
	settings.Add("LV_Casino", true, "Casino");
	settings.Add("LV_Crash", true, "C.R.A.S.H.");
	settings.Add("LV_MaddDogg", true, "Madd Dogg");
	settings.Add("LV_Heist", true, "Heist");
	settings.CurrentDefaultParent = "RTLS";
	settings.Add("RTLS_Mansion", true, "Mansion");
	settings.Add("RTLS_Grove", true, "Grove");
	settings.Add("RTLS_Riot", true, "Finale");

	settings.CurrentDefaultParent = null;
	
	// Los Santos
	//-----------

	settings.Add("itb", false, "In the Beginning", "LS_Intro");
	settings.Add("itb_cutsceneskipped", false, "Cutscene skipped", "itb");
	addMission4Custom("itb_grovestreethome", true, "\"Grove Street - Home\" dialogue played", "itb");
	addMissionList("LS_Intro", new List<string>() { "Big Smoke", "Ryder" });
	addMissionList("LS_Sweet", new List<string>() { 
        "Tagging up Turf", "Cleaning the Hood", "Drive-Thru",
		"Nines and AKs", "Drive-By", "Sweet's Girl", 
        "Cesar Vialpando", "Doberman", "Los Sepulcros"
    });
	addMissionList("LS_Smoke", new List<string>() { 
        "OG Loc", "Running Dog", "Wrong Side of the Tracks", "Just Business"
    });
	addMissionList("LS_Ogloc", new List<string>() { 
        "Life's a Beach", "Madd Dogg's Rhymes",	"Management Issues", 
        "House Party (Cutscene)", "House Party" 
    });
	addMissionList("LS_Ryder", new List<string>() { "Home Invasion", "Catalyst", "Robbing Uncle Sam" });
	addMissionList("LS_Final", new List<string>() { "Reuniting the Families", "The Green Sabre" });
	addMissionList("LS_Crash", new List<string>() { "Burning Desire", "Gray Imports"});
	addMissionList("LS_Cesar", new List<string>() { "High Stakes Lowrider" });

	// Badlands
	//---------
	addMissionList("BL_Intro", new List<string>() { "Badlands", "King in Exile" });
	addMissionList("BL_Catalina", new List<string>() { 
        "Tanker Commander", "Small Town Bank", 
        "Local Liquor Store", "Against All Odds" 
        });
	addMissionList("BL_Cesar", new List<string>() { "Wu Zi Mu",	"Farewell, My Love" });
	addMissionList("BL_Truth", new List<string>() { "Body Harvest", "Are You Going To San Fierro?" });
    
	// San Fierro
	//-----------
	addMissionList("SF_Wuzimu", new List<string>() { 
        "Mountain Cloud Boys", "Ran Fa Li", "Lure", 
        "Amphibious Assault", "The Da Nang Thang"
    });
	addMissionList("SF_Main", new List<string>() { 
        "Wear Flowers in your Hair", "555 WE TIP", "Deconstruction",
        "Photo Opportunity", "Jizzy (Cutscene)", "Jizzy", 
        "T-Bone Mendez", "Mike Toreno", "Outrider",
		"Snail Trail", "Ice Cold Killa", "Pier 69", 
        "Toreno's Last Flight", "Yay Ka-Boom-Boom"
    });
	addMissionList("SF_Zero", new List<string>() { 
        "Air Raid", "Supply Lines...", "New Model Army"
    });

	// Desert
	//-------
	addMissionList("D_Toreno", new List<string>() {
		"Monster", "Highjack", "Interdiction", "Verdant Meadows", "Learning to Fly"
	});
    addMissionList("D_WangCars", new List<string>() {
		"Zeroing In", "Test Drive", "Customs Fast Track", "Puncture Wounds"
	});

	// Las Venturas
	//-------------
	addMissionList("LV_AirStrip", new List<string>() {
        "N.O.E.", "Stowaway", "Black Project", "Green Goo"
	});
	addMissionList("LV_Casino", new List<string>() {
		"Fender Ketchup", "Explosive Situation", 
        "You've Had Your Chips", "Don Peyote", "Intensive Care", 
        "The Meat Business", "Fish in a Barrel", "Freefall", "Saint Mark's Bistro"
	});
	addMissionList("LV_Crash", new List<string>() {
        "Misappropriation", "High Noon"
	});
	addMissionList("LV_MaddDogg", new List<string>() { "Madd Dogg" });
	addMissionList("LV_Heist", new List<string>() {
        "Architectural Espionage", "Key to her Heart", "Dam and Blast",
        "Cop Wheels", "Up, Up and Away!", "Breaking the Bank at Caligula's"
    });

	// Return to Los Santos
	//---------------------
	//---------------------
	//---------------------
	settings.CurrentDefaultParent = "RTLS";

	addMissionList("RTLS_Mansion", new List<string>() {
		"A Home in the Hills", "Vertical Bird", "Home Coming", 
		"Cut Throat Business", 
	});
	addMissionList("RTLS_Grove", new List<string>() {
        "Beat Down on B Dup", "Grove 4 Life"
	});
	addMissionList("RTLS_Riot", new List<string>() { "Riot", "Los Desperados" });
	settings.CurrentDefaultParent = "RTLS_Riot";
	addMissionCustom("End of the Line Part 1", true, "End of the Line Part 1 (after killing Big Smoke)");
	addMissionCustom("End of the Line Part 2", true, "End of the Line Part 2 (start of chase)");
	
	// End of the Line Part 3
	//-----------------------
	settings.Add("eotlp3", true, "End of the Line Part 3");
	settings.CurrentDefaultParent = "eotlp3";
	settings.Add("eotlp3_chase1", false, "Start of cutscene after catching Sweet");
	settings.Add("eotlp3_chase2", false, "Start of cutscene near Cluckin' Bell");
	settings.Add("eotlp3_chase3", true, "End of any%: Start of firetruck bridge cutscene");
	addMissionCustom("End of the Line Part 3", true, "After credits");

	settings.CurrentDefaultParent = null;

    #endregion

	#region Add settings

	// Side Missions
	//==============
	settings.Add("Missions2", true, "Side Missions");
	settings.CurrentDefaultParent = "Missions2";

	// Courier
	//--------
	settings.Add("Courier", true, "Courier");
	settings.CurrentDefaultParent = "Courier";
	settings.Add("Courier 1", true, "Courier Los Santos");
	settings.Add("Courier 2", true, "Courier San Fierro");
	settings.Add("Courier 3", true, "Courier Las Venturas");
	settings.CurrentDefaultParent = "Courier 1";
	settings.Add("courier_1_started", false, "Los Santos Courier Started");
	addMissionCustom("Los Santos Courier", true, "Los Santos Courier Complete");
	settings.CurrentDefaultParent = "Courier 2";
	settings.Add("courier_2_started", false, "San Fierro Courier Started");
	addMissionCustom("San Fierro Courier", true, "San Fierro Courier Complete");
	settings.CurrentDefaultParent = "Courier 3";
	settings.Add("courier_3_started", false, "Las Venturas Courier Started");
	addMissionCustom("Las Venturas Courier", true, "Las Venturas Courier Complete");
	for (int city = 1; city <= 3; city++) {
		settings.Add("Courier "+city+" Levels", false, "Level Completion", "Courier "+city);
		settings.Add("Courier "+city+" Deliveries", false, "Deliveries", "Courier "+city);
		for (int level = 1; level <= 4; level++) {
			var parent = "Courier "+city+" Levels";
			var handle = "courier_"+city+"_level_"+level;
			settings.Add(handle, false, "Level "+level, parent);
			for (int cp = 1; cp <= level + 2; cp++) {
				parent = "Courier "+city+" Deliveries";
				handle = "courier_"+city+"_level_"+level+"_delivery_"+cp;
				settings.Add(handle, false, "Level "+level+" Delivery "+cp, parent);
			}
		}
	}
	settings.CurrentDefaultParent = "Missions2";

	// Trucking
	//---------
	settings.Add("TruckingMissions", true, "Trucking");
	settings.CurrentDefaultParent = "TruckingMissions";
	settings.Add("trucking_start", false, "Starting mission for the first time");
	settings.SetToolTip("trucking_start", "Split when starting a trucking mission for the first time.");
	settings.Add("trucking_leftcompound", false, "Leaving the compound");
	settings.SetToolTip("trucking_leftcompound", "Split when driving the truck out of the compound. Useful for separating truck reset RNG from the actual mission.");
	for (int i = 1; i <= 8; i++) {
		settings.Add("trucking_start"+i, false, "Trucking "+i.ToString()+" - Start", "trucking_start");
		settings.Add("trucking_leftcompound"+i, false, "Trucking "+i.ToString()+" - Leaving compound", "trucking_leftcompound");
		addMissionCustom("Trucking "+i, true, "Trucking "+i+" Completed");
	}
	settings.CurrentDefaultParent = "Missions2";
	
	// Quarry
	//-------
	addMissionsHeader("Quarry", 6592864 + (8171 * 4), "Quarry");

	// Valet Parking
	//--------------
	settings.Add("ValetMissions", true, "Valet Parking");
	settings.CurrentDefaultParent = "ValetMissions";
	addMission4Custom("valet_started", false, "Valet started for the first time", "ValetMissions");
	settings.Add("valets_cars", false, "Cars");
	for (int i = 1; i <= 5; i++) {
		settings.Add("valet_level"+i, false, "Level "+i+" complete");
		for (int j = i+1; j > 0; j--) {
			var handle = "valet_level"+i+"_car"+j;
			settings.Add(handle, false, "Level "+i+": "+j+" car"+(j==1?"":"s")+" remaining", "valets_cars");
			settings.SetToolTip(handle, "Split when there's "+j+" cars left to park on level "+i);
		}
	}
	addMissionCustom("Valet Parking", true, "Valet mission complete");
	settings.CurrentDefaultParent = "Missions2";

	// Vehicle submissions
	//--------------------
	settings.Add("VehicleSubmissions", true, "Vehicle Submissions");
	settings.CurrentDefaultParent = "VehicleSubmissions";
	
	addMissions3Header(6592864 + (8213 * 4), "firefighter_level", "Firefighter");
	settings.CurrentDefaultParent = "firefighter_level";
	addMissionCustom("Firefighter", true, "Firefighter level 12 (Completion)");
	settings.CurrentDefaultParent = "VehicleSubmissions";

	settings.Add("freight_level", true, "Freight");
	settings.CurrentDefaultParent = "freight_level";
	addMission4Custom("freight_started", false, "Freight started for the first time", "freight_level");
	settings.Add("freight_station 1 1", false, "Freight Level 1 Stop 1");
	settings.SetToolTip("freight_station 1 1", "Split when reaching the first stop on the first level. In common 100% routes, this would be Linden Station.");
	settings.Add("freight_station 1 2", false, "Freight Level 1 Stop 2");
	settings.SetToolTip("freight_station 1 2", "Split when reaching the second stop on the first level. In common 100% routes, this would be Yellow Bell Station.");
	settings.Add("freight_station 1 3", false, "Freight Level 1 Stop 3");
	settings.SetToolTip("freight_station 1 3", "Split when reaching the third stop on the first level. In common 100% routes, this would be Cranberry Station.");
	settings.Add("freight_station 1 4", false, "Freight Level 1 Stop 4");
	settings.SetToolTip("freight_station 1 4", "Split when reaching the fourth stop on the first level. In common 100% routes, this would be Market Station.");
	addMissionCustom("Freight Level 1", false, "Freight Level 1 Stop 5 (Level 1 Completion)");
	settings.SetToolTip("Freight Level 1", "Split when reaching the fifth stop on the first level, completing the level. In common 100% routes, this would be Market Station.");
	settings.Add("freight_station 2 1", false, "Freight Level 2 Stop 1");
	settings.SetToolTip("freight_station 2 1", "Split when reaching the first stop on the first level. In common 100% routes, this would be Linden Station.");
	settings.Add("freight_station 2 2", false, "Freight Level 2 Stop 2");
	settings.SetToolTip("freight_station 2 2", "Split when reaching the second stop on the first level. In common 100% routes, this would be Yellow Bell Station.");
	settings.Add("freight_station 2 3", false, "Freight Level 2 Stop 3");
	settings.SetToolTip("freight_station 2 3", "Split when reaching the third stop on the first level. In common 100% routes, this would be Cranberry Station.");
	settings.Add("freight_station 2 4", false, "Freight Level 2 Stop 4");
	settings.SetToolTip("freight_station 2 4", "Split when reaching the fourth stop on the first level. In common 100% routes, this would be Market Station.");
	addMissionCustom("Freight Level 2", true, "Freight Level 2 Stop 5 (Level 2 Completion)");
	settings.SetToolTip("Freight Level 2", "Split when reaching the fifth stop on the second level, completing the level and submission. In common 100% routes, this would be Market Station.");
	settings.CurrentDefaultParent = "VehicleSubmissions";

	addMissions3Header(6592864 + (8211 * 4), "paramedic_level", "Paramedic");
	settings.CurrentDefaultParent = "paramedic_level";
	addMissionCustom("Paramedic", true, "Paramedic level 12 (Completion)");
	settings.CurrentDefaultParent = "VehicleSubmissions";

	settings.Add("pimping_level", true, "Pimping");
	settings.CurrentDefaultParent = "pimping_level";
	addMission4Custom("pimping_started", false, "Pimping started for the first time", "pimping_level");
	addMissions3(0x779168, "pimping_level");
	addMissionCustom("Pimping", true, "Pimping Complete");
	settings.CurrentDefaultParent = "VehicleSubmissions";
	
	addMissions3Header(6592864 + (180 * 4), "taxi_fares", "Taxi Driver");
	settings.CurrentDefaultParent = "taxi_fares";
	addMissionCustom("Taxi Driver", true, "50 Taxi Fares dropped off (Completion)");
	settings.Add("taxidriver51plus", false, "51+ Taxi Fares dropped off (split for each)", "taxi_fares");
	settings.CurrentDefaultParent = "VehicleSubmissions";
	
	addMissions3Header(6592864 + (8227 * 4), "vigilante_level", "Vigilante");
	settings.CurrentDefaultParent = "vigilante_level";
	addMissionCustom("Vigilante", true, "Vigilante level 12 (Completion)");
	settings.Add("vigilantelevel13plus", false, "Vigilante level 13+ (split for each level)", "vigilante_level");
	settings.CurrentDefaultParent = "VehicleSubmissions";

	// Races
	//------
	settings.Add("Races", true, "Races", "Missions2");
	settings.CurrentDefaultParent = "Races";
	settings.Add("All Races Won", false);
	settings.Add("LS Races", true, "Los Santos");
	settings.Add("SF Races", true, "San Fierro");
	settings.Add("LV Races", true, "Las Venturas");
	settings.Add("Air Races", true, "Air Races");
	for (int i = 0; i < vars.missions2["Streetraces"].Count; i++) {
		var raceName = vars.missions2["Streetraces"][0x64BD50 + i*4];
		var parent = "LS Races";
		if (i >= 19) { parent = "Air Races"; }
		else if (i >= 15) { parent = "LV Races"; }
		else if (i >= 9) { parent = "SF Races"; }
		var defaultSplit = i != 0 && i != 7 && i != 8;
		var raceId = "Race "+i;
		var cpCount = vars.streetrace_checkpointcounts[raceName] - 1;
		settings.Add(raceId, defaultSplit, raceName, parent);
		settings.CurrentDefaultParent = raceId;
		settings.Add(raceId+" Checkpoint 0", false, "Race start (Countdown end)");
		for (int cp = 1; cp < cpCount; cp++) {
			var cpName = raceId+" Checkpoint "+cp;
			settings.Add(cpName, false, "Checkpoint "+cp);
		}
		settings.Add(raceId+" Checkpoint "+cpCount, false, "Checkpoint "+cpCount+" (Final)");
		settings.SetToolTip(raceId+" Checkpoint "+cpCount, "Split when hitting the final checkpoint. Causes a double split when combined with 'Race Won' setting, but unlike that this will still trigger even if the race has been passed before");
		addMissionCustom(raceName, defaultSplit, "Race won");
	}
	settings.CurrentDefaultParent = null;

	// Stadium Events
	//---------------
	// Max lap counts are hardcoded in here & chiliad challenge. Not very future proof, but I don't 
	// expect any SA DLC any time soon
	settings.Add("Stadium Events", true, "Stadium Events", "Missions2");
	settings.CurrentDefaultParent = "Stadium Events";
	settings.Add("Race 25", true, "8-Track", "Stadium Events");
	settings.CurrentDefaultParent = "Race 25";
	settings.Add("Race 25 Lap 1 Checkpoint 0", false, "Race start (Countdown end)");
	var race25CpCount = vars.streetrace_checkpointcounts["8-Track"] - 1;
	for (int lap = 1; lap <= 12; lap++) {
		for (int cp = 1; cp < race25CpCount; cp++) {
			var cpName = "Race 25 Lap "+lap+" Checkpoint "+cp;
			settings.Add(cpName, false, "Lap "+lap+" Checkpoint "+cp);
		}
		if (lap < 12) { settings.Add("Race 25 Lap "+(lap+1)+" Checkpoint 0", false, "Lap "+lap+" Checkpoint "+race25CpCount+" (Lap complete)"); }
		// Laps gets set to -1 immediately upon finishing the race
		else { settings.Add("Race 25 Lap -1 Checkpoint "+race25CpCount, false, "Lap "+lap+" Checkpoint "+race25CpCount+" (Final)"); }
	}
	settings.SetToolTip("Race 25 Lap -1 Checkpoint "+race25CpCount, "Split when hitting the final checkpoint. Causes a double split when combined with 'Race Won' setting, but unlike that this will still trigger even if the race has been passed before");
	addMissionCustom("8-Track", true, "Race won");

	settings.Add("Blood Ring (Header)", true, "Blood Ring", "Stadium Events");
	settings.CurrentDefaultParent = "Blood Ring (Header)";
	settings.Add("Blood Ring Started", false, "Blood Ring Started");
	addMissionCustom("Blood Ring", true, "Blood Ring Passed");
	settings.CurrentDefaultParent = null;

	settings.Add("Race 26", true, "Dirt Track", "Stadium Events");
	settings.CurrentDefaultParent = "Race 26";
	settings.Add("Race 26 Checkpoint 0", false, "Race start (Countdown end)");
	var race26CpCount = vars.streetrace_checkpointcounts["Dirt Track"] - 1;
	for (int lap = 1; lap <= 6; lap++) {
		for (int cp = 1; cp < race26CpCount; cp++) {
			var cpName = "Race 26 Lap "+lap+" Checkpoint "+cp;
			settings.Add(cpName, false, "Lap "+lap+" Checkpoint "+cp);
		}
		if (lap < 6) { settings.Add("Race 26 Lap "+(lap+1)+" Checkpoint 0", false, "Lap "+lap+" Checkpoint "+race26CpCount+" (Lap complete)"); }
		// Laps gets set to -1 immediately upon finishing the race
		else { settings.Add("Race 26 Lap -1 Checkpoint "+race26CpCount, false, "Lap "+lap+" Checkpoint "+race26CpCount+" (Final)"); }
	}
	settings.SetToolTip("Race 26 Lap -1 Checkpoint "+race26CpCount, "Split when hitting the final checkpoint. Causes a double split when combined with 'Race Won' setting, but unlike that this will still trigger even if the race has been passed before");
	addMissionCustom("Dirt Track", true, "Race won");	

	settings.Add("Kickstart (Header)", true, "Kickstart", "Stadium Events");
	settings.CurrentDefaultParent = "Kickstart (Header)";
	settings.Add("Kickstart Started", false);
	settings.Add("Kickstart Points 26", false, "26 Points achieved");
	settings.SetToolTip("Kickstart Points 26", "Split when reaching the minimum score requirement of 26, independent of checkpoint number.");
	settings.Add("Kickstart Checkpoints", false, "Checkpoints");
	settings.SetToolTip("Kickstart Checkpoints", "Split when hitting each corona, ignoring the worth of each corona. There are 33 coronae total.");
	for (int i = 1; i <= 33; i++) {
		settings.Add("Kickstart Checkpoint "+i, false, "Checkpoint "+i, "Kickstart Checkpoints");
	}
	addMissionCustom("Kickstart", true, "Kickstart Complete");	

	// Vehicle Challenges
	//-------------------
	settings.Add("Vehicle Challenges", true, "Vehicle Challenges", "Missions2");

	// BMX Challenge
	settings.Add("BMX Stunt Challenge (Header)", true, "BMX Stunt Challenge", "Vehicle Challenges");
	settings.CurrentDefaultParent = "BMX Stunt Challenge (Header)";
	settings.Add("BMX Stunt0", false, "Challenge Started");
	for (var i = 1; i <= 19; i++) {
		settings.Add("BMX Stunt"+i, false, "Checkpoint "+i);
	}
	addMissionCustom("BMX Stunt Challenge", true, "BMX Stunt Challenge Complete");	

	// Chilliad Challenge
	settings.Add("Chiliad Challenge", true, "Chiliad Challenge", "Vehicle Challenges");
	settings.CurrentDefaultParent = "Chiliad Challenge";
	settings.Add("Chiliad Challenge #1", true, "Scotch Bonnet Yellow Route");
	settings.Add("Chiliad Challenge #2", true, "Birdseye Winder");
	settings.Add("Chiliad Challenge #3", true, "Cobra Run");
	settings.CurrentDefaultParent = "Chiliad Challenge #1";
	settings.Add("Chiliad Challenge #1 Checkpoint 0", false, "Race start (Countdown end)");
	for (int cp = 1; cp < 18; cp++) { // 19 32 24
		var cpName = "Chiliad Challenge #1 Checkpoint "+cp;
		settings.Add(cpName, false, "Checkpoint "+cp);
	}
	settings.Add("Chiliad Challenge #1 Checkpoint 18", false, "Checkpoint 18 (Final)");
	settings.SetToolTip("Chiliad Challenge #1 Checkpoint 18", "Split when hitting the final checkpoint. Causes a double split when combined with the Challenge Complete setting.");
	settings.Add("Chiliad Challenge #1 Complete", true);
	
	settings.CurrentDefaultParent = "Chiliad Challenge #2";
	settings.Add("Chiliad Challenge #2 Checkpoint 0", false, "Race start (Countdown end)");
	for (int cp = 1; cp < 31; cp++) { // 19 32 24
		var cpName = "Chiliad Challenge #2 Checkpoint "+cp;
		settings.Add(cpName, false, "Checkpoint "+cp);
	}
	settings.Add("Chiliad Challenge #2 Checkpoint 31", false, "Checkpoint 31 (Final)");
	settings.SetToolTip("Chiliad Challenge #2 Checkpoint 31", "Split when hitting the final checkpoint. Causes a double split when combined with the Challenge Complete setting.");
	settings.Add("Chiliad Challenge #2 Complete", true);

	settings.CurrentDefaultParent = "Chiliad Challenge #3";
	settings.Add("Chiliad Challenge #3 Checkpoint 0", false, "Race start (Countdown end)");
	for (int cp = 1; cp < 23; cp++) { // 19 32 24
		var cpName = "Chiliad Challenge #3 Checkpoint "+cp;
		settings.Add(cpName, false, "Checkpoint "+cp);
	}
	settings.Add("Chiliad Challenge #3 Checkpoint 23", false, "Checkpoint 23 (Final)");
	settings.SetToolTip("Chiliad Challenge #3 Checkpoint 23", "Split when hitting the final checkpoint. Causes a double split when combined with the Challenge Complete setting.");
	settings.Add("Chiliad Challenge #3 Complete", true);

	// NRG Challenge
	settings.Add("NRG Stunt Challenge (Header)", true, "NRG-500 Stunt Challenge", "Vehicle Challenges");
	settings.CurrentDefaultParent = "NRG Stunt Challenge (Header)";
	settings.Add("NRG Stunt0", false, "Challenge Started");
	for (var i = 1; i <= 18; i++) {
		settings.Add("NRG Stunt"+i, false, "Checkpoint "+i);
	}
	addMissionCustom("NRG-500 Stunt Challenge", true, "NRG-500 Stunt Challenge Complete");	

	// Schools
	//--------
	settings.Add("Schools", true, "Schools");
	settings.CurrentDefaultParent = "Schools";
	settings.Add("drivingschool_level", true, "Driving School");
	settings.Add("flightschool_level", true, "Pilot School");
	settings.Add("bikeschool_level", true, "Bike School");
	settings.Add("boatschool_level", true, "Boat School");
	
	settings.CurrentDefaultParent = "drivingschool_level";
	settings.Add("Driving School Started", false, "Driving School started for the first time");
	settings.Add("The 360 (Driving School)", false, "The 360");
	settings.Add("The 180 (Driving School)", false, "The 180");
	settings.Add("Whip and Terminate", false);
	settings.Add("Pop and Control", false);
	settings.Add("Burn and Lap", false);
	settings.Add("Cone Coil", false);
	settings.Add("The '90'", false);
	settings.Add("Wheelie Weave", false);
	settings.Add("Spin and Go", false);
	settings.Add("P. I. T. Maneuver", false);
	settings.Add("Alley Oop", false);
	addMissionCustom("Driving School", true, "City Slicking (Driving School Passed)");
	
	settings.CurrentDefaultParent = "flightschool_level";
	settings.Add("Pilot School Started", false, "Pilot School started for the first time");
	addMissions3(6592864 + (1952 * 4), "flightschool_level");
	addMissionCustom("Pilot School", true, "Parachute Onto Target (Pilot School Passed)");
	
	settings.CurrentDefaultParent = "bikeschool_level";
	settings.Add("Bike School Started", false, "Bike School started for the first time");
	settings.Add("The 360 (Bike School)", false, "The 360");  
	settings.Add("The 180 (Bike School)", false, "The 180");
	settings.Add("The Wheelie", false);  
	settings.Add("Jump & Stop", false); 
	settings.Add("The Stoppie", false); 
	addMissionCustom("Bike School", true, "Jump & Stoppie (Bike School Passed)");

	settings.CurrentDefaultParent = "boatschool_level";
	settings.Add("Boat School Started", false, "Boat School started for the first time");
	addMissions3(6592864 + (8189 * 4), "boatschool_level");
	addMissionCustom("Boat School", true, "Land, Sea and Air (Pilot School Passed)");

	// Ammunation Challenge
	//---------------------
	settings.CurrentDefaultParent = "Missions2";
	addMissionsHeader("Shooting Range", 6592864 + (1861 * 4), "Shooting Range");
	settings.CurrentDefaultParent = "Shooting RangeMissions";
	addMissionCustom("Shooting Range Complete", true, "Shooting Range Complete");

	// Gym Moves
	//----------
	settings.CurrentDefaultParent = "Missions2";
	addMissions2Header("Gym Moves", true, "Gym Moves");


	// addMissions2("Challenges", true);

	// Import/Export
	//--------------
	settings.Add("Export Lists", false, "Import/Export", "Missions2");
	foreach (var list in vars.exportLists)
	{
		var listNumber = list.Key+1;
		var parent = "ExportList"+listNumber;
		settings.Add(parent, true, "List "+listNumber, "Export Lists");
		foreach (var item in list.Value)
		{
			settings.Add("Export "+item, false, item, parent);
		}
		var listComplete = "Export List "+listNumber;
		settings.CurrentDefaultParent = parent;
		// settings.Add(listComplete, false, listComplete, parent);
		addMissionCustom(listComplete, true, listComplete+" Complete");
	}
	settings.CurrentDefaultParent = null;

	// Other
	//======
	settings.CurrentDefaultParent = null;
	settings.Add("Other", false);
	settings.CurrentDefaultParent = "Other";
	settings.Add("Plane Flight", false);
	settings.SetToolTip("Plane Flight", "Splits when entering the ticket machine marker for the first time");
	// Add "Properties" before addMissions2, so Wang Cars can be added at the top
	settings.Add("Properties", false);
	settings.Add("Verdant Meadows (Safehouse)", false, "Verdant Meadows (Safehouse)", "Properties");
	settings.Add("Wang Cars (Showroom Bought)", false, "Wang Cars (Showroom Bought)", "Properties");
	addMissions2("Properties", false);
	settings.CurrentDefaultParent = null;
	

	// Collectibles
	//=============
	settings.Add("Collectibles", false, "Collectibles");
	settings.CurrentDefaultParent = "Collectibles";
	foreach (var item in vars.collectibles)
	{
		settings.Add(item.Key+"All", false, item.Key+" (All Done)");
		settings.Add(item.Key+"Each", false, item.Key+" (Each)");
	}
	settings.CurrentDefaultParent = null;

    // Death & Busted Warps
	//=====================
	settings.Add("Warps", false, "Death & Busted Warps");
	settings.Add("BustedWarps", false, "Busted Warps", "Warps");
	settings.Add("DeathWarps", false, "Death Warps", "Warps");
    settings.CurrentDefaultParent = "BustedWarps";
	foreach (var item in vars.bustedWarps) {
		foreach (var item2 in item.Value) {
			var warpName = "BW '" + item.Key + "' to '" + item2 + "'";
			settings.Add(warpName, false);
		}
	}
    settings.CurrentDefaultParent = "DeathWarps";
	foreach (var item in vars.deathWarps) {
		foreach (var item2 in item.Value) {
			var warpName = "DW '" + item.Key + "' to '" + item2 + "'";
			settings.Add(warpName, false);
		}
	}
	settings.CurrentDefaultParent = null;

    // More
    //=====
    settings.Add("Gang Territories", false, "Gang Territories Held");
	settings.SetToolTip("Gang Territories", "Splits when gang territories held stat changes to this number (during RTLS only)");
	settings.CurrentDefaultParent = "Gang Territories";
    settings.Add("gangTerritoriesDuringRTLSOnly", true, "Split during RTLS only");
	settings.SetToolTip("gangTerritoriesDuringRTLSOnly", "Only split gang territories during RTLS. Disable to also split during LS (after Doberman) eg. for the purpose of an All Territories run.");
    for (int i = 1; i <= 379; i++) 
    {
        string name = "GT " + i.ToString();
        if (i == 1) { name += " (Grove Street during Home Coming)";}
        else if (i == 2) { name += " (Gained for free after Home Coming)";}
        else if (i == 3) { name += " (Glen Park during Beat Down on B Dup in common routes)";}
        else if (i == 5) { name += " (Number of territories gained from story missions only)";}
        else if (i == 7) { name += " (Gang Territories Part 1 in common any% NMG routes)";}
        else if (i == 9) { name += " (After Grove 4 Life in common any% NMG routes)";}
        else if (i == 11) { name += " (Starting count on new game)";}
        else if (i == 12) { name += " (Glen Park during Doberman)";}
        else if (i == 17) { name += " (All non-mission territories before Grove 4 Life)";}
        else if (i == 19) { name += " (Requirement to unlock End of the Line)"; }
        else if (i == 53) { name += " (All Captured)"; }
        else if (i == 57) { name += " (All Captured + Varrios Los Aztecas territories)"; }
        else if (i == 378) { name += " (Entire map glitch)"; }
        else if (i == 379) { name += " (Entire map glitch + extra territory glitch)"; }
        settings.Add("GangTerritory"+i.ToString(), false, name);
    }
	settings.CurrentDefaultParent = null;

	// Other Settings
	//===============
	settings.Add("startOnSaveLoad", false, "Start timer when loading save (experimental)");
	settings.SetToolTip("startOnSaveLoad",
		@"This may start the timer too early on New Game, however if you have Reset enabled, 
 it should reset again before the desired start.");
	settings.Add("startOnLoadFinish", false, "Start timer on load complete");
	settings.SetToolTip("startOnLoadFinish",
        "Start the timer when the game finishes loading, before the cutscene begins, as opposed to upon skipping it." + 
        "\nUseful for runs where waiting through the cutscene for a bit can affect gameplay factors." +
        "\nOnly works consistently when starting from a full game restart." +
        "\nWarning: Using this in combination with auto-reset is very prone to accidental resets eg. when accidentally clicking New Game instead of Load Game.");
	settings.Add("doubleSplitPrevention", false, "Double-Split Prevention");
	settings.SetToolTip("doubleSplitPrevention",
        @"Impose cooldown of 2.5s between auto-splits.
This may not work for all types of splits.");

	#endregion

	//=============================================================================
	// Other Stuff
	//=============================================================================
	refreshRate = 30;
	vars.waiting = false;
}

init
{
	//=============================================================================
	// Version Detection
	//=============================================================================
	vars.enabled = true;
	var versionValue = 38079;
	int versionOffset = 0;

	int playingTimeAddr = 	0x77CB84;
	int startAddr =		0x77CEDC;
	int threadAddr =	0x68B42C;
	int loadingAddr =	0x7A67A5;
	int playerPedAddr =	0x77CD98;

	// Detect Version
	//===============
	// Look for both the value in the memory and the module size to determine the
	// version.
	//
	// Checking the memory value doesn't seem to work for the more recent Steam
	// version at all. In addition to that, it also doesn't seem to work if the
	// game is still checking the CD (if you're not using Steam or NoCD version).
	//
	// The memory values and associated versions/offsets where taken from the
	// AHK Autosplitter and checked and extended as possible.

	int moduleSize = modules.First().ModuleMemorySize;
	if (current.version_100_EU == versionValue
		|| current.version_100_US == versionValue
		|| moduleSize == 18313216)
	{
		versionOffset = 0;
		version = "1.0";
	}
	if (current.version_101_EU == versionValue
		|| current.version_101_US == versionValue
		|| moduleSize == 34471936)
	{
		versionOffset = 0x2680;
		version = "1.01";
	}
	if (moduleSize == 17985536)
	{
		// This may be some kind of Austrian version
		versionOffset = 0x2680;
		version = "2.00";
	}
	if (current.version_300_Steam == versionValue
		|| moduleSize == 9691136)
	{
		// Older Steam version, still showing 3.00 in the menu and may work with
		// just the offset (since 1.01 works like that and they seem similiar)
		versionOffset = 0x75130;
		version = "3.00 Steam";
	}
	if (current.version_101_Steam == versionValue)
	{
		// Otherwise unknown version
		versionOffset = 0x75770;
		version = "1.01 Steam";
	}
	if (moduleSize == 9981952)
	{
		// More recent Steam Version (no version in menu), this is referred to
		// as just "Steam"
		versionOffset = 0x77970;
		version = "Steam";
        playingTimeAddr = 0x80FD74;
		startAddr =	0x810214;
		threadAddr =	0x702D98;
		loadingAddr =	0x833995;
		playerPedAddr =	0x8100D0;
	}

	// Version detected
	//=================

	if (version == "")
	{
		version = "<unknown>";
		vars.enabled = false;
	}

	// Extra variable because versionOffset was different from offset before (keep it
	// like this just in case)
	int offset = versionOffset;

	// Apply offset, except for Steam, since that version has completely separate addresses
	if (version != "Steam") {
		playingTimeAddr += offset;
		startAddr += offset;
		threadAddr += offset;
		loadingAddr += offset;
		playerPedAddr += offset;
	}
	
	

	//=============================================================================
	// Memory Watcher
	//=============================================================================

	// Add missions as watched memory values
	vars.watchers = new MemoryWatcherList();

	// Same address for several different splits
	foreach (var item in vars.missions) {
		vars.watchers.Add(
			new MemoryWatcher<int>(
				new DeepPointer(item.Key+offset)
			) { Name = item.Key.ToString() }
		);

		// Check if setting for each mission exists (this will output a message to debug if not,
		// for development)
		foreach (var m in item.Value) {
			if (settings[m.Value]) { }
		}
	}

	// Different address for each split
	foreach (var item in vars.missions2) {
		foreach (var m in item.Value) {
			vars.watchers.Add(
				new MemoryWatcher<int>(
					new DeepPointer(m.Key+offset)
				) { Name = m.Value }
			);

			if (settings[m.Value]) { }
		}
	}

	// Mid-Mission Events
	foreach (var item in vars.missions3) {
		vars.watchers.Add(
			new MemoryWatcher<int>(
				new DeepPointer(item.Key+offset)
			) { Name = item.Key.ToString() }
		);

		// Check if setting for each mission exists (this will output a message to debug if not,
		// for development)
		foreach (var m in item.Value) {
			if (settings[m.Value]) { }
		}
	}

	// Other bools
	foreach (var item in vars.missions4) {
		vars.watchers.Add(
			new MemoryWatcher<int>(
				new DeepPointer(item.Key+offset)
			) { Name = item.Value }
		);

		if (settings[item.Value]) { }
	}
	
	// Add global variables for mid-mission events
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (1799 * 4)+offset)) { Name = "chiliad_race" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (1801 * 4)+offset)) { Name = "chiliad_done" }); // $MISSION_CHILIAD_CHALLENGE_PASSED
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (189 * 4)+offset)) { Name = "courier_active" }); // $ONMISSION_COURIER
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (8014 * 4)+offset)) { Name = "eotlp3_chase" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (8250 * 4)+offset)) { Name = "kickstart_checkpoints" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (8262 * 4)+offset)) { Name = "kickstart_points" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (1510 * 4)+offset)) { Name = "intro_newgamestarted" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (5353 * 4)+offset)) { Name = "intro_state" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (352 * 4)+offset)) { Name = "race_index" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (10933 * 4)+offset)) { Name = "valet_carstopark" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (247 * 4)+offset)) { Name = "schools_currentexercise" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (726 * 4)+offset)) { Name = "stunt_type" }); // $STUNT_MISSION_TYPE
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (8267 * 4)+offset)) { Name = "stunt_timer" });

	// Local variables. These are used across multiple missions and it's hard to tell which without just testing it
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x649518+offset)) { Name = "chiliad_checkpoints" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x649534+offset)) { Name = "courier_checkpoints" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x649540+offset)) { Name = "courier_levels" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x649700+offset)) { Name = "courier_city" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648B68+offset)) { Name = "freight_stations" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648D78+offset)) { Name = "races_checkpoint" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648D70+offset)) { Name = "races_badlandscheckpoint" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648D64+offset)) { Name = "races_flycheckpoint" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648D90+offset)) { Name = "races_stadiumcheckpoint" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x691424+offset)) { Name = "races_laps" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648A4C+offset)) { Name = "stunt_checkpoint" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648B08+offset)) { Name = "trucking_leftcompound" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x68F3B4+offset)) { Name = "valet_level" }); 

	// Add global variables that aren't missions
    vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x7791D0+offset)) { Name = "gang_territories" });
	// vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (352 * 4)+offset)) { Name = "player_current_city" }); // $352

	// This means loading from a save and such, not load screens (this doesn't work with Steam since I couldn't find the address for it)
	vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(loadingAddr)) { Name = "loading" });

	// Values that have a different address defined for the Steam version
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(playerPedAddr, 0x530)) { Name = "pedStatus" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(playingTimeAddr)) { Name = "playingTime" });
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(startAddr)) { Name = "started" });
	vars.watchers.Add(new StringWatcher(new DeepPointer(threadAddr, 0x8), 10) { Name = "thread" });


	// Weird variables
	//================

	// $2332 or $CARMOD_DISABLED_FLAG gets set to 1 during the following missions:
	// Burning Desire, Home Invasion, Races, Architectural Espionage, 
	// Breaking the Bank at Caligula's, Burglaries. 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (2332 * 4)+offset)) { Name = "carmod_disabled_flag" });
	// $10493 is set to 1 at the start of a race and 0 at the end. It also gets set by
	// Explosive Situation, the only other mission to do this. Its purpose is to disable
	// entering cranes. 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (10493 * 4)+offset)) { Name = "on_race_or_explosive_situation" });
	
	// Collectibles
	//=============
	// Separate Steam version addresses are defined in vars.collectibles and
	// chosen here if Steam version was detected.
	foreach (var item in vars.collectibles) {
		var type = item.Key;
		var addr = item.Value[0]+offset;
		if (version == "Steam") {
			addr = item.Value[1];
		}
		vars.watchers.Add(
			new MemoryWatcher<int>(
				new DeepPointer(addr)
			) { Name = type }
		);
	}

	// Export Lists
	//=============

	// vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x64A9C4+offset)) { Name = "exportList" });
	var exportBaseAddr = 0x64A9F0+offset;
	for (int i = 0; i < 10; i++)
	{
		var address = exportBaseAddr + i*4;
		//print(address.ToString("X"));
		vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(address)) { Name = "export"+i });
	}

	vars.watchers.UpdateAll(game);

	//=============================================================================	
	// Utility functions
	//=============================================================================

	/*
	 * Check if splitting should occur based on whether this split
	 * has already been split since the timer started or is on the
	 * blacklist.
	 * 
	 * If this is true (the split should occur), the split
	 * is also added to the list of already split splits. (Kappa b)
	 * 
	 * Instead of outright returning true or false, this function
	 * now stores the name of splits to occur in a list, as in some
	 * cases when 'prevent double-splitting' is off some double splits
	 * will be prevented anyway. So we need to make sure that the 
	 * entire split{} action is run and not aborted mid-way upon the
	 * first true TrySplit.
	 */

	vars.splitBuffer = new List<string>();
	Func<string, bool> TrySplit = (splitId) => {
		if (!settings[splitId]) {
			vars.DebugOutput("Split Prevented (Disabled in Settings): "+splitId);
			return false;
		}
		if (!vars.split.Contains(splitId)) {
			vars.split.Add(splitId);
			/*
			 * Double split prevention (mostly for duping). This is set to 2.5s so that dupes should
			 * (hopefully) not split spice, whereas close-on splits like the Deathwarp to Angel Pine
			 * after Body Harvest still do get split.
			 *
			 * Make sure to always add this to the already executed splits, so that cooldown-prevented
			 * splits are not split if a savegame is loaded and the dupe done again.
			 */
			if (!settings["doubleSplitPrevention"] || Environment.TickCount - vars.lastSplit > 2500) {
				vars.DebugOutput("Split: "+splitId);
				vars.lastSplit = Environment.TickCount;
				vars.splitBuffer.Add(splitId);
				return true;
			}
			else {
				vars.DebugOutput("Split Prevented (Cooldown): "+splitId);
				return false;
			}
		}
		vars.DebugOutput("Split Prevented (Already Done): "+splitId);
		return false;
	};
	vars.TrySplit = TrySplit;

	/*
	 * Check if the given mission (the name has to be exact) has
	 * already been passed, based on the current memory value.
	 * 
	 * Returns true if the mission should already have been passed,
	 * false otherwise.
	 */
	Func<string, bool> MissionPassed = m => {
		foreach (var item in vars.missions) {
			foreach (var item2 in item.Value) {
				if (item2.Value == m) {
					int currentValue = vars.watchers[item.Key.ToString()].Current;
					vars.DebugOutput("Check "+m+": "+currentValue+" >= "+item2.Key.ToString());
					return currentValue >= item2.Key;
				}
			}
		}
        foreach (var item in vars.missions2) {
			foreach (var item2 in item.Value) {
				if (item2.Value == m) {
					int currentValue = vars.watchers[item2.Value.ToString()].Current;
					vars.DebugOutput("Check2 "+m+": "+currentValue+" >= 1");
					return currentValue >= 1;
				}
			}
		}
		foreach (var item in vars.missions4) {
			if (item.Value == m) {
				int currentValue = vars.watchers[item.Value.ToString()].Current;
				vars.DebugOutput("Check4 "+m+": "+currentValue+" >= 1");
				return currentValue >= 1;
			}
		}
		foreach (var item in vars.exportLists) {
			var list = 0;
			if (vars.Passed("Export List 3")) {
				list = 3;
			}
			else if (vars.Passed("Export List 2")) {
				list = 2;
			}
			else if (vars.Passed("Export List 1")) {
				list = 1;
			}	
			for (int i = 0; i < item.Value.Count; i++) {
				if (item.Value[i] == m) {
					if (list > item.Key) {
						vars.DebugOutput("CheckE "+m+": On list "+item.Key+" < "+list);
						return true;
					}
					if (list < item.Key) {
						vars.DebugOutput("CheckE "+m+": On list "+item.Key+" < "+list);
						return false;
					}
					int currentValue = vars.watchers["export"+i].Current;
					vars.DebugOutput("CheckE "+m+": "+currentValue+" >= 1");
					return currentValue >= 1;
				}
			}
		}
		vars.DebugOutput("Mission not found: "+m);
		return false;
	};
	vars.Passed = MissionPassed;
}

update
{
	//=============================================================================
	// General Housekeeping
	//=============================================================================
	// Disable all timer control actions if version was not detected
	if (!vars.enabled)
		return false;

	// Update always, to prevent splitting after loading (if possible, doesn't seem to be 100% reliable)
	vars.watchers.UpdateAll(game);

	// Clear list of already executed splits if timer is reset
	if (timer.CurrentPhase != vars.PrevPhase)
	{
		if (timer.CurrentPhase == TimerPhase.NotRunning)
		{
			vars.split.Clear();
			vars.DebugOutput("Cleared list of already executed splits");
		}
		vars.PrevPhase = timer.CurrentPhase;
	}

	//print(vars.watchers["pedStatus"].Current.ToString());
}

split
{
	//=============================================================================
	// Split prevention
	//=============================================================================
	if (vars.watchers["loading"].Current) {
		vars.DebugOutput("Loading");
		vars.lastLoad = Environment.TickCount;
		return false;
	}
	if (Environment.TickCount - vars.lastLoad < 500) {
		// Prevent splitting shortly after loading from a save, since this can
		// sometimes occur because memory values change
		if (!vars.waiting)
		{
			vars.DebugOutput("Wait..");
			vars.waiting = true;
		}
		return false;
	}
	if (vars.waiting)
	{
		vars.DebugOutput("Done waiting..");
		vars.waiting = false;
	}

	//=============================================================================
	// Splits
	//=============================================================================

	// Completing a mission
	//=====================
	foreach (var item in vars.missions) {
		var value = vars.watchers[item.Key.ToString()];
		if (value.Current > value.Old && item.Value.ContainsKey(value.Current)) {
			string splitId = item.Value[value.Current];
			vars.TrySplit(splitId);
		}
	}

	// More missions
	//==============
	foreach (var item in vars.missions2) {
		foreach (var m in item.Value) {
			var value = vars.watchers[m.Value];
			// Some values changes from 0 -> 2, so check for > 0
			if (value.Current > 0 && value.Old == 0)
			{
				vars.TrySplit(m.Value);
			}
		}
	}

	// Split for each level of a vehicle oddjob
	//=========================================
	foreach (var item in vars.missions3) {
		var value = vars.watchers[item.Key.ToString()];
		if (value.Current > value.Old && item.Value.ContainsKey(value.Current)) {
			string splitId = item.Value[value.Current];
			vars.TrySplit(splitId);
		}
	}

	// Misc Non-mission booleans to split for
	//=========================================
	foreach (var item in vars.missions4) {
		var value = vars.watchers[item.Value];
		// Some values changes from 0 -> 2, so check for > 0
		if (value.Current > 0 && value.Old == 0)
		{
			vars.TrySplit(item.Value);
		}
	}

	// Starting a certain mission
	//===========================
	// This requires the feature of splitting every split only once, because
	// it only checks the first thread, which can sometimes change. Even when
	// checking all threads, it could cause issues if a mission is restarted
	// (e.g. if the mission failed, rather than an earlier Save loaded, where
	// splitting again may or may not be actually wanted).
	//
	// This is relatively lazy and simply checks for the first thread in the
	// list, which probably is the thread that was last started.
	//
	// 'thread' var is also used for mid-mission event splits checks. Don't
	// move this down.
	var thread = vars.watchers["thread"];
	var threadChanged = thread.Current != thread.Old;
	if (threadChanged)
	{
		foreach (var item in vars.startMissions)
		{
			if (thread.Current == item.Key)
			{
				vars.TrySplit(item.Value);
			}
		}
	}

	// Mid-Mission Events
	//===================
	// Custom code to check various mid-mission events. Most of them involving counters 
	// or local variables that require special attention.
	#region mission events

	// Chiliad Challenge
	//==================
	// "chiliad_race" contains the next race to be started (1-3), but also repeats
	// when you do the races again (changes to 1 on finishing the last race).
	// "chiliad_done" changes from 0 to 1 when all races have been done.
	//
	var chiliad_race = vars.watchers["chiliad_race"];
	if (chiliad_race.Current != chiliad_race.Old) {
		vars.TrySplit("Chiliad Challenge #"+chiliad_race.Old+" Complete");
	}
	var chiliad_checkpoints = vars.watchers["chiliad_checkpoints"];
	if (chiliad_checkpoints.Current > chiliad_checkpoints.Old) {
		if (thread.Current == "mtbiker") {
			vars.TrySplit("Chiliad Challenge #"+chiliad_race.Current+" Checkpoint "+chiliad_checkpoints.Current);
		}
	}

	// Courier
	//========
	// started, completed levels, & packages delivered
	// Courier_city is set to 0 for an extra frame, which is meaningless. So we want to check it first
	// and only then check if it got changed because of a courier start. Honestly just using the start
	// threads monitor would be easier, but we need to watch these variables anyway.
	var courier_active = vars.watchers["courier_active"];
	var courier_city = vars.watchers["courier_city"];
	if (courier_city.Current != courier_city.Old) {
		if (courier_city.Current != 0 && courier_active.Current == 1) {
			vars.TrySplit("courier_"+courier_city.Current+"_started");
		}
	}
	if (courier_active.Current == 1) {
		var courier_levels = vars.watchers["courier_levels"];
		if (courier_levels.Current > courier_levels.Old) {
			vars.TrySplit("courier_" + courier_city.Current + "_level_" + courier_levels.Current);
		}
		var courier_checkpoints = vars.watchers["courier_checkpoints"];
		if (courier_checkpoints.Current > courier_checkpoints.Old) {
			vars.TrySplit("courier_" + courier_city.Current + "_level_" + courier_levels.Current + "_delivery_" + courier_checkpoints.Current);
		}
	}

	// End of the Line
	//================
	// Any% ending point + other cutscenes
	var eotlp3_chase = vars.watchers["eotlp3_chase"];
	if (eotlp3_chase.Current > eotlp3_chase.Old) {
		if (vars.Passed("End of the Line Part 2")) {
			vars.TrySplit("eotlp3_chase" + eotlp3_chase.Current.ToString());
		}
	}

	// Freight
	//========
	// Split on each train station, except for the 5th one, which is the last one 
	// causing level completion which will split already anyway.
	var freight_stations = vars.watchers["freight_stations"];
	if (freight_stations.Current > freight_stations.Old && freight_stations.Current < 5) {
		// Do a check we're actually on Freight, since this is a local variable used for multiple missions
		if (vars.Passed("freight_started")) {
			var freightlevel = "1 ";
			if (vars.Passed("Freight Level 1")) {
				freightlevel = "2 ";
			}
			var splitName = "freight_station " + freightlevel + freight_stations.Current;
			vars.TrySplit(splitName);
		}
	}

	// Kickstart
	//==========
	var kickstart_checkpoints = vars.watchers["kickstart_checkpoints"];
	var kickstart_points = vars.watchers["kickstart_points"];
	if (kickstart_checkpoints.Current > kickstart_checkpoints.Old) {
		vars.TrySplit("Kickstart Checkpoint "+kickstart_checkpoints.Current);
	}
	if (kickstart_points.Current >= kickstart_points.Old && kickstart_points.Current >= 26 && kickstart_points.Old < 26) {
		vars.TrySplit("Kickstart Points 26");
	}

	// In the beginning
	//=================
	// Cutscene skipped
	var playingTime = vars.watchers["playingTime"];
	var intro_state = vars.watchers["intro_state"];
    if (intro_state.Current == 1 && intro_state.Old == 0 && playingTime.Current > 2000 && playingTime.Current < 60*1000) {
		vars.TrySplit("itb_cutsceneskipped");
	}

	// Races
	//======
	// Split for each checkpoint
	// races_checkpoint is your checkpoint count, except for during stadium events, where it
	// the CP count of some random opponent. Yours is races_stadiumcheckpoint. For some reason
	// fly races have a separate checkpoint counter.
	// We need to first make sure we are on a race. These two variables are shared with other
	// missions, but the combination of the two only happens during races. I'm not sure if we
	// can just use thread start var for this. Races go all over the map and there might be
	// hidden funny stuff. Also not sure how that works with Cesar's race missions.
	var on_race_or_explosive_situation = vars.watchers["on_race_or_explosive_situation"];
	var carmod_disabled_flag = vars.watchers["carmod_disabled_flag"];
	if (carmod_disabled_flag.Current == 1 && on_race_or_explosive_situation.Current == 1) {
		var race_index = vars.watchers["race_index"];
		if (race_index.Current == 7 || race_index.Current == 8) {
			// Badlands A & B
			var races_badlandscheckpoint = vars.watchers["races_badlandscheckpoint"];
			if (races_badlandscheckpoint.Current > races_badlandscheckpoint.Old) {
				var splitName = "Race "+race_index.Current+" Checkpoint "+races_badlandscheckpoint.Old;
				vars.TrySplit(splitName);
			}
		}
		else if (race_index.Current >= 19 || race_index.Current < 25) {
			// Fly races
			var races_flycheckpoint = vars.watchers["races_flycheckpoint"];
			if (races_flycheckpoint.Current > races_flycheckpoint.Old) {
				var splitName = "Race "+race_index.Current+" Checkpoint "+races_flycheckpoint.Old;
				vars.TrySplit(splitName);
			}
		}
		else if (race_index.Current < 19) {
			// Normal races
			var races_checkpoint = vars.watchers["races_checkpoint"];
			if (races_checkpoint.Current > races_checkpoint.Old) {
				var splitName = "Race "+race_index.Current+" Checkpoint "+races_checkpoint.Old;
				vars.TrySplit(splitName);
			}
		}
		else if (race_index.Current == 25 || race_index.Current == 26) {
			// Stadium races
			var races_stadiumcheckpoint = vars.watchers["races_stadiumcheckpoint"];
			var races_laps = vars.watchers["races_laps"];
			// Invisible intralap checkpoints in stadium races	
			if (races_stadiumcheckpoint.Current > races_stadiumcheckpoint.Old) {
				var splitName = "Race "+race_index.Current+" Lap "+races_laps.Current+" Checkpoint "+races_stadiumcheckpoint.Old;
				vars.TrySplit(splitName);
			}
			// Stadium race laps
			if (races_laps.Current > races_laps.Old && races_laps.Old != -1) {
				var splitName = "Race "+race_index.Current+" Lap "+races_laps.Current+" Checkpoint 0";
				vars.TrySplit(splitName);
			}

		}	
	}

	// Schools
	//========
	// Current exercise is used by driving and boat school
	var schools_currentexercise = vars.watchers["schools_currentexercise"];
	if (schools_currentexercise.Current > schools_currentexercise.Old) {
		if (thread.Current == "dskool" && !vars.Passed("Driving School")) {
			if (schools_currentexercise.Old == 1) { vars.TrySplit("The 360 (Driving School)"); }
			else if (schools_currentexercise.Old == 2) { vars.TrySplit("The 180 (Driving School)"); }
			else if (schools_currentexercise.Old == 4) { vars.TrySplit("Whip and Terminate"); }
			else if (schools_currentexercise.Old == 5) { vars.TrySplit("Pop and Control");}
			else if (schools_currentexercise.Old == 7) { vars.TrySplit("Burn and Lap");}
			else if (schools_currentexercise.Old == 9) { vars.TrySplit("Cone Coil");}
			else if (schools_currentexercise.Old == 10) { vars.TrySplit("The '90'");}
			else if (schools_currentexercise.Old == 11) { vars.TrySplit("Wheelie Weave");}
			else if (schools_currentexercise.Old == 13) { vars.TrySplit("Spin and Go");}
			else if (schools_currentexercise.Old == 14) { vars.TrySplit("P. I. T. Maneuver");}
			else if (schools_currentexercise.Old == 15) { vars.TrySplit("Alley Oop");}
			// City Slicking not included because this variable indicates current exercise. Use the school finish var
		}
		else if (thread.Current == "bskool" && !vars.Passed("Bike School")) {
			if (schools_currentexercise.Old == 1) { vars.TrySplit("The 360 (Bike School)"); }
			else if (schools_currentexercise.Old == 2) { vars.TrySplit("The 180 (Bike School)"); }
			else if (schools_currentexercise.Old == 3) { vars.TrySplit("The Wheelie"); }
			else if (schools_currentexercise.Old == 4) { vars.TrySplit("Jump & Stop");}
			else if (schools_currentexercise.Old == 5) { vars.TrySplit("The Stoppie");}
			// Jump & Stoppie not included because this variable indicates current exercise. Use the school finish var
		}
	}
	
	// Taxi Driver
	//============
	// 51+ fares
	var taxiFrs = vars.watchers[(6592864 + (180 * 4)).ToString()];
	if (taxiFrs.Current > taxiFrs.Old && taxiFrs.Old >= 13 && settings["taxidriver51plus"]) { 
		// Need to keep track of already split splits seperately from the setting
		var splitName = "taxifare"+taxiFrs.Old;
		vars.TrySplit(splitName);
	}

	// Stunt Challenge (BMX / NRG-500)
	//================================
	// $8267 is the timer for the mission. At the start of a mission it gets set to the ingame time
	// and stays there for the duration of the cutscene. It is only used on these missions.
	var stunt_timer = vars.watchers["stunt_timer"];
	if (stunt_timer.Current > stunt_timer.Old + 10001) {
		var stunt_type = vars.watchers["stunt_type"].Current;
		var name = "BMX Stunt";
		if (stunt_type == 1) { name = "NRG Stunt"; }
		vars.TrySplit(name + "0");		
	}
	var stunt_checkpoint = vars.watchers["stunt_checkpoint"];
	if (stunt_checkpoint.Current > stunt_checkpoint.Old) {
		var stunt_type = vars.watchers["stunt_type"].Current;
		var name = "BMX Stunt";
		if (stunt_type == 1) { name = "NRG Stunt"; }
		vars.TrySplit(name + stunt_checkpoint.Current);
	}

	// Trucking
	//=========
	// Start & Leaving the compound
	var trucking_current = vars.watchers[0x6518DC.ToString()].Current + 1;
	if (threadChanged && thread.Current == "truck") {
		var splitName = "trucking_start"+trucking_current;
		vars.TrySplit(splitName);
	}
	else if (thread.Current == "truck") {
		var trucking_leftcompound = vars.watchers["trucking_leftcompound"];
		if (trucking_leftcompound.Current > trucking_leftcompound.Old) {
			var splitName = "trucking_leftcompound"+trucking_current;
			vars.TrySplit(splitName);
		}
	}

	// Valet Parking
	//==============
	// Levels
	var valet_level = vars.watchers["valet_level"];
	if (valet_level.Current > valet_level.Old && valet_level.Old != 0) {
		if (thread.Current == "valet") {
			var splitName = "valet_level" + valet_level.Old;
			vars.TrySplit(splitName);
		}
	}
	var valet_carstopark = vars.watchers["valet_carstopark"];
	if (valet_carstopark.Current < valet_carstopark.Old && valet_carstopark.Current != 0 && valet_carstopark.Old != 0) {
		var splitName = "valet_level" + valet_level.Current + "_car" + valet_carstopark.Current;
		vars.TrySplit(splitName);
	}

	// Vigilante
	//==========
	// Levels 13+
	var vigiLvl = vars.watchers[(6592864 + (8227 * 4)).ToString()];
	if (vigiLvl.Current > vigiLvl.Old && vigiLvl.Old >= 13 && settings["vigilantelevel13plus"]) { 
		// Need to keep track of already split splits seperately from the setting
		var splitName = "vigilantelvl"+vigiLvl.Old;
		vars.TrySplit(splitName);
	}

	#endregion

	// Split collectibles
	//===================
	foreach (var item in vars.collectibles) {
		var value = vars.watchers[item.Key.ToString()];
		if (value.Current > value.Old) {
			var type = item.Key;
			if (settings[type+"All"])
			{
				int max = 50;
				if (type == "Tags")
					max = 100;
				if (type == "Stunts (Completed)")
					max = 70;
				if (value.Current == max && value.Old == max-1)
				{
					vars.TrySplit(type+"All");
				}
			}
			if (settings[type+"Each"]) {
				// Need to keep track of already split splits seperately from the setting
				var splitName = type+" "+value.Current;
				if (!vars.split.Contains(splitName))
				{
					vars.split.Add(splitName);
					vars.DebugOutput("Split: "+splitName);
					vars.splitBuffer.Add(splitName); // Change this to vars.TrySplit once I updated collectibles
				}
				else {
					vars.DebugOutput("Split Prevented (Already Done): "+splitName);
				}
			}
			else {
				vars.DebugOutput("Split Prevented (Disabled in Settings): "+type+" (Each)");
			}
		}
	}

	// Busted/Deathwarp
	//=================
	var pedStatus = vars.watchers["pedStatus"];
	if (pedStatus.Current != pedStatus.Old) {
		if (pedStatus.Current == 63) // Busted
		{
			foreach (var item in vars.bustedWarps) {
				if (vars.Passed(item.Key)) {
					foreach (var item2 in item.Value) {
						if (!vars.Passed(item2)) {
							vars.TrySplit("BW '" + item.Key + "' to '" + item2 + "'");
						}
					}
				}
			}
		}
		if (pedStatus.Current == 55) // Wasted
		{
			foreach (var item in vars.deathWarps) {
				if (vars.Passed(item.Key)) {
					foreach (var item2 in item.Value) {
						if (!vars.Passed(item2)) {
							vars.TrySplit("DW '" + item.Key + "' to '" + item2 + "'");
						}
					}
				}
			}
		}
	}

	// Import/Export Lists
	//====================
	// The three lists all contain 10 vehicles, which have their exported state
	// stored in an array, so basicially 10 values that change from 0 to 1 when
	// that car is exported. This is per list, so which vehicles the values
	// refer to changes based on which list is active.
	//
	for (int i = 0; i < 10; i++)
	{
		// Check if this vehicle has just been exported
		var vehicle = vars.watchers["export"+i];
		bool shouldSplit = false;
		int vehicleId = i;
		var exportList = 0;
		if (vehicle.Current == 1 && vehicle.Old == 0)
		{
			shouldSplit = true;
			if (!vars.Passed("Export List 3"))
			{
				if (vars.Passed("Export List 2")) {
					exportList = 2;
				}
				else if (vars.Passed("Export List 1")) {
					exportList = 1;
				}
			}
			else {
				exportList = 2;
				shouldSplit = true;
			}
		}
		if (vehicle.Current == 0 && vehicle.Old == 1) {
			// List changed. We need to do this check in case someone has a split
			// only for exporting a specific vehicle (eg. Slamvan), but not for
			// completing its entire list. In those cases, if the Slamvan were to
			// be the last vehicle to delivered on the list, no split would trigger.
			// This causes double splits if both are ticked, but would be caught by
			// double split prevention so it's fine.
			shouldSplit = true;	
			if (vars.Passed("Export List 3"))
			{
				exportList = 2;
			}
			else if (vars.Passed("Export List 2")) {
				exportList = 1;
			}		
		}
		if (shouldSplit)
		{
			vars.TrySplit("Export "+vars.exportLists[exportList][vehicleId]);
		}
	}

    // Gang Territories
    //=================
    // Gang Territories as tracked by the "Territories Held" stat.
    // Gang Territories only split if Home Coming is completed (RTLS).
    var gangTerritoriesHeld = vars.watchers["gang_territories"];
    if (gangTerritoriesHeld.Current > gangTerritoriesHeld.Old) {
    	if (vars.Passed("Home Coming") || !settings["gangTerritoriesDuringRTLSOnly"]) {
            var territoriesHeld = gangTerritoriesHeld.Current;
            vars.TrySplit("GangTerritory" + territoriesHeld.ToString());
        }
    }

	if (vars.splitBuffer.Count > 0) {
		vars.splitBuffer.RemoveAt(0);
		return true;
	}
}

start
{
	//=============================================================================
	// Starting Timer
	//=============================================================================

	var playingTime = vars.watchers["playingTime"];
	var intro_newgamestarted = vars.watchers["intro_newgamestarted"];
	var intro_state = vars.watchers["intro_state"];
	var loading = vars.watchers["loading"];

	/*
	 * Note:
	 * Tried to check which menu is selected, which at New Game usually seems to be 6, but doesn't really
	 * seem to work with the Steam version, so that was removed. (1.0 0x7A68A5, Steam 0x5409BC)
	 */

    // Timer start before cutscene
    //============================
    /*
     * intro_newgamestarted gets set to 1 almost first thing in the INITIAL thread. It never gets used for anything but gets
     * set to 0 during Learning to Fly and Dam and Blast only. Start the timer when this value gets set.
     * To prevent resets from happening during a saveload, or during aforementioned missions, check if
     * game timer is low enough (60s). The variable in question is commonly known as $1510. Note: This does not
     * consistently activate when doing new game from the pause menu. This shouldn't be a big issue since speedrun
     * rules dictate starting from a fresh game boot anyway.
     */
    if (settings["startOnLoadFinish"] && intro_newgamestarted.Current != intro_newgamestarted.Old && intro_newgamestarted.Old == 0 && playingTime.Current < 60*1000) {
        return true;
    }

	// New Game
	//=========
	/*
	 * intro_state is a variable only used in the intro mission, changing from
	 * 0 to 1 when the cutscene is skipped. It gets set to other values during the
	 * intro cutscene, so the timer will only start when you skip the cutscene
	 * within the first 90s or so.
	 *
	 * Since the value seems to stay at 1 until after, but not sometime later in
	 * the game, loading a Save can sometimes trigger New Game, so also check if
	 * playingTime is low enough (60s).
	 *
	 * In the commonly used decompiled main.scm, this should be the variable $5353.
	 */
	if (!settings["startOnLoadFinish"] && intro_state.Current == 1 && intro_state.Old == 0 && playingTime.Current < 60*1000)
	{
		if (settings.StartEnabled)
		{
			// Only output when actually starting timer (the return value of this method
			// is only respected by LiveSplit when the setting is actually enabled)
			vars.DebugOutput("New Game"+playingTime.Current);
		}
		return true;
	}
	

	// Loaded Save
	//============
	// Optional starting the timer when loading a save. The "loading" value seems
	// to only be true when loading a game initially (so not loading screens during
	// the game).
	//
	if (settings["startOnSaveLoad"] && !loading.Current && loading.Old)
	{
		vars.lastLoad = Environment.TickCount;
		if (settings.StartEnabled)
		{
			vars.DebugOutput("Loaded Save");
		}
		return true;
	}
}

reset
{
	//=============================================================================
	// Resetting Timer
	//=============================================================================

	var playingTime = vars.watchers["playingTime"];
	var intro_newgamestarted = vars.watchers["intro_newgamestarted"];
	var intro_state = vars.watchers["intro_state"];
	/*
	 * Previously the playingTime was used to reset the timer, although it seems like for
	 * different people the game started at different playingTime values (probably depending
	 * on game version and loading times), so sometimes the timer would be reset after the
	 * game started.
	 *
	 * This is now using the same value changes as for starting the timer, so the time
	 * should be reset (if running) and started in the same update iteration. Still check
	 * a reasonable playingTime interval though, so that there is no chance of the timer
	 * being reset midgame.
	 *
	 * With this method, the timer resets even later than before, making accidental resets
	 * when e.g. starting a new game instead of loading a save even less a problem (because
	 * you have enough time to ESC before the timer is reset).
	 */

    if (settings["startOnLoadFinish"] && intro_newgamestarted.Current != intro_newgamestarted.Old && intro_newgamestarted.Old == 0 && playingTime.Current < 60*1000) {
        return true;
    }

    if (!settings["startOnLoadFinish"] && intro_state.Current == 1 && intro_state.Old == 0 && playingTime.Current > 2000 && playingTime.Current < 60*1000)
	{
		if (settings.ResetEnabled)
		{
			// Only output when actually resetting (the return value of this method
			// is only respected by LiveSplit when the setting is actually enabled)
			vars.DebugOutput("Reset");
		}
		return true;
	}
}
