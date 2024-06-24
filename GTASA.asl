//

/* This is originally by Tduva:
 * https://github.com/tduva/LiveSplit-ASL/blob/master/GTASA.asl
 *
 * Github doesn't let me fork individual files, so I have to do it like this
 * instead...
 * /

/* This could come in useful:
 * https://docs.google.com/spreadsheets/d/15iu5n86RzrQNZib-sL_FQRU6hcIab3VjWMak_Oj88HM/edit#gid=1480623135
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
		{"Tag",	new List<int> {0x69AD74, 0x71258C}},
		{"Snapshot",	new List<int> {0x7791BC, 0x80C3E4}},
		{"Horseshoe", 	new List<int> {0x7791E4, 0x80C40C}},
		{"Oyster",	new List<int> {0x7791EC, 0x80C414}},
		{"Completed Stunt Jump", new List<int> {0x779064, 0x80C28C}},
		{"Found Stunt Jump", new List<int> {0x779064, 0x80C28C}},
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
			{2, "Wu Zi Mu Starting Cutscene Ended"},
			{3, "Wu Zi Mu Race Finished"},
			{4, "Wu Zi Mu Ending Cutscene Started"},
			{5, "Wu Zi Mu"},
			{7, "Farewell, My Love Starting Cutscene Ended"},
			{8, "Farewell, My Love Race Finished"},
			{9, "Farewell, My Love Ending Cutscene Started"},
			{10, "Farewell, My Love"}
		}},
        {0x64BDC8, new Dictionary<int, string> { // $RACES_WON_NUMBER (first 3 Races are in a fixed order due to missions)
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
		{0x779174, new Dictionary<int, string> {
			{1, "Export Number 1"},
			{2, "Export Number 2"},
			{3, "Export Number 3"},
			{4, "Export Number 4"},
			{5, "Export Number 5"},
			{6, "Export Number 6"},
			{7, "Export Number 7"},
			{8, "Export Number 8"},
			{9, "Export Number 9"},
			{10, "Export Number 10"},
			{11, "Export Number 11"},
			{12, "Export Number 12"},
			{13, "Export Number 13"},
			{14, "Export Number 14"},
			{15, "Export Number 15"},
			{16, "Export Number 16"},
			{17, "Export Number 17"},
			{18, "Export Number 18"},
			{19, "Export Number 19"},
			{20, "Export Number 20"},
			{21, "Export Number 21"},
			{22, "Export Number 22"},
			{23, "Export Number 23"},
			{24, "Export Number 24"},
			{25, "Export Number 25"},
			{26, "Export Number 26"},
			{27, "Export Number 27"},
			{28, "Export Number 28"},
			{29, "Export Number 29"},
			{30, "Export Number 30"},
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
			{0x64A518, "Angel Pine (Safehouse)"},
			{0x64A53C, "Blueberry (Safehouse)"},
			{0x64A4EC, "Calton Heights (Safehouse)"},
			{0x64A508, "Chinatown (Safehouse)"},
			{0x64A534, "Creek (Safehouse)"},
			{0x64A524, "Dillimore (Safehouse)"},
			{0x64A510, "Doherty (Safehouse)"},
			{0x64A51C, "El Quebrados (Safehouse)"},
			{0x64A4D4, "Fort Carson (Safehouse)"},
			{0x64A4F8, "Hashbury (Safehouse)"},
			{0x64A528, "Jefferson (Safehouse)"},
			{0x64A4F0, "Mulholland (Safehouse)"},
			{0x64A52C, "Old Venturas Strip (Hotel Suite)"},
			{0x64A4E0, "Palomino Creek (Safehouse)"},
			{0x64A4F4, "Paradiso (Safehouse)"},
			{0x64A500, "Pirates In Men's Pants (Hotel Suite)"},
			{0x64A4D8, "Prickle Pine (Safehouse)"},
			{0x64A514, "Queens (Hotel Suite)"},
			{0x64A4E4, "Redsands West (Safehouse)"},
			{0x64A4D0, "Rockshore West (Safehouse)"},
			{0x64A4CC, "Santa Maria Beach (Safehouse)"},			
			{0x64A504, "The Camel's Toe (Hotel Suite)"},
			{0x64A530, "The Clown's Pocket (Hotel Suite)"},
			{0x64A520, "Tierra Robada (Safehouse)"},
			{0x64A4E8, "Verdant Bluffs (Safehouse)"},
			{0x64A4FC, "Verona Beach (Safehouse)"},
			{0x64A50C, "Whetstone (Safehouse)"},
			{0x64A4DC, "Whitewood Estate (Safehouse)"},
			{0x64A538, "Willowfield (Safehouse)"},
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
			{0x64BDB8, "Dirt Track"},		// streetraces 26
		}},	
		{"Assets", new Dictionary<int, string> {
			{0x64B710, "Valet Parking"}, 	// $1900
			{0x64B0B4, "Quarry"}, 			// $MISSION_QUARRY_PASSED ($1493)
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
		{"Collectibles", new Dictionary<int, string> {
			{6592864 + (1516 * 4), "OysterAll"}, 	// $ALL_OUSTERS_COLLECTED 
			{6592864 + (1517 * 4), "HorseshoeAll"}, 	// $ALL_HORSESHOES_COLLECTED
			{6592864 + (1518 * 4), "SnapshotAll"}, 	// $ALL_PHOTOS_TAKEN
			{6592864 + (1519 * 4), "TagAll"}, 	// $ALL_TAGS_SPRAYED
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
			// {1, "Vigilante started for the first time"},
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
		{ 6592864 + (54 * 4), "itb_grovestreethome" }, // $HELP_INTRO_SHOWN
		{ 6592864 + (162 * 4), "pimping_started" },
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
		{"Tanker Commander", new List<string> {"Body Harvest"}},
		{"Body Harvest", new List<string> {"King in Exile"}},
		{"Jizzy (Cutscene)", new List<string> {"Jizzy"}},
		{"Jizzy", new List<string> {"Mountain Cloud Boys"}},
		{"Mike Toreno", new List<string> {"Lure"}},
		{"Lure", new List<string> {"Paramedic"}},
		{"The Da Nang Thang", new List<string> {"Yay Ka-Boom-Boom"}},
		
		{"Boat School", new List<string> {"Yay Ka-Boom-Boom","Taxi Driver"}},

		{"Stretch", new List<string> {"Infernus"}},
		{"Patriot", new List<string> {"Infernus"}},
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
	// vars.thread // Mission Start
	vars.startMissions = new Dictionary<string, string> {
		{"blood", "Blood Ring Started"},
		{"boat", "Boat School Started"},
		{"bcrash1", "Badlands Started"},
		{"bskool", "Bike School Started"},
		{"catcut", "King in Exile Started"},
		{"cat4", "Against All Odds Started"},
		{"cesar1", "High Stakes Lowrider Started"},
		{"desert5", "Pilot School Started"},
		{"drugs4", "Reuniting The Families Started"},
		{"dskool", "Driving School Started"},
		{"freight", "Freight Started"},
		{"grove2", "Grove 4 Life Started"},
		{"gymls", "Los Santos Gym Entered"},
		{"gymlv", "Las Venturas Gym Entered"},
		{"gymsf", "San Fierro Gym Entered"},
		{"kicksta", "Kickstart Started"},
		{"la1fin2", "The Green Sabre Started"},
		{"intro1", "Big Smoke Started"},
		{"intro2", "Ryder Started"},
		{"manson5", "Cut Throat Business Started"},
		{"planes", "Plane Flight"},
		{"psch", "Verdant Meadows (Airstrip Bought)"},
		{"ryder3", "Catalyst Started"},
		{"steal", "Wang Cars (Showroom Bought)"},
		{"sweet7", "Los Sepulcros Started"},
		{"truth2", "Are You Going To San Fierro? Started"},
	};

	// These missions are not directly split when they become active, but need to
	// be checked anyway so we can use this knowledge for mission specific subsplits
	vars.startMissions2 = new List<string> {
		"bcesar4",	// Wu Zi Mu / Farewell My Love
		"bcour",	// Courier (LS, SF & LV)
		"catalin", 	// Catalina Quadrilogy Mission Select Mode
		"copcar", 	// Vigilante
		"cprace", 	// Race Tournament / 8 Track / Dirt Track
		"mtbiker",	// Chilliad CHallenge
		"stunt",	// BMX / NRG Challenge
		"truck",	// Trucking
		"music5",	// House Party (Parts 1 & 2)
		// "valet",	// Valet / 555 We Tip / General being near the valet building
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

	/*
	 * Skipping and undoing splits.
	 */
	vars.timerModel = new TimerModel { CurrentState = timer };

	//=============================================================================
	// State keeping
	//=============================================================================

	// Already split splits during this attempt (until timer reset)
	vars.split = new List<string>();

	// Splits that are about to be done
	vars.splitBuffer = new List<string>();

	// Most recently started mission thread. Does not get reset when failed or passed.
	vars.lastStartedMission = "";

	// Bool to track if splits should be skipped instead of splits (for deviating non-linear-esque routes.)
	vars.skipSplits = false;

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
	// defaultTrue: whether enabled by default
	Action<string, int, string, bool> addMissionsHeader = (section, missions, header, defaultTrue) => {
		var parent = section+"Missions";
		settings.Add(parent, true, header);
		foreach (var item in vars.missions[missions]) {
			var mission = item.Value;
			if (missionPresent(mission)) {
				settings.Add(mission, defaultTrue, mission, parent);
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
	settings.Add("Missions", true, "Story Missions");
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
	//-----------
	//-----------
	addMissionList("LS_Sweet", new List<string>() { 
        "Tagging up Turf", "Cleaning the Hood", "Drive-Thru",
		"Nines and AKs", "Drive-By", "Sweet's Girl", 
        "Cesar Vialpando", "Doberman", //"Los Sepulcros"
    });
	addMissionList("LS_Smoke", new List<string>() { 
        "OG Loc", "Running Dog", "Wrong Side of the Tracks", "Just Business"
    });
	addMissionList("LS_Ogloc", new List<string>() { 
        "Life's a Beach", "Madd Dogg's Rhymes",	"Management Issues", 
        "House Party (Cutscene)", "House Party" 
    });
	addMissionList("LS_Ryder", new List<string>() { "Home Invasion", "Catalyst", "Robbing Uncle Sam" });
	addMissionList("LS_Final", new List<string>() { "Reuniting the Families"});
	addMissionList("LS_Crash", new List<string>() { "Burning Desire", "Gray Imports"});
	// addMissionList("LS_Cesar", new List<string>() { "High Stakes Lowrider" });

	// In the Beginning
	settings.Add("itb", false, "In the Beginning", "LS_Intro");
	settings.Add("itb_cutsceneskipped", false, "Cutscene skipped", "itb");

	// Big Smoke
	settings.Add("bs", true, "Big Smoke", "LS_Intro");
	settings.CurrentDefaultParent = "bs";
	settings.Add("Big Smoke Started", false, "Mission Started");
	settings.Add("Big Smoke: Parking Lot Cutscene Start", false, "Parking lot cutscene start");
	settings.Add("Big Smoke: Parking Lot Cutscene End", false, "Parking lot cutscene end");
	settings.Add("Big Smoke: Grove Street Reached", false, "Grove Street cutscene start");
	addMissionCustom("Big Smoke", true, "Mission Passed");

	// Ryder
	settings.Add("r", true, "Ryder", "LS_Intro");
	settings.CurrentDefaultParent = "r";
	settings.Add("Ryder Started", false, "Mission Started");
	settings.Add("r_failed", false, "Failing the mission (eg. blowing up Ryder's car)");
	settings.Add("r_restarted", false, "Restarting the mission after failing");
	settings.Add("r_barberentered", false, "Entering the barbershop");
	settings.Add("r_hairchanged", false, "Haircut purchased");
	settings.Add("r_barbershopleft", false, "Leaving the barbershop");
	settings.Add("r_pizzashopentered", false, "Entering the pizza restaurant");
	settings.Add("r_pizzabought", false, "Pizza bought");
	settings.Add("r_pizzashopleft", false, "Leaving the pizza restaurant");
	settings.Add("r_arrivingathishouse", false, "Arriving back at Ryder's house");

	addMissionCustom("Ryder", true, "Mission Passed");

	// Los Sepulcros
	settings.Add("lossep", true, "Los Sepulcros", "LS_Sweet");
	settings.CurrentDefaultParent = "lossep";
	settings.Add("Los Sepulcros Started", false, "Mission Started");
	settings.Add("Los Sepulcros: Intro Cutscene End", false, "Intro cutscene ended");
	settings.Add("Los Sepulcros: One Homie Recruited", false, "1 homie recruited");
	settings.Add("Los Sepulcros: Two Homies Recruited", false, "All homies recruited");
	settings.Add("Los Sepulcros: Homies Entered Car", false, "Sweet's car brakes unlocked");
	settings.Add("Los Sepulcros: Arrival at the Cemetery", false, "Arrival at the cemetery");
	settings.Add("Los Sepulcros: Wall Climbed", false, "Wall climbed, waiting for Kane");
	settings.Add("Los Sepulcros: Kane Arrived", false, "Kane's arrival");
	settings.Add("Los Sepulcros: Kane Dead", false, "Kane killed");
	settings.Add("Los Sepulcros: Escape Vehicle Entered", false, "Escape vehicle entered");
	settings.Add("Los Sepulcros: Arrival at Grove Street", false, "Arrival at Grove Street");
	addMissionCustom("Los Sepulcros", true, "Mission Passed");

	// High Stakes Lowrider
	settings.Add("hslr", true, "High Stakes Lowrider", "LS_Cesar");
	settings.SetToolTip("hslr", "See also 'Lowrider Race'");
	settings.CurrentDefaultParent = "hslr";
	settings.Add("High Stakes Lowrider Started", false, "Mission Started");
	addMissionCustom("High Stakes Lowrider", true, "Mission Passed");

	// The Green Sabre
	settings.Add("tgs", true, "The Green Sabre", "LS_Final");
	settings.CurrentDefaultParent = "tgs";
	settings.Add("The Green Sabre Started", false, "Mission Started");
	settings.Add("The Green Sabre: End of initial cutscene", false, "End of initial cutscene");
	settings.Add("The Green Sabre: Entered the Bravura", false, "Entered the Bravura");
	settings.Add("The Green Sabre: Exiting the Bravura", false, "Exiting the Bravura");
	settings.Add("The Green Sabre: Arriving at the parking lot", false, "Arriving at the parking lot");
	settings.Add("The Green Sabre: Parking lot shootout start", false, "Parking lot shootout start");
	settings.Add("The Green Sabre: Parking lot shootout end", false, "Parking lot shootout end");
	settings.Add("The Green Sabre: Start of cutscene with Tenpenny", false, "Start of cutscene with Tenpenny");
	addMissionCustom("The Green Sabre", true, "Mission Passed");

	// Badlands
	//---------
	//---------
	//---------
	addMissionList("BL_Intro", new List<string>() { });
	addMissionList("BL_Catalina", new List<string>() { 
        "Tanker Commander", "Small Town Bank", 
        "Local Liquor Store" 
        });
	// addMissionList("BL_Cesar", new List<string>() { "Wu Zi Mu",	"Farewell, My Love" });
	addMissionList("BL_Truth", new List<string>() { "Body Harvest" });
    settings.Add("aygtsf", true, "Are You Going To San Fierro?", "BL_Truth");
	settings.CurrentDefaultParent = "aygtsf";
	settings.Add("Are You Going To San Fierro? Started", false, "Mission Started");
	settings.Add("AYGTSF: 1 Plants Destroyed", false, "1 Plant Destroyed");
	for (int i = 2; i <= 43; i++) {
		settings.Add("AYGTSF: "+i+" Plants Destroyed", false, i+" Plants Destroyed");
	}
	settings.Add("AYGTSF: 44 Plants Destroyed", false, "All 44 Plants Destroyed");
	settings.Add("AYGTSF: Rocket Launcher", false, "Talking to the Truth to get the RPG");
	settings.Add("AYGTSF: Helicopter Destroyed", false, "Helicopter Destroyed");
	settings.Add("AYGTSF: Mothership Entered", false, "Mothership Entered");
	settings.Add("AYGTSF: Arrival at the Garage", false, "Arrival at the Garage");
	addMissionCustom("Are You Going To San Fierro?", true, "Mission Passed");

	// Badlands
	settings.Add("bl", true, "Badlands", "BL_Intro");
	settings.CurrentDefaultParent = "bl";
	settings.Add("Badlands Started", false, "Mission Started");
	settings.Add("Badlands: Mountain Base", false, "Hit Marker at Mountain Base");
	settings.Add("Badlands: Cabin Reached", false, "Cabin Arrival Cutscene Start");
	settings.Add("Badlands: Cabin Cutscene", false, "Cabin Arrival Cutscene End");
	settings.Add("Badlands: Reporter Dead", false, "Reporter Killed");
	settings.Add("Badlands: Photo Taken", false, "Photo Taken");
	addMissionCustom("Badlands", true, "Mission Passed");

	// Catalina Quadrilogy
	settings.Add("catalina quadrilogy", false, "Cutscenes", "BL_Catalina");
	settings.CurrentDefaultParent = "catalina quadrilogy";
	settings.Add("First Date Started", false);
	settings.Add("First Base Started", false);
	settings.Add("Gone Courting Started", false);
	settings.Add("Made in Heaven Started", false);

	// Against All Odds
	settings.Add("aao", true, "Against All Odds", "BL_Catalina");
	settings.CurrentDefaultParent = "aao";
	settings.Add("Against All Odds Started", false, "Mission Started");
	settings.Add("AAO: Robbery Cutscene Ended", false, "Robbery Cutscene Ended");
	settings.Add("AAO: Door Satchel Placed", false, "First Satchel Placed");
	settings.Add("AAO: Door Blown", false, "Door Blown");
	settings.Add("AAO: Store Left", false, "Store Left");
	settings.Add("AAO: 4th Wanted Level Star Lost", false, "Wanted Level Star 4 Lost (3 Remain)");
	settings.Add("AAO: 3rd Wanted Level Star Lost", false, "Wanted Level Star 3 Lost (2 Remain)");
	settings.Add("AAO: 2nd Wanted Level Star Lost", false, "Wanted Level Star 2 Lost (1 Remains)");
	settings.Add("AAO: 1st Wanted Level Star Lost", false, "Wanted Level Star 1 Lost (None Remain)");
	settings.Add("AAO: Final Marker Entered", false, "Final Marker Entered");
	addMissionCustom("Against All Odds", true, "Mission Passed");

	// King in Exile
	settings.Add("kie", true, "King in Exile", "BL_Intro");
	settings.CurrentDefaultParent = "kie";
	settings.Add("King in Exile Started", false, "Mission Started");
	addMissionCustom("King in Exile", true, "Mission Passed");

	// Wu Zi Mu
	settings.Add("wzm", true, "Wu Zi Mu", "BL_Cesar");
	settings.CurrentDefaultParent = "wzm";
	settings.Add("Wu Zi Mu Started", false, "Mission Started");
	addMissionCustom("Wu Zi Mu Starting Cutscene Ended", false, "Starting Cutscene Ended");
	addMissionCustom("Wu Zi Mu Race Finished", false, "Race Finished");
	addMissionCustom("Wu Zi Mu Ending Cutscene Started", false, "Ending Cutscene Started");
	addMissionCustom("Wu Zi Mu", true, "Mission Passed");

	// Farewell, My Love
	settings.Add("fml", true, "Farewell, My Love", "BL_Cesar");
	settings.CurrentDefaultParent = "fml";
	settings.Add("Farewell, My Love Started", false, "Mission Started");
	addMissionCustom("Farewell, My Love Starting Cutscene Ended", false, "Starting Cutscene Ended");
	addMissionCustom("Farewell, My Love Race Finished", false, "Race Finished");
	addMissionCustom("Farewell, My Love Ending Cutscene Started", false, "Ending Cutscene Started");
	addMissionCustom("Farewell, My Love", true, "Mission Passed");
	
	// San Fierro
	//-----------
	//-----------
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
	//-------
	//-------
	addMissionList("D_Toreno", new List<string>() {
		"Monster", "Highjack", "Interdiction", "Verdant Meadows", "Learning to Fly"
	});
    addMissionList("D_WangCars", new List<string>() {
		"Zeroing In", "Test Drive", "Customs Fast Track", "Puncture Wounds"
	});

	// Las Venturas
	//-------------
	//-------------
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
	});
	addMissionList("RTLS_Grove", new List<string>() {
        "Beat Down on B Dup"
	});
	addMissionList("RTLS_Riot", new List<string>() { "Riot", "Los Desperados" });
	settings.CurrentDefaultParent = "RTLS_Riot";
	addMissionCustom("End of the Line Part 1", true, "End of the Line Part 1 (after killing Big Smoke)");
	addMissionCustom("End of the Line Part 2", true, "End of the Line Part 2 (start of chase)");
	
	// Cut Throat Business
	//--------------------
	settings.Add("ctb", true, "Cut Throat Business", "RTLS_Mansion");
	settings.CurrentDefaultParent = "ctb";
	settings.Add("Cut Throat Business Started", false, "Mission Started");
	settings.Add("ctb_checkpoint1", false, "Arriving at the video shoot");
	settings.Add("ctb_checkpoint2", false, "Arriving at the pier");
	addMissionCustom("Cut Throat Business", true, "Mission Passed");

	// Grove 4 Life
	//-------------
	settings.Add("g4l", true, "Grove 4 Life", "RTLS_Grove");
	settings.CurrentDefaultParent = "g4l";
	settings.Add("Grove 4 Life Started", false, "Mission Started");
	settings.Add("g4l_drivetoidlewood", false, "Arriving in Idlewood");
	settings.Add("g4l_territory1", false, "First territory captured");
	settings.Add("g4l_territory2", false, "Second territory captured");
	addMissionCustom("Grove 4 Life", true, "Mission Passed");

	// End of the Line Part 3
	//-----------------------
	settings.Add("eotlp3", true, "End of the Line Part 3", "RTLS_Riot");
	settings.CurrentDefaultParent = "eotlp3";
	settings.Add("eotlp3_chase1", false, "Start of cutscene after catching Sweet");
	settings.Add("eotlp3_chase2", false, "Start of cutscene near Cluckin' Bell");
	settings.Add("eotlp3_chase3", true, "End of any%: Start of firetruck bridge cutscene");
	addMissionCustom("End of the Line Part 3", true, "After credits");

	settings.CurrentDefaultParent = null;

    #endregion

	#region Side Missions

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
	settings.Add("Trucking Start Header", false, "Starting mission for the first time");
	settings.SetToolTip("Trucking Start Header", "Split when starting a trucking mission for the first time.");
	settings.Add("Trucking Left Compound Header", false, "Leaving the compound");
	settings.SetToolTip("Trucking Left Compound Header", "Split when driving the truck out of the compound. Useful for separating truck reset RNG from the actual mission.");
	for (int i = 1; i <= 8; i++) {
		settings.Add("Trucking "+i+" Started", false, "Trucking "+i.ToString()+" - Start", "Trucking Start Header");
		settings.SetToolTip("Trucking "+i+" Started", "Split when starting a trucking mission for the first time.");
		settings.Add("Trucking "+i+": Left Compound", false, "Trucking "+i.ToString()+" - Leaving compound", "Trucking Left Compound Header");
		settings.SetToolTip("Trucking "+i+": Left Compound", "Split when driving the truck out of the compound. Useful for separating truck reset RNG from the actual mission.");
		addMissionCustom("Trucking "+i, true, "Trucking "+i+" Completed");
	}
	settings.CurrentDefaultParent = "Missions2";
	
	// Quarry
	//-------
	settings.Add("Quarry Missions", true, "Quarry");
	addMissionList("Quarry Missions", new List<string>() { "Quarry 1", "Quarry 2", "Quarry 3", "Quarry 4", "Quarry 5", "Quarry 6", "Quarry 7" });
	settings.CurrentDefaultParent = "Quarry Missions";
	addMissionCustom("Quarry", false, "Quarry Asset Completed");

	// Valet Parking
	//--------------
	settings.CurrentDefaultParent = "Missions2";
	settings.Add("ValetMissions", true, "Valet Parking");
	settings.CurrentDefaultParent = "ValetMissions";
	settings.Add("valet_started", false, "Valet Started", "ValetMissions");
	settings.Add("valet_cars", false, "Cars");
	for (int lvl = 1; lvl <= 5; lvl++) {
		settings.Add("valet_level"+lvl, false, "Level "+lvl+" complete");
	}
	var valet_levelCar = 1;
	var valet_level = 1;
	for (int car = 1; car <= 3+4+5+6+7; car++) {
		var handle = "valet_car" + car;
		var name = "Level "+valet_level+": Car "+valet_levelCar;
		settings.Add(handle, false, name, "valet_cars");
		valet_levelCar++;
		if (valet_levelCar >= valet_level + 3) {
			valet_levelCar = 1;
			valet_level++;
		}
	}
	addMissionCustom("Valet Parking", true, "Mission Passed");
	settings.CurrentDefaultParent = "Missions2";

	// Vehicle submissions
	//--------------------
	settings.Add("VehicleSubmissions", true, "Vehicle Submissions");
	settings.CurrentDefaultParent = "VehicleSubmissions";
	
	addMissions3Header(6592864 + (8213 * 4), "firefighter_level", "Firefighter");
	settings.CurrentDefaultParent = "firefighter_level";
	addMissionCustom("Firefighter", true, "Firefighter level 12 (Completion)");
	settings.CurrentDefaultParent = "VehicleSubmissions";

	settings.Add("Freight Level", true, "Freight");
	settings.CurrentDefaultParent = "Freight Level";
	settings.Add("Freight Started", false, "Freight started for the first time", "Freight Level");
	settings.Add("Freight Station 1 1", false, "Freight Level 1 Stop 1");
	settings.Add("Freight Station 1 2", false, "Freight Level 1 Stop 2");
	settings.Add("Freight Station 1 3", false, "Freight Level 1 Stop 3");
	settings.Add("Freight Station 1 4", false, "Freight Level 1 Stop 4");
	addMissionCustom("Freight Level 1", false, "Freight Level 1 Stop 5 (Level 1 Completion)");
	settings.Add("Freight Station 2 1", false, "Freight Level 2 Stop 1");
	settings.Add("Freight Station 2 2", false, "Freight Level 2 Stop 2");
	settings.Add("Freight Station 2 3", false, "Freight Level 2 Stop 3");
	settings.Add("Freight Station 2 4", false, "Freight Level 2 Stop 4");
	addMissionCustom("Freight Level 2", true, "Freight Level 2 Stop 5 (Level 2 Completion)");
	settings.SetToolTip("Freight Station 1 1", "Split when reaching the first stop on the first level. In common 100% routes, this would be Linden Station.");
	settings.SetToolTip("Freight Station 1 2", "Split when reaching the second stop on the first level. In common 100% routes, this would be Yellow Bell Station.");
	settings.SetToolTip("Freight Station 1 3", "Split when reaching the third stop on the first level. In common 100% routes, this would be Cranberry Station.");
	settings.SetToolTip("Freight Station 1 4", "Split when reaching the fourth stop on the first level. In common 100% routes, this would be Market Station.");
	settings.SetToolTip("Freight Level 1", "Split when reaching the fifth stop on the first level, completing the level. In common 100% routes, this would be Market Station.");
	settings.SetToolTip("Freight Station 2 1", "Split when reaching the first stop on the first level. In common 100% routes, this would be Linden Station.");
	settings.SetToolTip("Freight Station 2 2", "Split when reaching the second stop on the first level. In common 100% routes, this would be Yellow Bell Station.");
	settings.SetToolTip("Freight Station 2 3", "Split when reaching the third stop on the first level. In common 100% routes, this would be Cranberry Station.");
	settings.SetToolTip("Freight Station 2 4", "Split when reaching the fourth stop on the first level. In common 100% routes, this would be Market Station.");
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
	settings.CurrentDefaultParent = "VehicleSubmissions";
	
	settings.Add("vigilante_level", true, "Vigilante");
	settings.CurrentDefaultParent = "vigilante_level";
	settings.Add("Vigilante Started", false);
	settings.Add("Vigilante Started after Learning to Fly", false);
	addMissions3(6592864 + (8227 * 4), "vigilante_level");
	addMissionCustom("Vigilante", true, "Vigilante level 12 (Completion)");
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
	// Max lap counts are hardcoded in here & chilliad challenge. Not very future proof, but I don't 
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
	settings.Add("Race 26 Lap 1 Checkpoint 0", false, "Race start (Countdown end)");
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
	settings.Add("Chilliad Challenge", true, "Chilliad Challenge", "Vehicle Challenges");
	settings.CurrentDefaultParent = "Chilliad Challenge";
	settings.Add("Chilliad Challenge #1", true, "Scotch Bonnet Yellow Route");
	settings.Add("Chilliad Challenge #2", true, "Birdseye Winder");
	settings.Add("Chilliad Challenge #3", true, "Cobra Run");
	settings.CurrentDefaultParent = "Chilliad Challenge #1";
	settings.Add("Chilliad Challenge #1 Started", false, "Countdown Start");
	settings.Add("Chilliad Challenge #1 Checkpoint 0", false, "Countdown End");
	for (int cp = 1; cp < 17; cp++) { // 19 32 24
		var cpName = "Chilliad Challenge #1 Checkpoint "+cp;
		settings.Add(cpName, false, "Checkpoint "+cp);
	}
	settings.Add("Chilliad Challenge #1 Checkpoint 17", false, "Checkpoint 17 (Penultimate)");
	settings.SetToolTip("Chilliad Challenge #1 Checkpoint 17", "Split when hitting the second-to-last checkpoint.");
	settings.Add("Chilliad Challenge #1 Complete", true);
	
	settings.CurrentDefaultParent = "Chilliad Challenge #2";
	settings.Add("Chilliad Challenge #2 Started", false, "Countdown Start");	
	settings.Add("Chilliad Challenge #2 Checkpoint 0", false, "Countdown End");
	for (int cp = 1; cp < 30; cp++) { // 19 32 24
		var cpName = "Chilliad Challenge #2 Checkpoint "+cp;
		settings.Add(cpName, false, "Checkpoint "+cp);
	}
	settings.Add("Chilliad Challenge #2 Checkpoint 30", false, "Checkpoint 30 (Penultimate)");
	settings.SetToolTip("Chilliad Challenge #2 Checkpoint 30", "Split when hitting the second-to-last checkpoint.");
	settings.Add("Chilliad Challenge #2 Complete", true);

	settings.CurrentDefaultParent = "Chilliad Challenge #3";
	settings.Add("Chilliad Challenge #3 Started", false, "Countdown Start");	
	settings.Add("Chilliad Challenge #3 Checkpoint 0", false, "Countdown End");
	for (int cp = 1; cp <= 11; cp++) { // 19 32 24
		var cpName = "Chilliad Challenge #3 Checkpoint "+cp;
		settings.Add(cpName, false, "Checkpoint "+cp);
	}
	settings.Add("Chilliad Challenge #3 Checkpoint 12", false, "Checkpoint 12 & 13");
	settings.SetToolTip("Chilliad Challenge #3 Checkpoint 12", "Checkpoint 13 is bugged and is automatically rewarded upon hitting checkpoint 12.");
	for (int cp = 14; cp < 22; cp++) { // 19 32 24
		var cpName = "Chilliad Challenge #3 Checkpoint "+cp;
		settings.Add(cpName, false, "Checkpoint "+cp);
	}
	settings.Add("Chilliad Challenge #3 Checkpoint 22", false, "Checkpoint 22 (Penultimate)");
	settings.SetToolTip("Chilliad Challenge #3 Checkpoint 22", "Split when hitting the second-to-last checkpoint.");
	settings.Add("Chilliad Challenge #3 Complete", true);

	// NRG Challenge
	settings.Add("NRG Stunt Challenge (Header)", true, "NRG-500 Stunt Challenge", "Vehicle Challenges");
	settings.CurrentDefaultParent = "NRG Stunt Challenge (Header)";
	settings.Add("NRG Stunt0", false, "Challenge Started");
	settings.Add("NRG Stunt0AfterExportList1", false, "Challenge Started after completion of Export List 1");
	settings.Add("NRG Stunt0AfterExportList3", false, "Challenge Started after completion of Export List 3");
	settings.SetToolTip("NRG Stunt0AfterExportList1", "Split the first time the mission is started after completion of the first export list.");
	settings.SetToolTip("NRG Stunt0AfterExportList3", "Split the first time the mission is started after completion of all export lists.");
	for (var i = 1; i <= 18; i++) {
		settings.Add("NRG Stunt"+i, false, "Checkpoint "+i);
	}
	addMissionCustom("NRG-500 Stunt Challenge", true, "NRG-500 Stunt Challenge Complete");	

	// Schools
	//--------
	settings.Add("Schools", true, "Schools", "Missions2");
	settings.CurrentDefaultParent = "Schools";
	settings.Add("drivingschool_level", true, "Driving School");
	settings.Add("flightschool_level", false, "Pilot School");
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
	addMissionCustom("Boat School", true, "Land, Sea and Air (Boat School Passed)");
	settings.CurrentDefaultParent = "Missions2";

	// Properties
	//-----------
	// Add "Properties" before addMissions2, so Wang Cars can be added at the top
	settings.Add("Properties", false, "Properties Bought");
	settings.Add("Verdant Meadows (Airstrip Bought)", false, "Verdant Meadows (Airstrip Bought)", "Properties");
	settings.Add("Wang Cars (Showroom Bought)", false, "Wang Cars (Showroom Bought)", "Properties");
	addMissions2("Properties", false);
	settings.CurrentDefaultParent = "Missions2";

	// Import/Export
	//--------------
	settings.Add("Export Lists", true, "Import/Export", "Missions2");
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
	settings.Add("Exported Number", false, "Exported Vehicle Count", "Export Lists");
	settings.CurrentDefaultParent = "Exported Number";
	addMissionCustom("Export Number 1", false, "Exported 1 Vehicle");
	for (int i = 2; i <= 30; i++) {
		addMissionCustom("Export Number "+i, i==30, "Exported "+i+" Vehicles");
	}
	settings.CurrentDefaultParent = "Missions2";

	// Ammunation Challenge
	//---------------------
	settings.CurrentDefaultParent = "Missions2";
	addMissionsHeader("Shooting Range", 6592864 + (1861 * 4), "Shooting Range", false);
	settings.CurrentDefaultParent = "Shooting RangeMissions";
	addMissionCustom("Shooting Range Complete", true, "Shooting Range Complete");

	// Gym Moves
	//----------
	settings.CurrentDefaultParent = "Missions2";
	settings.Add("Gym Moves", true);
	settings.CurrentDefaultParent = "Gym Moves";
	settings.Add("LS Gym", true, "Los Santos Gym");
	settings.Add("SF Gym", true, "San Fierro Gym");
	settings.Add("LV Gym", true, "Las Venturas Gym");
	
	settings.Add("Los Santos Gym Entered", false, "LS Gym Entered", "LS Gym");
	settings.Add("San Fierro Gym Entered", false, "SF Gym Entered", "SF Gym");
	settings.Add("Las Venturas Gym Entered", false, "LV Gym Entered", "LV Gym");

	settings.Add("Los Santos Gym Fight Start", false, "Los Santos Gym Fight Start", "LS Gym");
	settings.Add("San Fierro Gym Fight Start", false, "San Fierro Gym Fight Start", "SF Gym");
	settings.Add("Las Venturas Gym Fight Start", false, "Las Venturas Gym Fight Start", "LV Gym");

	settings.Add("Los Santos Gym Moves", true, "LS Moves Learnt", "LS Gym");
	settings.Add("San Fierro Gym Moves", true, "SF Moves Learnt", "SF Gym");
	settings.Add("Las Venturas Gym Moves", true, "LV Moves Learnt", "LV Gym");

	#endregion

	#region Collectibles

	// Collectibles
	//=============
	settings.CurrentDefaultParent = null;
	settings.Add("Collectibles", true, "Collectibles");
	settings.CurrentDefaultParent = "Collectibles";
	foreach (var item in vars.collectibles)
	{
		settings.Add(item.Key, true, item.Key+"s");
		settings.Add(item.Key+"All", false, "All "+item.Key+"s (Rewards Given)", item.Key);
		settings.SetToolTip(item.Key+"All", "Splits when the game registers all as collected. This check is only done by the game once every 3 seconds.");
		settings.Add(item.Key+"Each", false, "Total Collected "+item.Key+"s", item.Key);
		settings.SetToolTip(item.Key+"Each", "Splits when the total collected reaches this number, as it is shown on screen upon collection.");
		if (true) {
			settings.Add(item.Key+"Specific", false, "Specific "+item.Key+"s", item.Key);
			settings.SetToolTip(item.Key+"Specific", "Splits when a specific collectible of this kind is collected. For reference, see ehgames.com/gta/maplist");
			var count = 50;
			if (item.Key == "Tag") { count = 100; }
			else if (item.Key == "Completed Stunt Jump") { count = 70; }
			else if (item.Key == "Found Stunt Jump") { count = 70; }
			for (int i = 1; i <= count; i++) {
				var absName = "Specific "+item.Key+": "+i;
				var relName = item.Key+" "+(i < count?i.ToString():i+" (All Done)");
				settings.Add(item.Key+"Specific"+i, false, absName, item.Key+"Specific");
				settings.Add(item.Key+"Each"+i, i == count, relName, item.Key+"Each");
			}
		}
		else {
			var count = 50;
			for (int i = 1; i <= count; i++) {
				var relName = item.Key+" "+(i < count?i.ToString():i+" (All Done)");
				settings.Add(item.Key+"Each"+i, i == count, relName, item.Key+"Each");
			}
		}
	}
	settings.CurrentDefaultParent = null;

	#endregion

	#region Warps

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
			settings.SetToolTip(warpName, "Split when getting busted while "+item.Key+" is completed but "+item2+" is not.");
		}
	}
    settings.CurrentDefaultParent = "DeathWarps";
	foreach (var item in vars.deathWarps) {
		foreach (var item2 in item.Value) {
			var warpName = "DW '" + item.Key + "' to '" + item2 + "'";
			settings.Add(warpName, false);
			settings.SetToolTip(warpName, "Split when getting wasted while "+item.Key+" is completed but "+item2+" is not.");
		}
	}
	settings.CurrentDefaultParent = null;

	#endregion

	#region Other

	// Other
	//======
	settings.CurrentDefaultParent = null;
	settings.Add("Other", false);
	settings.CurrentDefaultParent = "Other";

	settings.Add("100% Achieved", false);
	settings.SetToolTip("100% Achieved", "Split when the game has given all rewards for 100%. This is checked every 3 seconds, and then given 2 seconds later.");
	settings.Add("Plane Flight", false);
	settings.SetToolTip("Plane Flight", "Splits when entering the ticket machine marker for the first time");
	addMission4Custom("itb_grovestreethome", true, "\"Grove Street - Home\" line played", "Other");

	// Gang Territories
	//-----------------
    settings.Add("Gang Territories", false, "Gang Territories", "Other");
	settings.SetToolTip("Gang Territories", "Splits when gang territories held stat changes to this number");
	settings.CurrentDefaultParent = "Gang Territories";
	settings.Add("Gang Territories LS", false, "During LS");
	settings.Add("Gang Territories RTLS", false, "During RTLS");
	settings.SetToolTip("Gang Territories LS", "Split for territories captured during LS (before The Green Sabre).");
	settings.SetToolTip("Gang Territories RTLS", "Split for territories captured during RTLS (after Vertical Bird).");
    for (int i = 1; i <= 379; i++) 
    {
        string nameLS = "GT " + i;
		string nameRTLS = "GT " + i;
        if (i == 1) { nameRTLS += " (Grove Street during Home Coming)";}
        else if (i == 2) { nameRTLS += " (Gained for free after Home Coming)";}
        else if (i == 3) { nameRTLS += " (Glen Park during Beat Down on B Dup in common routes)";}
        else if (i == 5) { nameRTLS += " (Number of territories gained from story missions only)";}
        else if (i == 7) { nameRTLS += " (Gang Territories Part 1 in common any% NMG routes)";}
        else if (i == 9) { nameRTLS += " (After Grove 4 Life in common any% NMG routes)";}
        else if (i == 11) { nameLS += " (Starting count on new game)";}
        else if (i == 12) { nameLS += " (Glen Park during Doberman)";}
        else if (i == 17) { nameRTLS += " (All non-mission territories before Grove 4 Life)";}
        else if (i == 19) { nameRTLS += " (Requirement to unlock End of the Line)"; }
        else if (i == 53) { nameRTLS += " (All Captured)"; nameLS += " (All Captured)";}
        else if (i == 57) { nameRTLS += " (All Captured + Varrios Los Aztecas territories)"; nameLS += " (All Captured + Varrios Los Aztecas territories)";}
        else if (i == 378) { nameRTLS += " (Entire map glitch)"; nameLS += " (Entire map glitch)";}
        else if (i == 379) { nameRTLS += " (Entire map glitch + extra territory glitch)"; nameLS += " (Entire map glitch + extra territory glitch)"; }
        settings.Add("GangTerritoryLS"+i.ToString(), false, nameLS, "Gang Territories LS");
        settings.Add("GangTerritoryRTLS"+i.ToString(), false, nameRTLS, "Gang Territories RTLS");
    }
	settings.CurrentDefaultParent = null;

	// Girlfriends
	//------------
	settings.Add("Girlfriends", false, "Girlfriends", "Other");
	settings.CurrentDefaultParent = "Girlfriends";
	for (int i = 0; i <= 5; i++) {
		var gfName = "";
		switch (i) {
			default: case 0: gfName = "Denise"; break;
			case 1: gfName = "Michelle"; break;
			case 2: gfName = "Helena"; break;
			case 3: gfName = "Barbara"; break;
			case 4: gfName = "Katie"; break;
			case 5: gfName = "Millie"; break;
		}
		settings.Add(gfName, i == 5);
		settings.Add("gf_"+gfName.ToLower()+"_unlocked", i == 4, gfName + "'s number acquired", gfName);
		settings.Add("gf_"+gfName.ToLower()+"_killed", i == 5, gfName + " killed", gfName);
		settings.Add("gf_"+gfName.ToLower()+"_carunlocked", false, gfName + " 50% progress (car unlocked)", gfName);
		settings.Add("gf_"+gfName.ToLower()+"_maxed", false, gfName + " max progress (outfit unlocked)", gfName);
	}

	#endregion

    // Non-Linear Split Skipping
    //==========================
	
	settings.CurrentDefaultParent = null;
	settings.Add("Split Skipping", false);
	settings.SetToolTip("Split Skipping", "Skip splits for sections that may deviate from the most optimal order. Eg. due to bad luck in a non-linear segment.");
	settings.CurrentDefaultParent = "Split Skipping";
	
	// settings.Add("LS_NonLinear_100", false, "100% Time Dependent Grove Street Missions");
	// settings.SetToolTip("LS_NonLinear_100", "A block of missions towards the end of Los Santos involving many time of day locked missions. Select the preferred route (only one) to enable skipping on other routes.");
	settings.Add("NonLinear GI LS HP C RUS RTF", false, "Route: GI > LS > HP > C > RUS > RTF");
	settings.SetToolTip("NonLinear GI LS HP C RUS RTF", 
		"Gray Imports -> Los Sepulcros -> House Party -> Catalyst -> Robbing Uncle Sam -> Reuniting the Families.\n" +
		"Skip splits until Reuniting the Families if Los Sepulcros is not done immediately after Gray Imports.\n" +
		"Skipping starts upon starting either House Party or Catalyst instead of Los Sepulcros.\n" +
		"Regular splitting continues upon starting Reuniting the Families."
	);
	// settings.Add("LS_NonLinear_100_CatalystFirst", false, "Catalyst after Gray Imports", "LS_NonLinear_100");
	// settings.SetToolTip("LS_NonLinear_100_CatalystFirst", 
	// 	"Skip splits until Reuniting the Families if Catalyst is not done immediately after Gray Imports.\n" +
	// 	"Gray Imports -> Catalyst -> House Party -> Robbing Uncle Sam -> Los Sepulcros -> Reuniting the Families.\n" +
	// 	"Skipping starts upon starting either House Party or Los Sepulcros instead of Catalyst.\n" +
	// 	"Regular splitting continues upon starting Reuniting the Families."
	// );

	// // settings.Add("D_NonLinear_100", false, "100% Taxi & Exports");
	// // settings.SetToolTip("D_NonLinear_100", "Select the preferred route (only one) to enable skipping in cases of bad car RNG.");
	// settings.Add("NonLinear Slamvan Taxi", false, "Route: Slamvan before Taxi Driver");
	// settings.SetToolTip("NonLinear Slamvan Taxi",
	// 	"Skip splits if Taxi Driver is started before a Slamvan is delivered.\n" +
	// 	"Skipping starts upon starting Taxi Driver without having delivered a Slamvan.\n" +
	// 	"Regular splitting continues upon dropping off another fare or starting Interdiction after delivering a Slamvan."
	// );

	// Other Settings
	//===============
	settings.CurrentDefaultParent = null;
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
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (802 * 4)+offset)) { Name = "100%_achieved" }); // $_100_PERCENT_COMPLETE
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (7011 * 4)+offset)) { Name = "aygtsf_plantsremaining" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (2208 * 4)+offset)) { Name = "bl_cabinreached" });	// Trip Skip enabled
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (6965 * 4)+offset)) { Name = "bl_stage" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (64 * 4)+offset)) { Name = "catalina_count" }); // CATALINA_TOTAL_PASSED_MISSIONS
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (1799 * 4)+offset)) { Name = "chilliad_race" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (1801 * 4)+offset)) { Name = "chilliad_done" }); // $MISSION_CHILIAD_CHALLENGE_PASSED
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (189 * 4)+offset)) { Name = "courier_active" }); // $ONMISSION_COURIER
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (8014 * 4)+offset)) { Name = "eotlp3_chase" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (359 * 4)+offset)) { Name = "gf_denise_progress" }); // $GIRL_PROGRESS[0]
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (360 * 4)+offset)) { Name = "gf_michelle_progress" }); // $GIRL_PROGRESS[1]
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (361 * 4)+offset)) { Name = "gf_helena_progress" }); // $GIRL_PROGRESS[2]
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (362 * 4)+offset)) { Name = "gf_barbara_progress" }); // $GIRL_PROGRESS[3]
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (363 * 4)+offset)) { Name = "gf_katie_progress" }); // $GIRL_PROGRESS[4]
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (364 * 4)+offset)) { Name = "gf_millie_progress" }); // $GIRL_PROGRESS[5]
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (406 * 4)+offset)) { Name = "gf_unlocked" }); // $GIRLS_GIFTS_BITMASK
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (8250 * 4)+offset)) { Name = "kickstart_checkpoints" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (8262 * 4)+offset)) { Name = "kickstart_points" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (1510 * 4)+offset)) { Name = "intro_newgamestarted" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (5353 * 4)+offset)) { Name = "intro_state" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (352 * 4)+offset)) { Name = "race_index" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (169 * 4)+offset)) { Name = "r_onmission" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (676 * 4)+offset)) { Name = "r_hairchanged" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (1514 * 4)+offset)) { Name = "r_failed" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (10933 * 4)+offset)) { Name = "valet_carstopark" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (1848 * 4)+offset)) { Name = "valet_carsparked" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (247 * 4)+offset)) { Name = "schools_currentexercise" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (726 * 4)+offset)) { Name = "stunt_type" }); // $STUNT_MISSION_TYPE
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (8267 * 4)+offset)) { Name = "stunt_timer" });
	// vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (1883 * 4)+offset)) { Name = "valet_started" }); // Gets set during 555 we tip, could be useful to track its progress

	// Local variables. These are used across multiple missions and it's hard to tell which without just testing it
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x55EE68+offset)) { Name = "ctb_checkpoint1" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x57F10C+offset)) { Name = "ctb_checkpoint2" });

	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648A00+offset)) { Name = "r_dialogueblock" }); // 40@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648A10+offset)) { Name = "gym_fighting" }); // 44@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648A18+offset)) { Name = "bs_dialogueblock" }); // 46@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648A38+offset)) { Name = "g4l_territory2" }); // 54@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648A40+offset)) { Name = "g4l_drivetoidlewood" }); // 56@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648A48+offset)) { Name = "g4l_territory1" }); // 58@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648A4C+offset)) { Name = "stunt_checkpoint" }); //59@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648ABC+offset)) { Name = "aygtsf_progress" }); //87@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648AC8+offset)) { Name = "aao_finalmarker" }); //90@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648AE8+offset)) { Name = "aao_storeleft" }); //98@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648AF0+offset)) { Name = "tgs_chapter" }); //100@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648B08+offset)) { Name = "trucking_leftcompound" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648B10+offset)) { Name = "aao_angryshouts" }); //108@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648B68+offset)) { Name = "freight_stations" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648BBC+offset)) { Name = "aygtsf_dialogue" }); //151@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648D64+offset)) { Name = "races_flycheckpoint" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648D70+offset)) { Name = "races_badlandscheckpoint" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648D74+offset)) { Name = "lossep_homiesrecruited" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648D78+offset)) { Name = "races_checkpoint" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648D90+offset)) { Name = "races_stadiumcheckpoint" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x648DD8+offset)) { Name = "lossep_cardoorsunlocked" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x6491B8+offset)) { Name = "lossep_dialogue" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x64950C+offset)) { Name = "chilliad_checkpoints3" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x649518+offset)) { Name = "chilliad_checkpoints" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x649534+offset)) { Name = "courier_checkpoints" }); 
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x649540+offset)) { Name = "couriersf_levels" }); //760@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x649544+offset)) { Name = "courierls_levels" }); //761@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x649548+offset)) { Name = "courierlv_levels" }); //762@
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x649700+offset)) { Name = "courier_city" }); 

	// Things
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x691424+offset)) { Name = "races_laps" }); 
    vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x7791D0+offset)) { Name = "gang_territories" });
	
	// Values not mission specific
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(0x7AA420+offset)) { Name = "wanted_level" });
    
	// Values not mission specific, global from SCM ($xxxx)
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (43 * 4)+offset)) { Name = "interior" });

	// This means loading from a save and such, not load screens (this doesn't work with Steam since I couldn't find the address for it)
	vars.watchers.Add(new MemoryWatcher<bool>(new DeepPointer(loadingAddr)) { Name = "loading" });

	// Values that have a different address defined for the Steam version
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(playerPedAddr, 0x530)) { Name = "pedStatus" });
	vars.watchers.Add(new MemoryWatcher<int>(new DeepPointer(playingTimeAddr)) { Name = "playingTime" });
	vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(startAddr)) { Name = "started" });
	vars.watchers.Add(new StringWatcher(new DeepPointer(threadAddr, 0x8), 10) { Name = "thread" });
	
	// Collectibles
	//=============
	// Separate Steam version addresses are defined in vars.collectibles and
	// chosen here if Steam version was detected.
	//
	// Snapshots collected counts are tracked as a byte, with 20 being uncollected, and 0 being collected.
	// Addresses are 0x20 apart for each, starting at the given address for snapshot #1 (the big antenna).
	// After collection, the value may change randomly to numbers like 13, but this does not seem to occur
	// before collecting.
	//
	// Tags are tracked as an int, with 0 being not sprayed and 255 being fully sprayed. The tag counts
	// at values 229 and above, and the beep will play when it reaches 255. (Values inbetween produce 
	// 'boopless' ). The values are spread over 3 regions in memory, with the third region (88 - 100) not
	// matching the order as the tags are listed on EHGames.com/gta/maplist
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
	var collectibleType = "Snapshot";
	for (int i = 1; i <= 50; i++) {
		var baseAddr = 0x57953C+offset;
		var addr = baseAddr + (i-1) * 0x20;
		vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(addr)) { Name = collectibleType+i });
	}
	collectibleType = "Tag";
	for (int i = 1; i <= 50; i++) {
		var baseAddr = 0x69A9EC+offset;
		var addr = baseAddr + (i-1) * 0x8;
		vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(addr)) { Name = collectibleType+i });
	}
	for (int i = 51; i <= 87; i++) {
		var j = i - 50;
		var baseAddr = 0x69A8C4+offset;
		var addr = baseAddr + (j-1) * 0x8;
		vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(addr)) { Name = collectibleType+i });
	}
	for (int i = 88; i <= 92; i++) {
		var j = i - 87;
		var baseAddr = 0x69AB7C+offset;
		var addr = baseAddr + (j-1) * 0x8;
		vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(addr)) { Name = collectibleType+i });
	}
	for (int i = 93; i <= 96; i++) {
		var j = i - 92;
		var baseAddr = 0x69ABC4+offset;
		var addr = baseAddr + (j-1) * 0x8;
		vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(addr)) { Name = collectibleType+i });
	}
	for (int i = 97; i <= 100; i++) {
		var j = i - 96;
		var baseAddr = 0x69ABA4+offset;
		var addr = baseAddr + (j-1) * 0x8;
		vars.watchers.Add(new MemoryWatcher<byte>(new DeepPointer(addr)) { Name = collectibleType+i });
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
			vars.splitBuffer.Clear();
			vars.lastStartedMission = "";
			vars.skipSplits = false;
			vars.DebugOutput("Cleared list of already executed splits");
		}
		vars.PrevPhase = timer.CurrentPhase;
	}

	//print(vars.watchers["pedStatus"].Current.ToString());
}

split
{
	#region Split prevention
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
	#endregion

	#region Splits
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
			vars.lastStartedMission = "None";
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
				// vars.lastStartedMission = "None";
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
	// Dump started mission to a var, used for mid-mission checks later. Don't
	// move this down.
	var thread = vars.watchers["thread"];
	var threadChanged = thread.Current != thread.Old;
	if (threadChanged)
	{
		foreach (var item in vars.startMissions)
		{
			if (thread.Current == item.Key)
			{
				vars.lastStartedMission = item.Key;
				vars.TrySplit(item.Value);
				break;
			}
		}
		foreach (var item in vars.startMissions2)
		{
			if (thread.Current == item)
			{
				vars.lastStartedMission = item;
				break;
			}
		}
	}

	var interior = vars.watchers["interior"];
	var interiorChanged = interior.Current != interior.Old;
	// Mid-Mission Events
	//===================
	//===================
	//===================
	// Custom code to check various mid-mission events. Most of them involving counters 
	// or local variables that require special attention.
	#region mission events

	#region Against All Odds
	// Angry Shouts: Based on lines/tutorial boxes
	// 0: Pre cutscene
	// 1: Post cutscene
	// 2: How to place
	// 3: How to move away
	// 4: How to detonate
	// 5: Boom
	// 6: Now do the safe
	if (vars.lastStartedMission == "cat4") {
		var aao_angryshouts = vars.watchers["aao_angryshouts"];
		var aao_storeleft = vars.watchers["aao_storeleft"];
		var aao_finalmarker = vars.watchers["aao_finalmarker"];
		var aao_wantedlevel = vars.watchers["wanted_level"];
		if (aao_angryshouts.Old == 0 && aao_angryshouts.Current == 1) { vars.TrySplit("AAO: Robbery Cutscene Ended");}
		else if (aao_angryshouts.Old == 2 && aao_angryshouts.Current == 3) { vars.TrySplit("AAO: Door Satchel Placed");}
		else if (aao_angryshouts.Old == 4 && aao_angryshouts.Current == 5) { vars.TrySplit("AAO: Door Blown");}
		if (aao_storeleft.Current == 1) { 
			if (aao_storeleft.Old == 0) {
				vars.TrySplit("AAO: Store Left");
			}
			if (aao_wantedlevel.Old == 4 && aao_wantedlevel.Current == 3) { vars.TrySplit("AAO: 4th Wanted Level Star Lost");}
			else if (aao_wantedlevel.Old == 3 && aao_wantedlevel.Current == 2) { vars.TrySplit("AAO: 3rd Wanted Level Star Lost");}
			else if (aao_wantedlevel.Old == 2 && aao_wantedlevel.Current == 1) { vars.TrySplit("AAO: 2nd Wanted Level Star Lost");}
			else if (aao_wantedlevel.Old == 1 && aao_wantedlevel.Current == 0) { vars.TrySplit("AAO: 1st Wanted Level Star Lost");}
			if (aao_finalmarker.Current == 1 && aao_finalmarker.Old == 0) {
				vars.TrySplit("AAO: Final Marker Entered");
			}
		}
	}
	#endregion
	#region Are You Going To San Fierro?
	//==================================
	// aygtsf_progress reaches 1 when all plants are destroyed. Redundant because we're already counting the plants
	if (vars.lastStartedMission == "truth2") {
		var aygtsf_plantsremaining = vars.watchers["aygtsf_plantsremaining"];
		if (aygtsf_plantsremaining.Current != aygtsf_plantsremaining.Old && aygtsf_plantsremaining.Current != 44) {
			for (int i = aygtsf_plantsremaining.Old; i > aygtsf_plantsremaining.Current; i--) {
				var aygtsf_plants = 45 - i;
				vars.TrySplit("AYGTSF: " + aygtsf_plants + " Plants Destroyed");
			}
		}
		var aygtsf_dialogue = vars.watchers["aygtsf_dialogue"];
		if (aygtsf_dialogue.Current == 8 && aygtsf_dialogue.Old != 8) {
			vars.TrySplit("AYGTSF: Rocket Launcher");
		}
		var aygtsf_progress = vars.watchers["aygtsf_progress"];
		if (aygtsf_progress.Current == 2 && aygtsf_progress.Old < 2) {
			vars.TrySplit("AYGTSF: Helicopter Destroyed");
		}
		if (aygtsf_progress.Current == 3 && aygtsf_progress.Old == 2) {
			vars.TrySplit("AYGTSF: Mothership Entered");
		}
		if (aygtsf_progress.Current == 5 && aygtsf_progress.Old < 5) {
			vars.TrySplit("AYGTSF: Arrival at the Garage");
		}
	}
	#endregion
	#region Badlands
	// =============
	// bl_stage
	// -1: mission start
	// 0: mountain base marker reached
	// bl_cabinreached set to 1 at start of cabin cutscene
	// 1: cabin cutscene finished
	// 2: ?
	// 3: reporter fleeing to car / car driving away cutscene
	// 4: car chase
	// 5: car on fire, reporter fleeing
	// 6: car exploded, reporter still alive
	// 7: reporter dead
	// 8: photograph taken, return
	if (vars.lastStartedMission == "bcrash1") {
		var badlands_progress = vars.watchers["bl_stage"];
		var badlands_tripskip = vars.watchers["bl_cabinreached"];
		if (badlands_tripskip.Current == 1 && badlands_tripskip.Old == 0) {
			vars.TrySplit("Badlands: Cabin Reached");
		}
		if (badlands_progress.Current == 0 && badlands_progress.Old == -1) { vars.TrySplit("Badlands: Mountain Base"); }
		if (badlands_progress.Current == 1 && badlands_progress.Old == 0) { vars.TrySplit("Badlands: Cabin Cutscene"); }
		if (badlands_progress.Current == 7 && badlands_progress.Old <= 6) { vars.TrySplit("Badlands: Reporter Dead"); }
		if (badlands_progress.Current == 8 && badlands_progress.Old == 7) { vars.TrySplit("Badlands: Photo Taken"); }
	}
	#endregion
	#region Big Smoke
	//===============
	// Dialogue block
	// 0: You wanna drive?
	// 1: Ballas! Drive by! Incoming!
	// 2: I got with them motherfuckers though
	// 3: Shit, a Ballas car is onto us
	// 4: Takes you back some huh CJ? Yeah
	// 5: Straight back into the game right dog?
	// 6: You're just a liability CJ
	var bs_dialogueblock = vars.watchers["bs_dialogueblock"];
	if (bs_dialogueblock.Current != bs_dialogueblock.Old) {
		if (vars.lastStartedMission == "intro1" && !vars.Passed("Big Smoke")) {
			if (bs_dialogueblock.Current == 3 && bs_dialogueblock.Old == 4) {
				vars.TrySplit("Big Smoke: Parking Lot Cutscene Start");
			}
			if (bs_dialogueblock.Current == 6 && bs_dialogueblock.Old == 3) {
				vars.TrySplit("Big Smoke: Parking Lot Cutscene End");
			}
			else if (bs_dialogueblock.Current == 2 && (bs_dialogueblock.Old == 5 || bs_dialogueblock.Old == 6)) {
				vars.TrySplit("Big Smoke: Grove Street Reached");
			}
		}
	}
	#endregion
	#region Catalina Quadrilogy
	if (threadChanged && thread.Current == "catalin") {
		var catalina_count = vars.watchers["catalina_count"];
		if (catalina_count.Current == 0) { vars.TrySplit("First Date Started");}
		else if (catalina_count.Current == 1) { vars.TrySplit("First Base Started");}
		else if (catalina_count.Current == 2) { vars.TrySplit("Gone Courting Started");}
		else if (catalina_count.Current == 3) { vars.TrySplit("Made in Heaven Started");}
	} 
	#endregion
	#region Chilliad Challenge
	//==================
	// "chilliad_race" contains the next race to be started (1-3), but also repeats
	// when you do the races again (changes to 1 on finishing the last race).
	// "chilliad_done" changes from 0 to 1 when all races have been done.
	// current race gets set before current checkpoint. This causes a glitch where finishing race 1 will also trigger CP 18 of race 2.
	// Using else if instead of just if seems to remedy this.
	var chilliad_race = vars.watchers["chilliad_race"];
	if (threadChanged && thread.Current == "mtbiker") {
		vars.TrySplit("Chilliad Challenge #"+chilliad_race.Current+" Started");
	}	
	var chilliad_checkpoints = vars.watchers["chilliad_checkpoints"];
	var chilliad_checkpoints3 = vars.watchers["chilliad_checkpoints3"];
	if (chilliad_race.Current != chilliad_race.Old) {
		vars.TrySplit("Chilliad Challenge #"+chilliad_race.Old+" Complete");
	}
	else if (chilliad_checkpoints.Current > chilliad_checkpoints.Old) {
		if (vars.lastStartedMission == "mtbiker" && chilliad_race.Current != 3) {
			vars.TrySplit("Chilliad Challenge #"+chilliad_race.Current+" Checkpoint "+chilliad_checkpoints.Old);
		}
	}
	else if (chilliad_checkpoints3.Current > chilliad_checkpoints3.Old) {
		if (vars.lastStartedMission == "mtbiker" && chilliad_race.Current == 3) {
			vars.TrySplit("Chilliad Challenge #"+chilliad_race.Current+" Checkpoint "+chilliad_checkpoints3.Old);
		}
	}
	#endregion
	#region Courier
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
		string courier_cityname = "ls";
		if (courier_city.Current == 2) courier_cityname = "sf";
		if (courier_city.Current == 3) courier_cityname = "lv";

		var courier_levels = vars.watchers["courier"+courier_cityname+"_levels"];
		if (courier_levels.Current > courier_levels.Old) {
			vars.TrySplit("courier_" + courier_city.Current + "_level_" + (courier_levels.Current));
		}
		var courier_checkpoints = vars.watchers["courier_checkpoints"];
		if (courier_checkpoints.Current > courier_checkpoints.Old) {
			vars.TrySplit("courier_" + courier_city.Current + "_level_" + (courier_levels.Current+1) + "_delivery_" + courier_checkpoints.Current);
		}
	}
	#endregion
	#region Cut Throat Business
	//=========================
	var ctb_checkpoint1 = vars.watchers["ctb_checkpoint1"];
	if (ctb_checkpoint1.Current > ctb_checkpoint1.Old && ctb_checkpoint1.Old == 0) {
		if (vars.lastStartedMission == "manson5" && !vars.Passed("Cut Throat Business")) {
	 		vars.TrySplit("ctb_checkpoint1");
		}
	}
	var ctb_checkpoint2 = vars.watchers["ctb_checkpoint2"];
	if (ctb_checkpoint2.Current > ctb_checkpoint2.Old && ctb_checkpoint2.Old == 0) {
		if (vars.lastStartedMission == "manson5" && !vars.Passed("Cut Throat Business")) {
	 		vars.TrySplit("ctb_checkpoint2");
		}
	}
	#endregion
	#region End of the Line
	//================
	// Any% ending point + other cutscenes
	var eotlp3_chase = vars.watchers["eotlp3_chase"];
	if (eotlp3_chase.Current > eotlp3_chase.Old) {
		if (vars.Passed("End of the Line Part 2")) {
			vars.TrySplit("eotlp3_chase" + eotlp3_chase.Current.ToString());
		}
	}
	#endregion
	#region Freight
	//========
	// Split on each train station, except for the 5th one, which is the last one 
	// causing level completion which will split already anyway.
	var freight_stations = vars.watchers["freight_stations"];
	if (freight_stations.Current > freight_stations.Old && freight_stations.Current < 5) {
		// Do a check we're actually on Freight, since this is a local variable used for multiple missions
		if (vars.lastStartedMission == "freight") {
			var freightlevel = "1 ";
			if (vars.Passed("Freight Level 1")) {
				freightlevel = "2 ";
			}
			var splitName = "Freight Station " + freightlevel + freight_stations.Current;
			vars.TrySplit(splitName);
		}
	}
	#endregion
	#region Gang Territories
    //=================
    // Gang Territories as tracked by the "Territories Held" stat.
    var gangTerritoriesHeld = vars.watchers["gang_territories"];
    if (gangTerritoriesHeld.Current > gangTerritoriesHeld.Old) {
    	if (vars.Passed("Vertical Bird")) {
            var territoriesHeld = gangTerritoriesHeld.Current;
            vars.TrySplit("GangTerritoryRTLS" + territoriesHeld);
        }
		else if (!vars.Passed("The Green Sabre")) {
			var territoriesHeld = gangTerritoriesHeld.Current;
			vars.TrySplit("GangTerritoryLS" + territoriesHeld);
		}
    }
	#endregion
	#region Grove 4 Life
	//==================
	var g4l_drivetoidlewood = vars.watchers["g4l_drivetoidlewood"];
	var g4l_territory1 = vars.watchers["g4l_territory1"];
	var g4l_territory2 = vars.watchers["g4l_territory2"];
	if (g4l_drivetoidlewood.Current > g4l_drivetoidlewood.Old && g4l_drivetoidlewood.Old == 0) {
		if (vars.lastStartedMission == "grove2" && !vars.Passed("Grove 4 Life")) {
			vars.TrySplit("g4l_drivetoidlewood");
		}
	}
	if (g4l_territory1.Current > g4l_territory1.Old && g4l_territory1.Old == 0) {
		if (vars.lastStartedMission == "grove2" && !vars.Passed("Grove 4 Life")) {
			vars.TrySplit("g4l_territory1");
		}
	}
	if (g4l_territory2.Current > g4l_territory2.Old && g4l_territory2.Old == 0) {
		if (vars.lastStartedMission == "grove2" && !vars.Passed("Grove 4 Life")) {
			vars.TrySplit("g4l_territory2");
		}
	}
	#endregion
	#region Gym Moves
	//===============
	if (vars.lastStartedMission == "gymsf") {
		var gym_start = vars.watchers["gym_fighting"];
		if (gym_start.Current > gym_start.Old && gym_start.Current == 1) {
			vars.TrySplit("San Fierro Gym Fight Start");
		}
	} 
	else if (vars.lastStartedMission == "gymls") {
		var gym_start = vars.watchers["gym_fighting"];
		if (gym_start.Current > gym_start.Old && gym_start.Current == 1) {
			vars.TrySplit("Los Santos Gym Fight Start");
		}
	}
	else if (vars.lastStartedMission == "gymlv") {
		var gym_start = vars.watchers["gym_fighting"];
		if (gym_start.Current > gym_start.Old && gym_start.Current == 1) {
			vars.TrySplit("Las Venturas Gym Fight Start");
		}
	}

	#endregion
	#region Import/Export Lists
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
	#endregion
	#region In the beginning
	//=================
	// Cutscene skipped
	var playingTime = vars.watchers["playingTime"];
	var intro_state = vars.watchers["intro_state"];
    if (intro_state.Current == 1 && intro_state.Old == 0 && playingTime.Current > 2000 && playingTime.Current < 60*1000) {
		vars.TrySplit("itb_cutsceneskipped");
	}
	#endregion
	#region Kickstart
	//===============
	var kickstart_checkpoints = vars.watchers["kickstart_checkpoints"];
	var kickstart_points = vars.watchers["kickstart_points"];
	if (kickstart_checkpoints.Current > kickstart_checkpoints.Old) {
		vars.TrySplit("Kickstart Checkpoint "+kickstart_checkpoints.Current);
	}
	if (kickstart_points.Current >= kickstart_points.Old && kickstart_points.Current >= 26 && kickstart_points.Old < 26) {
		vars.TrySplit("Kickstart Points 26");
	}
	#endregion
	#region Los Sepulcros
	//===================
	// lossep_homiesrecruited -> Number of homies recruited in the mission. Includes optional homies.
	// lossep_cardoorsunlocked -> Set to 1 when the two obligatory homies are recruited. Set to 2 at various later points.
	// lossep_dialogue ->
	// 1 = We gonna need some allies
	// 23 = We're gonna round back to Los Sepulcros and sneak over the wall
	// 	35 = Kane? Ain't that cap front yard royalty?
	// 	36 = Yeah so if there's a hint of trouble, he's a no show.
	// 29 = This is it (Sweet and homies getting out the car to jump over the wall)
	// 34 = Y'all take up positions and wait for Kane
	// 40 = Here he comes
	// 67 = Nice one CJ
	// 	68 = I'll get us a getaway car, you guys take out the rest of those ballas
	// 69 = Okay everybody in let's roll
	// 70 = Man we was a force back there
	// 	71 = Everybody go home, we aint seen each other all day. Copy?
	// 	72 = I'll catch you later CJ
	if (vars.lastStartedMission == "sweet7") {
		var lossep_homiesrecruited = vars.watchers["lossep_homiesrecruited"];
		var lossep_cardoorsunlocked = vars.watchers["lossep_cardoorsunlocked"];
		var lossep_dialogue = vars.watchers["lossep_dialogue"];
		if (lossep_homiesrecruited.Old == 0 && lossep_homiesrecruited.Current == 1) {
			vars.TrySplit("Los Sepulcros: One Homie Recruited");
		}
		if (lossep_cardoorsunlocked.Old == 0 && lossep_cardoorsunlocked.Current == 1) {
			vars.TrySplit("Los Sepulcros: Two Homies Recruited");
		}
		if (lossep_dialogue.Old != 1 && lossep_dialogue.Current == 1) {
			vars.TrySplit("Los Sepulcros: Intro Cutscene End");
		}
		if (lossep_dialogue.Old != 23 && lossep_dialogue.Current == 23) {
			vars.TrySplit("Los Sepulcros: Homies Entered Car");
		}
		if (lossep_dialogue.Old != 29 && lossep_dialogue.Current == 29) {
			vars.TrySplit("Los Sepulcros: Arrival at the Cemetery");
		}
		if (lossep_dialogue.Old != 34 && lossep_dialogue.Current == 34) {
			vars.TrySplit("Los Sepulcros: Wall Climbed");
		}
		if (lossep_dialogue.Old != 40 && lossep_dialogue.Current == 40) {
			vars.TrySplit("Los Sepulcros: Kane Arrived");
		}
		if (lossep_dialogue.Old != 67 && lossep_dialogue.Current == 67) {
			vars.TrySplit("Los Sepulcros: Kane Dead");
		}
		if (lossep_dialogue.Old != 69 && lossep_dialogue.Current == 69) {
			vars.TrySplit("Los Sepulcros: Escape Vehicle Entered");
		}
		if (lossep_dialogue.Old != 70 && lossep_dialogue.Current == 70) {
			vars.TrySplit("Los Sepulcros: Arrival at Grove Street");
		}
	}

	#endregion
	#region Races
	//===========
	// Split for each checkpoint
	// which variable is your cp count depends on the number of opponents in the races.
	var race_index = vars.watchers["race_index"];
	if (vars.lastStartedMission == "cprace" || vars.lastStartedMission == "bcesar4" || vars.lastStartedMission == "cesar1") {
		if (race_index.Current == 7 || race_index.Current == 8) {
			// Badlands A & B
			var races_badlandscheckpoint = vars.watchers["races_badlandscheckpoint"];
			if (races_badlandscheckpoint.Current > races_badlandscheckpoint.Old) {
				var splitName = "Race "+race_index.Current+" Checkpoint "+races_badlandscheckpoint.Old;
				vars.TrySplit(splitName);
			}
		}
		else if (race_index.Current >= 19 && race_index.Current < 25) {
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
	#endregion
	#region Ryder
	//===========
	// Dialogue Block:
	// 0 - Hey, old Reece still run the barber shop?
	// 1 - Man, what's this? Shit look ridiculous
	// 2 - Give up the money. This a raid
	// 3 - Better drop by and see Sweet
	// 4 - What you waiting for fool?
	// r_OnMission is set to 1 after Dialogue's "show me how they drive on the east coast" line
	// and is a reliable way of telling we're past the intro cutscene.
	var r_failed = vars.watchers["r_failed"];
	if (r_failed.Current > r_failed.Old) {
		vars.TrySplit("r_failed");
	}
	if (threadChanged && thread.Current == "intro2" && r_failed.Current > 0) {
		vars.TrySplit("r_restarted");
	}
	var r_dialogueblock = vars.watchers["r_dialogueblock"];
	if (vars.lastStartedMission == "intro2") {
		if (r_dialogueblock.Current != r_dialogueblock.Old) {
			if (!vars.Passed("Ryder")) {
				if (r_dialogueblock.Current == 1 && r_dialogueblock.Old == 0) {
					vars.TrySplit("r_barbershopleft");
				}
				else if (r_dialogueblock.Current == 2 && r_dialogueblock.Old == 1) {
					vars.TrySplit("r_pizzabought");
				}
				else if (r_dialogueblock.Current == 4 && r_dialogueblock.Old == 2) {
					vars.TrySplit("r_pizzashopleft");
				}
				else if (r_dialogueblock.Current == 3 && r_dialogueblock.Old == 4) {
					vars.TrySplit("r_arrivingathishouse");
				}
			}
		}
		var r_hairchanged = vars.watchers["r_hairchanged"];
		var r_onmission = vars.watchers["r_onmission"];
		if (r_hairchanged.Current != r_hairchanged.Old && r_hairchanged.Current == 1) {
			vars.TrySplit("r_hairchanged");
		}
		if (interiorChanged && interior.Current == 2 && vars.lastStartedMission == "intro2" && r_onmission.Current == 1) {
			vars.TrySplit("r_barberentered");
		}
		if (interiorChanged && interior.Current == 5 && vars.lastStartedMission == "intro2" && r_onmission.Current == 1) {
			vars.TrySplit("r_pizzashopentered");
		}
	}
	#endregion
	#region Schools
	//========
	// Current exercise is used by driving and boat school
	var schools_currentexercise = vars.watchers["schools_currentexercise"];
	if (schools_currentexercise.Current > schools_currentexercise.Old) {
		if (vars.lastStartedMission == "dskool" && !vars.Passed("Driving School")) {
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
		else if (vars.lastStartedMission == "bskool" && !vars.Passed("Bike School")) {
			if (schools_currentexercise.Old == 1) { vars.TrySplit("The 360 (Bike School)"); }
			else if (schools_currentexercise.Old == 2) { vars.TrySplit("The 180 (Bike School)"); }
			else if (schools_currentexercise.Old == 3) { vars.TrySplit("The Wheelie"); }
			else if (schools_currentexercise.Old == 4) { vars.TrySplit("Jump & Stop");}
			else if (schools_currentexercise.Old == 5) { vars.TrySplit("The Stoppie");}
			// Jump & Stoppie not included because this variable indicates current exercise. Use the school finish var
		}
	}
	#endregion
	#region Stunt Challenge (BMX / NRG-500)
	//================================
	// $8267 is the timer for the mission. At the start of a mission it gets set to the ingame time
	// and stays there for the duration of the cutscene. It is only used on these missions.
	var stunt_timer = vars.watchers["stunt_timer"];
	if (stunt_timer.Current > stunt_timer.Old + 10001) {
		if (vars.lastStartedMission == "stunt") {
			var stunt_type = vars.watchers["stunt_type"].Current;
			var name = "BMX Stunt";
			if (stunt_type == 1) { name = "NRG Stunt"; }
			vars.TrySplit(name + "0");
			if (stunt_type == 1) {
				if (vars.Passed("Export Number 30")) {
					vars.TrySplit(name+"0AfterExportList3");
				}
				else if (vars.Passed("Export List 1")) {
					vars.TrySplit(name+"0AfterExportList1");
				}
			} 
		}
	}
	var stunt_checkpoint = vars.watchers["stunt_checkpoint"];
	if (stunt_checkpoint.Current > stunt_checkpoint.Old) {
		if (vars.lastStartedMission == "stunt") {
			var stunt_type = vars.watchers["stunt_type"].Current;
			var name = "BMX Stunt";
			if (stunt_type == 1) { name = "NRG Stunt"; }
			vars.TrySplit(name + stunt_checkpoint.Current);
		}
	}
	#endregion
	#region The Green Sabre
	// ====================
	// 1 = Initial cutscene
	// 2 = Cesar's phone call
	// 3 = Entered Bravura
	// 4 = Exiting Bravura
	// 5 = Sweet Dying Cutscene
	// 6 = Combat
	// 7 = Cops arrive at the parking lot
	// 8 = You got a bag over your head boy
	var tgs_chapter = vars.watchers["tgs_chapter"];
	if (tgs_chapter.Current > tgs_chapter.Old) {
		if (vars.lastStartedMission == "la1fin2" && !vars.Passed("The Green Sabre")) {
			switch ((int)tgs_chapter.Current) {
				case 2: 
					vars.TrySplit("The Green Sabre: End of initial cutscene");
					break;
				case 3:
					vars.TrySplit("The Green Sabre: Entered the Bravura");
					break;
				case 4:
					vars.TrySplit("The Green Sabre: Exiting the Bravura");
					break;
				case 5:
					vars.TrySplit("The Green Sabre: Arriving at the parking lot");
					break;
				case 6:
					vars.TrySplit("The Green Sabre: Parking lot shootout start");
					break;
				case 7:
					vars.TrySplit("The Green Sabre: Parking lot shootout end");
					break;
				case 8:
					vars.TrySplit("The Green Sabre: Start of cutscene with Tenpenny");
					break;
				default:
					break;
			}
		}
	}
	#endregion
	#region Trucking
	//=========
	// Start & Leaving the compound
	var trucking_current = vars.watchers[0x6518DC.ToString()].Current + 1;
	if (threadChanged && thread.Current == "truck") {
		var splitName = "Trucking "+trucking_current+" Started";
		vars.TrySplit(splitName);
	}
	else if (vars.lastStartedMission == "truck") {
		var trucking_leftcompound = vars.watchers["trucking_leftcompound"];
		if (trucking_leftcompound.Current > trucking_leftcompound.Old) {
			var splitName = "Trucking "+trucking_current+": Left Compound";
			vars.TrySplit(splitName);
		}
	}
	#endregion
	#region Valet Parking
	//===================
	// Levels
	// var valet_level = vars.watchers["valet_level"];
	// if (valet_level.Current > valet_level.Old && valet_level.Old != 0) {
	// 	if (thread.Current == "valet") {
	// 		var splitName = "valet_level" + valet_level.Old;
	// 		vars.TrySplit(splitName);
	// 	}
	// }
	var valet_carstopark = vars.watchers["valet_carstopark"];
	var valet_carsparked = vars.watchers["valet_carsparked"];
	// if (thread.Current == "valet") {
		if (valet_carstopark.Old == 0 && valet_carstopark.Current == 3) {
			vars.TrySplit("valet_started");
		}
		if (valet_carstopark.Old == 1 && valet_carstopark.Current == 4) {
			vars.TrySplit("valet_level1");
		}
		if (valet_carstopark.Old == 1 && valet_carstopark.Current == 5) {
			vars.TrySplit("valet_level2");
		}
		if (valet_carstopark.Old == 1 && valet_carstopark.Current == 6) {
			vars.TrySplit("valet_level3");
		}
		if (valet_carstopark.Old == 1 && valet_carstopark.Current == 7) {
			vars.TrySplit("valet_level4");
		}
		if (valet_carstopark.Old == 1 && valet_carstopark.Current == 8) {
			vars.TrySplit("valet_level5");
		}
		if (valet_carsparked.Current > valet_carsparked.Old) {
			var splitName = "valet_car" + valet_carsparked.Current;
			vars.TrySplit(splitName);
		}
	// }
	#endregion
	#region Wu Zi Mu / Farewell, My Love
	//=================================
	if (threadChanged && thread.Current == "bcesar4" && !vars.Passed("Wu Zi Mu")) {
		vars.TrySplit("Wu Zi Mu Started");
	}
	if (race_index.Current == 8 && race_index.Old == 7 && !vars.Passed("Farewell, My Love")) {
		// If parking in the marker and starting FML during the fadein of WZM, currentthread will never change, so we have to detect its start like this
		vars.TrySplit("Farewell, My Love Started");
	}
	#endregion
	#region Vigilante
	//===============
	if (threadChanged && thread.Current == "copcar") {
		vars.TrySplit("Vigilante Started");
		if (vars.Passed("Learning to Fly")) {
			vars.TrySplit("Vigilante Started after Learning to Fly");
		}
	}
	#endregion


	#endregion

	// 100% Achieved
	//==============
	// Split when the hundo rewards are given
	// var hundo_achieved = vars.watchers["100%_achieved"];
	// if (hundo_achieved.Current && !hundo_achieved.Old) {
	// 	vars.TrySplit("100% Achieved");
	// }

	// Girlfriends
	//============
	// Progress is tracked in an array. Whether a GF is available for dates is tracked in a bitmask
	for (int i = 0; i <= 5; i++) {
		var gfName = "";
		switch (i) {
			default: case 0: gfName = "denise"; break;
			case 1: gfName = "michelle"; break;
			case 2: gfName = "helena"; break;
			case 3: gfName = "barbara"; break;
			case 4: gfName = "katie"; break;
			case 5: gfName = "millie"; break;
		}
		var progress = vars.watchers["gf_"+gfName+"_progress"];
		if (progress.Current != progress.Old) {
			if (progress.Current == -999) {
				vars.TrySplit("gf_"+gfName+"_killed");
			}
			else if (progress.Current == 100) {
				vars.TrySplit("gf_"+gfName+"_maxed");
			}
			else if (progress.Old < 50 && progress.Current >= 50) {
				vars.TrySplit("gf_"+gfName+"_carunlocked");
			}
		}
	}
	var gf_unlocked = vars.watchers["gf_unlocked"];
	int gf_unlockedOld = gf_unlocked.Old;
	int gf_unlockedCurrent = gf_unlocked.Current;
	if (gf_unlocked.Current != gf_unlocked.Old) {
		vars.DebugOutput("DEBUG: GF Var changed from "+gf_unlockedOld+" to "+gf_unlockedCurrent);
		if ((gf_unlockedCurrent & 1) != 0 && (gf_unlockedOld & 1) == 0) { vars.TrySplit("gf_denise_unlocked"); }
		else if ((gf_unlockedCurrent & 2) != 0 && (gf_unlockedOld & 2) == 0) { vars.TrySplit("gf_michelle_unlocked"); }
		else if ((gf_unlockedCurrent & 4) != 0 && (gf_unlockedOld & 4) == 0) { vars.TrySplit("gf_helena_unlocked"); }
		else if ((gf_unlockedCurrent & 8) != 0 && (gf_unlockedOld & 8) == 0) { vars.TrySplit("gf_barbara_unlocked"); }
		else if ((gf_unlockedCurrent & 16) != 0 && (gf_unlockedOld & 16) == 0) { vars.TrySplit("gf_katie_unlocked"); }
		else if ((gf_unlockedCurrent & 32) != 0 && (gf_unlockedOld & 32) == 0) { vars.TrySplit("gf_millie_unlocked"); }
	}
	
	// Split collectibles
	//===================
	foreach (var item in vars.collectibles) {
		var value = vars.watchers[item.Key.ToString()];
		if (value.Current > value.Old) {
			var type = item.Key;
			var splitName = type+"Each"+value.Current;
			vars.TrySplit(splitName);
		}
	}
	for (int i = 1; i <= 50; i++) {
		var snapshot = vars.watchers["Snapshot"+i];
		if (snapshot.Current != 20 && snapshot.Old == 20) {
			if (snapshot.Current == 0) {
				var splitName = "SnapshotSpecific"+i;
				vars.TrySplit(splitName);
			}
			else {
				vars.DebugOutput("Snapshot "+i+" was "+snapshot.Current);
			}
		}
	}
	for (int i = 1; i <= 100; i++) {
		var tag = vars.watchers["Tag"+i];
		if (tag.Current >= 229 && tag.Old <= 228) {
			var splitName = "TagSpecific"+i;
			vars.TrySplit(splitName);
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
							break;
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
							break;
						}
					}
				}
			}
		}
	}
	#endregion

	// Skip splits
	if (settings["NonLinear GI LS HP C RUS RTF"] && threadChanged) {
		if ((thread.Current == "ryder3") || (thread.Current == "music5" && vars.Passed("House Party (Cutscene)"))) {
			if (!vars.Passed("Los Sepulcros") && vars.Passed("Gray Imports")) {
				// Started House Party or Catalyst before Los Sepulcros. Stop splitting and skip instead.
				vars.skipSplits = true;
				vars.DebugOutput("Start skipping splits: Deviation from route GI->LS->HP->C->RUS->RTF");
			}
		}
		if (thread.Current == "drugs4" && vars.skipSplits == true) {
			// Start splitting again on Reuniting The Families
			vars.skipSplits = false;
			vars.DebugOutput("End skipping splits");
		}
	}

	// Split
	if (vars.splitBuffer.Count > 0) {
		vars.splitBuffer.RemoveAt(0);
		if (vars.skipSplits) {
			vars.DebugOutput("Skipping split");
			vars.timerModel.SkipSplit();
		}
		else {
			return true;
		}
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
		if (settings.StartEnabled)
		{
			// Only output when actually starting timer (the return value of this method
			// is only respected by LiveSplit when the setting is actually enabled)
			vars.DebugOutput("New Game"+playingTime.Current);
		}
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
