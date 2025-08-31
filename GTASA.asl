
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
 * the 0x400000 or whatever the module address is. Compatibility for the most
 * recent Steam version has been removed. This was the version referred to as
 * just "Steam" in Tduva's code and did not seem to include the v3.00 and v1.01
 * versions in its definition.
 *
 * Most addresses are for the 1.0 version (unless noted otherwise). All global
 * variables seem to work in all versions if you apply the appropriate version
 * offset. Global variables refers to variables that are written in the mission
 * script as $1234. Other addresses have to be manually corrected for the Steam
 * version (this has not been done in this code, hence it's unsupported).
 *
 * Formula for global variable decimal $v:
 * 		0x649960 + v * 0x4
 *
 * Formula for local variables in mission threads decimal v@ to hexadecimal address y:
 * 		0xA48960 + v * 0x4
 *
 * Formula for local variables in non-mission threads decimal v@ to hexadecimal address y:
 * 		0xA8B430 + t * 0xE0 + 0x3C + v * 0x4
 * where decimal t = id of script (starts at 95 and goes down. Scripts are added below as they are started.)
 * So 'main' thread = 95, 'intro' thread = 94, 'oddveh' thread = 93, ... 'tri' thread = 75.
 * After that, numbers are unpredictable as threads are started in different order based on gameplay.
 * Thread names are at address. Iterate over t until found:
 * 		0xA8B430 + t * 0xE0 + 0x8
 *
 * All splits are only split once per reset (so if you load an earlier Save and
 * revert splits, it won't split them again). This is mostly because this
 * behaviour makes sense: If you move back through the splits manually, you
 * should also split those splits manually. It is however also required for
 * the "Split at start of missions" section, which splits based on the current
 * first thread and would most likely split several times otherwise.
 */


state("gta_sa") {
	int version_100_EU : 0x4245BC;
	int version_100_US : 0x42457C;
	int version_101_EU : 0x42533C;
	int version_101_US : 0x4252FC;
	int version_300_Steam : 0x45EC4A;
	int version_101_Steam : 0x45DEDA;
}

// Detect .exe of version with "-" instead of "_"
state("gta-sa") {
	int version_100_EU : 0x4245BC;
	int version_100_US : 0x42457C;
	int version_101_EU : 0x42533C;
	int version_101_US : 0x4252FC;
	int version_300_Steam : 0x45EC4A;
	int version_101_Steam : 0x45DEDA;
}

startup {
	refreshRate = 30;

	/*
	 * For skipping and undoing splits.
	 */
	vars.timerModel = new TimerModel { CurrentState = timer };

	#region Utility Functions
		// Easier debug output.
		Action<string> DebugOutput = (text) => {
			print("[GTASA Autosplitter] "+text);
		};
		vars.DebugOutput = DebugOutput;

		Action<string> DebugWatcherOutput = (name) => {
			var dbgW = vars.GetWatcher(name);
			if (dbgW.Changed) {
				vars.DebugOutput(name + ": " + dbgW.Old + " -> " + dbgW.Current);
			}
		};
		vars.DebugWatcherOutput = DebugWatcherOutput;

		Func<string, MemoryWatcher> GetWatcher = (name) => {
			var w = vars.watcherList[name];
			if (vars.currentWatchers.Contains(name)) {
				return w;
			}
			w.Update(vars.game);
			return w;
		};
		vars.GetWatcher = GetWatcher;
	#endregion
	#region Address Keeping
		// Global SCM variables ($xxxx) to watch in memory
		vars.watchScmGlobalVariables = new Dictionary<int,string>();

		// Local SCM variables (xx@) to watch in memory (these are actually just global)
		vars.watchScmMissionLocalVariables = new HashSet<int>();

		// Non-SCM addresses (eg. Stats entries)
		vars.nonScmAddresses = new List<Tuple<string, int, int>>();
		vars.nonScmAddressesChanges = new List<Tuple<string, int, int>>();

		// Pointer addresses
		vars.pointerList = new List<Tuple<string, int, DeepPointer>>();

		Action<int,string,int> AddNonScmAddressWatcher = (address,name,bytes) => {
			vars.nonScmAddresses.Add(Tuple.Create(name, bytes, address));
		};
		vars.AddNonScmAddressWatcher = AddNonScmAddressWatcher;

		Action<int,string,int> ChangeNonScmAddressWatcher = (address,name,bytes) => {
			vars.nonScmAddressesChanges.Add(Tuple.Create(name, bytes, address));
		};
		vars.ChangeNonScmAddressWatcher = ChangeNonScmAddressWatcher;

		Action<DeepPointer,string,int> AddPointerWatcher = (pointer, name, bytes) => {
			vars.pointerList.Add(Tuple.Create(name, bytes, pointer));
		};
		vars.AddPointerWatcher = AddPointerWatcher;

		vars.significantThreads = new Dictionary<string,string>();
		vars.missionNames = new Dictionary<string,string>();
	#endregion

	//=============================================================================
	// State keeping
	//=============================================================================

	vars.completedSplits = new List<string>();	// Already split splits during this attempt (until timer reset)
	vars.splitQueue = new Queue<string>();	// A queue to ensure splits are split one by one to prevent single-splitting when multiple are completed simultaneously.
	vars.lastStartedMission = "";	// Most recently started mission thread. Resets on pass, but not on fail.
	vars.skipSplits = false;	// Bool to track if splits should be skipped instead of splits (for deviating non-linear-esque routes.)
	vars.lastLoad = 0;		// Timestamp when the last load occured (load means loading from a save and such, not load screens)
	vars.lastSplit = 0;		// Timestamp when the last split was executed (to prevent double-splits)
	vars.waiting = false;	// Whether we should wait before splitting (eg game is still being loaded)

	//=============================================================================
	// Settings & Memory Addresses
	//=============================================================================
	// There are more memory addresses defined in `init` in the "Version Detection"
	// and "Memory Watcher" sections.  TODO: Confirm this

	// Funcs to execute in the split check.
	// Checks conditions, then if a condition is met, returns the ID of a split.
	// If no conditions are met, return null.
	vars.CheckSplit = new List<Func<string>>();

	#region Settings & Split Checking
		settings.Add("Splits", true, "Splits");
		settings.CurrentDefaultParent = "Splits";
		// Settings as well as the splitting logic is all kept together in one place
		// so it can be updated without having to scroll between two different sections
		// in startup and init.
		// Most addresses are defined here now, but a few generic ones that are relevant for missions
		// (like wanted level, playtime, current thread, etc are still asigned in init.
		#region Main Missions
			settings.Add("Missions", true, "Story Missions");
			settings.SetToolTip("Missions", "Missions with a visible-anywhere minimap marker until completion");
			#region Los Santos
				settings.Add("LS", true, "Los Santos", "Missions");
				#region Intro Chain
					settings.Add("LS_Intro", true, "Intro", "LS");
					// 1: Big Smoke / Sweet & Kendl
					// 2: Ryder
					vars.watchScmGlobalVariables.Add(448, "ls_intro_chain"); // $INTRO_TOTAL_PASSED_MISSIONS
					#region In the Beginning
						// In the Beginning is not technically part of the "intro chain", but
						// including it here anyway as it fits in narratively.
						settings.Add("intro", false, "In the Beginning", "LS_Intro");
						settings.CurrentDefaultParent = "intro";
						settings.Add("intro_cutsceneEnd", false, "Intro cutscenes skipped or finished", "intro");
						settings.Add("intro_passed", false, "Bicycle entered or abandoned", "intro");
						settings.Add("intro_groveStreet", false, "\"Grove Street - Home\" line played", "intro");

						vars.watchScmGlobalVariables.Add(5353, "intro_cutsceneState");
						vars.watchScmGlobalVariables.Add(54, "intro_groveStreet");	// $HELP_INTRO_SHOWN
						// important: newGameStarted is used in general splitting behavior
						// to see whether the game has started and avoid dud splits.
						// it gets set immediately to 1, is never used, and gets set
						// back to 0 during Flight School & Dam and Blast.
						vars.watchScmGlobalVariables.Add(1510, "intro_newGameStarted");

						Func<string> func_intro = () => {
							var intro_cutsceneState = vars.GetWatcher("intro_cutsceneState");
							var playingTime = vars.GetWatcher("playingTime");
							if (intro_cutsceneState.Changed && playingTime.Current > 2000) {
								if (intro_cutsceneState.Current == 1 || (intro_cutsceneState.Current == 0 && intro_cutsceneState.Old == 3)) {
									return "intro_cutsceneEnd";
								}
							}
							// intro_passed gets set when the player enters the bike, moves the bike,
							// or leaves the starting area. In other words: Anything that makes the
							// blue arrow over the bicycle disappear.
							var intro_passed = vars.GetWatcher("intro_passed");
							if (intro_passed.Changed && intro_passed.Current == 1) {
								return "intro_passed";
							}
							var intro_groveStreet = vars.GetWatcher("intro_groveStreet");
							if (intro_groveStreet.Changed && intro_groveStreet.Current == 1) {
								return "intro_groveStreet";
							}
							return null;
						};
						vars.CheckSplit.Add(func_intro);
					#endregion
					#region Big Smoke / Sweet & Kendl
						// ==============================
						settings.Add("bs", true, "Big Smoke", "LS_Intro");
						settings.CurrentDefaultParent = "bs";
						settings.Add("bs_marker", false, "Mission Marker Entered");
						settings.Add("bs_start", false, "Mission Started");
						settings.Add("bs_sweetAndKendl", false, "Sweet & Kendl mission text shown");
						settings.Add("bs_parkingLotStart", false, "Parking lot cutscene start");
						settings.Add("bs_parkingLotEnd", false, "Parking lot cutscene end");
						settings.Add("bs_groveStreet", false, "Grove Street cutscene start");
						settings.Add("bs_pass", true, "Mission Passed");
						settings.Add("bs_houseEnter", false, "Entering CJ's house after passing");
						settings.Add("bs_houseExit", false, "Leaving CJ's house after passing");

						vars.watchScmGlobalVariables.Add(65, "bs_houseHelp"); // $HELP_GROOVE_SHOWN

						vars.watchScmMissionLocalVariables.Add(46);

						vars.significantThreads.Add("intro1","bs_start");
						vars.missionNames.Add("Big Smoke","bs_marker");
						vars.missionNames.Add("Sweet & Kendl","bs_sweetAndKendl");

						Func<string> func_bs = () => {
							if (vars.lastStartedMission == "intro2") {
								return;
							}
							var ls_intro_chain = vars.GetWatcher("ls_intro_chain");
							if (ls_intro_chain.Current == 2) {
								return;
							}
							else if (ls_intro_chain.Current == 1) {
								if (ls_intro_chain.Changed) {
									return "bs_pass";
								}
								//===========
								// House Help
								// 1: "Go inside the house" shown
								// 2: after "To save the game..."
								// 3: after "Go and see Ryder"
								var bs_houseHelp = vars.GetWatcher("bs_houseHelp");
								var interior = vars.GetWatcher("interior");
								if (interior.Changed) {
									if ((bs_houseHelp.Current == 1 || bs_houseHelp.Current == 0) && interior.Current == 3) {
										return "bs_houseEnter";
									}
									else if (bs_houseHelp.Current == 2 && interior.Current == 0) {
										return "bs_houseExit";
									}
								}
								return;
							}
							if (vars.lastStartedMission != "intro1") {
								return;
							}
							//===============
							// Dialogue block
							// 0: You wanna drive?
							// 1: Ballas! Drive by! Incoming!
							// 2: I got with them motherfuckers though
							// 3: Shit, a Ballas car is onto us
							// 4: Takes you back some huh CJ? Yeah
							// 5: Straight back into the game right dog?
							// 6: You're just a liability CJ
							var bs_dialogueBlock = vars.GetWatcher("46@");
							if (bs_dialogueBlock.Changed) {
								if (bs_dialogueBlock.Current == 3 && bs_dialogueBlock.Old == 4) {
									return "bs_parkingLotStart";
								}
								if (bs_dialogueBlock.Current == 6 && bs_dialogueBlock.Old == 3) {
									return "bs_parkingLotEnd";
								}
								else if (bs_dialogueBlock.Current == 2 && (bs_dialogueBlock.Old == 5 || bs_dialogueBlock.Old == 6)) {
									return "bs_groveStreet";
								}
							}
							return;
						};
						vars.CheckSplit.Add(func_bs);

					#endregion
					#region Ryder
						// ==========
						settings.Add("r", true, "Ryder", "LS_Intro");
						settings.CurrentDefaultParent = "r";
						settings.Add("r_marker", false, "Mission Marker Entered");
						settings.Add("r_start", false, "Mission Started");
						settings.Add("r_fail", false, "Failing the mission (eg. blowing up Ryder's car)");
						settings.Add("r_restart", false, "Restarting the mission after failing");
						settings.Add("r_barberEnter", false, "Entering the barbershop");
						settings.Add("r_barberBought", false, "Haircut purchased");
						settings.Add("r_barberExit", false, "Leaving the barbershop");
						settings.Add("r_pizzaEnter", false, "Entering the pizza restaurant");
						settings.Add("r_pizzaBought", false, "Pizza bought");
						settings.Add("r_pizzaExit", false, "Leaving the pizza restaurant");
						settings.Add("r_returnToHouse", false, "Arriving back at Ryder's house");
						settings.Add("r_pass", true, "Mission Passed");

						vars.watchScmGlobalVariables.Add(169, "r_onMission");
						vars.watchScmGlobalVariables.Add(676, "r_barberBought");
						vars.watchScmGlobalVariables.Add(1514, "r_fail");

						vars.watchScmMissionLocalVariables.Add(40);

						vars.significantThreads.Add("intro2","r_start");
						vars.missionNames.Add("Ryder","r_marker");

						Func<string> func_r = () => {
							if (!vars.ValidateMissionProgress("intro2", "ls_intro_chain", 1, 2, "r_pass", "r")) {
								return;
							}

							var r_fail = vars.GetWatcher("r_fail");
							if (r_fail.Changed && r_fail.Current == 1) {
								return "r_fail";
							}
							var thread = vars.GetWatcher("thread");
							var r_onMission = vars.GetWatcher("r_onMission");
							if (thread.Changed && thread.Current == "intro2" && r_fail.Current == 1 && r_onMission.Current == 0) {
								return "r_restart";
							}
							if (r_onMission.Current == 0) {
								return;
							}
							var r_barberBought = vars.GetWatcher("r_barberBought");
							if (r_barberBought.Changed && r_barberBought.Current == 1) {
								return "r_barberBought";
							}
							var interior = vars.GetWatcher("interior");
							if (interior.Changed) {
								if (interior.Current == 2) {
									return "r_barberEnter";
								}
								else if (interior.Current == 5) {
									return "r_pizzaEnter";
								}
							}
							// Dialogue Block:
							// 0 - Hey, old Reece still run the barber shop?
							// 1 - Man, what's this? Shit look ridiculous
							// 2 - Give up the money. This a raid
							// 3 - Better drop by and see Sweet
							// 4 - What you waiting for fool?
							// r_OnMission is set to 1 after Dialogue's "show me how they drive on the east coast" line
							// and is a reliable way of telling we're past the intro cutscene.
							var r_dialogueBlock = vars.GetWatcher("40@");
							if (r_dialogueBlock.Changed) {
									if (r_dialogueBlock.Current == 1 && r_dialogueBlock.Old == 0) {
										return "r_barberExit";
									}
									else if (r_dialogueBlock.Current == 2 && r_dialogueBlock.Old == 1) {
										return "r_pizzaBought";
									}
									else if (r_dialogueBlock.Current == 4 && r_dialogueBlock.Old == 2) {
										return "r_pizzaExit";
									}
									else if (r_dialogueBlock.Current == 3 && r_dialogueBlock.Old == 4) {
										return "r_returnToHouse";
									}
							}
							return;
						};
						vars.CheckSplit.Add(func_r);
					#endregion
				#endregion
				#region Sweet Chain
					settings.Add("LS_Sweet", true, "Sweet", "LS");
					// 1: Tagging up Turf
					// 2: Cleaning the Hood
					// 3: Drive-Thru
					// 4: Nines and AKs
					// 5: Drive-By
					// 6: Sweet's Girl
					// 7: Cesar Vialpando
					// 8: Doberman
					// 9: Los Sepulcros
					vars.watchScmGlobalVariables.Add(452, "ls_sweet_chain"); // $SWEET_TOTAL_PASSED_MISSIONS

				#region Tagging up Turf
					// ====================
					settings.Add("tut", true, "Tagging up Turf", "LS_Sweet");
					settings.SetToolTip("tut", "Specific tags involved are 39, 38, 37, 63, 64 & 62");
					settings.CurrentDefaultParent = "tut";
					settings.Add("tut_marker", false, "Mission Marker Entered");
					settings.Add("tut_start", false, "Mission Started");
					settings.Add("tut_introCutsceneEnd", false, "Intro cinematic end");
					settings.Add("tut_cutsceneSweetSprayTagEnd", false, "Cutscene of Sweet spraying first tag ended");
					settings.Add("tut_carEnterAfterTag3", false, "Entering the car after spraying first group of tags");
					settings.Add("tut_carExitBeforeTag4", false, "Exiting the car before spraying second group of tags");
					settings.Add("tut_approachingGangMembers", false, "Approaching tag with gang members");
					settings.Add("tut_carEnterAfterTag6", false, "Entering the car after spraying second group of tags");
					settings.Add("tut_finalCutsceneStart", false, "Ending cutscene start");
					settings.Add("tut_pass", true, "Mission Passed");

					vars.watchScmMissionLocalVariables.Add(40);
					vars.watchScmMissionLocalVariables.Add(46);
					vars.watchScmMissionLocalVariables.Add(48);
					vars.watchScmMissionLocalVariables.Add(58);
					vars.watchScmMissionLocalVariables.Add(65);

					vars.significantThreads.Add("sweet1","tut_start");
					vars.missionNames.Add("Tagging up Turf","tut_marker");

					Func<string> func_tut = () => {
						if (!vars.ValidateMissionProgress("sweet1", "ls_sweet_chain", 0, 1, "tut_pass", "tut")) {
							return;
						}

						// Dialogue block:
						// 4 - Hey, wait up!
						// 6 - Like riding a bike ain't it boy
						var tut_dialogueBlock = vars.GetWatcher("48@");
						if (tut_dialogueBlock.Changed) {
							if (tut_dialogueBlock.Old == 0 && tut_dialogueBlock.Current == 4) {
								return "tut_introCutsceneEnd";
							}
							if (tut_dialogueBlock.Old == 4 && tut_dialogueBlock.Current == 6) {
								// $6548 also covers this (changes from 0 to 1)
								return "tut_finalCutsceneStart";
							}
						}

						if (tut_dialogueBlock.Current == 0) {
							// Failsafe for mission restart
							return;
						}

						// Something also related to help boxes or something. Gets set to 1 when the cutscene ends, and to 2 shortly after.
						var tut_cutsceneSweetSprayTagEnd = vars.GetWatcher("65@");
						if (tut_cutsceneSweetSprayTagEnd.Changed && tut_cutsceneSweetSprayTagEnd.Old == 0 && tut_cutsceneSweetSprayTagEnd.Current == 1) {
							return "tut_cutsceneSweetSprayTagEnd";
						}

						// Sub phase:
						// Appears to be related to the help boxes/objectives notifications.
						// It gets set to 1 when the "hold LMB to spray" box displays, and 2 for the subsequent box
						// Upon entering Sweets car after spraying first 3 tags, it gets reset to 0
						// On the drive, it gets set to 1.
						// It gets set to 0 when leaving the car, then set back to 1 shortly after.
						var tut_subPhase = vars.GetWatcher("58@");
						if (tut_subPhase.Changed) {
							if (tut_subPhase.Old == 2 && tut_subPhase.Current == 0) {
								return "tut_carEnterAfterTag3";
							}
							else if (tut_subPhase.Old == 1 && tut_subPhase.Current == 0) {
								return "tut_carExitBeforeTag4";
							}
						}

						// A variable keeping track of which lines are to be said by the gang members.
						// Set to 1 when the approach cutscene ended, or when it should have played if killing the gang members
						// Set to 2 and then 3 as lines are spoken, or to 4 if gang members are dead
						var tut_approachingGangMembers = vars.GetWatcher("46@");
						if (tut_approachingGangMembers.Changed && tut_approachingGangMembers.Old == 0 && tut_approachingGangMembers.Current == 1) {
							return "tut_approachingGangMembers";
						}

						// "Get us back to the hood, CJ" line played
						var tut_carEnterAfterTag6 = vars.GetWatcher("40@");
						if (tut_carEnterAfterTag6.Changed && tut_carEnterAfterTag6.Old == 0 && tut_carEnterAfterTag6.Current == 1) {
							return "tut_carEnterAfterTag6";
						}

						return;
					};
					vars.CheckSplit.Add(func_tut);

				#endregion
				#region Cleaning the Hood
					settings.Add("cth", true, "Cleaning the Hood", "LS_Sweet");
					settings.CurrentDefaultParent = "cth";
					settings.Add("cth_marker", false, "Mission Marker Entered");
					settings.Add("cth_start", false, "Mission Started");
					settings.Add("cth_cutsceneSkipped", false, "Intro cinematic end");
					settings.Add("cth_bDupVisited", false, "After visiting B Dup");
					settings.Add("cth_dealerApproached", false, "Approaching and talking to the dealer");
					settings.SetToolTip("cth_dealerApproached", "This is skipped in common speedruns.");
					settings.Add("cth_dealerKilled", false, "Cutscene start after killing dealer");
					settings.Add("cth_crackDenArrive", false, "Arrival in front of the crack Den");
					settings.Add("cth_crackDenCleared", false, "Crack den occupants killed");
					settings.Add("cth_finalCutscene", false, "Arrival back at Grove Street");
					settings.Add("cth_pass", true, "Mission Passed");

					vars.watchScmMissionLocalVariables.Add(43);
					vars.watchScmMissionLocalVariables.Add(87);
					vars.watchScmMissionLocalVariables.Add(91);
					vars.watchScmMissionLocalVariables.Add(102);

					vars.significantThreads.Add("sweet1b","cth_start");
					vars.missionNames.Add("Cleaning the Hoo","cth_marker");

					Func<string> func_cth = () => {
						if (!vars.ValidateMissionProgress("sweet1b", "ls_sweet_chain", 1, 2, "cth_pass", "cth")) {
							return;
						}

						// Act:
						// 0 - Start
						// 1 - After visiting B Dup
						// 2 - After dealer dead cutscene
						// 3 - Getting out of the car in front of the house
						// 4 - Indoor combat done
						var cth_stage = vars.GetWatcher("102@");
						if (cth_stage.Changed) {
							if (cth_stage.Current == 1) {
								return "cth_bDupVisited";
							}
							else if (cth_stage.Current == 3) {
								return "cth_crackDenArrive";
							}
						}

						// Dialogue block:
						// 0 - Hey, B Dup is only a couple blocks (7)
						// 1 - Man, I know this cat (6)
						// 2 - <unused>
						// 3 - Now Ballas know Grove Street Families on their way back up (5)
						// 4 - Hey Partner, Im working man (1)
						// 5 - Man, we on a serious mission now (1)
						// 6 - Oooeee you can smell a crack den (1)
						// 7 - Now that the base ain't getting pushed up (3)
						var cth_dialogueBlock = vars.GetWatcher("87@");
						if (cth_dialogueBlock.Changed) {
							if (cth_dialogueBlock.Current == 4) {
								return "cth_dealerApproached";
							}
							else if (cth_dialogueBlock.Current == 1) {
								return "cth_dealerKilled";
							}
							else if (cth_dialogueBlock.Current == 7) {
								return "cth_finalCutscene";
							}
						}

						// When a dialogue block is selected, another variable is set as well to indicate the number of lines in this dialogue.
						var cth_dialogueLength = vars.GetWatcher("91@");
						if (cth_dialogueLength.Changed) {
							if (cth_dialogueLength.Current == 7) {
								return "cth_cutsceneSkipped";
							}
						}

						// Upon killing all 3 Ballas guys
						var cth_crackDenCleared = vars.GetWatcher("43@");
						if (cth_crackDenCleared.Changed && cth_crackDenCleared.Old == 0 && cth_crackDenCleared.Current == 1) {
							return "cth_crackDenCleared";
						}
						return;
					};
					vars.CheckSplit.Add(func_cth);

				#endregion
				#region Drive-Thru
					settings.Add("dt", true, "Drive-Thru", "LS_Sweet");
					settings.CurrentDefaultParent = "dt";
					settings.Add("dt_marker", false, "Mission Marker Entered");
					settings.Add("dt_start", false, "Mission Started");
					settings.Add("dt_introEnded", false, "Intro cinematic end");
					settings.Add("dt_chaseStarted", false, "Start of the chase");
					settings.Add("dt_chaseOver", false, "Ballas killed");
					settings.Add("dt_returnToGrove", false, "Start of cutscene back at Grove Street");
					settings.Add("dt_leavingGrove", false, "End of cutscene back at Grove Street");
					settings.Add("dt_arriveAtSmokes", false, "Arrival at Big Smoke's House");
					settings.Add("dt_pass", true, "Mission Passed");
					settings.SetToolTip("dt_introEnded", "Splits after \"Smoke looks like he's gonna pass out\" line.");

					vars.watchScmMissionLocalVariables.Add(79);

					vars.significantThreads.Add("sweet3","dt_start");
					vars.missionNames.Add("Drive-thru","dt_marker");

					Func<string> func_dt = () => {
						if (!vars.ValidateMissionProgress("sweet3", "ls_sweet_chain", 2, 3, "dt_pass", "dt")) {
							return;
						}

						// Dialogue block:
						// 1 - How'd mom get killed
						// 2 - Hit it, go go go
						// 3 - Damn that was some serious shit
						// 4 - Thats one up for the Grove
						// 5 - What was with you back there Smoke
						// 6 - Hey thanks Carl
						// 7 - My special!
						// 8 - Watch the damn road
						var dt_dialogueBlock = vars.GetWatcher("79@");
						if (dt_dialogueBlock.Changed) {
							if (dt_dialogueBlock.Current == 1) {
								return "dt_introEnded";
							}
							if (dt_dialogueBlock.Current == 2) {
								return "dt_chaseStarted";
							}
							else if (dt_dialogueBlock.Current == 3) {
								return "dt_chaseOver";
							}
							else if (dt_dialogueBlock.Current == 4) {
								return "dt_returnToGrove";
							}
							else if (dt_dialogueBlock.Current == 5) {
								return "dt_leavingGrove";
							}
							else if (dt_dialogueBlock.Current == 6) {
								return "dt_arriveAtSmokes";
							}
						}

						return;
					};
					vars.CheckSplit.Add(func_dt);
				#endregion
				#region Nines and AK's
					settings.Add("naak", true, "Nines and AK's", "LS_Sweet");
					settings.CurrentDefaultParent = "naak";
					settings.Add("naak_marker", false, "Mission Marker Entered");
					settings.Add("naak_start", false, "Mission Started");
					settings.Add("naak_cutsceneEnd", false, "Intro cinematic end");
					settings.Add("naak_round1Start", false, "Bottleshooter round 1 started");
					settings.Add("naak_round1Bottle1", false, "Round 1: 1 bottle shot");
					settings.Add("naak_round2Start", false, "Bottleshooter round 1 started");
					settings.Add("naak_round2Bottle1", false, "Round 2: 1 bottle shot");
					settings.Add("naak_round2Bottle2", false, "Round 2: 2 bottles shot");
					settings.Add("naak_round2Bottle3", false, "Round 2: 3 bottles shot");
					settings.Add("naak_round3Start", false, "Bottleshooter round 3 started");
					settings.Add("naak_round3Bottle1", false, "Round 3: 1 bottle shot");
					settings.Add("naak_round3Bottle2", false, "Round 3: 2 bottles shot");
					settings.Add("naak_round3Bottle3", false, "Round 3: 3 bottles shot");
					settings.Add("naak_round3Bottle4", false, "Round 3: 4 bottles shot");
					settings.Add("naak_round3Bottle5", false, "Round 3: 5 bottles shot");
					settings.Add("naak_postShootoutCutsceneStart", false, "Start of cutscene after blowing up Tampa");
					settings.Add("naak_postShootoutCutsceneEnd", false, "End of cutscene after blowing up Tampa");
					settings.Add("naak_phoneCall", false, "Answering Sweet's phone call");
					settings.Add("naak_shopEnter", false, "Clothing store enter");
					settings.Add("naak_shopExit", false, "Clothing store exit");
					settings.Add("naak_pass", true, "Mission Passed");

					vars.watchScmMissionLocalVariables.Add(39);
					vars.watchScmMissionLocalVariables.Add(48);
					vars.watchScmMissionLocalVariables.Add(36);
					vars.watchScmMissionLocalVariables.Add(62);
					vars.watchScmMissionLocalVariables.Add(64);
					vars.watchScmMissionLocalVariables.Add(86);

					vars.significantThreads.Add("sweet2","naak_start");
					vars.missionNames.Add("Nines and AK's","naak_marker");

					Func<string> func_naak = () => {
						if (!vars.ValidateMissionProgress("sweet2", "ls_sweet_chain", 3, 4, "naak_pass", "naak")) {
							return;
						}

						// Dialogue block:
						// 0 - What happened to the families? (8)
						// 1 - Damn, you a killer baby, ice cold
						// 2 - Whats going on man shit seems fucked up
						// 3 - Speak; I thought you was representing
						var naak_dialogueBlock = vars.GetWatcher("39@");
						if (naak_dialogueBlock.Changed) {
							if (naak_dialogueBlock.Current == 1) {
								return "naak_postShootoutCutsceneStart";
							}
							if (naak_dialogueBlock.Current == 2) {
								return "naak_postShootoutCutsceneEnd";
							}
							else if (naak_dialogueBlock.Current == 3) {
								return "naak_phoneCall";
							}
						}
						var naak_dialogueLength = vars.GetWatcher("48@");
						if (naak_dialogueLength.Changed) {
							if (naak_dialogueLength.Current == 8 && naak_dialogueLength.Old == 0) {
								return "naak_cutsceneEnd";
							}
						}

						// Bottle shooter segment:
						// Smoke actions:
						// 0 - First bottle
						// 3 - Second three bottles
						// 6 - Final five bottles
						var naak_combatActive = vars.GetWatcher("62@");
						if (naak_combatActive.Current == 1) {
							var naak_smokeActions = vars.GetWatcher("64@");
							var naak_bottlesShot = vars.GetWatcher("36@");
							if (naak_combatActive.Changed) {
								if (naak_smokeActions.Current == 0) {
									return "naak_round1Start";
								}
								else if (naak_smokeActions.Current == 3) {
									return "naak_round2Start";
								}
								else if (naak_smokeActions.Current == 6) {
									return "naak_round3Start";
								}
							}
							if (naak_bottlesShot.Changed && naak_bottlesShot.Current > 0) {
								if (naak_smokeActions.Current == 0) {
									return "naak_round1Bottle" + naak_bottlesShot.Current;
								}
								else if (naak_smokeActions.Current == 3) {
									return "naak_round2Bottle" + naak_bottlesShot.Current;
								}
								else if (naak_smokeActions.Current == 6) {
									return "naak_round3Bottle" + naak_bottlesShot.Current;
								}
							}
						}

						var naak_interior = vars.GetWatcher("86@");
						if (naak_interior.Changed && naak_dialogueBlock.Current == 3) {
							if (naak_interior.Current == 15 && naak_interior.Old == 0) {
								return "naak_shopEnter";
							}
							if (naak_interior.Current == 0 && naak_interior.Old == 15) {
								return "naak_shopExit";
							}
						}
						return;
					};
					vars.CheckSplit.Add(func_naak);
				#endregion
				#region Drive-By
					settings.Add("db", true, "Drive-By", "LS_Sweet");
					settings.CurrentDefaultParent = "db";
					settings.Add("db_marker", false, "Mission Marker Entered");
					settings.Add("db_start", false, "Mission Started");
					settings.Add("db_carEnter", false, "Everybody entered Sweet's car");
					settings.Add("db_markerArrive", false, "Arrival at the marker");
					settings.Add("db_shootoutStart", false, "Shootout section begin");
					for (int i = 0; i < 16; i++) {
						if (i % 4 == 0) {
							settings.Add("db_group"+(i/4), false, "Group "+((i/4)+1), "db");
							settings.CurrentDefaultParent = "db_group"+(i/4);
						}
						settings.Add("db_kill"+i, false, "Ballas #"+(i+1)+" killed");
						if (i % 4 == 3) {
							settings.Add("db_group"+(i/4)+"all", false, "Entire group killed");
						}
					}
					settings.CurrentDefaultParent = "db";
					settings.Add("db_shootoutEnd", false, "All Ballas killed");
					settings.Add("db_payNSpray", false, "Car resprayed");
					settings.Add("db_groveCut", false, "Arrival at Grove Street");
					settings.Add("db_pass", true, "Mission Passed");

					vars.watchScmGlobalVariables.Add(6637, "db_stage");
					for (int i = 0; i < 16; i++) {
						vars.watchScmGlobalVariables.Add(6640+i, "db_kill"+i);
					}

					vars.significantThreads.Add("sweet4","db_start");
					vars.missionNames.Add("Drive-By","db_marker");

					Func<string> func_db = () => {
						if (!vars.ValidateMissionProgress("sweet4", "ls_sweet_chain", 4, 5, "db_pass", "db")) {
							return;
						}

						// Stage
						// 3 - Entered car, drive to destination
						// 4 - Cutscene before shootout
						// 5 - Shootout
						// 6 - Drive to pay n spray
						// 7 - Drive back
						// 8 - Grove Cut
						var db_stage = vars.GetWatcher("db_stage");
						if (db_stage.Changed) {
							switch ((int)db_stage.Current) {
								case 3:
									return "db_carEnter";
									break;
								case 4:
									return "db_markerArrive";
									break;
								case 5:
									return "db_shootoutStart";
									break;
								case 6:
									return "db_shootoutEnd";
									break;
								case 7:
									return "db_payNSpray";
									break;
								case 8:
									return "db_groveCut";
									break;
								default:
									break;
							}
						}
						var db_groupKillCount = 0;
						var db_killHappened = false;
						for (int i = 0; i < 16; i++) {
							if (i % 4 == 0) {
								db_groupKillCount = 0;
							}
							var db_kill = vars.GetWatcher("db_kill"+i);
							if (db_kill.Current == 1) {
								db_groupKillCount++;
								if (db_kill.Changed) {
									db_killHappened = true;
									vars.TrySplit("db_kill"+i);
								}
								if (db_groupKillCount == 4 && db_killHappened) {
									vars.TrySplit("db_group"+(i/4)+"all");
								}
							}
						}
						return;
					};
					vars.CheckSplit.Add(func_db);

				#endregion
				#region Sweet's Girl
					settings.Add("sg", true, "Sweet's Girl", "LS_Sweet");
					settings.CurrentDefaultParent = "sg";
					settings.Add("sg_marker", false, "Mission Marker Entered");
					settings.Add("sg_start", false, "Mission Started");
					settings.Add("sg_introCut", false, "Intro cinematic end");
					settings.Add("sg_combatOver", false, "All enemies killed");
					settings.Add("sg_findCar", false, "Phonecall end");
					settings.Add("sg_carFound", false, "Marker entered with valid 4-door car");
					settings.Add("sg_chaseStart", false, "Chase start");
					settings.Add("sg_chaseEnd", false, "Arrival at Sweet's house");
					settings.Add("sg_pass", true, "Mission Passed");

					vars.watchScmMissionLocalVariables.Add(127);

					vars.significantThreads.Add("hoods5","sg_start");
					vars.missionNames.Add("Sweet's Girl","sg_marker");

					Func<string> func_sg = () => {
						if (!vars.ValidateMissionProgress("hoods5", "ls_sweet_chain", 5,  6, "sg_pass", "sg")) {
							return;
						}

						// Stage:
						// 1 - Intro cinematic + phonecall cutscene
						// 2 - Drive to location
						// 3 - Everybody killed, phonecall
						// 4 - Find car
						// 5 - Sweet gets in car cutscene
						// 6 - Chase
						// 7 - End cut
						// 8 - Mission Passed
						var sg_stage = vars.GetWatcher("127@");
						if (sg_stage.Changed) {
							switch ((int)sg_stage.Current) {
								case 2:
									return "sg_introCut";
									break;
								case 3:
									return "sg_combatOver";
									break;
								case 4:
									return "sg_findCar";
									break;
								case 5:
									return "sg_carFound";
									break;
								case 6:
									return "sg_chaseStart";
									break;
								case 7:
									return "sg_chaseEnd";
									break;
							}
						}
						return;
					};
					vars.CheckSplit.Add(func_sg);
				#endregion
				#region Cesar Vialpando
					settings.Add("cv", true, "Cesar Vialpando", "LS_Sweet");
					settings.CurrentDefaultParent = "cv";
					settings.Add("cv_marker", false, "Mission Marker Entered");
					settings.Add("cv_start", false, "Mission Started");
					settings.Add("cv_introCut", false, "Intro cinematic end");
					settings.Add("cv_arriveAtGarage", false, "Arriving at the mod shop");
					settings.Add("cv_cutsceneAtGarageStart", false, "Cutscene at mod shop start");
					settings.Add("cv_cutsceneAtGarageEnd", false, "Cutscene at mod shop end");
					settings.Add("cv_garageEnter", false, "Mod shop entered");
					settings.Add("cv_garageExit", false, "Mod shop exited");
					settings.Add("cv_danceCutStart", false, "Arrival at the car meeting");
					settings.Add("cv_danceCutEnd", false, "Start of the wager placement screen");
					settings.Add("cv_wagerPlaced", false, "Wager placed");
					settings.Add("cv_danceStart", false, "Dance start");
					settings.Add("cv_feedbackStart", false, "Dance end");
					settings.Add("cv_endCinematicStart", false, "Start of final cinematic");
					settings.Add("cv_pass", true, "Mission Passed");

					vars.watchScmMissionLocalVariables.Add(34);
					vars.watchScmMissionLocalVariables.Add(35);

					vars.significantThreads.Add("sweet6", "cv_start");
					vars.missionNames.Add("Cesar Vialpando","cv_marker");

					Func<string> func_cv = () => {
						if (!vars.ValidateMissionProgress("sweet6", "ls_sweet_chain", 6, 7, "cv_pass", "cv")) {
							return;
						}

						// Stage.SubStage:
						// 1.1 = Intro cutscene
						// 1.2 = Fadein
						// 2.0 = Drive
						// 2.2 = Marker hit (fadeout)
						// 2.4 = Cutscene of guy handing you car
						// 2.19 = Gameplay, drive car into garage
						// 2.20 = Mod shop menu gameplay
						// 3.1 = Drive to the meet
						// 4.0 = Cutscene of dude walking over to you
						// 4.4 = Cutscene of dude talking to you
						// 4.6 = Wager placement menu
						// 4.10 = Cutscene after placing wager
						// 5.7 = dancing
						// 6.1 = feedback cutscene
						// 6.9 = cinematic cutscene with Kendl
						// 7.0 = mission passed
						var cv_stage = vars.GetWatcher("34@");
						var cv_subStage = vars.GetWatcher("35@");
						if (cv_subStage.Changed) {
							switch((int)cv_stage.Current) {
								case 1:
									if (cv_subStage.Current == 1) {
										return "cv_introCut";
									}
									break;
								case 2:
									if (cv_subStage.Current == 2) {
										return "cv_arriveAtGarage";
									}
									if (cv_subStage.Current == 4) {
										return "cv_cutsceneAtGarageStart";
									}
									if (cv_subStage.Current == 19) {
										return "cv_cutsceneAtGarageEnd";
									}
									if (cv_subStage.Current == 20) {
										return "cv_garageEnter";
									}
									break;
								case 3:
									if (cv_subStage.Current == 1) {
										return "cv_garageExit";
									}
									break;
								case 4:
									if (cv_subStage.Current == 0) {
										return "cv_danceCutStart";
									}
									if (cv_subStage.Current == 6) {
										return "cv_danceCutEnd";
									}
									if (cv_subStage.Current == 10) {
										return "cv_wagerPlaced";
									}
									break;
								case 5:
									if (cv_subStage.Current == 7) {
										return "cv_danceStart";
									}
									break;
								case 6:
									if (cv_subStage.Current == 1) {
										return "cv_feedbackStart";
									}
									if (cv_subStage.Current == 9) {
										return "cv_endCinematicStart";
									}
									break;
							}
						}
						return;
					};
					vars.CheckSplit.Add(func_cv);
				#endregion
				#region Doberman
					settings.Add("d", true, "Doberman", "LS_Sweet");
					settings.SetToolTip("d", "See also: Specific gang territory Glen Park: GLN1");
					settings.CurrentDefaultParent = "d";
					settings.Add("d_marker", false, "Mission Marker Entered");
					settings.Add("d_start", false, "Mission Started");
					settings.Add("d_cut1", false, "Intro cutscenes over");
					settings.Add("d_cut2", false, "Glen park cutscene over");
					settings.Add("d_pass", true, "Mission Passed");

					vars.significantThreads.Add("crash4", "d_start");
					vars.missionNames.Add("Doberman","d_marker");

					vars.watchScmGlobalVariables.Add(2414, "d_cut2");
					vars.watchScmGlobalVariables.Add(2577, "d_cut1");

					Func<string> func_d = () => {
						if (!vars.ValidateMissionProgress("crash4", "ls_sweet_chain", 7, 8, "d_pass", "d")) {
							return;
						}
						var d_cut1 = vars.GetWatcher("d_cut1");
						if (d_cut1.Changed && d_cut1.Current == 1) {
							return "d_cut1";
						}
						var d_cut2 = vars.GetWatcher("d_cut2");
						if (d_cut2.Changed && d_cut2.Current == 1) {
							return "d_cut2";
						}

						return;
					};
					vars.CheckSplit.Add(func_d);
				#endregion
				#region Los Sepulcros
					settings.Add("ls", true, "Los Sepulcros", "LS_Sweet");
					settings.CurrentDefaultParent = "ls";
					settings.Add("ls_marker", false, "Mission Marker Entered");
					settings.Add("ls_start", false, "Mission Started");
					settings.Add("ls_pass", true, "Mission Passed");

					vars.significantThreads.Add("sweet7", "ls_start");
					vars.missionNames.Add("Los Sepulcros","ls_marker");

					Func<string> func_ls = () => {
						if (!vars.ValidateMissionProgress("sweet7", "ls_sweet_chain", 8, 9, "ls_pass", "ls")) {
							return;
						}
						return;
					};
					vars.CheckSplit.Add(func_ls);
				#endregion
				#endregion
				#region Smoke Chain
					settings.Add("LS_Smoke", true, "Big Smoke", "LS");
					// 1: OG Loc
					// 2: Running Dog
					// 3: Wrong Side of the Tracks
					// 4: Just Business
					vars.watchScmGlobalVariables.Add(454, "ls_smoke_chain"); // $SMOKE_TOTAL_PASSED_MISSIONS
					#region OG Loc
						settings.Add("ogl", true, "OG Loc", "LS_Smoke");
						settings.CurrentDefaultParent = "ogl";
						settings.Add("ogl_marker", false, "Mission Marker Entered");
						settings.Add("ogl_start", false, "Mission Started");
						settings.Add("ogl_introCinematicEnd", false, "Intro cutscenes end");
						settings.Add("ogl_arriveAtPrecinct", false, "Cutscene at police station start");
						settings.Add("ogl_leavePrecinct", false, "Cutscene at police station end");
						settings.Add("ogl_arriveAtHouse", false, "Cutscene in front of Freddy's start");
						settings.Add("ogl_approachHouse", false, "Cutscene in front of Freddy's end");
						settings.Add("ogl_knockOnDoor", false, "Knocking on Freddy's door");
						settings.Add("ogl_chaseStarted", false, "Chase started");
						settings.Add("ogl_stage5", false, "Freddy arrives at the corner in Los Flores");
						settings.Add("ogl_chase", false, "Extra chase moments");
						settings.SetToolTip("ogl_chase", "These are normally skipped in a regular speedrun as the chase is ended early.");
						settings.Add("ogl_stage6", false, "Freddy arrives up the hill in East Los Santos", "ogl_chase");
						settings.Add("ogl_stage7", false, "Freddy arrives at base of steep road in Las Colinas", "ogl_chase");
						settings.Add("ogl_stage8", false, "Freddy arrives at Mulholland Intersection", "ogl_chase");
						settings.Add("ogl_stage9", false, "Freddy exits the highway at Commerce", "ogl_chase");
						settings.Add("ogl_stage10", false, "Freddy arrives near the skatepark", "ogl_chase");
						settings.Add("ogl_stage11", false, "Freddy exits the highway at East Los Santos", "ogl_chase");
						settings.Add("ogl_stage12", false, "Freddy arrives at a Well Stacked Pizza", "ogl_chase");
						settings.Add("ogl_stage13", false, "Freddy arrives at The Pig Pen", "ogl_chase");
						settings.Add("ogl_chaseOver", false, "Freddy gets off his bike at the park", "ogl_chase");
						settings.Add("ogl_targetDead", false, "Freddy dead");
						settings.Add("ogl_travelToBurgerShot", false, "Cutscene after killing Freddy end");
						settings.Add("ogl_atBurgerShot", false, "Arrival at Burger Shot");
						settings.Add("ogl_pass", true, "Mission Passed");

						vars.watchScmMissionLocalVariables.Add(67);
						vars.watchScmMissionLocalVariables.Add(68);

						vars.significantThreads.Add("twar7","ogl_start");
						vars.missionNames.Add("OG Loc","ogl_marker");

						Func<string> func_ogl = () => {
							if (!vars.ValidateMissionProgress("twar7", "ls_smoke_chain", 0, 1, "ogl_pass", "ogl")) {
								return;
							}

							// Stage:
							// 0 - Intro cutscenes
							// 1 - Drive to police station and then to the house
							// 2 - Cutscene in front of house
							// 3 - Walking up the stairs
							// 4-13 Bike Chase
							// 14 Combat
							// 15 Target dead
							// 16 Drive to burger shot
							// 17 At burger shot
							var ogl_stage = vars.GetWatcher("67@");
							if (ogl_stage.Changed) {
								switch ((int)ogl_stage.Current) {
									case 1:
										return "ogl_introCinematicEnd";
										break;
									case 2:
										return "ogl_arriveAtHouse";
										break;
									case 3:
										return "ogl_approachHouse";
										break;
									case 4:
										return "ogl_chaseStarted";
										break;
									case 14:
										return "ogl_chaseOver";
										break;
									case 15:
										return "ogl_targetDead";
										break;
									case 16:
										return "ogl_travelToBurgerShot";
										break;
									case 17:
										return "ogl_atBurgerShot";
										break;
									case 0:
										break;
									default:
										return "ogl_stage" + ogl_stage.Current;
										break;
								}

								if (ogl_stage.Current == 1) {
									return "";
								}
							}
							// Unsure what this variable does exactly
							var ogl_subStage = vars.GetWatcher("68@");
							if (ogl_subStage.Changed) {
								if (ogl_subStage.Current == 1) {
									if (ogl_stage.Current == 1) {
										return "ogl_arriveAtPrecinct";
									}
									if (ogl_stage.Current == 3) {
										return "ogl_knockOnDoor";
									}
								}
								if (ogl_subStage.Current == 2 && ogl_stage.Current == 1) {
									return "ogl_leavePrecinct";
								}
							}
							return;
						};
						vars.CheckSplit.Add(func_ogl);

					#endregion
					#region Running Dog
						settings.Add("rd", true, "Running Dog", "LS_Smoke");
						settings.CurrentDefaultParent = "rd";
						settings.Add("rd_marker", false, "Mission Marker Entered");
						settings.Add("rd_start", false, "Mission Started");
						settings.Add("rd_car", false, "Entered Big Smoke's car");
						settings.Add("rd_arrive", false, "Start of mid mission cinematic");
						settings.Add("rd_chaseStart", false, "End of mid mission cinematic");
						settings.Add("rd_pass", true, "Mission Passed");

						vars.watchScmMissionLocalVariables.Add(162);
						vars.watchScmMissionLocalVariables.Add(166);
						vars.watchScmMissionLocalVariables.Add(181);

						vars.significantThreads.Add("smoke2","rd_start");
						vars.missionNames.Add("Running Dog","rd_marker");

						Func<string> func_rd = () => {
							if (!vars.ValidateMissionProgress("smoke2", "ls_smoke_chain", 1, 2, "rd_pass", "rd")) {
								return;
							}

							var rd_car = vars.GetWatcher("162@");
							if (rd_car.Changed && rd_car.Current == 1) {
								return "rd_car";
							}
							var rd_arrive = vars.GetWatcher("166@");
							if (rd_arrive.Changed && rd_arrive.Current == 1) {
								return "rd_arrive";
							}
							var rd_chaseStart = vars.GetWatcher("181@");
							if (rd_chaseStart.Changed && rd_chaseStart.Current == 1) {
								return "rd_chaseStart";
							}
							return;
						};
						vars.CheckSplit.Add(func_rd);

					#endregion
					#region Wrong Side of the Tracks
						settings.Add("wsott", true, "Wrong Side of the Tracks", "LS_Smoke");
						settings.CurrentDefaultParent = "wsott";
						settings.Add("wsott_marker", false, "Mission Marker Entered");
						settings.Add("wsott_start", false, "Mission Started");
						settings.Add("wsott_cutEnd", false, "Intro cinematic end");
						settings.Add("wsott_chaseStart", false, "Start of the case");
						settings.Add("wsott_bikeEntered", false, "Sanchez mounted");
						settings.Add("wsott_guy0", false, "Vagos member #1 killed");
						settings.SetToolTip("wsott_guy0", "Front most");
						settings.Add("wsott_guy1", false, "Vagos member #2 killed");
						settings.SetToolTip("wsott_guy1", "Second from the front");
						settings.Add("wsott_guy2", false, "Vagos member #3 killed");
						settings.SetToolTip("wsott_guy2", "Third from the front");
						settings.Add("wsott_subWin", false, "Three frontmost Vagos killed");
						settings.SetToolTip("wsott_subWin", "Splits when all except the rear most Vagos are killed, as the guy in the back dies by himself.");
						settings.Add("wsott_guy3", false, "Vagos member #4 killed");
						settings.SetToolTip("wsott_guy3", "Rear most, gets himself killed by an overhanging beam early on");
						settings.Add("wsott_win", false, "All Vagos killed");
						settings.Add("wsott_return", false, "Returned to Smoke's house");
						settings.Add("wsott_pass", true, "Mission Passed");

						vars.significantThreads.Add("smoke3", "wsott_start");
						vars.missionNames.Add("Wrong Side of th","wsott_marker");

						vars.watchScmMissionLocalVariables.Add(80);		// smoke_s3flag
						vars.watchScmMissionLocalVariables.Add(87);		// mex1dead_s3flag
						vars.watchScmMissionLocalVariables.Add(88);		// mex2dead_s3flag
						vars.watchScmMissionLocalVariables.Add(89);		// mex3dead_s3flag
						vars.watchScmMissionLocalVariables.Add(90);		// mex4dead_s3flag
						vars.watchScmMissionLocalVariables.Add(128);	// audio_label_s3

						Func<string> func_wsott = () => {
							if (!vars.ValidateMissionProgress("smoke3", "ls_smoke_chain", 2, 3, "wsott_pass", "wsott")) {
								return;
							}
							var wsott_stage = vars.GetWatcher("80@");
							if (wsott_stage.Changed) {
								switch ((int)wsott_stage.Current) {
									case 1:
										return "wsott_cutEnd";
										break;
									case 2:
										return "wsott_chaseStart";
										break;
									case 3:
										vars.TrySplit("wsott_win");
										break;
									case 4:
										return "wsott_return";
										break;
								}
							}
							var wsott_bikeEntered = vars.GetWatcher("128@");
							if (wsott_bikeEntered.Changed && wsott_bikeEntered.Current == 35420) {
								// Audio data for Smoke's line "Follow that train".
								return "wsott_bikeEntered";
							}
							var wsott_kills = 0;
							var wsott_freshKill = false;
							for (int i = 0; i < 4; i++) {
								if (i == 3 && wsott_freshKill && wsott_kills == 3) {
									vars.TrySplit("wsott_subWin");
								}
								var wsott_guy = vars.GetWatcher((87+i)+"@");
								if (wsott_guy.Changed && wsott_guy.Current == 1) {
									wsott_freshKill = true;
									vars.TrySplit("wsott_guy"+i);
								}
								if (wsott_guy.Current == 1) {
									wsott_kills++;
								}
							}
							return;
						};
						vars.CheckSplit.Add(func_wsott);
					#endregion
					#region Just Business
						settings.Add("jb", true, "Just Business", "LS_Smoke");
						settings.CurrentDefaultParent = "wsott";
						settings.Add("jb_marker", false, "Mission Marker Entered");
						settings.Add("jb_start", false, "Mission Started");
						settings.Add("jb_introCut", false, "Intro cinematic ended");
						settings.Add("jb_arrive", false, "Arrival at the atrium building");
						settings.Add("jb_shootoutStart", false, "Shootout inside atrium start");
						settings.Add("jb_atriumSmokeStepsArrive", false, "Smoke moved towards the stairs");
						settings.Add("jb_atriumSmokeStepsCross", false, "Smoke moved past the stairs");
						settings.Add("jb_atriumSmokePillar", false, "Smoke moved towards the exit");
						settings.Add("jb_atriumSmokeLeaving", false, "Shootout inside atrium over");
						settings.Add("jb_atriumOutside", false, "Shootout outside atrium start");
						settings.Add("jb_shootoutEnd", false, "Shootout outside atrium over");
						settings.Add("jb_leavingAtrium", false, "Start of cutscene before chase sequence");
						settings.Add("jb_chaseStart", false, "End of cutscene before chase sequence");
						settings.Add("jb_chaseBlock", false, "Smoke starts driving into the sewer");
						settings.Add("jb_pass", true, "Mission Passed");

						vars.missionNames.Add("Just Business", "jb_marker");
						vars.significantThreads.Add("drugs1", "jb_start");

						vars.watchScmMissionLocalVariables.Add(90);		// smoke_s4flag
						vars.watchScmMissionLocalVariables.Add(243);	// firstchase_s4flag

						vars.watchScmGlobalVariables.Add(6898, "jb_atriumStage");

						Func<string> func_jb = () => {
							if (!vars.ValidateMissionProgress("drugs1", "ls_smoke_chain", 3, 4, "jb_pass", "jb")) {
								return;
							}
							var jb_stage = vars.GetWatcher("90@");
							if (jb_stage.Changed) {
								switch ((int)jb_stage.Current) {
									case 1:
										return "jb_introCut";
										break;
									case 8:
										return "jb_arrive";
										break;
									case 11:
										return "jb_shootoutStart";
										break;
									case 12:
										return "jb_shootoutEnd";
										break;
									case 14:
										return "jb_leavingAtrium";
										break;
									case 20:
										return "jb_chaseStart";
										break;
								}
							}
							var jb_atriumStage = vars.GetWatcher("jb_atriumStage");
							if (jb_atriumStage.Changed) {
								switch ((int)jb_atriumStage.Current) {
									case 3:
										return "jb_atriumSmokeStepsArrive";
										break;
									case 4:
										return "jb_atriumSmokeStepsCross";
										break;
									case 5:
										return "jb_atriumSmokePillar";
										break;
									case 6:
										return "jb_atriumSmokeLeaving";
										break;
									case 7:
										return "jb_atriumOutside";
										break;
								}
							}
							var jb_chaseBlock = vars.GetWatcher("243@");
							if (jb_chaseBlock.Changed && jb_chaseBlock.Current == 1) {
								return "jb_chaseBlock";
							}
							return;
						};
						vars.CheckSplit.Add(func_jb);
					#endregion
				#endregion
				#region Ogloc Chain
					settings.Add("LS_Ogloc", true, "OG Loc", "LS");
					// 1: Life's a Beach
					// 2: Madd Dogg's Rhymes
					// 3: Management Issues
					// 4: House Party (Cutscene)
					// 5: House Party
					vars.watchScmGlobalVariables.Add(455, "ls_ogloc_chain"); // $OG_LOC_TOTAL_PASSED_MISSIONS
					#region Life's a Beach
						settings.Add("lab", true, "Life's a Beach", "LS_Ogloc");
						settings.CurrentDefaultParent = "lab";
						settings.Add("lab_marker", false, "Mission Marker Entered");
						settings.Add("lab_start", false, "Mission Started");
						settings.Add("lab_partyObserved", false, "Cutscene near party playing");
						settings.Add("lab_vanEntered", false, "Van entered");
						settings.Add("lab_pass", true, "Mission Passed");

						vars.watchScmMissionLocalVariables.Add(207);
						vars.watchScmMissionLocalVariables.Add(279);

						vars.significantThreads.Add("music1","lab_start");
						vars.missionNames.Add("Life's a Beach","lab_marker");

						Func<string> func_lab = () => {
							if (!vars.ValidateMissionProgress("music1", "ls_ogloc_chain", 0, 1, "lab_pass", "lab")) {
								return;
							}
							// Other vars I found but couldn't determine consistency/usefulness:
							// 193@ - approaching the beach (party spawns in)
							// 189@ - "Hes Stealing the Sounds"
							var lab_partyObserved = vars.GetWatcher("279@");
							if (lab_partyObserved.Changed && lab_partyObserved.Current == 1) {
								return "lab_partyObserved";
							}
							var lab_vanEntered = vars.GetWatcher("207@");
							if (lab_vanEntered.Changed && lab_vanEntered.Current == 1) {
								return "lab_vanEntered";
							}
							return;
						};
						vars.CheckSplit.Add(func_lab);

					#endregion
					#region Madd Dogg's Rhymes
						settings.Add("mdr", true, "Madd Dogg's Rhymes", "LS_Ogloc");
						settings.CurrentDefaultParent = "mdr";
						settings.Add("mdr_marker", false, "Mission Marker Entered");
						settings.Add("mdr_start", false, "Mission Started");
						settings.Add("mdr_houseApproach", false, "Approaching mansion");
						settings.SetToolTip("mdr_houseApproach", "Triggers when the message about the entrance being around the back shows up");
						settings.Add("mdr_houseEnter", false, "Mansion entered");
						settings.Add("mdr_poolArea", false, "Cutscene before swimming pool end");
						settings.Add("mdr_alcoveArea", false, "Cutscene before plant hallway end");
						settings.Add("mdr_gamingArea", false, "Cutscene before lounge end");
						settings.Add("mdr_book", false, "Rhyme book picked up");
						settings.Add("mdr_houseExit", false, "Mansion exited");
						settings.Add("mdr_endCut", false, "Return to Burger Shot");
						settings.Add("mdr_pass", true, "Mission Passed");

						vars.watchScmMissionLocalVariables.Add(70);
						vars.watchScmMissionLocalVariables.Add(71);
						vars.watchScmMissionLocalVariables.Add(73);

						vars.significantThreads.Add("music2","mdr_start");
						vars.missionNames.Add("Madd Dogg's Rhym","mdr_marker");

						Func<string> func_mdr = () => {
							if (!vars.ValidateMissionProgress("music2","ls_ogloc_chain",1,2,"mdr_pass", "mdr")) {
								return;
							}
							// Stage:
							// 0 - Initial drive
							// 1 - You can find the door around the back
							// 2 - Mansion entered
							// 3 - Book grabbed
							// 5 - Mansion exited
							// 6 - End cut
							var mdr_stage = vars.GetWatcher("70@");
							if (mdr_stage.Changed) {
								switch ((int)mdr_stage.Current) {
									case 1:
										return "mdr_houseApproach";
										break;
									case 2:
										return "mdr_houseEnter";
										break;
									case 3:
										return "mdr_book";
										break;
									case 5:
										return "mdr_houseExit";
										break;
									case 6:
										return "mdr_endCut";
										break;
								}
							}
							if (mdr_stage.Current != 2) {
								return;
							}
							var mdr_room = vars.GetWatcher("71@");
							if (mdr_room.Changed) {
								if (mdr_room.Current == 6) {
									return "mdr_poolArea";
								}
								if (mdr_room.Current == 9) {
									return "mdr_gamingArea";
								}
							}
							var mdr_alcoveArea = vars.GetWatcher("73@");
							if (mdr_alcoveArea.Changed && mdr_alcoveArea.Current == 1) {
								return "mdr_alcoveArea";
							}
							return;
						};
						vars.CheckSplit.Add(func_mdr);
					#endregion
					#region Management Issues
						settings.Add("mi", true, "Management Issues", "LS_Ogloc");
						settings.CurrentDefaultParent = "mi";
						settings.Add("mi_marker", false, "Mission Marker Entered");
						settings.Add("mi_start", false, "Mission Started");
						settings.Add("mi_phoneCall", false, "OG Loc calling");
						settings.Add("mi_carTaken", false, "Car taken");
						settings.Add("mi_convoyApproach", false, "Approaching convoy");
						settings.Add("mi_convoyJoin", false, "Joined convoy");
						settings.Add("mi_convoyStart", false, "Convoy starts moving");
						settings.Add("mi_convoyFrosty", false, "Convoy passes road block");
						settings.Add("mi_convoyArrive", false, "Convoy arrives at the ceremony");
						settings.Add("mi_chaseStart", false, "Chase start");
						settings.Add("mi_carDunk", false, "Car dunked");
						settings.Add("mi_pass", true, "Mission Passed");

						vars.watchScmMissionLocalVariables.Add(174);
						vars.watchScmMissionLocalVariables.Add(122);
						vars.watchScmMissionLocalVariables.Add(160);

						vars.significantThreads.Add("music3", "mi_start");
						vars.missionNames.Add("Management Issue","mi_marker");

						Func<string> func_mi = () => {
							if (!vars.ValidateMissionProgress("music3","ls_ogloc_chain",2,3,"mi_pass", "mi")) {
								return;
							}
							// Stage:
							// 1 = Car Stolen
							// 2 = Arrived at convoy
							// 3 = Convoy moving
							// 4 = Convoy arrives
							// 5 = Chase started
							// 6 = Car dunked, but spotted.
							// 7 = Car dunked
							var mi_stage = vars.GetWatcher("122@");
							if (mi_stage.Changed) {
								switch((int)mi_stage.Current) {
									case 1:
										return "mi_carTaken";
										break;
									case 2:
										return "mi_convoyJoin";
										break;
									case 3:
										return "mi_convoyStart";
										break;
									case 4:
										return "mi_convoyArrive";
										break;
									case 5:
										return "mi_chaseStart";
										break;
									case 6:
									case 7:
										return "mi_carDunk";
										break;
								}
							}
							// dialogueBlock. Relevant:
							// 1 - hey what the fuck you playing at
							// 7 - phone ringing
							// 8 - keep frosty guys
							// everything else is cutscene or chase dialogue and does not get set straight away
							var mi_dialogueBlock = vars.GetWatcher("174@");
							if (mi_dialogueBlock.Changed) {
								switch((int)mi_dialogueBlock.Current) {
									case 7:
										return "mi_phoneCall";
										break;
									case 8:
										return "mi_convoyFrosty";
										break;
								}
							}
							// variable to show the "park the car straight" objective
							var mi_convoyApproach = vars.GetWatcher("160@");
							if (mi_convoyApproach.Changed && mi_convoyApproach.Current == 1) {
								return "mi_convoyApproach";
							}
							return;
						};
						vars.CheckSplit.Add(func_mi);
					#endregion
					#region House Party
						settings.Add("hp1", true, "House Party (Cutscene)", "LS_Ogloc");
						settings.CurrentDefaultParent = "hp1";
						settings.Add("hp1_start", false, "Mission Started");
						settings.Add("hp1_pass", true, "Mission Passed");
						settings.Add("hp2", true, "House Party", "LS_Ogloc");
						settings.CurrentDefaultParent = "hp2";
						settings.Add("hp2_marker", false, "Mission Marker Entered");
						settings.Add("hp2_start", false, "Mission Started");
						settings.Add("hp2_cutsceneEnd", false, "Cutscenes ended");
						settings.Add("hp2_blockadeDead", false, "First two cars cleared");
						settings.Add("hp2_bridgeDead", false, "Bridge cleared");
						settings.Add("hp2_fightOver", false, "Last big fight cleared");
						settings.Add("hp2_pass", true, "Mission Passed");

						vars.significantThreads.Add("music5", "");
						vars.missionNames.Add("House Party","hp2_marker");

						vars.watchScmMissionLocalVariables.Add(80);	// music5_goals

						Func<string> func_hp = () => {
							var mission_chain = vars.GetWatcher("ls_ogloc_chain");
							if (mission_chain.Current >= 3 && mission_chain.Current < 5) {
								var thread = vars.GetWatcher("thread");
								if (thread.Changed) {
									if (thread.Current == "music5") {
										return mission_chain.Current == 3 ? "hp1_start" : "hp2_start";
									}
								}
							}

							if (vars.lastStartedMission != "music5") {
								return;
							}
							if (mission_chain.Changed) {
								if (mission_chain.Current >= 3) {
									if (mission_chain.Old == 3) {
										vars.TrySplit("hp1_pass");
									}
									else if (mission_chain.Old == 4) {
										vars.TrySplit("hp2_pass");
									}
								}
							}

							// 1: Car blockade
							// 2: Enemies on bridge
							// 3: Big fight all round
							// 4: Fight over, wait for cutscene
							var hp_stage = vars.GetWatcher("80@");
							if (hp_stage.Changed) {
								switch((int)hp_stage.Current) {
									case 1:
										return "hp2_cutsceneEnd";
										break;
									case 2:
										return "hp2_blockadeDead";
										break;
									case 3:
										return "hp2_bridgeDead";
										break;
									case 4:
										return "hp2_fightOver";
										break;
								}
							}
							return;
						};
						vars.CheckSplit.Add(func_hp);
					#endregion
				#endregion
				#region CRASH Chain
					settings.Add("LS_Crash", true, "C.R.A.S.H.", "LS");
					// 1: Burning Desire
					// 2: Gray Imports
					vars.watchScmGlobalVariables.Add(456, "ls_crash_chain");	// $CRASH_LS_TOTAL_PASSED_MISSIONS
					#region Burning Desire
						settings.Add("bd", true, "Burning Desire", "LS_Crash");
						settings.CurrentDefaultParent = "bd";
						settings.Add("bd_marker", false, "Mission Marker Entered");
						settings.Add("bd_start", false, "Mission Started");
						settings.Add("bd_cutEnd", false, "Initial cinematic ended");
						settings.Add("bd_molotovPicked", false, "Molotovs picked up");
						settings.Add("bd_houseApproach", false, "Getting within 300 meters of the house");
						settings.Add("bd_houseArrive", false, "Arrival at the house");
						settings.Add("bd_window1", false, "1 window torched");
						settings.Add("bd_window2", false, "2 windows torched");
						settings.Add("bd_window3", false, "3 windows torched");
						settings.Add("bd_window4", false, "4 windows torched");
						settings.Add("bd_window5", false, "5 windows torched");
						settings.Add("bd_windowsTorched", false, "All windows torched");
						settings.Add("bd_houseEnter", false, "House entered");
						settings.Add("bd_fireExtinguisherPick", false, "Fire extinguisher picked up");
						settings.Add("bd_deniseReach", false, "Arrived in front of Denise's room");
						settings.Add("bd_deniseCutStart", false, "Entered Denise's room");
						settings.Add("bd_deniseCutEnd", false, "Escape sequence started");
						settings.Add("bd_houseLeft", false, "House left with Denise");
						settings.Add("bd_deniseHouseReach", false, "Arrival at Denise's place");
						settings.Add("bd_deniseWave", false, "Denise waves the player goodbye");
						settings.Add("bd_pass", true, "Mission Passed");

						vars.significantThreads.Add("crash1", "bd_start");
						vars.missionNames.Add("Burning Desire","bd_marker");

						vars.watchScmMissionLocalVariables.Add(34);		// m_stage
						vars.watchScmMissionLocalVariables.Add(35);		// m_goals
						vars.watchScmMissionLocalVariables.Add(209);	// countTargetRoomsHit

						Func<string> func_bd = () => {
							if (!vars.ValidateMissionProgress("crash1", "ls_crash_chain", 0, 1, "bd_pass", "bd")) {
								return;
							}
							// stage.goal:
							// 1.1 after intro cut, go pick up molotovs
							// 1.4 molotovs grabbed and next objective shown
							// 1.5 place guys at house and animate them
							// 2.2 arrived at house, show torch objective
							// 3.1 all windows torched
							// 4.2 house entered
							// 4.12 coochie approached
							// 5 denise reached cutscene
							// 6 denise cutscene end
							// 7 house left
							// 7.4 arrived at denise's house
							// 7.11 denise waves player goodbye
							var bd_stage = vars.GetWatcher("34@");
							if (bd_stage.Current == 2 || bd_stage.Old == 2) {
								var bd_windowsTorched = vars.GetWatcher("209@");
								if (bd_windowsTorched.Changed) {
									vars.TrySplit("bd_window"+bd_windowsTorched.Current);
								}
							}
							if (bd_stage.Changed) {
								switch ((int)bd_stage.Current) {
									case 1:
										return "bd_cutEnd";
										break;
									case 2:
										return "bd_houseArrive";
										break;
									case 3:
										return "bd_windowsTorched";
										break;
									case 4:
										return "bd_houseEnter";
										break;
									case 5:
										return "bd_deniseCutStart";
										break;
									case 6:
										return "bd_deniseCutEnd";
										break;
									case 7:
										return "bd_houseLeft";
										break;
								}
							}
							var bd_goals = vars.GetWatcher("35@");
							if (bd_goals.Changed) {
								if (bd_stage.Current == 1) {
									if (bd_goals.Current == 4) {
										return "bd_molotovPicked";
									}
									else if (bd_goals.Current == 5) {
										return "bd_houseApproach";
									}
								}
								else if (bd_stage.Current == 4 && bd_goals.Current == 12) {
									return "bd_deniseReach";
								}
								else if (bd_stage.Current == 7) {
									if (bd_goals.Current == 4) {
										return "bd_deniseHouseReach";
									}
									if (bd_goals.Current == 11) {
										return "bd_deniseWave";
									}
								}
							}
							return;
						};
						vars.CheckSplit.Add(func_bd);
					#endregion
				#endregion
				#region Ryder Chain
					settings.Add("LS_Ryder", true, "Ryder", "LS");
					// 1: Home Invasion
					// 2: Catalyst
					// 3: Robbing Uncle Sam
					vars.watchScmGlobalVariables.Add(453, "ls_ryder_chain");	// $RYDER_TOTAL_PASSED_MISSIONS
					#region Home Invasion
						settings.Add("hi", true, "Home Invasion", "LS_Ryder");
						settings.CurrentDefaultParent = "hi";
						settings.Add("hi_marker", false, "Mission Marker Entered");
						settings.Add("hi_start", false, "Mission Started");
						settings.Add("hi_cut1End", false, "Intro cinematic ended");
						settings.Add("hi_cut2End", false, "Post-cinematic intro cutscene ended");
						settings.Add("hi_houseArrive", false, "Arrival at the house");
						settings.Add("hi_vanExit", false, "End of cutscene in front of the house");
						settings.Add("hi_houseEnter1", false, "Entered the house");
						settings.Add("hi_houseGo", false, "End of burglary tutorial cutscene");
						settings.Add("hi_boxGrab1", false, "First box picked up");
						settings.Add("hi_houseExit1", false, "First box taken outside");
						settings.Add("hi_boxDrop1", false, "First box placed in the van");
						settings.Add("hi_houseEnter2", false, "House reentered after first box");
						settings.Add("hi_boxGrab2", false, "Second box picked up");
						settings.Add("hi_houseExit2", false, "Second box taken outside");
						settings.Add("hi_boxDrop2", false, "Second box placed in the van");
						settings.Add("hi_houseEnter3", false, "House reentered after second box");
						settings.Add("hi_boxGrab3", false, "Third box picked up");
						settings.Add("hi_houseExit3", false, "Third box taken outside");
						settings.Add("hi_boxDrop3", false, "Third box placed in the van");
						settings.Add("hi_optional", false, "Optional boxes");
						settings.Add("hi_houseEnter4", false, "House reentered after third box", "hi_optional");
						settings.Add("hi_boxGrab4", false, "Fourth box picked up", "hi_optional");
						settings.Add("hi_houseExit4", false, "Fourth box taken outside", "hi_optional");
						settings.Add("hi_boxDrop4", false, "Fourth box placed in the van", "hi_optional");
						settings.Add("hi_houseEnter5", false, "House reentered after fourth box", "hi_optional");
						settings.Add("hi_boxGrab5", false, "Fifth box picked up", "hi_optional");
						settings.Add("hi_houseExit5", false, "Fifth box taken outside", "hi_optional");
						settings.Add("hi_boxDrop5", false, "Fifth box placed in the van", "hi_optional");
						settings.Add("hi_houseEnter6", false, "House reentered after fifth box", "hi_optional");
						settings.Add("hi_boxGrab6", false, "Final box picked up", "hi_optional");
						settings.Add("hi_houseExit6", false, "Final box taken outside", "hi_optional");
						settings.Add("hi_boxDrop6", false, "Final box placed in the van", "hi_optional");
						settings.Add("hi_enteredVan", false, "Entered van early");
						settings.SetToolTip("hi_enteredVan", "Does not occur when collecting all 6 boxes");
						settings.Add("hi_houseLeave", false, "Driving away with the van");
						settings.Add("hi_endCut", false, "Locker box entered");
						settings.Add("hi_pass", true, "Mission Passed");

						vars.significantThreads.Add("guns1", "hi_start");
						vars.missionNames.Add("Home Invasion","hi_marker");

						vars.watchScmMissionLocalVariables.Add(35);		// ryd1_number_gunbox_truck
						vars.watchScmMissionLocalVariables.Add(51);		// ryd1_mission_progression_flag
						vars.watchScmMissionLocalVariables.Add(60);		// ryd1_player_holding_box_flag
						vars.watchScmMissionLocalVariables.Add(88);		// ryd1_clothes_changed
						vars.watchScmMissionLocalVariables.Add(95);		// ryd1_inside_house_flag
						vars.watchScmMissionLocalVariables.Add(254);	// ryd1_audio_counter


						Func<string> func_hi = () => {
							if (!vars.ValidateMissionProgress("guns1", "ls_ryder_chain", 0, 1, "hi_pass", "hi")) {
								return;
							}
							// progression flag:
							// 1 - intro cinematic over
							// 2 - post cinematic cutscene over
							// 3 - arrival at house
							// 4 - cutscene at house skipped
							// 5 - house entered
							// 6 - burglary start
							// 8 - drive off
							var hi_stage = vars.GetWatcher("51@");
							if (hi_stage.Changed) {
								switch ((int)hi_stage.Current) {
									case 1:
										return "hi_cut1End";
										break;
									case 2:
										return "hi_cut2End";
										break;
									case 3:
										return "hi_houseArrive";
										break;
									case 4:
										return "hi_vanExit";
										break;
									case 6:
										return "hi_houseGo";
										break;
									case 8:
										return "hi_houseLeave";
										break;
								}
							}
							var hi_gunboxDroppedOff = vars.GetWatcher("35@");
							if (hi_gunboxDroppedOff.Changed && hi_gunboxDroppedOff.Current > 1) {
								return "hi_boxDrop" + hi_gunboxDroppedOff.Old;
							}
							var hi_endCut = vars.GetWatcher("88@");
							if (hi_endCut.Changed && hi_endCut.Old == 1 && hi_endCut.Current == 0) {
								return "hi_endCut";
							}
							var hi_inHouse = vars.GetWatcher("95@");
							var hi_holdingBox = vars.GetWatcher("60@");
							if (hi_gunboxDroppedOff.Current > 0) {
								if (hi_inHouse.Changed) {
									if (hi_inHouse.Current == 1 && hi_inHouse.Old == 0) {
										return "hi_houseEnter" + hi_gunboxDroppedOff.Current;
									}
									if (hi_inHouse.Current == 0 && hi_inHouse.Old == 1) {
										return "hi_houseExit" + hi_gunboxDroppedOff.Current;
									}
								}
								if (hi_inHouse.Current == 1 && hi_holdingBox.Changed && hi_holdingBox.Current == 1) {
									return "hi_boxGrab" + hi_gunboxDroppedOff.Current;
								}
							}
							var hi_enteredVan = vars.GetWatcher("254@");
							if (hi_enteredVan.Changed && hi_enteredVan.Current == 38) {
								// "Let's get up out of here" line
								return "hi_enteredVan";
							}
							return;
						};
						vars.CheckSplit.Add(func_hi);
					#endregion
				#endregion
				#region Cesar Chain
					settings.Add("LS_Cesar", true, "Cesar", "LS");
					// 1: High Stakes, Low-Rider
					vars.watchScmGlobalVariables.Add(457, "ls_cesar_chain");	// $MISSION_LOWRIDER_PASSED
				#region High Stakes, Low-Rider
					settings.Add("hslr", true, "High Stakes, Low-Rider", "LS_Cesar");
					settings.SetToolTip("hslr", "See also 'Lowrider Race' in Side Missions -> Races section.");
					settings.CurrentDefaultParent = "hslr";
					settings.Add("hslr_marker", false, "Mission Marker Entered");
					settings.Add("hslr_start", false, "Mission Started");
					settings.Add("hslr_cutEnd", false, "Intro cutscenes ended");
					settings.Add("hslr_raceStart", false, "Race started");
					settings.Add("hslr_pass", true, "Mission Passed");

					vars.significantThreads.Add("cesar1","hslr_start");
					vars.missionNames.Add("High Stakes, Low","hslr_marker");

					vars.watchScmGlobalVariables.Add(2336, "hslr_raceStart");

					vars.watchScmMissionLocalVariables.Add(34);

					Func<string> func_hslr = () => {
						var ls_cesar_chain = vars.GetWatcher("ls_cesar_chain");
						if (ls_cesar_chain.Current >= 1) {
							if (ls_cesar_chain.Changed && ls_cesar_chain.Old == 0) {
								return "hslr_pass";
							}
							return;
						}
						var hslr_raceStart = vars.GetWatcher("hslr_raceStart");
						if (hslr_raceStart.Changed && hslr_raceStart.Current == 2) {
							return "hslr_raceStart";
						}
						if (vars.lastStartedMission != "cesar1") {
							return;
						}
						var hslr_cutEnd = vars.GetWatcher("34@");
						if (hslr_cutEnd.Changed && hslr_cutEnd.Current == 1) {
							return "hslr_cutEnd";
						}
						return;
					};
					vars.CheckSplit.Add(func_hslr);
				#endregion
				#endregion
				settings.Add("LS_Final", true, "Finale", "LS");
				vars.watchScmGlobalVariables.Add(458, "ls_final_chain");	// $LS_FINAL_TOTAL_PASSED_MISSIONS

			#endregion

			settings.Add("BL", true, "Badlands", "Missions");
			settings.Add("BL_Intro", true, "Trailer Park", "BL");
			settings.Add("BL_Catalina", true, "Catalina", "BL");
			settings.Add("BL_Cesar", true, "Cesar", "BL");
			settings.Add("BL_Truth", true, "The Truth", "BL");

			settings.Add("SF", true, "San Fierro", "Missions");
			settings.CurrentDefaultParent = "SF";
			settings.Add("SF_Main", true, "Garage / Syndicate", "SF");
			settings.Add("SF_Wuzimu", true, "Woozie", "SF");
			settings.Add("SF_Zero", true, "Zero", "SF");

			settings.Add("Des", true, "Desert", "Missions");
			settings.Add("Des_Toreno", true, "Toreno", "Des");
			settings.Add("Des_WangCars", true, "Wang Cars", "Des");

			settings.Add("LV", true, "Las Venturas", "Missions");
			settings.Add("LV_AirStrip", true, "Air Strip", "LV");
			settings.Add("LV_Casino", true, "Casino", "LV");
			settings.Add("LV_Crash", true, "C.R.A.S.H.", "LV");
			settings.Add("LV_MaddDogg", true, "Madd Dogg", "LV");
			settings.Add("LV_Heist", true, "Heist", "LV");

			settings.Add("RTLS", true, "Return to Los Santos", "Missions");
			settings.Add("RTLS_Mansion", true, "Mansion", "RTLS");
			settings.Add("RTLS_Grove", true, "Grove", "RTLS");
			settings.Add("RTLS_Riot", true, "Finale", "RTLS");
			vars.watchScmGlobalVariables.Add(626, "rtls_mansion_chain");	// $MANSION_TOTAL_PASSED_MISSIONS

		#endregion
		#region Side Missions
			settings.CurrentDefaultParent = "Splits";
			settings.Add("SideMissions", true, "Side Missions");

			#region Courier
				settings.Add("courier", true, "Courier", "SideMissions");
				settings.CurrentDefaultParent = "courier";
				// 1 = LS, 2 = SF, 3 = LV
				settings.Add("courier1", true, "Courier Los Santos");
				settings.Add("courier2", true, "Courier San Fierro");
				settings.Add("courier3", true, "Courier Las Venturas");
				settings.Add("courier1_start", false, "Courier Los Santos Started", "courier1");
				settings.Add("courier2_start", false, "Courier San Fierro Started", "courier2");
				settings.Add("courier3_start", false, "Courier Las Venturas Started", "courier3");
				settings.Add("courier1_level", false, "Levels", "courier1");
				settings.Add("courier2_level", false, "Levels", "courier2");
				settings.Add("courier3_level", false, "Levels", "courier3");
				for (int i = 1; i <= 4; i++) {
					settings.Add("courier1_level"+i, false, "Level "+i, "courier1_level");
					settings.Add("courier2_level"+i, false, "Level "+i, "courier2_level");
					settings.Add("courier3_level"+i, false, "Level "+i, "courier3_level");
					for (int j = 1; j <= i + 2; j++) {
						settings.Add("courier1_level"+i+"_delivery"+j, false, "Delivery "+j, "courier1_level"+i);
						settings.Add("courier2_level"+i+"_delivery"+j, false, "Delivery "+j, "courier2_level"+i);
						settings.Add("courier3_level"+i+"_delivery"+j, false, "Delivery "+j, "courier3_level"+i);
					}
					settings.Add("courier1_level"+i+"_pass", false, "Level "+i+" passed", "courier1_level"+i);
					settings.Add("courier2_level"+i+"_pass", false, "Level "+i+" passed", "courier2_level"+i);
					settings.Add("courier3_level"+i+"_pass", false, "Level "+i+" passed", "courier3_level"+i);
				}
				settings.Add("courier1_pass", true, "Courier Los Santos Passed", "courier1");
				settings.Add("courier2_pass", true, "Courier San Fierro Passed", "courier2");
				settings.Add("courier3_pass", true, "Courier Las Venturas Passed", "courier3");

				vars.watchScmGlobalVariables.Add(1992, "courier1_pass");	// $MISSION_COURIER_LS_PASSED
				vars.watchScmGlobalVariables.Add(1993, "courier3_pass");	// $MISSION_COURIER_LV_PASSED
				vars.watchScmGlobalVariables.Add(1994, "courier2_pass");	// $MISSION_COURIER_SF_PASSED
				vars.watchScmGlobalVariables.Add(189, "courier_active");	// $ONMISSION_COURIER

				vars.watchScmMissionLocalVariables.Add(757);
				vars.watchScmMissionLocalVariables.Add(760);
				vars.watchScmMissionLocalVariables.Add(761);
				vars.watchScmMissionLocalVariables.Add(762);
				vars.watchScmMissionLocalVariables.Add(872);

				vars.significantThreads.Add("bcour","");

				Func<string> func_courier = () => {
					if (vars.lastStartedMission != "bcour") {
						return;
					}
					var courier1_pass = vars.GetWatcher("courier1_pass");
					if (courier1_pass.Changed && courier1_pass.Current == 1) {
						vars.TrySplit("courier1_pass");
					}
					var courier2_pass = vars.GetWatcher("courier2_pass");
					if (courier2_pass.Changed && courier2_pass.Current == 1) {
						vars.TrySplit("courier2_pass");
					}
					var courier3_pass = vars.GetWatcher("courier3_pass");
					if (courier3_pass.Changed && courier3_pass.Current == 1) {
						vars.TrySplit("courier3_pass");
					}
					var courier_active = vars.GetWatcher("courier_active");
					if (courier_active.Current == 0) {
						return;
					}
					var courier_city = vars.GetWatcher("872@");
					var ccc = courier_city.Current;
					if (courier_city.Changed && ccc != 0) {
						return "courier"+ccc+"_start";
					}
					var courier_levelAddress = "";
					if (courier_city.Current == 1) {
						courier_levelAddress = "761@";
					}
					else if (courier_city.Current == 2) {
						courier_levelAddress = "760@";
					}
					else {
						courier_levelAddress = "762@";
					}
					var courier_level = vars.GetWatcher(courier_levelAddress);
					var ccl = courier_level.Current + 1;
					var courier_checkpoints = vars.GetWatcher("757@");
					var ccp = "courier"+ccc+"_level"+ccl;
					if (courier_checkpoints.Changed && courier_checkpoints.Current > 0) {
						vars.TrySplit(ccp+"_delivery"+courier_checkpoints.Current);
					}
					if (courier_level.Changed && ccl > 0) {
						vars.TrySplit("courier"+ccc+"_level"+courier_level.Current+"_pass");
					}
					return;
				};
				vars.CheckSplit.Add(func_courier);

			#endregion

			settings.Add("Trucking", true, "Trucking", "SideMissions");
			settings.Add("Quarry", true, "Quarry", "SideMissions");
			settings.Add("Valet", true, "Valet Parking", "SideMissions");

			#region Vehicle submissions
				settings.Add("VehicleSubmissions", true, "Vehicle Submissions", "SideMissions");
			#region Firefighter
				settings.Add("firefighter", true, "Firefighter", "VehicleSubmissions");
				settings.Add("firefighter_start", false, "Mission Started for the first time", "firefighter");
				settings.Add("firefighter_level", false, "Levels", "firefighter");
				settings.CurrentDefaultParent = "firefighter_level";
				for (int i = 1; i <= 12; i++) {
					settings.Add("firefighter_level"+i, false, "Level "+i);
				}
				var firefighter_levelsForFire = new int[78] {
					1, 2, 2, 3, 3, 3, 4, 4, 4, 4,
					5, 5, 5, 5, 5, 6, 6, 6, 6, 6,
					6, 7, 7, 7, 7, 7, 7, 7, 8, 8,
					8, 8, 8, 8, 8, 8, 9, 9, 9, 9,
					9, 9, 9, 9, 9,10,10,10,10,10,
					10,10,10,10,10,11,11,11,11,11,
					11,11,11,11,11,11,12,12,12,12,
					12,12,12,12,12,12,12,12
				};
				settings.Add("firefighter_fire", false, "Fires Extinguished", "firefighter");
				settings.CurrentDefaultParent = "firefighter_fire";
				settings.Add("firefighter_fire1", false, "1 fire extinguished (level 1 fire 1)");
				var firefighter_levelFireCounter = 0;
				var firefighter_levelCounter = 2;
				for (int i = 2; i <= 78; i++) {
					firefighter_levelFireCounter++;
					settings.Add("firefighter_fire"+i, false, i+" fires extinguished (level "+firefighter_levelCounter+" fire "+firefighter_levelFireCounter+")");
					if (firefighter_levelFireCounter >= firefighter_levelCounter) {
						firefighter_levelCounter++;
						firefighter_levelFireCounter = 0;
					}
				}
				settings.Add("firefighter_pass", false, "Mission Passed", "firefighter");

				vars.watchScmGlobalVariables.Add(1489, "firefighter_passed");	// directly goes to 2 when complete
				vars.watchScmGlobalVariables.Add(8213, "firefighter_currentLevel");
				vars.watchScmGlobalVariables.Add(8214, "firefighter_firesExtinguished");

				vars.significantThreads.Add("firetru","firefighter_start");

				Func<string> func_firefighter = () => {
					if (vars.lastStartedMission != "firetru") {
						return;
					}
					// Mission order: Extinguish fire, advance level, pass mission.
					// So we want to split them in that order too just to be clean.
					var firefighter_firesExtinguished = vars.GetWatcher("firefighter_firesExtinguished");
					if (firefighter_firesExtinguished.Changed) {
						var c = firefighter_firesExtinguished.Current;
						var o = firefighter_firesExtinguished.Old;
						for (int i = o+1; i <= c; i++) {
							// Do a for loop in case two fires are extinguished at once.
							vars.TrySplit("firefighter_fire"+i);
						}
					}
					var firefighter_currentLevel = vars.GetWatcher("firefighter_currentLevel");
					if (firefighter_currentLevel.Changed) {
						if (firefighter_currentLevel.Old > 0 && firefighter_currentLevel.Current > firefighter_currentLevel.Old) {
							vars.TrySplit("firefighter_level"+firefighter_currentLevel.Old);
							return;
						}
					}
					var firefighter_passed = vars.GetWatcher("firefighter_passed");
					if (firefighter_passed.Changed && firefighter_passed.Current == 2) {
						vars.TrySplit("firefighter_pass");
					}
					return;
				};
				vars.CheckSplit.Add(func_firefighter);
			#endregion

			#endregion
			#region Races
				settings.Add("Races", true, "Races", "SideMissions");
				settings.Add("raceLS", true, "Los Santos", "Races");
				settings.CurrentDefaultParent = "raceLS";
				settings.Add("race0", true, "Lowrider Race");
				settings.Add("race1", true, "Little Loop");
				settings.Add("race2", true, "Backroad Wanderer");
				settings.Add("race3", true, "City Circuit");
				settings.Add("race4", true, "Vinewood");
				settings.Add("race5", true, "Freeway");
				settings.Add("race6", true, "Into the Country");
				settings.Add("race7", true, "Badlands A");
				settings.Add("race8", true, "Badlands B");
				settings.Add("raceSF", true, "San Fierro", "Races");
				settings.CurrentDefaultParent = "raceSF";
				settings.Add("race9", true, "Dirtbike Danger");
				settings.Add("race10", true, "Bandito County");
				settings.Add("race11", true, "Go-Go Karting");
				settings.Add("race12", true, "San Fierro Fastlane");
				settings.Add("race13", true, "San Fierro Hills");
				settings.Add("race14", true, "Country Endurance");
				settings.Add("raceLV", true, "Las Venturas", "Races");
				settings.CurrentDefaultParent = "raceLV";
				settings.Add("race15", true, "SF to LV");
				settings.Add("race16", true, "Dam Rider");
				settings.Add("race17", true, "Desert Tricks");
				settings.Add("race18", true, "LV Ringroad");
				settings.Add("raceA", true, "Air", "Races");
				settings.CurrentDefaultParent = "raceA";
				settings.Add("race19", true, "World War Ace");
				settings.Add("race20", true, "Barnstorming");
				settings.Add("race21", true, "Military Service");
				settings.Add("race22", true, "Chopper Checkpoint");
				settings.Add("race23", true, "Whirly Bird Waypoint");
				settings.Add("race24", true, "Heli Hell");
				// settings.Add("race"+25, true, "8-Track");
				// settings.Add("race"+26, true, "Dirt Track");

				// Checkpoint count for each race.
				// This includes the 0th checkpoint (GO! signal)
				var race_checkpointCounts = new int[27] {
					12,11,19,19,21,
					23,27,31,33,19,
					20,16,16,41,42,
					27,25,27,21,35,
					62,70,27,27,28,
					8,14
				};
				for (int i = 0; i < 24; i++) {
					var race_id = "race"+i;
					settings.CurrentDefaultParent = race_id;
					settings.Add(race_id+"cp0", false, "Race start (Countdown end)");
					for (int j = 1; j < race_checkpointCounts[i]; j++) {
						if (j == race_checkpointCounts[i]-1) {
							settings.Add(race_id+"cp"+j, false, "Checkpoint "+j+" (Finish)");
						}
						else {
							settings.Add(race_id+"cp"+j, false, "Checkpoint "+j);
						}
					}
					settings.Add(race_id+"_pass", true, "Race won");
					settings.SetToolTip(race_id+"_pass", "Notice: This will double split when also splitting on checkpoint "+(race_checkpointCounts[i]-1)+", as it is the last checkpoint of the race.");
				}

				vars.watchScmGlobalVariables.Add(352, "race_index");
				for (int i = 0; i <= 26; i++) {
					vars.watchScmGlobalVariables.Add(2300+i, "race"+i);
				}

				vars.watchScmMissionLocalVariables.Add(257);
				vars.watchScmMissionLocalVariables.Add(260);
				vars.watchScmMissionLocalVariables.Add(262);
				vars.watchScmMissionLocalVariables.Add(268);
				vars.watchScmMissionLocalVariables.Add(284);

				vars.significantThreads.Add("cprace","");	// Race Tournament / 8 Track / Dirt Track

				Func<string> func_race = () => {
					if (vars.lastStartedMission != "cprace") {
						return;
					}
					var race_index = vars.GetWatcher("race_index");
					var race_lapped = false;
					var race_checkpointAddress = "262@";	// Common races
					if (race_index.Current == 7 || race_index.Current == 8) {
						race_checkpointAddress = "260@";	// Badlands A & B
					}
					else if (race_index.Current >= 25) {
						race_lapped = true;
						race_checkpointAddress = "268@";	// Stadium races
					}
					else if (race_index.Current >= 19) {
						race_checkpointAddress = "257@";	// Fly races
					}
					// race_checkpoint indicates the CP the player is currently headed for.
					// it's set to 0 during countdown, so a change 0>1 means GO! signal given
					var race_checkpoint = vars.GetWatcher(race_checkpointAddress);
					var splitName = "race"+race_index.Current;
					var race_passed = vars.GetWatcher(splitName);
					if (race_passed.Changed && race_passed.Current == 1) {
						vars.TrySplit(splitName+"_pass");
					}
					if (race_lapped) {
						var race_lap = vars.GetWatcher("284@");
						splitName = splitName + "lap"+race_lap.Old;
						if (race_lap.Changed && race_lap.Current > race_lap.Old) {
							vars.TrySplit(splitName);
						}
					}
					if (race_checkpoint.Changed && race_checkpoint.Current > race_checkpoint.Old) {
						splitName = splitName + "cp"+race_checkpoint.Old;
						return splitName;
					}
					return;
				};
				vars.CheckSplit.Add(func_race);
			#endregion

			settings.Add("StadiumEvents", true, "Stadium Events", "SideMissions");
			settings.Add("VehicleChallenges", true, "Vehicle Challenges", "SideMissions");
			settings.Add("Schools", true, "Schools", "SideMissions");

			#region Properties
				settings.Add("Properties", true, "Properties", "SideMissions");
				settings.Add("PropertiesA", true, "Assets", "Properties");
				settings.Add("PropertiesLS", true, "Los Santos", "Properties");
				settings.Add("PropertiesBL", true, "Badlands", "Properties");
				settings.Add("PropertiesSF", true, "San Fierro", "Properties");
				settings.Add("PropertiesDes", true, "Desert", "Properties");
				settings.Add("PropertiesLV", true, "Las Venturas", "Properties");

				// Properties array ($728) has each index set upon purchasing property
				// List sorted alphabetically
				// Wang Cars (+0) and Verdant Meadows (+2) do not actually get set.
				// Their purchase status needs to be checked differently.
				settings.Add("Property1", true, "Zero (RC Shop Bought)", "PropertiesA");
				settings.Add("Property22", true, "Angel Pine (Safehouse)", "PropertiesBL");
				settings.Add("Property31", true, "Blueberry (Safehouse)", "PropertiesBL");
				settings.Add("Property11", true, "Calton Heights (Safehouse)", "PropertiesSF");
				settings.Add("Property18", true, "Chinatown (Safehouse)", "PropertiesSF");
				settings.Add("Property29", true, "Creek (Safehouse)", "PropertiesLV");
				settings.Add("Property25", true, "Dillimore (Safehouse)", "PropertiesBL");
				settings.Add("Property20", true, "Doherty (Safehouse)", "PropertiesSF");
				settings.Add("Property23", true, "El Quebrados (Safehouse)", "PropertiesDes");
				settings.Add("Property5", true, "Fort Carson (Safehouse)", "PropertiesDes");
				settings.Add("Property14", true, "Hashbury (Safehouse)", "PropertiesSF");
				settings.Add("Property26", true, "Jefferson (Safehouse)", "PropertiesLS");
				settings.Add("Property12", true, "Mulholland (Safehouse)", "PropertiesLS");
				settings.Add("Property27", true, "Old Venturas Strip (Hotel Suite)", "PropertiesLV");
				settings.Add("Property8", true, "Palomino Creek (Safehouse)", "PropertiesBL");
				settings.Add("Property13", true, "Paradiso (Safehouse)", "PropertiesSF");
				settings.Add("Property16", true, "Pirates In Men's Pants (Hotel Suite)", "PropertiesLV");
				settings.Add("Property6", true, "Prickle Pine (Safehouse)", "PropertiesLV");
				settings.Add("Property21", true, "Queens (Hotel Suite)", "PropertiesSF");
				settings.Add("Property9", true, "Redsands West (Safehouse)", "PropertiesLV");
				settings.Add("Property4", true, "Rockshore West (Safehouse)", "PropertiesLV");
				settings.Add("Property3", true, "Santa Maria Beach (Safehouse)", "PropertiesLS");
				settings.Add("Property17", true, "The Camel's Toe (Hotel Suite)", "PropertiesLV");
				settings.Add("Property28", true, "The Clown's Pocket (Hotel Suite)", "PropertiesLV");
				settings.Add("Property24", true, "Tierra Robada (Safehouse)", "PropertiesDes");
				settings.Add("Property10", true, "Verdant Bluffs (Safehouse)", "PropertiesLS");
				settings.Add("Property15", true, "Verona Beach (Safehouse)", "PropertiesLS");
				settings.Add("Property19", true, "Whetstone (Safehouse)", "PropertiesBL");
				settings.Add("Property7", true, "Whitewood Estates (Safehouse)", "PropertiesLV");
				settings.Add("Property30", true, "Willowfield (Safehouse)", "PropertiesLS");

				vars.watchScmGlobalVariables.Add(728+1, "Property1");
				for (int i = 3; i <= 31; i++) {
					vars.watchScmGlobalVariables.Add(728+i, "Property"+i);
				}

				Func<string> func_properties = () => {
					for (int i = 1; i <= 31; i++) {
						if (i == 2) {
							continue;
						}
						var property_purchased = vars.GetWatcher("Property"+i);
						if (property_purchased.Changed && property_purchased.Current == 1) {
							return "Property"+i;
						}
					}
					return;
				};
				vars.CheckSplit.Add(func_properties);
			#endregion

			settings.Add("ImportExport", true, "Import/Export", "SideMissions");
			settings.Add("ShootingRange", true, "Shooting Range", "SideMissions");
			settings.Add("GymMoves", true, "Gym Moves", "SideMissions");

		#endregion
		#region Collectibles
			#region Collectibles info & settings
				//==================
				// Collectibles are tracked in multiple ways:
				// * Checking for the rewards given when all have been collected (which is on a 3 second cycle)
				// * Checking for a normal count by monitoring the stats entry (X / 50 collected)
				// * Checking each collectible specifically by monitoring its collection status
				//		-> This requires very intricate memory checking
				//
				// === Tags ===
				// Tags are tracked as an int, with 0 being not sprayed and 255 being fully sprayed.
				// Tags at values 229 and above count as collected. The boop will play at 255.
				// The order in memory does not match the order listed on EHGames.com/gta/maplist
				// Tags always stay in memory, even after collection. Their location appears consistent
				// between saves as well. Tag address (8 bytes) looks like this:
				// 48 ?? ?? ??	 	-> 48 = appears specific to each tag (repeats possible). The rest is inconsistent gibberish.
				// ?? 00 00 00		-> ?? = collection %
				//
				// === Pickup Collectibles ===
				// Horseshoes, Snapshots, & Oysters - in that order - are placed back to back in memory.
				// Horseshoes 0-49, snapshots 50-99, oysters 100-149
				// After collection, their addresses are eventually garbo'd and recycled. Particularly after loading a game.
				// The position in memory is also inconsistent, but they seem to remain in order and at the right intervals of 0x20 between each.
				// Eg Snapshot 6 will always be at +0x40 from Snapshot 4, regardless if Snapshot 5 has been collected and its addresses recycled.
				// So once we find the first, we can calculate the addresses of the rest.
				// Do need to iterate over them, as #1 might be collected making #2 the first found in memory.
				//
				// === Horseshoes ===
				// Horseshoe collection status is a byte that's also used for the collectible being in range and visible.
				// 0x00 when out of range, 0x08 when in range, 0x09 when collected, 0x01 when collected out of range
				// Horseshoe address looks like this:
				// 00 00 00 00
				// ?? ?? ?? ?? 		-> Set to 00 00 00 00 when out of range, set to some values when in range
				// ?? 00 00 00 		-> Irrelevant
				// ?? ?? ?? ??		-> Unique phrase to identify each horseshoe (no clue what it means)
				// ?? ?? 00 00 		-> Unique phrase cont?
				// BA 03 ?? 00 		-> BA 03 = horseshoe model
				// ?? ?? 00 00 		-> second byte is a collection byte, first byte is irrelevant
				// 00 00 00 00
				//
				// === Snapshots ===
				// Snapshots collection status is a byte, with 20 being uncollected, and 0 being collected.
				// After collection, these addresses are eventually garbo'd and recycled. Particularly after loading a game.
				// Snapshots position in memory is also inconsistent, but they seem to remain in order and at the right intervals of 0x20 between each.
				// Snapshot address looks like this:
				// 00 00 00 00
				// 00 00 00 00
				// ?? ?? 00 00		-> Irrelevant
				// ?? ?? ?? ?? 		-> Unique phrase to identify each snapshot (no clue what it means)
				// ?? ?? 00 00		-> Unique phrase cont?
				// E5 04 ?? 00		-> E5 04 = Snapshot model
				// 14 ?? 00 00		-> 14 = uncollected. If it's not 14, it's collected and we can ignore it. the byte after is irrelevant
				// 00 00 00 00
				//
				// === Oysters ===
				// Same as horseshoes.
				// 00 00 00 00
				// ?? ?? ?? ?? 		-> Set to 00 00 00 00 when out of range, set to some values when in range
				// ?? 00 00 00 		-> Irrelevant
				// ?? ?? ?? ??		-> Unique phrase to identify each oyster (no clue what it means)
				// ?? ?? 00 00 		-> Unique phrase cont?
				// B9 03 ?? 00 		-> B9 03 = oyster model
				// ?? ?? 00 00 		-> second byte is a collection byte, first byte is irrelevant
				// 00 00 00 00
				vars.tag_ehgames_index = new byte[100] {
					50,51,52,53,54,55,56,57,58,59,
					60,61,62,63,64,65,66,67,68,69,
					70,71,72,73,74,75,76,77,78,79,
					80,81,82,83,84,85,86, 0, 1, 2,
					3, 4, 5, 6, 7, 8, 9,10,11,12,
					13,14,15,16,17,18,19,20,21,22,
					23,24,25,26,27,28,29,30,31,32,
					33,34,35,36,37,38,39,40,41,42,
					43,44,45,46,47,48,49,87,88,89,
					90,91,96,97,98,99,92,93,94,95,
				};
				vars.collectible_identifiers_lsb = new string[150] {
					// Horseshoes
					"4026C851", "98482028", "983F0848", "D84DB846", "C82C6057",
					"B8404016", "F8457839", "B850984A", "8059C81A", "A051C044",
					"1047182F", "4044084F", "383A5048", "3040104C", "1832D82C",
					"972AB91F", "55407843", "983E4034", "F0457823", "703CE61E",
					"4037F858", "E021A021", "F859D04E", "184AC83E", "882FD034",
					"884B0828", "002B0048", "882B4039", "C01E1850", "3837C812",
					"E041581F", "8F54343A", "E84DD01C", "C83AF058", "203F8049",
					"82349645", "B02D401D", "6C42A918", "E050703B", "B81CB040",
					"E843084D", "7A3FFA44", "684EC023", "3845803D", "1052C858",
					"404C8843", "7031084B", "E840C03B", "501ED837", "B12F7817",
					// Snapshots
					"86B1F9EA", "E3AA2BF6", "B3C9E4ED", "90D1C01C", "52D81D1E",
					"70CC300D", "23C6FBFC", "A0AA60F8", "6AA8BB0B", "58A97B18",
					"40ACB631", "9AB23B30", "48C5842D", "34CF7914", "97D6710F",
					"55C34D04", "B7BC720E", "E1B90E12", "E8BF400E", "08C39814",
					"80BFF01C", "56B6C81F", "40BF5021", "80C9631E", "58C3981B",
					"84C6F721", "BACAD029", "ACB6C610", "A8B39817", "98A9B80B",
					"FEA5C2E2", "E8BEC0E6", "F0C240E8", "DCE1A4F5", "38CB9801",
					"00BF0008", "98B4580A", "DDB9DA16", "10B3880B", "DDDC37FB",
					"22D8AD01", "10B43001", "08AF1005", "08AF80FF", "40ADD8FF",
					"F8AEC001", "66CDEB29", "E8B77806", "C8B688FD", "6BC43410",
					// Oysters
					"981EF0BA", "F05540AF", "F827D0E6", "095CE1BF", "180230E0",
					"B848D0AC", "E851B0B1", "082708AC", "A81638C6", "981670CE",
					"D80448C2", "803D68DA", "F8ACE030", "E0D8A80F", "38CD2000",
					"A0D1882E", "B5B13D30", "C8AA58F1", "70D8301E", "58E0F00E",
					"60D5300C", "9050704A", "5041503B", "90420024", "E83E3034",
					"184F0831", "B05DB05D", "00E6E81C", "300F18F8", "30FD90E3",
					"D300B9D6", "88F970CB", "C0CBB8CC", "48DB88AD", "B8DDB0A6",
					"B8A570DF", "68EB501B", "28E22052", "B0DEA844", "400168EF",
					"18E8B807", "9041A0FC", "7856B00E", "88E72042", "58E6F02A",
					"0CBECD48", "F0CF6035", "18AC4843", "E018D85B", "18445807",
				};
				vars.collectible_identifiers_msb = new uint[150] {
					// Horseshoes
					0x51C82640, 0x28204898, 0x48083F98, 0x46B84DD8, 0x57602CC8,
					0x164040B8, 0x397845F8, 0x4A9850B8, 0x1AC85980, 0x44C051A0,
					0x2F184710, 0x4F084440, 0x48503A38, 0x4C104030, 0x2CD83218,
					0x1FB92A97, 0x43784055, 0x34403E98, 0x237845F0, 0x1EE63C70,
					0x58F83740, 0x21A021E0, 0x4ED059F8, 0x3EC84A18, 0x34D02F88,
					0x28084B88, 0x48002B00, 0x39402B88, 0x50181EC0, 0x12C83738,
					0x1F5841E0, 0x3A34548F, 0x1CD04DE8, 0x58F03AC8, 0x49803F20,
					0x45963482, 0x1D402DB0, 0x18A9426C, 0x3B7050E0, 0x40B01CB8,
					0x4D0843E8, 0x44FA3F7A, 0x23C04E68, 0x3D804538, 0x58C85210,
					0x43884C40, 0x4B083170, 0x3BC040E8, 0x37D81E50, 0x17782FB1,
					// Snapshots
					0xEAF9B186, 0xF62BAAE3, 0xEDE4C9B3, 0x1CC0D190, 0x1E1DD852,
					0x0D30CC70, 0xFCFBC623, 0xF860AAA0, 0x0BBBA86A, 0x187BA958,
					0x31B6AC40, 0x303BB29A, 0x2D84C548, 0x1479CF34, 0x0F71D697,
					0x044DC355, 0x0E72BCB7, 0x120EB9E1, 0x0E40BFE8, 0x1498C308,
					0x1CF0BF80, 0x1FC8B656, 0x2150BF40, 0x1E63C980, 0x1B98C358,
					0x21F7C684, 0x29D0CABA, 0x10C6B6AC, 0x1798B3A8, 0x0BB8A998,
					0xE2C2A5FE, 0xE6C0BEE8, 0xE840C2F0, 0xF5A4E1DC, 0x0198CB38,
					0x0800BF00, 0x0A58B498, 0x16DAB9DD, 0x0B88B310, 0xFB37DCDD,
					0x01ADD822, 0x0130B410, 0x0510AF08, 0xFF80AF08, 0xFFD8AD40,
					0x01C0AEF8, 0x29EBCD66, 0x0678B7E8, 0xFD88B6C8, 0x1034C46B,
					// Oysters
					0xBAF01E98, 0xAF4055F0, 0xE6D027F8, 0xBFE15C09, 0xE0300218,
					0xACD048B8, 0xB1B051E8, 0xAC082708, 0xC63816A8, 0xCE701698,
					0xC24804D8, 0xDA683D80, 0x30E0ACF8, 0x0FA8D8E0, 0x0020CD38,
					0x2E88D1A0, 0x303DB1B5, 0xF158AAC8, 0x1E30D870, 0x0EF0E058,
					0x0C30D560, 0x4A705090, 0x3B504150, 0x24004290, 0x34303EE8,
					0x31084F18, 0x5DB05DB0, 0x1CE8E600, 0xF8180F30, 0xE390FD30,
					0xD6B900D3, 0xCB70F988, 0xCCB8CBC0, 0xAD88DB48, 0xA6B0DDB8,
					0xDF70A5B8, 0x1B50EB68, 0x5220E228, 0x44A8DEB0, 0xEF680140,
					0x07B8E818, 0xFCA04190, 0x0EB05678, 0x4220E788, 0x2AF0E658,
					0x48CDBE0C, 0x3560CFF0, 0x4348AC18, 0x5BD818E0, 0x07584418,
				};
				settings.CurrentDefaultParent = "Splits";
				settings.Add("Collectibles", false, "Collectibles");
				settings.CurrentDefaultParent = "Collectibles";
				settings.Add("Tags", false);
				settings.Add("TagAll", false, "All Tags (Rewards Given)", "Tags");
				settings.Add("TagEach", false, "Total Collected", "Tags");
				settings.Add("TagSpecific", false, "Specific Tags", "Tags");
				settings.SetToolTip("TagAll", "Splits when the game registers all as collected. This check is only done by the game once every 3 seconds.");
				settings.SetToolTip("TagEach", "Splits when the total collected reaches this number, as it is shown on screen upon collection or in the stats.");
				settings.SetToolTip("TagSpecific", "Splits when a specific collectible of this kind is collected. For reference, see ehgames.com/gta/maplist");
				settings.Add("Snapshots", false);
				settings.Add("SnapshotAll", false, "All Snapshots (Rewards Given)", "Snapshots");
				settings.Add("SnapshotEach", false, "Total Collected", "Snapshots");
				settings.Add("SnapshotSpecific", false, "Specific Snapshots", "Snapshots");
				settings.SetToolTip("SnapshotAll", "Splits when the game registers all as collected. This check is only done by the game once every 3 seconds.");
				settings.SetToolTip("SnapshotEach", "Splits when the total collected reaches this number, as it is shown on screen upon collection or in the stats.");
				settings.SetToolTip("SnapshotSpecific", "Splits when a specific collectible of this kind is collected. For reference, see ehgames.com/gta/maplist");
				settings.Add("Horseshoes", false);
				settings.Add("HorseshoeAll", false, "All Horseshoes (Rewards Given)", "Horseshoes");
				settings.Add("HorseshoeEach", false, "Total Collected", "Horseshoes");
				settings.Add("HorseshoeSpecific", false, "Specific Horseshoes", "Horseshoes");
				settings.SetToolTip("HorseshoeAll", "Splits when the game registers all as collected. This check is only done by the game once every 3 seconds.");
				settings.SetToolTip("HorseshoeEach", "Splits when the total collected reaches this number, as it is shown on screen upon collection or in the stats.");
				settings.SetToolTip("HorseshoeSpecific", "Splits when a specific collectible of this kind is collected. For reference, see ehgames.com/gta/maplist");
				settings.Add("Oysters", false);
				settings.Add("OysterAll", false, "All Oysters (Rewards Given)", "Oysters");
				settings.Add("OysterEach", false, "Total Collected", "Oysters");
				settings.Add("OysterSpecific", false, "Specific Oysters", "Oysters");
				settings.SetToolTip("OysterAll", "Splits when the game registers all as collected. This check is only done by the game once every 3 seconds.");
				settings.SetToolTip("OysterEach", "Splits when the total collected reaches this number, as it is shown on screen upon collection or in the stats.");
				settings.SetToolTip("OysterSpecific", "Splits when a specific collectible of this kind is collected. For reference, see ehgames.com/gta/maplist");
				settings.Add("Stunt Jump", false, "Stunt Jumps");
				settings.Add("Completed Stunt Jump", false, "Completed", "Stunt Jump");
				settings.Add("Completed Stunt JumpEach", false, "Total Completed", "Completed Stunt Jump");
				settings.Add("Completed Stunt JumpSpecific", false, "Specific Stunt Jumps", "Completed Stunt Jump");
				settings.SetToolTip("Completed Stunt JumpEach", "Splits when the total collected reaches this number, as it is shown on screen upon collection or in the stats.");
				settings.SetToolTip("Completed Stunt JumpSpecific", "Splits when a specific collectible of this kind is collected. For reference, see ehgames.com/gta/maplist");
				settings.Add("Found Stunt Jump", false, "Found", "Stunt Jump");
				settings.Add("Found Stunt JumpEach", false, "Total Found", "Found Stunt Jump");
				settings.Add("Found Stunt JumpSpecific", false, "Specific Stunt Jumps", "Found Stunt Jump");
				settings.SetToolTip("Found Stunt JumpEach", "Splits when the total collected reaches this number, as it is shown on screen upon collection or in the stats.");
				settings.SetToolTip("Found Stunt JumpSpecific", "Splits when a specific collectible of this kind is collected. For reference, see ehgames.com/gta/maplist");
				for (int i = 0; i < 100; i++) {
					settings.Add("TagEach"+i, false, (i+1)+" Tags", "TagEach");
					settings.Add("TagSpecific"+vars.tag_ehgames_index[i], false, "Tag "+(i+1), "TagSpecific");
					if (i >= 70) {
						continue;
					}
					settings.Add("Completed Stunt JumpEach"+i, false, (i+1)+" Completed Stunt Jumps", "Completed Stunt JumpEach");
					settings.Add("Found Stunt JumpEach"+i, false, (i+1)+" Found Stunt Jumps", "Found Stunt JumpEach");
					settings.Add("Completed Stunt JumpSpecific"+i, false, "Completed Stunt Jump "+(i+1), "Completed Stunt JumpSpecific");
					settings.Add("Found Stunt JumpSpecific"+i, false, "Found Stunt Jump "+(i+1), "Found Stunt JumpSpecific");
					if (i >= 50) {
						continue;
					}
					settings.Add("HorseshoeEach"+i, false, (i+1)+" Horseshoes", "HorseshoeEach");
					settings.Add("CollectibleSpecific"+i, false, "Horseshoe "+(i+1), "HorseshoeSpecific");
					settings.Add("SnapshotEach"+i, false, (i+1)+" Snapshots", "SnapshotEach");
					settings.Add("CollectibleSpecific"+(i+50), false, "Snapshot "+(i+1), "SnapshotSpecific");
					settings.Add("OysterEach"+i, false, (i+1)+" Oysters", "OysterEach");
					settings.Add("CollectibleSpecific"+(i+100), false, "Oyster "+(i+1), "OysterSpecific");
				}
			#endregion
			#region Tags
				for (int i = 0; i < 100; i++) {
					vars.AddNonScmAddressWatcher(0x69A8C0+0x4+i*0x8, "TagSpecific"+i, 1);
				}
				vars.AddNonScmAddressWatcher(0x69AD74, "TagEach", 1);
				vars.watchScmGlobalVariables.Add(1519, "TagAll"); // $ALL_TAGS_SPRAYED
				Func<string> func_tags = () => {
					var tag_allCollected = vars.GetWatcher("TagAll");
					if (tag_allCollected.Changed && tag_allCollected.Current == 1 && tag_allCollected.Old == 0) {
						vars.TrySplit("TagAll");
					}
					var tag_totalCollected = vars.GetWatcher("TagEach");
					if (tag_totalCollected.Changed && tag_totalCollected.Current > tag_totalCollected.Old) {
						vars.TrySplit("TagEach"+tag_totalCollected.Current);
					}
					else if (tag_totalCollected.Old >= 100) {
						// Break out if everything's already collected.
						return;
					}

					// Check collection state of specific tags
					if (!vars.CheckSetting("TagSpecific")) {
						return;
					}
					byte tag_collectedNow = 255;
					for (int i = 0; i < 100; i++) {
						if (tag_collectedNow < 100) {
							break;
						}
						var collectionStatus = vars.GetWatcher("TagSpecific"+i);
						if (collectionStatus.Changed && collectionStatus.Current >= 229 && collectionStatus.Old <= 228) {
							// Collection status changed, Split!
							tag_collectedNow = (byte)i;
						}
					}
					if (tag_collectedNow < 100) {
						vars.TrySplit("TagSpecific"+tag_collectedNow);
					}
					return;
				};
				vars.CheckSplit.Add(func_tags);
			#endregion
			#region Snapshots, Horseshoes, & Oysters
				for (int i = 0; i < 150; i++) {
					var b = 0x578EE4;
					vars.AddNonScmAddressWatcher(b+0xC+i*0x20, "CollectibleIdCheck"+i, 4);
					if (i < 50 || i >= 100) {
						// Horseshoes, Oysters
						vars.AddNonScmAddressWatcher(b+0x19+i*0x20, "CollectibleSpecific"+i, 1);
					}
					else {
						// Snapshots
						vars.AddNonScmAddressWatcher(b+0x18+i*0x20, "CollectibleSpecific"+i, 1);
					}
				}
				// Add watchers for unique stunt jumps
				for (int i = 0; i < 70; i++) {
					var p = new DeepPointer(0x69A888, 0x0, 0x40 + 0x44*i);
					vars.AddPointerWatcher(p, "Stunt JumpSpecific"+i, 2);
				}
				// Add watchers for # collected (regardless of which)
				vars.AddNonScmAddressWatcher(0x7791E4, "HorseshoeEach", 1);
				vars.AddNonScmAddressWatcher(0x7791BC, "SnapshotEach", 1);
				vars.AddNonScmAddressWatcher(0x7791EC, "OysterEach", 1);
				// Add watchers for collectible rewards given (USJ have none)
				vars.watchScmGlobalVariables.Add(1517, "HorseshoeAll"); // $ALL_HORSESHOES_COLLECTED
				vars.watchScmGlobalVariables.Add(1518, "SnapshotAll"); // $ALL_PHOTOS_TAKEN
				vars.watchScmGlobalVariables.Add(1516, "OysterAll"); // $ALL_OUSTERS_COLLECTED
				Func<string> func_collectibles = () => {
					if (!vars.CheckSetting("Collectibles")) {
						return;
					}
					var horseshoe_allCollected = vars.GetWatcher("HorseshoeAll");
					var snapshot_allCollected = vars.GetWatcher("SnapshotAll");
					var oyster_allCollected = vars.GetWatcher("OysterAll");
					if (horseshoe_allCollected.Changed && horseshoe_allCollected.Current == 1 && horseshoe_allCollected.Old == 0) {
						vars.TrySplit("HorseshoeAll");
					}
					else if (snapshot_allCollected.Changed && snapshot_allCollected.Current == 1 && snapshot_allCollected.Old == 0) {
						vars.TrySplit("SnapshotAll");
					}
					else if (oyster_allCollected.Changed && oyster_allCollected.Current == 1 && oyster_allCollected.Old == 0) {
						vars.TrySplit("OysterAll");
					}
					var horseshoe_totalCollected = vars.GetWatcher("HorseshoeEach");
					var snapshot_totalCollected = vars.GetWatcher("SnapshotEach");
					var oyster_totalCollected = vars.GetWatcher("OysterEach");
					var collectibles_totalCollected = horseshoe_totalCollected.Old+snapshot_totalCollected.Old+oyster_totalCollected.Old;
					if (horseshoe_totalCollected.Changed && horseshoe_totalCollected.Current > horseshoe_totalCollected.Old) {
						vars.TrySplit("HorseshoeEach"+horseshoe_totalCollected.Current);
					}
					else if (snapshot_totalCollected.Changed && snapshot_totalCollected.Current > snapshot_totalCollected.Old) {
						vars.TrySplit("SnapshotEach"+snapshot_totalCollected.Current);
					}
					else if (oyster_totalCollected.Changed && oyster_totalCollected.Current > oyster_totalCollected.Old) {
						vars.TrySplit("OysterEach"+oyster_totalCollected.Current);
					}
					else if (collectibles_totalCollected >= 150) {
						// Break out if everything's already collected.
						return;
					}

					if (!vars.CheckSetting("SnapshotSpecific") && !vars.CheckSetting("OysterSpecific") && !vars.CheckSetting("HorseshoeSpecific")) {
						return;
					}
					byte collectible_addressesIncorrect = 0;
					byte collectible_collectedNow = 255;
					for (byte i = 0; i < 150; i++) {
						var id = vars.GetWatcher("CollectibleIdCheck"+i).Current;
						// Check if this collectible's id is what we expect.
						if ((uint)id != vars.collectible_identifiers_msb[i]) {
							collectible_addressesIncorrect++;
							// If we can already tell the addresses broke, no need to check anything else
							if (collectible_addressesIncorrect > collectibles_totalCollected) {
								break;
							}
							continue;
						}
						// If we already found a collectible we just collected, we don't need to keep looking.
						// Until a new bug is discovered that lets players collect two collectibles simultaneously.
						if (collectible_collectedNow < 150) {
							continue;
						}
						// Check if we collected any
						var collectionStatus = vars.GetWatcher("CollectibleSpecific"+i);
						if (i < 50 || i >= 100) {
							// Horseshoes & Oysters
							if (!collectionStatus.Changed) {
								continue;
							}
							if (collectionStatus.Old != 0 && collectionStatus.Old != 8) {
								continue;
							}
							if (collectionStatus.Current != 1 && collectionStatus.Current != 9) {
								continue;
							}
							collectible_collectedNow = i;
						}
						else {
							// Snapshots
							if (collectionStatus.Changed && collectionStatus.Old == 20 && collectionStatus.Current == 0) {
								collectible_collectedNow = i;
							}
						}
					}
					// vars.DebugOutput(collectible_addressesIncorrect.ToString() + " - " + collectibles_totalCollected.ToString());
					// If the number of correct addresses is lower than what it should be. Purge everything and rebuild.
					if (collectible_addressesIncorrect > collectibles_totalCollected) {
						vars.DebugOutput("Collectible Addresses Changed");
						// Find new address
						int collectible_firstAddress = 0;
						for (int i = 0; i < 150; i++) {
							var collectible_identifier = vars.collectible_identifiers_lsb[i];
							var collectible_searchPhrase = "";
							if (i < 50) {
								// Horseshoes
								collectible_searchPhrase = "00000000??????????000000"+collectible_identifier+"????0000BA03??00????000000000000";
							}
							else if (i < 100) {
								// Snapshots
								collectible_searchPhrase = "0000000000000000????0000"+collectible_identifier+"????0000E504??0014??000000000000";
							}
							else {
								// Oysters
								collectible_searchPhrase = "00000000??????????000000"+collectible_identifier+"????0000B903??00????000000000000";
							}
							var collectible_address = vars.ScanForAddress(collectible_searchPhrase);
							if (collectible_address > 0) {
								vars.DebugOutput("New Address: "+collectible_address.ToString("x")+" for collectible"+i);
								collectible_firstAddress = collectible_address - i*0x20;
								vars.DebugOutput("First Address: "+collectible_firstAddress.ToString("x"));
								break;
							}
						}
						// Register new addresses
						for (int i = 0; i < 150; i++) {
							vars.ChangeNonScmAddressWatcher(collectible_firstAddress+0xC+i*0x20, "CollectibleIdCheck"+i, 4);
							if (i < 50 || i >= 100) {
								// Horseshoes, Oysters
								vars.ChangeNonScmAddressWatcher(collectible_firstAddress+0x19+i*0x20, "CollectibleSpecific"+i, 1);
							}
							else {
								// Snapshots
								vars.ChangeNonScmAddressWatcher(collectible_firstAddress+0x18+i*0x20, "CollectibleSpecific"+i, 1);
							}
						}
						return;
					}
					// A collectible was collected. Split it.
					if (collectible_collectedNow < 150) {
						vars.TrySplit("CollectibleSpecific"+collectible_collectedNow);
					}
					return;
				};
				vars.CheckSplit.Add(func_collectibles);
			#endregion Snapshots, Horseshoes, & Oysters
			#region Stunt Jumps
				vars.AddNonScmAddressWatcher(0x779064, "Completed Stunt JumpEach", 1);
				vars.AddNonScmAddressWatcher(0x779060, "Found Stunt JumpEach", 1);
				Func<string> func_usj = () => {
					var usj_totalCompleted = vars.GetWatcher("Completed Stunt JumpEach");
					if (usj_totalCompleted.Changed && usj_totalCompleted.Current > usj_totalCompleted.Old) {
						vars.TrySplit("Completed Stunt JumpEach"+usj_totalCompleted.Current);
					}
					var usj_totalfound = vars.GetWatcher("Found Stunt JumpEach");
					if (usj_totalfound.Changed && usj_totalfound.Current > usj_totalfound.Old) {
						vars.TrySplit("Found Stunt JumpEach"+usj_totalfound.Current);
					}
					else if (usj_totalCompleted.Old >= 70) {
						// Break out if everything's done already.
						return;
					}

					if (!vars.CheckSetting("Found Stunt JumpSpecific") && !vars.CheckSetting("Completed Stunt JumpSpecific")) {
						return;
					}
					var usj_completedNow = 255;
					var usj_foundNow = 255;
					for (int i = 0; i < 70; i++) {
						if (usj_completedNow < 70 || usj_foundNow < 70) {
							break;
						}
						var usj_status = vars.GetWatcher("Stunt JumpSpecific"+i);
						if (usj_status.Changed) {
							// Collection status changed, Split!
							if (usj_status.Current == 256 && usj_status.Old == 0) {
								usj_foundNow = i;
							}
							else if (usj_status.Current == 257 && usj_status.Old == 256) {
								usj_completedNow = i;
							}
						}
					}
					if (usj_completedNow < 70) {
						vars.TrySplit("Completed Stunt JumpSpecific"+usj_completedNow);
					}
					else if (usj_foundNow < 70) {
						vars.TrySplit("Found Stunt JumpSpecific"+usj_foundNow);
					}
					return;
				};
				vars.CheckSplit.Add(func_usj);
			#endregion Stunt Jumps
		#endregion
		#region Other
			settings.CurrentDefaultParent = "Splits";
			settings.Add("Other", false);
			#region Gang Territories
				settings.Add("GangTerritories", false, "Gang Territories", "Other");
				settings.Add("GT_LS", false, "Los Santos", "GangTerritories");
				settings.Add("GT_RTLS", false, "Return to Los Santos", "GangTerritories");
				settings.SetToolTip("GT_LS", "Splits for territories before The Green Sabre.");
				settings.SetToolTip("GT_RTLS", "Splits for territories after Vertical Bird.");
				settings.Add("GT_LS_Held", false, "Territories Held", "GT_LS");
				settings.Add("GT_RTLS_Held", false, "Territories Held", "GT_RTLS");
				settings.SetToolTip("GT_LS_Held", "Split when gang territories held stat changes to this number.");
				settings.SetToolTip("GT_RTLS_Held", "Split when gang territories held stat changes to this number.");
				for (int i = 1; i <= 379; i++) {
					string nameLS;
					string nameRTLS;
					if (i == 1) {
						nameLS = "1 territory held";
						nameRTLS = "1 territory held";
					}
					else {
						nameLS = i + " territories held";
						nameRTLS = i + " territories held";
					}
					if (i == 1) { nameRTLS += " (Grove Street during Home Coming)";}
					else if (i == 2) { nameRTLS += " (Gained for free after Home Coming)";}
					else if (i == 3) { nameRTLS += " (Glen Park during Beat Down on B Dup)";}
					else if (i == 5) { nameRTLS += " (Total number gained solely from story missions)";}
					else if (i == 7) { nameRTLS += " (\"Gang Territories Part 1\" in common any% NMG routes)";}
					else if (i == 9) { nameRTLS += " (After Grove 4 Life in common any% NMG routes)";}
					else if (i == 11) { nameLS += " (Starting count on new game)";}
					else if (i == 12) { nameLS += " (Glen Park during Doberman)";}
					else if (i == 17) { nameRTLS += " (All territories sans Grove 4 Life)";}
					else if (i == 19) { nameRTLS += " (Requirement to unlock End of the Line)";}
					else if (i == 53) { nameLS += " (All)"; nameRTLS += " (All)";}
					else if (i == 57) { nameRTLS += " (All + Varrios Los Aztecas territories)";}
					else if (i == 378) { nameLS += " (Entire map Glitch)"; nameRTLS += " (Entire map glitch)";}
					else if (i == 379) { nameLS += " (Entire map Glitch + SAN_AND)"; nameRTLS += " (Entire map glitch + SAN_AND)";}
					settings.Add("GT_LS_"+i, false, nameLS, "GT_LS_Held");
					settings.Add("GT_RTLS_"+i, false, nameLS, "GT_RTLS_Held");
				}
				settings.Add("GT_LS_Specific", false, "Specific Territories", "GT_LS");
				settings.Add("GT_RTLS_Specific", false, "Specific Territories", "GT_RTLS");
				settings.SetToolTip("GT_LS_Specific", "For reference: https://static.wikia.nocookie.net/gtawiki/images/4/40/TerritoriesNamesGTASA-map.png");
				settings.SetToolTip("GT_RTLS_Specific", "For reference: https://static.wikia.nocookie.net/gtawiki/images/4/40/TerritoriesNamesGTASA-map.png");

				vars.AddNonScmAddressWatcher(0x7791D0, "GT_count", 1);
				// Regions, as listed and ordered in the info.zon data file.
				// Zone names are based on the gxt, using this as a reference map:
				// https://static.wikia.nocookie.net/gtawiki/images/4/40/TerritoriesNamesGTASA-map.png/revision/latest?cb=20160714130032
				var GT_ZoneNames = new Dictionary<string,string>() {
					{"EBE", "East Beach"},
					{"ELS", "East Los Santos"},
					{"GAN", "Ganton"},
					{"GLN", "Glen Park"},
					{"IWD", "Idlewood"},
					{"JEF", "Jefferson"},
					{"CHC", "Las Colinas"},
					{"LFL", "Los Flores"},
					{"PLS", "Playa del Seville"},
					{"SMB", "Santa Maria Beach"},
					{"SUN", "Temple"},
					{"VERO", "Verona Beach"},
					{"VIN", "Vinewood"},
					{"LIND", "Willowfield"},
					{"Other", "Other territories (from glitch)"},
				};
				var GT_OtherZoneNames = new Dictionary<string,string>() {
					{"SUN", "Temple"},
					{"VIN", "Vinewood"},
					{"ELS", "East Los Santos"},
					{"JEF", "Jefferson"},
					{"LIND", "Willowfield"},
					{"GLN", "Glen Park"},
					{"ALDEA", "Aldea Malvada"},
					{"ANGPI", "Angel Pine"},
					{"ARCO", "Arco del Oeste"},
					{"CUNTC", "Avispa Country Club"},
					{"BACKO", "Back o Beyond"},
					{"BATTP", "Battery Point"},
					{"SUNMA", "Bayside Marina"},
					{"BYTUN", "Bayside Tunnel"},
					{"SUNNN", "Bayside"},
					{"BEACO", "Beacon Hill"},
					{"BFC", "Blackfield Chapel"},
					{"BFLD", "Blackfield"},
					{"BLUAC", "Blueberry Acres"},
					{"BLUEB", "Blueberry"},
					{"BONE", "Bone County"},
					{"CALI", "Caligula's Palace"},
					{"CALT", "Calton Heights"},
					{"CHINA", "Chinatown"},
					{"CITYS", "City Hall"},
					{"LOT", "Come-A-Lot"},
					{"COM", "Commerce"},
					{"CONF", "Conference Center"},
					{"CRANB", "Cranberry Station"},
					{"CREE", "Creek"},
					{"DILLI", "Dillimore"},
					{"DOH", "Doherty"},
					{"LDT", "Downtown Los Santos"},
					{"SFDWT", "Downtown"},
					{"EASB", "Easter Basin"},
					{"SFAIR", "Easter Bay Airport"},
					{"EBAY", "Easter Bay Chemicals"},
					{"ETUNN", "Easter Tunnel"},
					{"ELCA", "El Castillo del Diablo"},
					{"ELCO", "El Corona"},
					{"ELQUE", "El Quebrados"},
					{"ESPE", "Esplanade East"},
					{"ESPN", "Esplanade North"},
					{"HAUL", "Fallen Tree"},
					{"FALLO", "Fallow Bridge"},
					{"FERN", "Fern Ridge"},
					{"FINA", "Financial"},
					{"FISH", "Fisher's Lagoon"},
					{"FLINTC", "Flint County"},
					{"FLINTI", "Flint Intersection"},
					{"FLINTR", "Flint Range"},
					{"FLINW", "Flint Water"},
					{"CARSO", "Fort Carson"},
					{"SILLY", "Foster Valley"},
					{"FRED", "Frederick Bridge"},
					{"GANTB", "Gant Bridge"},
					{"GARC", "Garcia"},
					{"GARV", "Garver Bridge"},
					{"PALMS", "Green Palms"},
					{"GGC", "Greenglass College"},
					{"HBARNS", "Hampton Barns"},
					{"HANKY", "Hankypanky Point"},
					{"HGP", "Harry Gold Parkway"},
					{"HASH", "Hashbury"},
					{"TOPFA", "Hilltop Farm"},
					{"QUARY", "Hunter Quarry"},
					{"JTE", "Julius Thruway East"},
					{"JTN", "Julius Thruway North"},
					{"JTS", "Julius Thruway South"},
					{"JTW", "Julius Thruway West"},
					{"JUNIHI", "Juniper Hill"},
					{"JUNIHO", "Juniper Holow"},
					{"KACC", "K.A.C.C. Military Fuels"},
					{"KINC", "Kincaid Bridge"},
					{"THEA", "King's"},
					{"BARRA", "Las Barrancas"},
					{"BRUJA", "Las Brujas"},
					{"PAYAS", "Las Payasadas"},
					{"VAIR", "Las Venturas Airport"},
					{"VE", "Las Venturas"},
					{"LDM", "Last Dime Motel"},
					{"LEAFY", "Leafy Hollow"},
					{"PROBE", "Lil' Probe Inn"},
					{"LDS", "Linden Side"},
					{"LINDEN", "Linden Station"},
					{"LST", "Linden Station"},
					{"LMEX", "Little Mexico"},
					{"LSINL", "Los Santos Inlet"},
					{"LAIR", "Los Santos International"},
					{"LA", "Los Santos"},
					{"LVA", "LVA Freight Depot"},
					{"MAR", "Marina"},
					{"MARKST", "Market Station"},
					{"MKT", "Market"},
					{"MART", "Martin Bridge"},
					{"HILLP", "Missionary Hill"},
					{"MONINT", "Montgomery Intersection"},
					{"MONT", "Montgomery"},
					{"MTCHI", "Mount Chiliad"},
					{"MULINT", "Mulholland Intersection"},
					{"MUL", "Mulholland"},
					{"NROCK", "North Rock"},
					{"LDOC", "Ocean Docks"},
					{"OCEAF", "Ocean Flats"},
					{"OCTAN", "Octane Springs"},
					{"OVS", "Old Venturas Split"},
					{"BAYV", "Palisad"},
					{"PALO", "Palomino Creek"},
					{"PARA", "Paradiso"},
					{"PER1", "Pershing Square"},
					{"PILL", "Pilgrim"},
					{"PINT", "Pilson Intersection"},
					{"PIRA", "Pirates in Men's Pants"},
					{"PRP", "Prickle Pine"},
					{"WESTP", "Queens"},
					{"RIE", "Randolph Industrial Estate"},
					{"RED", "Red County"},
					{"REDE", "Redsands East"},
					{"REDW", "Redsands West"},
					{"TOM", "Regular Tom"},
					{"REST", "Restricted Area"},
					{"RIH", "Richman"},
					{"BINT", "Robada Intersection"},
					{"ROBINT", "Robada Intersection"},
					{"ROCE", "Roca Escalante"},
					{"RSE", "Rockshore East"},
					{"RSW", "Rockshore West"},
					{"ROD", "Rodeo"},
					{"ROY", "Royal Casino"},
					{"SASO", "San Andreas Sound"},
					{"SANB", "San Fierro Bay"},
					{"SF", "San Fierro"},
					{"CIVI", "Santa Flora"},
					{"SHACA", "Shady Cabin"},
					{"CREEK", "Shady Creeks"},
					{"SHERR", "Sherman Reservoir"},
					{"SRY", "Sobell Rail Yards"},
					{"SPIN", "Spinybed"},
					{"STAR", "Starfish Casino"},
					{"BIGE", "The Big Ear'"},
					{"CAM", "The Camel's Toe"},
					{"RING", "The Clown's Pocket"},
					{"ISLE", "The Emerald Isle"},
					{"FARM", "The Farm"},
					{"DRAG", "The Four Dragons Casino"},
					{"HIGH", "The High Roller"},
					{"MAKO", "The Mako Span"},
					{"PANOP", "The Panopticon"},
					{"PINK", "The Pink Swan"},
					{"DAM", "The Sherman Dam"},
					{"STRIP", "The Strip"},
					{"VISA", "The Visage"},
					{"ROBAD", "Tierra Robada"},
					{"UNITY", "Unity Station"},
					{"VALLE", "Valle Ocultado"},
					{"BLUF", "Verdant Bluffs"},
					{"MEAD", "Verdant Meadows"},
					{"WHET", "Whetstone"},
					{"WWE", "Whitewood Estates"},
					{"YBELL", "Yellow Bell Golf Course"},
					{"YELLOW", "Yellow Bell Station"},
				};
				var GT_TerritoryNames = new Dictionary<string,string>() {
					{"SMB1", "SMB"},
					{"SMB2", "SMB"},
					{"VERO1", "VERO"},
					{"VERO2", "VERO"},
					{"VERO3", "VERO"},
					{"VERO4a", "VERO"},
					{"VERO4b", "VERO"},
					{"VIN2", "VIN"},
					{"SUN1", "SUN"},
					{"SUN3a", "SUN"},
					{"SUN3b", "SUN"},
					{"SUN3c", "SUN"},
					{"SUN4", "SUN"},
					{"CHC1a", "CHC"},
					{"CHC1b", "CHC"},
					{"CHC2a", "CHC"},
					{"CHC2b", "CHC"},
					{"CHC3", "CHC"},
					{"CHC4a", "CHC"},
					{"CHC4b", "CHC"},
					{"GLN1", "GLN"},
					{"GLN2a", "GLN"},
					{"JEF1a", "JEF"},
					{"JEF1b", "JEF"},
					{"JEF2", "JEF"},
					{"JEF3b", "JEF"},
					{"JEF3c", "JEF"},
					{"ELS1a", "ELS"},
					{"ELS1b", "ELS"},
					{"ELS2", "ELS"},
					{"ELS3a", "ELS"},
					{"ELS3b", "ELS"},
					{"ELS4", "ELS"},
					{"LFL1a", "LFL"},
					{"LFL1b", "LFL"},
					{"EBE1", "EBE"},
					{"EBE2a", "EBE"},
					{"EBE2b", "EBE"},
					{"EBE3c", "EBE"},
					{"IWD1", "IWD"},
					{"IWD2", "IWD"},
					{"IWD3a", "IWD"},
					{"IWD3b", "IWD"},
					{"IWD4", "IWD"},
					{"IWD5", "IWD"},
					{"GAN1", "GAN"},
					{"GAN2", "GAN"},
					{"LIND1a", "LIND"},
					{"LIND1b", "LIND"},
					{"LIND2a", "LIND"},
					{"LIND2b", "LIND"},
					{"LIND3", "LIND"},
					{"PLS", "PLS"},
				};
				var GT_OtherTerritoryNames = new Dictionary<string,string>() {
					{"ALDEA", "ALDEA"},
					{"ANGPI", "ANGPI"},
					{"ARCO", "ARCO"},
					{"BACKO", "BACKO"},
					{"BARRA", "BARRA"},
					{"BATTP", "BATTP"},
					{"BAYV", "BAYV"},
					{"BEACO", "BEACO"},
					{"BFC1", "BFC"},
					{"BFC2", "BFC"},
					{"BFLD1", "BFLD"},
					{"BFLD2", "BFLD"},
					{"BIGE", "BIGE"},
					{"BINT1", "BINT"},
					{"BINT2", "BINT"},
					{"BINT3", "BINT"},
					{"BINT4", "BINT"},
					{"BLUAC", "BLUAC"},
					{"BLUEB", "BLUEB"},
					{"BLUEB1", "BLUEB"},
					{"BLUF1a", "BLUF"},
					{"BLUF1b", "BLUF"},
					{"BLUF2", "BLUF"},
					{"BONE", "BONE"},
					{"BRUJA", "BRUJA"},
					{"BYTUN", "BYTUN"},
					{"CALI1", "CALI"},
					{"CALI2", "CALI"},
					{"CALT", "CALT"},
					{"CAM", "CAM"},
					{"CARSO", "CARSO"},
					{"CHINA", "CHINA"},
					{"CITYS", "CITYS"},
					{"CIVI", "CIVI"},
					{"COM1a", "COM"},
					{"COM1b", "COM"},
					{"COM2", "COM"},
					{"COM3", "COM"},
					{"COM4", "COM"},
					{"CONF1a", "CONF"},
					{"CONF1b", "CONF"},
					{"CONST1", "STAR"},
					{"CRANB", "CRANB"},
					{"CREE", "CREE"},
					{"CREEK", "CREEK"},
					{"CREEK1", "CREEK"},
					{"CUNTC1", "CUNTC"},
					{"CUNTC2", "CUNTC"},
					{"CUNTC3", "CUNTC"},
					{"DAM", "DAM"},
					{"DILLI", "DILLI"},
					{"DOH1", "DOH"},
					{"DOH2", "DOH"},
					{"DRAG", "DRAG"},
					{"EASB1", "EASB"},
					{"EASB2", "EASB"},
					{"EBAY", "EBAY"},
					{"EBAY2", "EBAY"},
					{"ELCA", "ELCA"},
					{"ELCA1", "ELCA"},
					{"ELCA2", "ELCA"},
					{"ELCO1", "ELCO"},
					{"ELCO2", "ELCO"},
					{"ELQUE", "ELQUE"},
					{"ELS3c", "ELS"},
					{"ESPE1", "ESPE"},
					{"ESPE2", "ESPE"},
					{"ESPE3", "ESPE"},
					{"ESPN1", "ESPN"},
					{"ESPN2", "ESPN"},
					{"ESPN3", "ESPN"},
					{"ETUNN", "ETUNN"},
					{"FALLO", "FALLO"},
					{"FARM", "FARM"},
					{"FERN", "FERN"},
					{"FINA", "FINA"},
					{"FISH", "FISH"},
					{"FLINTC", "FLINTC"},
					{"FLINTI", "FLINTI"},
					{"FLINTR", "FLINTR"},
					{"FLINW", "FLINW"},
					{"FRED", "FRED"},
					{"GANTB", "GANTB"},
					{"GANTB1", "GANTB"},
					{"GARC", "GARC"},
					{"GARV", "GARV"},
					{"GARV1", "GARV"},
					{"GARV2", "GARV"},
					{"GGC1", "GGC"},
					{"GGC2", "GGC"},
					{"GLN1b", "GLN"},
					{"HANKY", "HANKY"},
					{"HASH", "HASH"},
					{"HAUL", "HAUL"},
					{"HBARNS", "HBARNS"},
					{"HGP", "HGP"},
					{"HIGH", "HIGH"},
					{"HILLP", "HILLP"},
					{"ISLE", "ISLE"},
					{"JEF3a", "JEF"},
					{"JTE1", "JTE"},
					{"JTE2", "JTE"},
					{"JTE3", "JTE"},
					{"JTE4", "JTE"},
					{"JTN1", "JTN"},
					{"JTN2", "JTN"},
					{"JTN3", "JTN"},
					{"JTN4", "JTN"},
					{"JTN5", "JTN"},
					{"JTN6", "JTN"},
					{"JTN7", "JTN"},
					{"JTN8", "JTN"},
					{"JTS1", "JTS"},
					{"JTS2", "JTS"},
					{"JTW1", "JTW"},
					{"JTW2", "JTW"},
					{"JUNIHI", "JUNIHI"},
					{"JUNIHO", "JUNIHO"},
					{"KACC", "KACC"},
					{"KINC", "KINC"},
					{"KINC1", "KINC"},
					{"KINC2", "KINC"},
					{"LA", "LA"},
					{"LAIR1", "LAIR"},
					{"LAIR2a", "LAIR"},
					{"LAIR2b", "LAIR"},
					{"LBAG1", "LAIR"},
					{"LBAG2", "LAIR"},
					{"LBAG3", "LAIR"},
					{"LDM", "LDM"},
					{"LDOC1a", "LDOC"},
					{"LDOC1b", "LDOC"},
					{"LDOC2", "LDOC"},
					{"LDOC3a", "LDOC"},
					{"LDOC3b", "LDOC"},
					{"LDOC3c", "LDOC"},
					{"LDOC4", "LDOC"},
					{"LDS", "LDS"},
					{"LDT1a", "LDT"},
					{"LDT1b", "LDT"},
					{"LDT1c", "LDT"},
					{"LDT3", "LDT"},
					{"LDT4", "LDT"},
					{"LDT5", "LDT"},
					{"LDT6", "LDT"},
					{"LDT7", "LDT"},
					{"LDT8", "LDT"},
					{"LEAFY", "LEAFY"},
					{"LIND4a", "LIND"},
					{"LIND4c", "LIND"},
					{"LINDEN", "LINDEN"},
					{"LMEX1a", "LMEX"},
					{"LMEX1b", "LMEX"},
					{"LOT", "LOT"},
					{"LSINL", "LSINL"},
					{"LST", "LST"},
					{"LVA1", "LVA"},
					{"LVA2", "LVA"},
					{"LVA3", "LVA"},
					{"LVA4", "LVA"},
					{"LVA5", "LVA"},
					{"LVBAG", "VAIR"},
					{"MAKO", "MAKO"},
					{"MAR1", "MAR"},
					{"MAR2", "MAR"},
					{"MAR3", "MAR"},
					{"MARKST", "MARKST"},
					{"MART", "MART"},
					{"MEAD", "MEAD"},
					{"MKT1", "MKT"},
					{"MKT2", "MKT"},
					{"MKT3", "MKT"},
					{"MKT4", "MKT"},
					{"MONINT (1)", "MONINT"},
					{"MONINT (2)", "MONINT"},
					{"MONT", "MONT"},
					{"MONT1", "MONT"},
					{"MTCHI1", "MTCHI"},
					{"MTCHI2", "MTCHI"},
					{"MTCHI3", "MTCHI"},
					{"MTCHI4", "MTCHI"},
					{"MUL1a", "MUL"},
					{"MUL1b", "MUL"},
					{"MUL1c", "MUL"},
					{"MUL2a", "MUL"},
					{"MUL2b", "MUL"},
					{"MUL3", "MUL"},
					{"MUL4", "MUL"},
					{"MUL5a", "MUL"},
					{"MUL5b", "MUL"},
					{"MUL5c", "MUL"},
					{"MUL6", "MUL"},
					{"MUL7a", "MUL"},
					{"MUL7b", "MUL"},
					{"MULINT", "MULINT"},
					{"NROCK", "NROCK"},
					{"OCEAF1", "OCEAF"},
					{"OCEAF2", "OCEAF"},
					{"OCEAF3", "OCEAF"},
					{"OCTAN", "OCTAN"},
					{"OVS", "OVS"},
					{"PALMS", "PALMS"},
					{"PALO", "PALO"},
					{"PANOP", "PANOP"},
					{"PARA", "PARA"},
					{"PAYAS", "PAYAS"},
					{"PER1", "PER1"},
					{"PILL1", "PILL"},
					{"PILL2", "PILL"},
					{"PINK", "PINK"},
					{"PINT", "PINT"},
					{"PIRA", "PIRA"},
					{"PROBE", "PROBE"},
					{"PRP1", "PRP"},
					{"PRP2", "PRP"},
					{"PRP3", "PRP"},
					{"PRP4", "PRP"},
					{"QUARY", "QUARY"},
					{"RED", "RED"},
					{"REDE1", "REDE"},
					{"REDE2", "REDE"},
					{"REDE3", "REDE"},
					{"REDW1", "REDW"},
					{"REDW2", "REDW"},
					{"REDW3", "REDW"},
					{"REDW4", "REDW"},
					{"REST", "REST"},
					{"RIE", "RIE"},
					{"RIH1a", "RIH"},
					{"RIH1b", "RIH"},
					{"RIH2", "RIH"},
					{"RIH3a", "RIH"},
					{"RIH3b", "RIH"},
					{"RIH4", "RIH"},
					{"RIH5a", "RIH"},
					{"RIH5b", "RIH"},
					{"RIH6a", "RIH"},
					{"RIH6b", "RIH"},
					{"RING", "RING"},
					{"ROBAD", "ROBAD"},
					{"ROBAD1", "ROBAD"},
					{"ROBINT", "ROBINT"},
					{"ROCE1", "ROCE"},
					{"ROCE2", "ROCE"},
					{"ROD1a", "ROD"},
					{"ROD1b", "ROD"},
					{"ROD1c", "ROD"},
					{"ROD2a", "ROD"},
					{"ROD2b", "ROD"},
					{"ROD3a", "ROD"},
					{"ROD3b", "ROD"},
					{"ROD4a", "ROD"},
					{"ROD4b", "ROD"},
					{"ROD4c", "ROD"},
					{"ROD5a", "ROD"},
					{"ROD5b", "ROD"},
					{"ROY", "ROY"},
					{"RSE", "RSE"},
					{"RSW1", "RSW"},
					{"RSW2", "RSW"},
					{"SANB1", "SANB"},
					{"SANB2", "SANB"},
					{"SASO", "SASO"},
					{"SF", "SF"},
					{"SFAIR1", "SFAIR"},
					{"SFAIR2", "SFAIR"},
					{"SFAIR3", "SFAIR"},
					{"SFAIR4", "SFAIR"},
					{"SFAIR5", "SFAIR"},
					{"SFBAG1", "SFAIR"},
					{"SFBAG2", "SFAIR"},
					{"SFBAG3", "SFAIR"},
					{"SFDWT1", "SFDWT"},
					{"SFDWT2", "SFDWT"},
					{"SFDWT3", "SFDWT"},
					{"SFDWT4", "SFDWT"},
					{"SFDWT5", "SFDWT"},
					{"SFDWT6", "SFDWT"},
					{"SFGLF1", "CUNTC"},
					{"SFGLF2", "CUNTC"},
					{"SFGLF3", "GARC"},
					{"SFGLF4", "CUNTC"},
					{"SHACA", "SHACA"},
					{"SHERR", "SHERR"},
					{"SILLY1", "SILLY"},
					{"SILLY2", "SILLY"},
					{"SILLY3", "SILLY"},
					{"SILLY4", "SILLY"},
					{"SPIN", "SPIN"},
					{"SRY", "SRY"},
					{"STAR1", "STAR"},
					{"STAR2", "STAR"},
					{"STRIP1", "STRIP"},
					{"STRIP2", "STRIP"},
					{"STRIP3", "STRIP"},
					{"STRIP4", "STRIP"},
					{"SUN2", "SUN"},
					{"SUNMA", "SUNMA"},
					{"SUNNN", "SUNNN"},
					{"THALL1", "COM"},
					{"THEA1", "THEA"},
					{"THEA2", "THEA"},
					{"THEA3", "THEA"},
					{"TOM", "TOM"},
					{"TOPFA", "TOPFA"},
					{"UNITY", "UNITY"},
					{"VAIR1", "VAIR"},
					{"VAIR2", "VAIR"},
					{"VAIR3", "VAIR"},
					{"VALLE", "VALLE"},
					{"VE", "VE"},
					{"VIN1a", "VIN"},
					{"VIN1b", "VIN"},
					{"VIN3", "VIN"},
					{"VISA1", "VISA"},
					{"VISA2", "VISA"},
					{"WESTP1", "WESTP"},
					{"WESTP2", "WESTP"},
					{"WESTP3", "WESTP"},
					{"WHET", "WHET"},
					{"WWE", "WWE"},
					{"WWE1", "WWE"},
					{"YBELL1", "YBELL"},
					{"YBELL2", "YBELL"},
					{"YELLOW", "YELLOW"},
				};
				vars.GT_TerritoryIndices = new List<string>() {
					"SUNMA", "SUNNN", "BATTP", "PARA", "CIVI", "BAYV", "CITYS", "OCEAF1", "OCEAF2", "OCEAF3", 
					"SILLY3", "SILLY4", "HASH", "JUNIHO", "ESPN1", "ESPN2", "ESPN3", "FINA", "CALT", "SFDWT1", 
					"SFDWT2", "SFDWT3", "SFDWT4", "JUNIHI", "CHINA", "SFDWT5", "THEA1", "THEA2", "THEA3", "GARC", 
					"DOH1", "DOH2", "SFDWT6", "SFAIR3", "EASB1", "EASB2", "ESPE1", "ESPE2", "ESPE3", "ANGPI", 
					"SHACA", "BACKO", "LEAFY", "FLINTR", "HAUL", "FARM", "ELQUE", "ALDEA", "DAM", "BARRA", 
					"CARSO", "QUARY", "OCTAN", "PALMS", "TOM", "BRUJA", "MEAD", "PAYAS", "ARCO", "SFAIR1", 
					"HANKY", "PALO", "NROCK", "MONT", "MONT1", "HBARNS", "FERN", "DILLI", "TOPFA", "BLUEB1", 
					"BLUEB", "PANOP", "FRED", "MAKO", "BLUAC", "MART", "FALLO", "CREEK", "CREEK1", "WESTP1", 
					"WESTP2", "WESTP3", "LA", "VE", "BONE", "ROBAD", "GANTB", "GANTB1", "SF", "ROBAD1", 
					"RED", "FLINTC", "EBAY", "EBAY2", "SFAIR4", "SILLY1", "SILLY2", "SFAIR2", "SFAIR5", "WHET", 
					"LAIR1", "LAIR2a", "BLUF1a", "ELCO2", "LIND1a", "LIND1b", "LIND2a", "LIND2b", "LDOC4", "LDOC1b", 
					"MAR3", "VERO4a", "VERO4b", "BLUF1b", "BLUF2", "ELCO1", "VERO1", "MAR1", "MAR2", "VERO3", 
					"VERO2", "CONF1b", "CONF1a", "THALL1", "COM1a", "COM1b", "COM2", "PER1", "COM4", "LMEX1a", 
					"LMEX1b", "COM3", "IWD3a", "IWD3b", "IWD4", "IWD1", "IWD2", "GLN2a", "GLN1b", "JEF3a", 
					"JEF3c", "JEF2", "JEF1b", "JEF1a", "CHC1a", "CHC1b", "CHC2b", "CHC2a", "IWD5", "GAN2", 
					"GAN1", "LIND4c", "EBE3c", "EBE2a", "EBE2b", "ELS4", "ELS3a", "JEF3b", "ELS3b", "ELS3c", 
					"ELS1a", "ELS1b", "ELS2", "LFL1a", "LFL1b", "EBE1", "CHC4a", "CHC4b", "CHC3", "LDT5", 
					"LDT7", "LDT4", "LDT3", "LDT6", "MULINT", "MUL3", "MUL2a", "MUL2b", "MKT3", "VIN3", 
					"MKT4", "LDT1a", "LDT1b", "LDT1c", "SUN3a", "SUN3b", "SUN3c", "MUL7a", "MUL7b", "MUL6", 
					"VIN2", "SUN1", "SUN4", "SUN2", "MUL4", "MUL1a", "MUL1b", "MUL5a", "MUL5b", "MUL5c", 
					"MUL1c", "SMB1", "SMB2", "ROD5b", "ROD5a", "ROD1a", "ROD1b", "ROD1c", "ROD3a", "ROD3b", 
					"ROD4a", "ROD4b", "ROD4c", "VIN1b", "RIH5a", "RIH5b", "ROD2b", "ROD2a", "RIH6a", "RIH6b", 
					"RIH3a", "RIH3b", "RIH4", "RIH2", "RIH1a", "RIH1b", "STRIP1", "STRIP2", "DRAG", "PINK", 
					"HIGH", "PIRA", "VISA1", "VISA2", "JTS1", "JTW1", "JTS2", "RSE", "LOT", "CAM", "ROY", 
					"CALI1", "CALI2", "PILL1", "STAR2", "STRIP3", "STRIP4", "ISLE", "OVS", "KACC", "CREE", 
					"SRY", "LST", "JTE2", "LDS", "JTE1", "JTN1", "JTE4", "JTE3", "JTN2", "JTN3", 
					"JTN4", "JTN5", "JTW2", "JTN6", "HGP", "REDE1", "REDE2", "REDE3", "JTN8", "REDW2", 
					"REDW1", "REDW3", "REDW4", "VAIR1", "VAIR2", "VAIR3", "LVA1", "BINT2", "BINT1", "BINT3", 
					"BINT4", "LVA2", "LVA3", "LVA4", "LVA5", "GGC1", "GGC2", "BFLD1", "BFLD2", "ROCE1", 
					"ROCE2", "LDM", "RSW1", "RSW2", "RIE", "BFC1", "BFC2", "JTN7", "PINT", "WWE", 
					"PRP1", "PRP2", "PRP3", "SPIN", "PRP4", "PILL2", "SASO", "FISH", "GARV", "GARV1", 
					"GARV2", "KINC", "KINC1", "KINC2", "LSINL", "SHERR", "FLINW", "ETUNN", "BYTUN", "BIGE", 
					"PROBE", "VALLE", "GLN1", "LDOC3a", "LINDEN", "UNITY", "VIN1a", "MARKST", "CRANB", "YELLOW", 
					"SANB1", "SANB2", "ELCA", "ELCA1", "ELCA2", "REST", "MONINT (1)", "MONINT (2)", "ROBINT", "FLINTI", 
					"SFBAG2", "SFBAG3", "SFBAG1", "MKT1", "MKT2", "SFGLF4", "CUNTC2", "HILLP", "MTCHI2", "MTCHI3", 
					"MTCHI1", "MTCHI4", "YBELL1", "YBELL2", "LVBAG", "LDOC1a", "LAIR2b", "LDOC3b", "LBAG1", "LBAG2", 
					"LBAG3", "CONST1", "BEACO", "SFGLF1", "SFGLF2", "SFGLF3", "CUNTC1", "CUNTC3", "PLS", "LDOC3c", 
					"STAR1", "RING", "LDOC2", "LIND3", "LIND4a", "WWE1", "LDT8", 
				};
				vars.GT_TerritoryCount = vars.GT_TerritoryIndices.Count;
				vars.GT_OGTerritories = new HashSet<int> {
					201,202,116,120,119,111,112,190,191,184,
					185,186,192,144,145,147,146,168,166,167,
					323,137,143,142,141,157,140,160,161,162,
					156,158,155,163,164,165,153,154,152,135,
					136,132,133,134,148,150,149,104,105,106,
					107,374,369,
				};
				foreach (var entry in GT_ZoneNames) {
					settings.Add("GT_LS_z"+entry.Key, false, entry.Value, "GT_LS_Specific");
					settings.Add("GT_RTLS_z"+entry.Key, false, entry.Value, "GT_RTLS_Specific");
				}
				foreach (var entry in GT_OtherZoneNames) {
					settings.Add("GT_LS_zx"+entry.Key, false, entry.Value, "GT_LS_zOther");
					settings.Add("GT_RTLS_zx"+entry.Key, false, entry.Value, "GT_RTLS_zOther");
				}
				foreach (var entry in GT_TerritoryNames) {
					settings.Add("GT_LS_r"+entry.Key, false, entry.Key, "GT_LS_z"+entry.Value);
					settings.Add("GT_RTLS_r"+entry.Key, false, entry.Key, "GT_RTLS_z"+entry.Value);
					settings.Add("GT_LS_r"+entry.Key+"_0", false, "Fight started", "GT_LS_r"+entry.Key);
					settings.Add("GT_RTLS_r"+entry.Key+"_0", false, "Fight started", "GT_RTLS_r"+entry.Key);
					settings.Add("GT_LS_r"+entry.Key+"_1", false, "Wave 1", "GT_LS_r"+entry.Key);
					settings.Add("GT_RTLS_r"+entry.Key+"_1", false, "Wave 1", "GT_RTLS_r"+entry.Key);
					settings.Add("GT_LS_r"+entry.Key+"_2", false, "Wave 2", "GT_LS_r"+entry.Key);
					settings.Add("GT_RTLS_r"+entry.Key+"_2", false, "Wave 2", "GT_RTLS_r"+entry.Key);
					settings.Add("GT_LS_r"+entry.Key+"_3", false, "Wave 3", "GT_LS_r"+entry.Key);
					settings.Add("GT_RTLS_r"+entry.Key+"_3", false, "Wave 3", "GT_RTLS_r"+entry.Key);
				}
				foreach (var entry in GT_OtherTerritoryNames) {
					settings.Add("GT_LS_r"+entry.Key, false, entry.Key, "GT_LS_zx"+entry.Value);
					settings.Add("GT_RTLS_r"+entry.Key, false, entry.Key, "GT_RTLS_zx"+entry.Value);
					settings.Add("GT_LS_r"+entry.Key+"_0", false, "Fight started", "GT_LS_r"+entry.Key);
					settings.Add("GT_RTLS_r"+entry.Key+"_0", false, "Fight started", "GT_RTLS_r"+entry.Key);
					settings.Add("GT_LS_r"+entry.Key+"_1", false, "Wave 1", "GT_LS_r"+entry.Key);
					settings.Add("GT_RTLS_r"+entry.Key+"_1", false, "Wave 1", "GT_RTLS_r"+entry.Key);
					settings.Add("GT_LS_r"+entry.Key+"_2", false, "Wave 2", "GT_LS_r"+entry.Key);
					settings.Add("GT_RTLS_r"+entry.Key+"_2", false, "Wave 2", "GT_RTLS_r"+entry.Key);
					settings.Add("GT_LS_r"+entry.Key+"_3", false, "Wave 3", "GT_LS_r"+entry.Key);
					settings.Add("GT_RTLS_r"+entry.Key+"_3", false, "Wave 3", "GT_RTLS_r"+entry.Key);
				}
				for (int i = 0; i < vars.GT_TerritoryCount; i++) {
					vars.AddNonScmAddressWatcher(0x7A1E01 + i*17, "GT_"+i, 4);
					vars.AddNonScmAddressWatcher(0x7A1E01+15 + i*17, "GT_c"+i, 1);
				}
				// Territories each take 17 bytes in memory.
				// First byte: % Ballas
				// Second byte: % Grove
				// Third byte: % Vagos
				// Fourth byte: % Aztecas? Not relevant anyway
				// Bytes 5 - 10: Idk. Haven't seen them not be 0x00
				// Byte 11: Some value, idk what it means
				// Byte 12: R value of zone on map
				// Byte 13: G value of zone on map
				// Byte 14: B value of zone on map
				// Byte 15: A value of zone on map
				// Byte 16: Some value, values between 0x40 - 0x5F means the map zone is flashing. Usually set to 0x46 or 0x47? IDK what it means exactly.
				// Byte 16: Unsure, some value. Could actually be the first byte of the next zone instead of the last of this. Didn't check.
				Func<string> func_GangTerritories = () => {
					var ls_sweet_chain = vars.GetWatcher("ls_sweet_chain");
					var ls_crash_chain = vars.GetWatcher("ls_crash_chain");
					if (ls_sweet_chain.Current < 7 && ls_crash_chain.Current < 1) {
						// Cesar Vialpando or Burning Desire not passed
						return;
					}
					var GT_splitPrefix = "GT_LS_";
					var ls_final_chain = vars.GetWatcher("ls_final_chain");
					var rtls_mansion_chain = vars.GetWatcher("rtls_mansion_chain");
					if (rtls_mansion_chain.Current < 2 && ls_final_chain.Current >= 2) {
						// Past LS, before RTLS
						return;
					}
					if (rtls_mansion_chain.Current >= 2) {
						GT_splitPrefix = "GT_RTLS_";
					}
					// Check count
					var GT_count = vars.GetWatcher("GT_count");
					if (GT_count.Changed) {
						if (GT_count.Current > GT_count.Old) {
							vars.TrySplit(GT_splitPrefix + GT_count.Current);
						}
					}
					// Check specific regions
					GT_splitPrefix += "r";
					for (int i = 0; i < vars.GT_TerritoryCount; i++) {
						if (!settings["GT_LS_zOther"] && !settings["GT_RTLS_zOther"] && !vars.GT_OGTerritories.Contains(i)) {
							continue;
						}
						var GT_x = vars.GetWatcher("GT_"+i);
						var GT_cx = vars.GetWatcher("GT_c"+i);
						if (GT_x.Changed || GT_cx.Changed) {
							
							var GT_ballasCurrent = (byte)(GT_x.Current & 0xFF);
							var GT_groveCurrent = (byte)(GT_x.Current >> 8 & 0xFF);
							var GT_yellowCurrent = (byte)(GT_x.Current >> 16 & 0xFF);
							var GT_ballasOld = (byte)(GT_x.Old & 0xFF);
							var GT_groveOld = (byte)(GT_x.Old >> 8 & 0xFF);
							var GT_yellowOld = (byte)(GT_x.Old  >> 16 & 0xFF);
							var GT_enemyCurrent = GT_yellowCurrent + GT_ballasCurrent;
							var GT_enemyOld = GT_yellowOld + GT_ballasOld;
							if (GT_x.Changed) {
								if (GT_groveOld == 0 && GT_groveCurrent > 0) {
									return GT_splitPrefix+vars.GT_TerritoryIndices[i]+"_1";
								}
								else if (GT_enemyCurrent == 0 && GT_enemyOld > 0) {
									return GT_splitPrefix+vars.GT_TerritoryIndices[i]+"_3";
								}
								else if (GT_groveCurrent > GT_enemyCurrent && GT_groveOld <= GT_enemyCurrent) {
									return GT_splitPrefix+vars.GT_TerritoryIndices[i]+"_2";
								}
							}
							// Check if the flashiness of the territory has changed.
							// This happens when starting a fight, the territory will flash red.
							// Also do a check to see if this is not an attack on us.
							if (GT_cx.Changed) {
								if (GT_cx.Current < 0x40 || GT_cx.Current > 0x5F) {
									// Flashing stopped
									return;
								}
								if (GT_cx.Old >= 0x40 && GT_cx.Old <= 0x5F) {
									// I don't think this can happen
									return;
								}
								if (GT_groveCurrent > GT_enemyCurrent && GT_groveOld > GT_enemyOld) {
									// This is an attack on a territory already owned by us.
									return;
								}
								return GT_splitPrefix+vars.GT_TerritoryIndices[i]+"_0";
							}
						}
					}
					return;
				};
				vars.CheckSplit.Add(func_GangTerritories);
			#endregion
			#region Phone Calls
				settings.Add("PhoneCalls", false, "Phone Calls", "Other");
				settings.CurrentDefaultParent = "PhoneCalls";
				// Calls:
				// 6 - House Party reminder call
				// 7 - Cesar to unlock High Stakes, Low-Rider
				// 9 - Officer Hernandez
				// 11 - HSLR Fail call
				// 12 - Burning Desire unlock call
				// 18 - Doberman unlock call
				// 19 - Sweet early missable phonecall
				// 20 - Sweet gym call (not fat)
				// 21 - * * Sweet gym call (fat)

				settings.Add("PhoneCall19", false, "Sweet; after Big Smoke; missable.");
				settings.SetToolTip("PhoneCall19", "\"Thought I'd explain some shit.\"\nSweet explains how the Grove has fallen apart.\nMissable phonecall, call stops coming in after Drive-Thru.");
				vars.watchScmGlobalVariables.Add(1347, "PhoneCall19");
				settings.Add("PhoneCall9", false, "Officer Hernandez; after Tagging Up Turf");
				settings.SetToolTip("PhoneCall9", "\"Carl, it's officer Hernandez\"\nOfficer Hernandez informs CJ the bridges to the other islands are closed.");
				vars.watchScmGlobalVariables.Add(1349, "PhoneCall9");
				settings.Add("PhoneCall20", false, "Sweet; after Drive-Thru; gym cutscene");
				settings.SetToolTip("PhoneCall20", "\"If you don't respect your body, ain't nobody going to respect you!\"\nSweet tells CJ to go to the gym.\nPlays a brief cinematic showing the gym after hanging up.\nCall is different if CJ is fat.");
				vars.watchScmGlobalVariables.Add(1348, "PhoneCall20");
				settings.Add("PhoneCall7", false, "Cesar; after Cesar Vialpando; unlocks mission");
				settings.SetToolTip("PhoneCall7", "\"What's up homie? It's Cesar Vialpando cabron, que honda?\"\nCesar tells CJ about a race.\nUnlocks High Stakes, Low-Rider.");
				vars.watchScmGlobalVariables.Add(1344, "PhoneCall7");
				settings.Add("PhoneCall11", false, "Kendl; after High Stakes, Low Rider; on fail");
				settings.SetToolTip("PhoneCall11", "\"Loser!\"\nKendl mocks CJ for losing the race.\nOccurs after failing the mission, rather than passing it.");
				vars.watchScmGlobalVariables.Add(1371, "PhoneCall11");
				settings.Add("PhoneCall6", false, "OG Loc; after House Party (Cutscene); timed");
				settings.SetToolTip("PhoneCall6", "\"This party is jumping! We got a gang of crazy ass bitches in the house!\"\nOG Loc reminds CJ about his party.\nOnly occurs between 20:00 and 06:00.");
				vars.watchScmGlobalVariables.Add(1342, "PhoneCall6");
				settings.Add("PhoneCall12", false, "Tenpenny; after Madd Dogg's Rhymes; unlocks mission");
				settings.SetToolTip("PhoneCall12", "\"Don't try and hit me up with that ghetto babble, boy!\"\nTenpenny invites CJ over for doughnuts.\nUnlocks Burning Desire.");
				vars.watchScmGlobalVariables.Add(1343, "PhoneCall12");
				settings.Add("PhoneCall18", false, "Sweet; after Cesar Vialpando & Burning Desire; unlocks mission");
				settings.SetToolTip("PhoneCall18", "\"Some punk-ass, base-head fool has been slingin' to his Grove brothers.\"\nSweet informs CJ about someone in Glen Park.\nUnlocks Doberman.");
				vars.watchScmGlobalVariables.Add(1346, "PhoneCall18");

				Func<string> func_phonecall = () => {
					for (int i = 0; i < 30; i++) {
						var badCalls = new HashSet<int>() {
							0, 1, 2, 3, 4, 5,       8,
							10,      13,14,15,16,17,
							21,22,23,24,25,26,27,28,29,
						};
						if (badCalls.Contains(i)) {
							continue;
						}
						var phonecall_taken = vars.GetWatcher("PhoneCall"+i);
						if (phonecall_taken.Changed && phonecall_taken.Current == 1) {
							return "PhoneCall"+i;
						}
					}
					return;
				};
				vars.CheckSplit.Add(func_phonecall);
			#endregion
		#endregion
		#region Other Settings
			settings.CurrentDefaultParent = null;
			settings.Add("Settings", true);
			settings.CurrentDefaultParent = "Settings";
			settings.Add("startOnSaveLoad", false, "Start timer when loading save");
			settings.Add("resetOnSaveLoad", false, "Reset timer when loading save");
			settings.Add("startOnLoadFinish", false, "Start timer when loading finishes (before cutscene)");
			settings.SetToolTip("startOnLoadFinish",
				"Start the timer when the game finishes loading, before the cutscene begins, as opposed to upon skipping it." +
				"\nUseful for runs where waiting through the cutscene for a bit can affect gameplay factors." +
				"\nWarning: Using this in combination with auto-reset is very prone to accidental resets eg. when accidentally clicking New Game instead of Load Game.");
			settings.Add("doubleSplitPrevention", false, "Double-Split Prevention");
			settings.SetToolTip("doubleSplitPrevention",
				@"Impose cooldown of 2.5s between auto-splits.");
		#endregion
	#endregion

	#region OLD_SHIT

		#region mission lists

			return;
			vars.missionChains = new Dictionary<int, Dictionary<int, string>> {
				{493, new Dictionary<int, string> { // $MISSION_BADLANDS_PASSED
					{1, "Badlands"}
				}},
				{714, new Dictionary<int, string> { // $MISSION_LOCAL_LIQUOR_STORE_PASSED
					{1, "Local Liquor Store"}
				}},
				{715, new Dictionary<int, string> { // $MISSION_SMALL_TOWN_BANK_PASSED
					{1, "Small Town Bank"}
				}},
				{716, new Dictionary<int, string> { // $MISSION_TANKER_COMMANDER_PASSED
					{1, "Tanker Commander"}
				}},
				{717, new Dictionary<int, string> { // $ALL_CATALINA_MISSIONS_PASSED (not aptly named variable)
					{1, "Against All Odds"}
				}},
				{2163, new Dictionary<int, string> {
					{1, "King in Exile"}
				}},
				{491, new Dictionary<int, string> { // $TRUTH_TOTAL_PASSED_MISSIONS
					{1, "Body Harvest"},
					{2, "Are You Going To San Fierro?"}
				}},
				{492, new Dictionary<int, string> { // $CESAR_TOTAL_PASSED_MISSIONS
					{2, "Wu Zi Mu Starting Cutscene Ended"},
					{3, "Wu Zi Mu Race Finished"},
					{4, "Wu Zi Mu Ending Cutscene Started"},
					{5, "Wu Zi Mu"},
					{7, "Farewell, My Love Starting Cutscene Ended"},
					{8, "Farewell, My Love Race Finished"},
					{9, "Farewell, My Love Ending Cutscene Started"},
					{10, "Farewell, My Love"}
				}},
				{541, new Dictionary<int, string> { // $GARAGE_TOTAL_PASSED_MISSIONS
					{1, "Wear Flowers in your Hair"},
					{2, "Deconstruction"}
				}},
				{543, new Dictionary<int, string> { // $WUZIMU_TOTAL_PASSED_MISSIONS
					{1, "Mountain Cloud Boys"},
					{2, "Ran Fa Li"},
					{3, "Lure"},
					{4, "Amphibious Assault"},
					{5, "The Da Nang Thang"}
				}},
				{545, new Dictionary<int, string> { // $SYNDICATE_TOTAL_PASSED_MISSIONS
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
				{546, new Dictionary<int, string> { // $CRASH_SF_TOTAL_PASSED_MISSIONS
					{1, "555 WE TIP"},
					{2, "Snail Trail"}
				}},
				{542, new Dictionary<int, string> { // $ZERO_TOTAL_PASSED_MISSIONS
					{1, "Air Raid"},
					{2, "Supply Lines..."},
					{3, "New Model Army"}
				}},
				{593, new Dictionary<int, string> { // $TORENO_TOTAL_PASSED_MISSIONS
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
				{544, new Dictionary<int, string> { // $STEAL_TOTAL_PASSED_MISSIONS
					{1, "Zeroing In"},
					{2, "Test Drive"},
					{3, "Customs Fast Track"},
					{4, "Puncture Wounds"}
				}},
				{597, new Dictionary<int, string> { // $CASINO_TOTAL_PASSED_MISSIONS
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
				{598, new Dictionary<int, string> {
					{1, "Misappropriation"},
					{2, "High Noon"}
				}},
				{599, new Dictionary<int, string> {
					{1, "Madd Dogg"}
				}},
				{600, new Dictionary<int, string> { // $HEIST_TOTAL_PASSED_MISSIONS
					{1, "Architectural Espionage"},
					{2, "Key to her Heart"},
					{3, "Dam and Blast"},
					{4, "Cop Wheels"},
					{5, "Up, Up and Away!"},
					{6, "Breaking the Bank at Caligula's"}
				}},
				{626, new Dictionary<int, string> { // $MANSION_TOTAL_PASSED_MISSIONS
					{1, "A Home in the Hills"},
					{2, "Vertical Bird"},
					{3, "Home Coming"},
					{4, "Cut Throat Business"}
				}},
				{627, new Dictionary<int, string> { // $GROVE_TOTAL_PASSED_MISSIONS
					{1, "Beat Down on B Dup"},
					{2, "Grove 4 Life"}
				}},
				{629, new Dictionary<int, string> { // $RIOT_TOTAL_PASSED_MISSIONS
					{1, "Riot"},
					{2, "Los Desperados"},
					{3, "End of the Line Part 1"},
					{4, "End of the Line Part 2"},
					{5, "End of the Line Part 3"} // After credits
				}},
				{8159, new Dictionary<int, string> { // $TRUCKING_TOTAL_PASSED_MISSIONS
					{1, "Trucking 1"},
					{2, "Trucking 2"},
					{3, "Trucking 3"},
					{4, "Trucking 4"},
					{5, "Trucking 5"},
					{6, "Trucking 6"},
					{7, "Trucking 7"},
					{8, "Trucking 8"}
				}},
				{8171, new Dictionary<int, string> { // $QUARRY_TOTAL_PASSED_MISSIONS
					{1, "Quarry 1"},
					{2, "Quarry 2"},
					{3, "Quarry 3"},
					{4, "Quarry 4"},
					{5, "Quarry 5"},
					{6, "Quarry 6"},
					{7, "Quarry 7"}
				}},
				{1049, new Dictionary<int, string> { // $CURRENT_WANTED_LIST (Export)
					{1, "Export List 1"},
					{2, "Export List 2"}
				}},
				{1184, new Dictionary<int, string> { // $ALL_CARS_COLLECTED_FLAG
					{1, "Export List 3"}
				}},
				// {0x779174, new Dictionary<int, string> {
				// 	{1, "Export Number 1"},
				// 	{2, "Export Number 2"},
				// 	{3, "Export Number 3"},
				// 	{4, "Export Number 4"},
				// 	{5, "Export Number 5"},
				// 	{6, "Export Number 6"},
				// 	{7, "Export Number 7"},
				// 	{8, "Export Number 8"},
				// 	{9, "Export Number 9"},
				// 	{10, "Export Number 10"},
				// 	{11, "Export Number 11"},
				// 	{12, "Export Number 12"},
				// 	{13, "Export Number 13"},
				// 	{14, "Export Number 14"},
				// 	{15, "Export Number 15"},
				// 	{16, "Export Number 16"},
				// 	{17, "Export Number 17"},
				// 	{18, "Export Number 18"},
				// 	{19, "Export Number 19"},
				// 	{20, "Export Number 20"},
				// 	{21, "Export Number 21"},
				// 	{22, "Export Number 22"},
				// 	{23, "Export Number 23"},
				// 	{24, "Export Number 24"},
				// 	{25, "Export Number 25"},
				// 	{26, "Export Number 26"},
				// 	{27, "Export Number 27"},
				// 	{28, "Export Number 28"},
				// 	{29, "Export Number 29"},
				// 	{30, "Export Number 30"},
				// }}, // TODO
				{1861, new Dictionary<int, string> { // $1861
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
				{1952, new Dictionary<int, string> { // $FLIGHT_SCHOOL_CONTESTS_PASSED (starts off at 1)
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
				{8189, new Dictionary<int, string> { // starts off at 1
					{2, "Basic Seamanship"},
					{3, "Plot a Course"},
					{4, "Fresh Slalom"},
					{5, "Flying Fish"},
					// Land, Sea and Air not included because this variable does not update upon completing it. Use the school finish var
				}},
				// Bike school and driving school share a variable and are handled differently
			};

			// Other Missions
			//===============
			// Addresses that are responsible for a single mission each.
			//
			vars.individualMissions = new Dictionary<int, string> {
				{86, "Driving School"},					// $MISSION_BACK_TO_SCHOOL_PASSED
				{87, "Pilot School"},					// $MISSION_LEARNING_TO_FLY_PASSED
				{1969, "Boat School"},					// $MISSION_BOAT_SCHOOL_PASSED
				{2201, "Bike School"},					// $MISSION_DRIVING_SCHOOL_PASSED (inaccurately named)
				{1488, "Vigilante"},
				{1491, "Taxi Driver"},					// $MISSION_TAXI_PASSED
				{1487, "Paramedic"},
				{1991, "Pimping"},						// $MISSION_PIMPING_PASSED
				{8240, "Freight Level 1"},
				{8239, "Freight Level 2"},				// goes to 2 at the end of the level
				{8153, "Los Santos Gym Moves"},
				{8154, "San Fierro Gym Moves"},
				{8158, "Las Venturas Gym Moves"},
				{2796, "NRG-500 Stunt Challenge"},
				{2795, "BMX Stunt Challenge"},
				{5272, "Shooting Range Complete"},
				{90, "Kickstart"}, 						// $MISSION_KICKSTART_PASSED
				{1941, "Blood Ring"}, 					// $MISSION_BLOODRING_PASSED
				{1900, "Valet Parking Asset Complete"},
				{1493, "Quarry Asset Complete"}, 		// $MISSION_QUARRY_PASSED
				{2300+25, "8-Track"},
				{2300+26, "Dirt Track"},
				{2331, "All Races Won"},
			};

			// Repetitive missions that demand repeated tasks over multiple levels (vehicle odd jobs)
			vars.repetitiveMissions = new Dictionary<int, Dictionary<int, string>> {
				{8211, new Dictionary<int, string> { // $PARAMEDIC_MISSION_LEVEL
					{1, "Paramedic started"},
				}},
				{8227, new Dictionary<int, string> {
					{1, "Vigilante started"},
				}},
				{180, new Dictionary<int, string> { // $TOTAL_PASSENGERS_DROPPEDOFF
					{1, "1 Taxi Fare dropped off"},
				}},
			};

			// Mission Levels
			//===============
			// These variables are not persistent
			vars.missions3 = new Dictionary<int, Dictionary<int, string>> {
				{0x779168, new Dictionary<int, string> { // Pimping level stat (ID 210)?
				}},
			};


			for (int i = 2; i < 13; i++) { vars.repetitiveMissions[8211].Add(i, "Paramedic level " + (i-1).ToString()); }
			for (int i = 2; i < 13; i++) { vars.repetitiveMissions[8227].Add(i, "Vigilante level " + (i-1).ToString()); }
			for (int i = 2; i < 50; i++) { vars.repetitiveMissions[180].Add(i, i.ToString() + " Taxi Fares dropped off"); }
			for (int i = 1; i <= 10; i++) { vars.missions3[0x779168].Add(i, "Pimping level " + i.ToString()); }

			// Misc boolean values
			//====================
			vars.missions4 = new Dictionary<int, string> {
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
			// Completion of the races themselves is done by individualMissions, but for per-checkpoint
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
				"catalin", 	// Catalina Quadrilogy Mission Select Mode
				"copcar", 	// Vigilante
				"mtbiker",	// Chilliad Challenge
				"stunt",	// BMX / NRG Challenge
				"truck",	// Trucking
				"music5",	// House Party (Parts 1 & 2)
				// "valet",	// Valet / 555 We Tip / General being near the valet building
			};

		#endregion

		#region utility

			//=============================================================================
			// Settings
			//=============================================================================
			// Settings are added manually so the order is guaranteed.

			// Setting Functions
			//==================

			// Check if the given string is the name of a mission as defined in vars.missionChains
			Func<string, bool> missionPresent = m => {
				foreach (var item in vars.missionChains)
				{
					foreach (var item2 in item.Value)
					{
						if (item2.Value == m)
						{
							return true;
						}
					}
				}
				foreach (var item in vars.individualMissions)
				{
					// foreach (var item2 in item.Value)
					// {
					// 	if (item2.Value == m)
					// 	{
					// 		return true;
					// 	}
					// }
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

				// Function to add a list of missions (including check if they are a mission)
				Action<string, List<string>> addMissionList = (parent, missions) => {
					foreach (var mission in missions) {
						if (missionPresent(mission)) {
							settings.Add(mission, true, mission, parent);
							settings.Add(mission + "AAA", true, "TEST", mission);
						}
					}
				};


			// Add missions from vars.missionChains (also add parent/header)
			//
			// header: only label
			// section: used for parent setting
			// missions: key for vars.missionChains (address)
			// defaultTrue: whether enabled by default
			Action<string, int, string, bool> addMissionsHeader = (section, missions, header, defaultTrue) => {
				var parent = section+"Missions";
				settings.Add(parent, true, header);
				foreach (var item in vars.missionChains[missions]) {
					var mission = item.Value;
					if (missionPresent(mission)) {
						settings.Add(mission, defaultTrue, mission, parent);
					}
				}
			};

			// Add missions from vars.individualMissions (to existing parent)
			//
			// missions: existing parent setting, key for vars.individualMissions
			// defaultValue: default value for all added settings
			Action<string, bool> addMissions2 = (missions, defaultValue) => {
				// var parent = missions;
				// foreach (var item in vars.individualMissions[missions]) {
				// 	var mission = item.Value;
				// 	settings.Add(mission, defaultValue, mission, parent);
				// }
			};

			Action<int, string> addMissions3 = (missions, handle) => {
				// var parent = handle;
				// foreach (var item in vars.missions3[missions]) {
				// 	var mission = item.Value;
				// 	settings.Add(mission, false, mission, parent);
				// }
			};

			Action<int, string, string> addMissions3Header = (missions, handle, header) => {
				settings.Add(handle, true, header);
				addMissions3(missions, handle);
			};

				// Add a single mission (checking if it's a mission)
				Action<string, bool, string> addMissionSetting = (mission, defaultValue, label) => {
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

		return;

		// Los Santos
		//-----------
		//-----------
		//-----------

		addMissionList("LS_Final", new List<string>() { "Reuniting the Families"});


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
		addMissionSetting("Los Sepulcros", true, "Mission Passed");

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
		addMissionSetting("The Green Sabre", true, "Mission Passed");

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
		addMissionSetting("Are You Going To San Fierro?", true, "Mission Passed");

		// Badlands
		settings.Add("bl", true, "Badlands", "BL_Intro");
		settings.CurrentDefaultParent = "bl";
		settings.Add("Badlands Started", false, "Mission Started");
		settings.Add("Badlands: Mountain Base", false, "Hit Marker at Mountain Base");
		settings.Add("Badlands: Cabin Reached", false, "Cabin Arrival Cutscene Start");
		settings.Add("Badlands: Cabin Cutscene", false, "Cabin Arrival Cutscene End");
		settings.Add("Badlands: Reporter Dead", false, "Reporter Killed");
		settings.Add("Badlands: Photo Taken", false, "Photo Taken");
		addMissionSetting("Badlands", true, "Mission Passed");

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
		addMissionSetting("Against All Odds", true, "Mission Passed");

		// King in Exile
		settings.Add("kie", true, "King in Exile", "BL_Intro");
		settings.CurrentDefaultParent = "kie";
		settings.Add("King in Exile Started", false, "Mission Started");
		addMissionSetting("King in Exile", true, "Mission Passed");

		// Wu Zi Mu
		settings.Add("wzm", true, "Wu Zi Mu", "BL_Cesar");
		settings.CurrentDefaultParent = "wzm";
		settings.Add("Wu Zi Mu Started", false, "Mission Started");
		addMissionSetting("Wu Zi Mu Starting Cutscene Ended", false, "Starting Cutscene Ended");
		addMissionSetting("Wu Zi Mu Race Finished", false, "Race Finished");
		addMissionSetting("Wu Zi Mu Ending Cutscene Started", false, "Ending Cutscene Started");
		addMissionSetting("Wu Zi Mu", true, "Mission Passed");

		// Farewell, My Love
		settings.Add("fml", true, "Farewell, My Love", "BL_Cesar");
		settings.CurrentDefaultParent = "fml";
		settings.Add("Farewell, My Love Started", false, "Mission Started");
		addMissionSetting("Farewell, My Love Starting Cutscene Ended", false, "Starting Cutscene Ended");
		addMissionSetting("Farewell, My Love Race Finished", false, "Race Finished");
		addMissionSetting("Farewell, My Love Ending Cutscene Started", false, "Ending Cutscene Started");
		addMissionSetting("Farewell, My Love", true, "Mission Passed");

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
		addMissionList("Des_Toreno", new List<string>() {
			"Monster", "Highjack", "Interdiction", "Verdant Meadows", "Learning to Fly"
		});
		addMissionList("Des_WangCars", new List<string>() {
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
		addMissionSetting("End of the Line Part 1", true, "End of the Line Part 1 (after killing Big Smoke)");
		addMissionSetting("End of the Line Part 2", true, "End of the Line Part 2 (start of chase)");

		// Cut Throat Business
		//--------------------
		settings.Add("ctb", true, "Cut Throat Business", "RTLS_Mansion");
		settings.CurrentDefaultParent = "ctb";
		settings.Add("Cut Throat Business Started", false, "Mission Started");
		settings.Add("ctb_checkpoint1", false, "Arriving at the video shoot");
		settings.Add("ctb_checkpoint2", false, "Arriving at the pier");
		addMissionSetting("Cut Throat Business", true, "Mission Passed");

		// Grove 4 Life
		//-------------
		settings.Add("g4l", true, "Grove 4 Life", "RTLS_Grove");
		settings.CurrentDefaultParent = "g4l";
		settings.Add("Grove 4 Life Started", false, "Mission Started");
		settings.Add("g4l_drivetoidlewood", false, "Arriving in Idlewood");
		settings.Add("g4l_territory1", false, "First territory captured");
		settings.Add("g4l_territory2", false, "Second territory captured");
		addMissionSetting("Grove 4 Life", true, "Mission Passed");

		// End of the Line Part 3
		//-----------------------
		settings.Add("eotlp3", true, "End of the Line Part 3", "RTLS_Riot");
		settings.CurrentDefaultParent = "eotlp3";
		settings.Add("eotlp3_chase1", false, "Start of cutscene after catching Sweet");
		settings.Add("eotlp3_chase2", false, "Start of cutscene near Cluckin' Bell");
		settings.Add("eotlp3_chase3", true, "End of any%: Start of firetruck bridge cutscene");
		addMissionSetting("End of the Line Part 3", true, "After credits");

		settings.CurrentDefaultParent = null;

		#endregion

		#region Side Missions

			// Side Missions
			//==============
			settings.Add("Missions2", true, "Side Missions");
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
				addMissionSetting("Trucking "+i, true, "Trucking "+i+" Completed");
			}
			settings.CurrentDefaultParent = "Missions2";

			// Quarry
			//-------
			settings.Add("Quarry Missions", true, "Quarry");
			addMissionList("Quarry Missions", new List<string>() { "Quarry 1", "Quarry 2", "Quarry 3", "Quarry 4", "Quarry 5", "Quarry 6", "Quarry 7" });
			settings.CurrentDefaultParent = "Quarry Missions";
			addMissionSetting("Quarry", false, "Quarry Asset Completed");

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
			addMissionSetting("Valet Parking", true, "Mission Passed");
			settings.CurrentDefaultParent = "Missions2";

			// Vehicle submissions
			//--------------------
			settings.Add("VehicleSubmissions", true, "Vehicle Submissions");
			settings.CurrentDefaultParent = "VehicleSubmissions";

			settings.CurrentDefaultParent = "VehicleSubmissions";

			// settings.Add("Freight Level", true, "Freight");
			// settings.CurrentDefaultParent = "Freight Level";
			// settings.Add("Freight Started", false, "Freight started for the first time", "Freight Level");
			// settings.Add("Freight Station 1 1", false, "Freight Level 1 Stop 1");
			// settings.Add("Freight Station 1 2", false, "Freight Level 1 Stop 2");
			// settings.Add("Freight Station 1 3", false, "Freight Level 1 Stop 3");
			// settings.Add("Freight Station 1 4", false, "Freight Level 1 Stop 4");
			// addMissionSetting("Freight Level 1", false, "Freight Level 1 Stop 5 (Level 1 Completion)");
			// settings.Add("Freight Station 2 1", false, "Freight Level 2 Stop 1");
			// settings.Add("Freight Station 2 2", false, "Freight Level 2 Stop 2");
			// settings.Add("Freight Station 2 3", false, "Freight Level 2 Stop 3");
			// settings.Add("Freight Station 2 4", false, "Freight Level 2 Stop 4");
			// addMissionSetting("Freight Level 2", true, "Freight Level 2 Stop 5 (Level 2 Completion)");
			// settings.SetToolTip("Freight Station 1 1", "Split when reaching the first stop on the first level. In common 100% routes, this would be Linden Station.");
			// settings.SetToolTip("Freight Station 1 2", "Split when reaching the second stop on the first level. In common 100% routes, this would be Yellow Bell Station.");
			// settings.SetToolTip("Freight Station 1 3", "Split when reaching the third stop on the first level. In common 100% routes, this would be Cranberry Station.");
			// settings.SetToolTip("Freight Station 1 4", "Split when reaching the fourth stop on the first level. In common 100% routes, this would be Market Station.");
			// settings.SetToolTip("Freight Level 1", "Split when reaching the fifth stop on the first level, completing the level. In common 100% routes, this would be Market Station.");
			// settings.SetToolTip("Freight Station 2 1", "Split when reaching the first stop on the first level. In common 100% routes, this would be Linden Station.");
			// settings.SetToolTip("Freight Station 2 2", "Split when reaching the second stop on the first level. In common 100% routes, this would be Yellow Bell Station.");
			// settings.SetToolTip("Freight Station 2 3", "Split when reaching the third stop on the first level. In common 100% routes, this would be Cranberry Station.");
			// settings.SetToolTip("Freight Station 2 4", "Split when reaching the fourth stop on the first level. In common 100% routes, this would be Market Station.");
			// settings.SetToolTip("Freight Level 2", "Split when reaching the fifth stop on the second level, completing the level and submission. In common 100% routes, this would be Market Station.");
			// settings.CurrentDefaultParent = "VehicleSubmissions";

			// addMissions3Header(6592864 + (8211 * 4), "paramedic_level", "Paramedic");
			// settings.CurrentDefaultParent = "paramedic_level";
			// addMissionSetting("Paramedic", true, "Paramedic level 12 (Completion)");
			// settings.CurrentDefaultParent = "VehicleSubmissions";

			// settings.Add("pimping_level", true, "Pimping");
			// settings.CurrentDefaultParent = "pimping_level";
			// addMission4Custom("pimping_started", false, "Pimping started for the first time", "pimping_level");
			// addMissions3(0x779168, "pimping_level");
			// addMissionSetting("Pimping", true, "Pimping Complete");
			// settings.CurrentDefaultParent = "VehicleSubmissions";

			// addMissions3Header(6592864 + (180 * 4), "taxi_fares", "Taxi Driver");
			// settings.CurrentDefaultParent = "taxi_fares";
			// addMissionSetting("Taxi Driver", true, "50 Taxi Fares dropped off (Completion)");
			// settings.CurrentDefaultParent = "VehicleSubmissions";

			// settings.Add("vigilante_level", true, "Vigilante");
			// settings.CurrentDefaultParent = "vigilante_level";
			// settings.Add("Vigilante Started", false);
			// settings.Add("Vigilante Started after Learning to Fly", false);
			// addMissions3(6592864 + (8227 * 4), "vigilante_level");
			// addMissionSetting("Vigilante", true, "Vigilante level 12 (Completion)");
			// settings.CurrentDefaultParent = "VehicleSubmissions";

			// Races
			//------
			// settings.Add("Races", true, "Races", "Missions2");
			// settings.CurrentDefaultParent = "Races";
			// settings.Add("All Races Won", false);
			// settings.Add("LS Races", true, "Los Santos");
			// settings.Add("SF Races", true, "San Fierro");
			// settings.Add("LV Races", true, "Las Venturas");
			// settings.Add("Air Races", true, "Air Races");
			// for (int i = 0; i < vars.individualMissions["Streetraces"].Count; i++) {
				// var raceName = vars.individualMissions["Streetraces"][0x64BD50 + i*4];
				// var parent = "LS Races";
				// if (i >= 19) { parent = "Air Races"; }
				// else if (i >= 15) { parent = "LV Races"; }
				// else if (i >= 9) { parent = "SF Races"; }
				// var defaultSplit = i != 0 && i != 7 && i != 8;
				// var raceId = "Race "+i;
				// var cpCount = vars.streetrace_checkpointcounts[raceName] - 1;
				// settings.Add(raceId, defaultSplit, raceName, parent);
				// settings.CurrentDefaultParent = raceId;
				// settings.Add(raceId+" Checkpoint 0", false, "Race start (Countdown end)");
				// for (int cp = 1; cp < cpCount; cp++) {
				// 	var cpName = raceId+" Checkpoint "+cp;
				// 	settings.Add(cpName, false, "Checkpoint "+cp);
				// }
				// settings.Add(raceId+" Checkpoint "+cpCount, false, "Checkpoint "+cpCount+" (Final)");
				// settings.SetToolTip(raceId+" Checkpoint "+cpCount, "Split when hitting the final checkpoint. Causes a double split when combined with 'Race Won' setting, but unlike that this will still trigger even if the race has been passed before");
				// addMissionSetting(raceName, defaultSplit, "Race won");
			// }
			// settings.CurrentDefaultParent = null;

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
			addMissionSetting("8-Track", true, "Race won");

			settings.Add("Blood Ring (Header)", true, "Blood Ring", "Stadium Events");
			settings.CurrentDefaultParent = "Blood Ring (Header)";
			settings.Add("Blood Ring Started", false, "Blood Ring Started");
			addMissionSetting("Blood Ring", true, "Blood Ring Passed");
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
			addMissionSetting("Dirt Track", true, "Race won");

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
			addMissionSetting("Kickstart", true, "Kickstart Complete");

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
			addMissionSetting("BMX Stunt Challenge", true, "BMX Stunt Challenge Complete");

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
			addMissionSetting("NRG-500 Stunt Challenge", true, "NRG-500 Stunt Challenge Complete");

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
			addMissionSetting("Driving School", true, "City Slicking (Driving School Passed)");

			settings.CurrentDefaultParent = "flightschool_level";
			settings.Add("Pilot School Started", false, "Pilot School started for the first time");
			addMissions3(6592864 + (1952 * 4), "flightschool_level");
			addMissionSetting("Pilot School", true, "Parachute Onto Target (Pilot School Passed)");

			settings.CurrentDefaultParent = "bikeschool_level";
			settings.Add("Bike School Started", false, "Bike School started for the first time");
			settings.Add("The 360 (Bike School)", false, "The 360");
			settings.Add("The 180 (Bike School)", false, "The 180");
			settings.Add("The Wheelie", false);
			settings.Add("Jump & Stop", false);
			settings.Add("The Stoppie", false);
			addMissionSetting("Bike School", true, "Jump & Stoppie (Bike School Passed)");

			settings.CurrentDefaultParent = "boatschool_level";
			settings.Add("Boat School Started", false, "Boat School started for the first time");
			addMissions3(6592864 + (8189 * 4), "boatschool_level");
			addMissionSetting("Boat School", true, "Land, Sea and Air (Boat School Passed)");
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
				addMissionSetting(listComplete, true, listComplete+" Complete");
			}
			settings.Add("Exported Number", false, "Exported Vehicle Count", "Export Lists");
			settings.CurrentDefaultParent = "Exported Number";
			addMissionSetting("Export Number 1", false, "Exported 1 Vehicle");
			for (int i = 2; i <= 30; i++) {
				addMissionSetting("Export Number "+i, i==30, "Exported "+i+" Vehicles");
			}
			settings.CurrentDefaultParent = "Missions2";

			// Ammunation Challenge
			//---------------------
			settings.CurrentDefaultParent = "Missions2";
			// addMissionsHeader("Shooting Range", 6592864 + (1861 * 4), "Shooting Range", false);
			settings.CurrentDefaultParent = "Shooting Range";
			// addMissionSetting("Shooting Range Complete", true, "Shooting Range Complete");

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

	#endregion
}

init {
	vars.baseModule = modules.First();
	vars.game = game;

	#region Version Detection
		//=============================================================================
		// Version Detection
		//=============================================================================
		vars.enabled = true;

		var versionValue = 38079;
		int versionOffset = 0;

		int playingTimeAddr = 	0x77CB84;
		int threadAddr =		0x68B42C;
		int missionTextAddr =	0x7AAD40;
		int loadingAddr =		0x7A67A5;
		int playerPedAddr =		0x77CD98;

		var scmGlobVarOffset = 			0x649960;
		var scmMissionLocalVarOffset = 	0x648960;

		// Detect Version
		//===============
		// Look for both the value in the memory or the module size to determine the
		// version.
		//
		// Checking the memory value doesn't seem to work if the
		// game is still checking the CD.
		//
		// The memory values and associated versions/offsets where taken from the
		// AHK Autosplitter and checked and extended as possible.

		int moduleSize = modules.First().ModuleMemorySize;
		if (current.version_100_EU == versionValue
			|| current.version_100_US == versionValue
			|| moduleSize == 18313216) {
			versionOffset = 0;
			version = "1.0";
		}
		else if (current.version_101_EU == versionValue
			|| current.version_101_US == versionValue
			|| moduleSize == 34471936) {
			versionOffset = 0x2680;
			version = "1.01";
		}
		else if (moduleSize == 17985536) {
			// This may be some kind of Austrian version
			versionOffset = 0x2680;
			version = "2.00";
		}
		else if (current.version_300_Steam == versionValue
			|| moduleSize == 9691136) {
			// Older Steam version, still showing 3.00 in the menu and may work with
			// just the offset (since 1.01 works like that and they seem similiar)
			versionOffset = 0x75130;
			version = "3.00 Steam";
		}
		else if (current.version_101_Steam == versionValue) {
			// Otherwise unknown version
			versionOffset = 0x75770;
			version = "1.01 Steam";
		}
		else if (moduleSize == 9981952) {
			// More recent Steam Version (no version in menu), this is referred to
			// as just "Steam"
			// This version is no longer supported
			versionOffset = 0x77970;
			version = "Steam";
			playingTimeAddr = 0x80FD74;
			threadAddr =	0x702D98;
			missionTextAddr = 0x7AAD40; // Not correct, didn't look it up
			loadingAddr =	0x833995;
			playerPedAddr =	0x8100D0;
		}

		// Version detected
		//=================

		if (version == "") {
			version = "<unknown>";
			vars.enabled = false;
		}
		else if (version == "Steam") {
			version = "Steam (Unsupported)";
			vars.enabled = false;
		}

		// Extra variable because versionOffset was different from offset before (keep it
		// like this just in case)
		int offset = versionOffset;

		// Apply offset
		playingTimeAddr += offset;
		threadAddr += offset;
		missionTextAddr += offset;
		loadingAddr += offset;
		playerPedAddr += offset;
		scmGlobVarOffset += offset;
		scmMissionLocalVarOffset += offset;
	#endregion

	//=============================================================================
	// Memory Watcher
	//=============================================================================
	var baseModule = modules.First();

	// Scan for an unknown address
	Func<string, int> ScanForAddress = targetStr => {
		var scanner = new SignatureScanner(game, baseModule.BaseAddress, baseModule.ModuleMemorySize);
		var target = new SigScanTarget(targetStr);
		int address = (int)scanner.Scan(target);
		return address -= (int)baseModule.BaseAddress;
	};
	vars.ScanForAddress = ScanForAddress;

	// Change watchers if an address is marked as changed
	Action ChangeAddressWatchers = () => {
		foreach (var tuple in vars.nonScmAddressesChanges) {

			string tupleName = tuple.Item1;
			int tupleType = tuple.Item2;
			int tupleAddress = tuple.Item3;
			//vars.DebugOutput("Changing Watcher (chng): " + tupleName + " 0x" + tupleAddress.ToString());

			vars.watcherList.Remove(vars.GetWatcher(tupleName));
			switch (tupleType) {
				case 1:
					vars.watcherList.Add(
						new MemoryWatcher<byte>(
							new DeepPointer(tupleAddress+offset)
						) { Name = tupleName }
					);
					break;
				case 2:
					vars.watcherList.Add(
						new MemoryWatcher<short>(
							new DeepPointer(tupleAddress+offset)
						) { Name = tupleName }
					);
					break;
				case 4:
				default:
					vars.watcherList.Add(
						new MemoryWatcher<int>(
							new DeepPointer(tupleAddress+offset)
						) { Name = tupleName }
					);
					break;
			}
		}
		vars.nonScmAddressesChanges.Clear();
	};
	vars.ChangeAddressWatchers = ChangeAddressWatchers;

	// Create MemoryWatcherList
	vars.watcherList = new MemoryWatcherList();
	vars.currentWatchers = new HashSet<string>();
	vars.DebugOutput("Watcher List Cleared");

	// Add some very basic addresses
	vars.watchScmGlobalVariables.Add(43, "interior");			// $ACTIVE_INTERIOR
	vars.watchScmGlobalVariables.Add(24, "intro_passed");		// $MISSION_INTRO_PASSED

	vars.AddNonScmAddressWatcher(playingTimeAddr, "playingTime", 4);
	vars.DebugOutput("Adding String Pointer Watcher (strn): thread");
	vars.watcherList.Add(new StringWatcher(new DeepPointer(threadAddr, 0x8), 10) { Name = "thread" });
	vars.watcherList.Add(new StringWatcher(new DeepPointer(missionTextAddr), 16) { Name = "missionStartText" });

	// Add other non-SCM addresses (eg stats entries) as added in startup()
	foreach (var tuple in vars.nonScmAddresses) {
		string tupleName = tuple.Item1;
		int tupleType = tuple.Item2;
		int tupleAddress = tuple.Item3;
		vars.DebugOutput("Adding Watcher (misc): " + tupleName + " 0x" + tupleAddress.ToString("x"));

		switch (tupleType) {
			case 1:
				vars.watcherList.Add(
					new MemoryWatcher<byte>(
						new DeepPointer(tupleAddress+offset)
					) { Name = tupleName }
				);
				break;
			case 2:
				vars.watcherList.Add(
					new MemoryWatcher<short>(
						new DeepPointer(tupleAddress+offset)
					) { Name = tupleName }
				);
				break;
			case 4:
			default:
				vars.watcherList.Add(
					new MemoryWatcher<int>(
						new DeepPointer(tupleAddress+offset)
					) { Name = tupleName }
				);
				break;
		}
	}
	// Add pointers as added in startup()
	foreach (var tuple in vars.pointerList) {
		string tupleName = tuple.Item1;
		int tupleType = tuple.Item2;
		DeepPointer tuplePointer = tuple.Item3;
		vars.DebugOutput("Adding Pointer Watcher (pntr): " + tupleName);

		switch (tupleType) {
			case 1:
				vars.watcherList.Add(
					new MemoryWatcher<byte>(tuplePointer) { Name = tupleName }
				);
				break;
			case 2:
				vars.watcherList.Add(
					new MemoryWatcher<short>(tuplePointer) { Name = tupleName }
				);
				break;
			case 4:
			default:
				vars.watcherList.Add(
					new MemoryWatcher<int>(tuplePointer) { Name = tupleName }
				);
				break;
		}
	}
	// Add all the SCM global var watchers ($xxxx)
	// Formula: 0x649960 + v * 0x4
	// as added in startup()
	foreach (var item in vars.watchScmGlobalVariables) {
		var address = item.Key*4+scmGlobVarOffset+offset;
		vars.DebugOutput("Adding watcher (scmG): 0x" + address.ToString("x") + " $" + item.Key.ToString() + " " + item.Value);
		vars.watcherList.Add(
			new MemoryWatcher<int>(
				new DeepPointer(address)
			) { Name = item.Value.ToString() }
		);
	}
	// Add all the SCM mission local var watchers (xx@)
	// All mission local variables are actually global. Located at
	// Formula: 0xA48960 + v * 0x4
	// as added in startup()
	foreach (var item in vars.watchScmMissionLocalVariables) {
		var address = item*4+scmMissionLocalVarOffset+offset;
		vars.DebugOutput("Adding watcher (scmL): 0x" + address.ToString("x") + " ScmLocal @" + item);
		vars.watcherList.Add(
			new MemoryWatcher<int>(
				new DeepPointer(address)
			) { Name = item.ToString() + "@" }
		);
	}

	//=============================================================================
	// Utility functions
	//=============================================================================

	// Check if splitting should occur based on whether
	// * The split has already been split before (eg. before loading a save)
	// * The split is disabled in settings
	// * Double split prevention cooldown is active
	//
	// Also stores the split to the list of already split splits. If a split
	// should occur, it is added to a queue, so splits that happen simultaneously
	// both get split subsequently. This is kind of the opposite of double split
	// prevention, rather it ensures multiple splits where applicable.
	Func<string, bool> TrySplit = (splitId) => {
		if (vars.completedSplits.Contains(splitId)) {
			vars.DebugOutput("Split Prevented (Already Done): "+splitId);
			return false;
		}
		// Add split to already split splits list so they won't get split again, even if the split
		// is blocked by a cooldown or disabled setting.
		vars.completedSplits.Add(splitId);

		if (!settings[splitId]) {
			vars.DebugOutput("Split Prevented (Disabled in Settings): "+splitId);
			return false;
		}
		// 2500 = magic number. It was chosen as it was large enough to prevent double splitting on
		// dupes, but small enough to allow short splits like a deathwarp after certain missions to
		// go through. However, dupes are handled differently now, so this functionality is mostly
		// obsolete. The option remains should the user wish to use it though. This will prevent
		// short subsequent or simultaneous splits like splitting on mission start as well as on
		// entering its starting marker.
		if (settings["doubleSplitPrevention"] && Environment.TickCount - vars.lastSplit > 2500) {
			vars.DebugOutput("Split Prevented (Cooldown): "+splitId);
			return false;
		}
		// Add split to a queue, so splits that happen simultaneously both get split subsequently.
		// This is kind of the opposite of double split prevention, rather it ensures multiple splits
		// where applicable.
		vars.DebugOutput("Split: "+splitId);
		vars.lastSplit = Environment.TickCount;
		vars.splitQueue.Enqueue(splitId);
		return true;
	};
	vars.TrySplit = TrySplit;

	// Function that's done when checking subsplits for each mission
	// Checks if the mission is or was recently active
	// Then checks if the mission has been passed, and splits if so
	// If the mission is both active and not passed, returns true
	// Also checks if the mission is enabled in the settings to begin with
	Func<string, string, int, int, string, string, bool> ValidateMissionProgress = (thread, chain, currentIndex, passIndex, split, setting) => {
		if (!settings[setting]) {
			return false;
		}
		if (vars.lastStartedMission != thread) {
			return false;
		}
		var mission_chain = vars.GetWatcher(chain);
		if (mission_chain.Current >= passIndex) {
			if (mission_chain.Changed && mission_chain.Old == currentIndex) {
				vars.TrySplit(split);
				return false;
			}
			return false;
		}
		return true;
	};
	vars.ValidateMissionProgress = ValidateMissionProgress;

	// Check if a setting is enabled. Have to do it like this because checking directly in the 
	// startup Funcs throws an error
	Func<string, bool> CheckSetting = (name) => {
		return settings[name];
	};
	vars.CheckSetting = CheckSetting;

	return;




















	// old shit V VV









	// Add global variables for mid-mission events
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (802 * 4)+offset)) { Name = "100%_achieved" }); // $_100_PERCENT_COMPLETE
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (7011 * 4)+offset)) { Name = "aygtsf_plantsremaining" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (2208 * 4)+offset)) { Name = "bl_cabinreached" });	// Trip Skip enabled
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (6965 * 4)+offset)) { Name = "bl_stage" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (64 * 4)+offset)) { Name = "catalina_count" }); // CATALINA_TOTAL_PASSED_MISSIONS
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (1799 * 4)+offset)) { Name = "chilliad_race" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (1801 * 4)+offset)) { Name = "chilliad_done" }); // $MISSION_CHILIAD_CHALLENGE_PASSED
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (8014 * 4)+offset)) { Name = "eotlp3_chase" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (359 * 4)+offset)) { Name = "gf_denise_progress" }); // $GIRL_PROGRESS[0]
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (360 * 4)+offset)) { Name = "gf_michelle_progress" }); // $GIRL_PROGRESS[1]
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (361 * 4)+offset)) { Name = "gf_helena_progress" }); // $GIRL_PROGRESS[2]
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (362 * 4)+offset)) { Name = "gf_barbara_progress" }); // $GIRL_PROGRESS[3]
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (363 * 4)+offset)) { Name = "gf_katie_progress" }); // $GIRL_PROGRESS[4]
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (364 * 4)+offset)) { Name = "gf_millie_progress" }); // $GIRL_PROGRESS[5]
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (406 * 4)+offset)) { Name = "gf_unlocked" }); // $GIRLS_GIFTS_BITMASK
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (8250 * 4)+offset)) { Name = "kickstart_checkpoints" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (8262 * 4)+offset)) { Name = "kickstart_points" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (10933 * 4)+offset)) { Name = "valet_carstopark" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (1848 * 4)+offset)) { Name = "valet_carsparked" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (247 * 4)+offset)) { Name = "schools_currentexercise" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (726 * 4)+offset)) { Name = "stunt_type" }); // $STUNT_MISSION_TYPE
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (8267 * 4)+offset)) { Name = "stunt_timer" });
	// vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (1883 * 4)+offset)) { Name = "valet_started" }); // Gets set during 555 we tip, could be useful to track its progress

	// Local variables. These are used across multiple missions and it's hard to tell which without just testing it
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x55EE68+offset)) { Name = "ctb_checkpoint1" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x57F10C+offset)) { Name = "ctb_checkpoint2" });

	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648A00+offset)) { Name = "r_dialogueBlock" }); // 40@
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648A10+offset)) { Name = "gym_fighting" }); // 44@
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648A38+offset)) { Name = "g4l_territory2" }); // 54@
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648A40+offset)) { Name = "g4l_drivetoidlewood" }); // 56@
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648A48+offset)) { Name = "g4l_territory1" }); // 58@
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648A4C+offset)) { Name = "stunt_checkpoint" }); //59@
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648ABC+offset)) { Name = "aygtsf_progress" }); //87@
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648AC8+offset)) { Name = "aao_finalmarker" }); //90@
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648AE8+offset)) { Name = "aao_storeleft" }); //98@
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648AF0+offset)) { Name = "tgs_chapter" }); //100@
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648B08+offset)) { Name = "trucking_leftcompound" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648B10+offset)) { Name = "aao_angryshouts" }); //108@
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648B68+offset)) { Name = "freight_stations" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648BBC+offset)) { Name = "aygtsf_dialogue" }); //151@
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648D74+offset)) { Name = "lossep_homiesrecruited" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x648DD8+offset)) { Name = "lossep_cardoorsunlocked" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x6491B8+offset)) { Name = "lossep_dialogue" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x64950C+offset)) { Name = "chilliad_checkpoints3" });
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x649518+offset)) { Name = "chilliad_checkpoints" });

	// Things
    vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x7791D0+offset)) { Name = "gang_territories" });

	// Values not mission specific
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x7AA420+offset)) { Name = "wanted_level" });

	// Values not mission specific, global from SCM ($xxxx)
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(6592864 + (43 * 4)+offset)) { Name = "interior" });

	// This means loading from a save and such, not load screens
	vars.watcherList.Add(new MemoryWatcher<bool>(new DeepPointer(loadingAddr)) { Name = "loading" });

	// Other values
	vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(playerPedAddr, 0x530)) { Name = "pedStatus" });

	// Export Lists
	//=============

	// vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(0x64A9C4+offset)) { Name = "exportList" });
	var exportBaseAddr = 0x64A9F0+offset;
	for (int i = 0; i < 10; i++)
	{
		var address = exportBaseAddr + i*4;
		//print(address.ToString("X"));
		vars.watcherList.Add(new MemoryWatcher<int>(new DeepPointer(address)) { Name = "export"+i });
	}


}

update {
	//=============================================================================
	// General Housekeeping
	//=============================================================================
	// Disable all timer control actions if version was not detected
	if (!vars.enabled) {
		return false;
	}

	// Change watchers if an address is marked as changed
	// Typically for collectibles which are in different places in memory
	vars.ChangeAddressWatchers();

	// Update always, to prevent splitting after loading (if possible, doesn't seem to be 100% reliable)
	// The number of watchers has increased too much this is no longer efficient.
	// vars.watcherList.UpdateAll(game);
	vars.currentWatchers.Clear();
}

onReset {
	// Clear list of already executed splits if timer is reset
	vars.completedSplits.Clear();
	vars.splitQueue.Clear();
	vars.lastStartedMission = "";
	vars.skipSplits = false;
	vars.DebugOutput("Cleared list of already executed splits");
}

split {
	#region Split prevention
		//=============================================================================
		// Split prevention
		//=============================================================================
		var playingTime = vars.GetWatcher("playingTime");
		var intro_newGameStarted = vars.GetWatcher("intro_newGameStarted");
		var intro_passed = vars.GetWatcher("intro_passed");

		// if (vars.GetWatcher("loading"].Current) {
		// 	vars.DebugOutput("Loading");
		// 	vars.lastLoad = Environment.TickCount;
		// 	return false;
		// }
		if (intro_newGameStarted.Current == 0 && intro_passed.Current == 0) {
			// Prevent splitting while in the main menu
			if (!vars.waiting) {
				vars.DebugOutput("Wait..");
				vars.waiting = true;
			}
			return false;
		}
		if (Environment.TickCount - vars.lastLoad < 600 || playingTime.Current < 600) {
			// Prevent splitting shortly after loading from a save, since this can
			// sometimes occur because memory values change
			if (!vars.waiting) {
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
	// move this down. If applicable, also splits for the thread being started.
	var thread = vars.GetWatcher("thread");
	if (thread.Changed) {
		if (vars.lastStartedMission != thread.Current) {
			if (vars.significantThreads.ContainsKey(thread.Current)) {
				var split = vars.significantThreads[thread.Current];
				if (!string.IsNullOrEmpty(split)) {
					vars.TrySplit(split);
				}
				vars.lastStartedMission = thread.Current;
			}
		}
	}

	// Marker entry
	// ============
	// This checks whether the yellow string shown in the bottom right matches a mission name
	var missionStartText = vars.GetWatcher("missionStartText");
	if (missionStartText.Changed) {
		var mst = missionStartText.Current;
		if (!string.IsNullOrEmpty(mst) && vars.missionNames.ContainsKey(mst)) {
			var split = vars.missionNames[mst];
			if (!string.IsNullOrEmpty(split)) {
				vars.TrySplit(split);
			}
		}
	}

	// Check main bulk of split conditions
	foreach (Func<string> f in vars.CheckSplit) {
		var split = f();
		if (!string.IsNullOrEmpty(split)) {
			vars.TrySplit(split);
		}
	}

	// Split a split if one is enqueued
	if (vars.splitQueue.Count > 0) {
		vars.splitQueue.Dequeue();
		if (vars.skipSplits) {
			vars.DebugOutput("Skipping split");
			vars.timerModel.SkipSplit();
		}
		else {
			return true;
		}
	}

	return false;




















	#region Splits OLDDDDD
		//=============================================================================
		// Splits
		//=============================================================================

		var interior = vars.GetWatcher("interior");
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
			var aao_angryshouts = vars.GetWatcher("aao_angryshouts");
			var aao_storeleft = vars.GetWatcher("aao_storeleft");
			var aao_finalmarker = vars.GetWatcher("aao_finalmarker");
			var aao_wantedlevel = vars.GetWatcher("wanted_level");
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
			var aygtsf_plantsremaining = vars.GetWatcher("aygtsf_plantsremaining");
			if (aygtsf_plantsremaining.Current != aygtsf_plantsremaining.Old && aygtsf_plantsremaining.Current != 44) {
				for (int i = aygtsf_plantsremaining.Old; i > aygtsf_plantsremaining.Current; i--) {
					var aygtsf_plants = 45 - i;
					vars.TrySplit("AYGTSF: " + aygtsf_plants + " Plants Destroyed");
				}
			}
			var aygtsf_dialogue = vars.GetWatcher("aygtsf_dialogue");
			if (aygtsf_dialogue.Current == 8 && aygtsf_dialogue.Old != 8) {
				vars.TrySplit("AYGTSF: Rocket Launcher");
			}
			var aygtsf_progress = vars.GetWatcher("aygtsf_progress");
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
			var badlands_progress = vars.GetWatcher("bl_stage");
			var badlands_tripskip = vars.GetWatcher("bl_cabinreached");
			if (badlands_tripskip.Current == 1 && badlands_tripskip.Old == 0) {
				vars.TrySplit("Badlands: Cabin Reached");
			}
			if (badlands_progress.Current == 0 && badlands_progress.Old == -1) { vars.TrySplit("Badlands: Mountain Base"); }
			if (badlands_progress.Current == 1 && badlands_progress.Old == 0) { vars.TrySplit("Badlands: Cabin Cutscene"); }
			if (badlands_progress.Current == 7 && badlands_progress.Old <= 6) { vars.TrySplit("Badlands: Reporter Dead"); }
			if (badlands_progress.Current == 8 && badlands_progress.Old == 7) { vars.TrySplit("Badlands: Photo Taken"); }
		}
	#endregion
	#region Catalina Quadrilogy
		if (thread.Changed && thread.Current == "catalin") {
			var catalina_count = vars.GetWatcher("catalina_count");
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
		var chilliad_race = vars.GetWatcher("chilliad_race");
		if (thread.Changed && thread.Current == "mtbiker") {
			vars.TrySplit("Chilliad Challenge #"+chilliad_race.Current+" Started");
		}
		var chilliad_checkpoints = vars.GetWatcher("chilliad_checkpoints");
		var chilliad_checkpoints3 = vars.GetWatcher("chilliad_checkpoints3");
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
		var courier_active = vars.GetWatcher("courier_active");
		var courier_city = vars.GetWatcher("courier_city");
		if (courier_city.Current != courier_city.Old) {
			if (courier_city.Current != 0 && courier_active.Current == 1) {
				vars.TrySplit("courier_"+courier_city.Current+"_started");
			}
		}
		if (courier_active.Current == 1) {
			string courier_cityname = "ls";
			if (courier_city.Current == 2) courier_cityname = "sf";
			if (courier_city.Current == 3) courier_cityname = "lv";

			var courier_levels = vars.GetWatcher("courier"+courier_cityname+"_levels");
			if (courier_levels.Current > courier_levels.Old) {
				vars.TrySplit("courier_" + courier_city.Current + "_level_" + (courier_levels.Current));
			}
			var courier_checkpoints = vars.GetWatcher("courier_checkpoints");
			if (courier_checkpoints.Current > courier_checkpoints.Old) {
				vars.TrySplit("courier_" + courier_city.Current + "_level_" + (courier_levels.Current+1) + "_delivery_" + courier_checkpoints.Current);
			}
		}
	#endregion
	#region Cut Throat Business
		//=========================
		var ctb_checkpoint1 = vars.GetWatcher("ctb_checkpoint1");
		if (ctb_checkpoint1.Current > ctb_checkpoint1.Old && ctb_checkpoint1.Old == 0) {
			if (vars.lastStartedMission == "manson5" && !vars.Passed("Cut Throat Business")) {
				vars.TrySplit("ctb_checkpoint1");
			}
		}
		var ctb_checkpoint2 = vars.GetWatcher("ctb_checkpoint2");
		if (ctb_checkpoint2.Current > ctb_checkpoint2.Old && ctb_checkpoint2.Old == 0) {
			if (vars.lastStartedMission == "manson5" && !vars.Passed("Cut Throat Business")) {
				vars.TrySplit("ctb_checkpoint2");
			}
		}
	#endregion
	#region End of the Line
		//================
		// Any% ending point + other cutscenes
		var eotlp3_chase = vars.GetWatcher("eotlp3_chase");
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
		var freight_stations = vars.GetWatcher("freight_stations");
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
	#region Grove 4 Life
		//==================
		var g4l_drivetoidlewood = vars.GetWatcher("g4l_drivetoidlewood");
		var g4l_territory1 = vars.GetWatcher("g4l_territory1");
		var g4l_territory2 = vars.GetWatcher("g4l_territory2");
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
			var gym_start = vars.GetWatcher("gym_fighting");
			if (gym_start.Current > gym_start.Old && gym_start.Current == 1) {
				vars.TrySplit("San Fierro Gym Fight Start");
			}
		}
		else if (vars.lastStartedMission == "gymls") {
			var gym_start = vars.GetWatcher("gym_fighting");
			if (gym_start.Current > gym_start.Old && gym_start.Current == 1) {
				vars.TrySplit("Los Santos Gym Fight Start");
			}
		}
		else if (vars.lastStartedMission == "gymlv") {
			var gym_start = vars.GetWatcher("gym_fighting");
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
			var vehicle = vars.GetWatcher("export"+i);
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
	#region Kickstart
		//===============
		var kickstart_checkpoints = vars.GetWatcher("kickstart_checkpoints");
		var kickstart_points = vars.GetWatcher("kickstart_points");
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
			var lossep_homiesrecruited = vars.GetWatcher("lossep_homiesrecruited");
			var lossep_cardoorsunlocked = vars.GetWatcher("lossep_cardoorsunlocked");
			var lossep_dialogue = vars.GetWatcher("lossep_dialogue");
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
		var race_index = vars.GetWatcher("race_index");
		if (vars.lastStartedMission == "cprace" || vars.lastStartedMission == "bcesar4" || vars.lastStartedMission == "cesar1") {
			if (race_index.Current == 7 || race_index.Current == 8) {
				// Badlands A & B
				var races_badlandscheckpoint = vars.GetWatcher("races_badlandscheckpoint");
				if (races_badlandscheckpoint.Current > races_badlandscheckpoint.Old) {
					var splitName = "Race "+race_index.Current+" Checkpoint "+races_badlandscheckpoint.Old;
					vars.TrySplit(splitName);
				}
			}
			else if (race_index.Current < 19) {
				// Normal races
				var races_checkpoint = vars.GetWatcher("races_checkpoint");
				if (races_checkpoint.Current > races_checkpoint.Old) {
					var splitName = "Race "+race_index.Current+" Checkpoint "+races_checkpoint.Old;
					vars.TrySplit(splitName);
				}
			}
			else if (race_index.Current < 25) {
				// Fly races
				var races_flycheckpoint = vars.GetWatcher("races_flycheckpoint");
				if (races_flycheckpoint.Current > races_flycheckpoint.Old) {
					var splitName = "Race "+race_index.Current+" Checkpoint "+races_flycheckpoint.Old;
					vars.TrySplit(splitName);
				}
			}
			else {
				// Stadium races
				var races_stadiumcheckpoint = vars.GetWatcher("races_stadiumcheckpoint");
				var races_laps = vars.GetWatcher("races_laps");
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
	#region Schools
		//========
		// Current exercise is used by driving and boat school
		var schools_currentexercise = vars.GetWatcher("schools_currentexercise");
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
		var stunt_timer = vars.GetWatcher("stunt_timer");
		if (stunt_timer.Current > stunt_timer.Old + 10001) {
			if (vars.lastStartedMission == "stunt") {
				var stunt_type = vars.GetWatcher("stunt_type").Current;
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
		var stunt_checkpoint = vars.GetWatcher("stunt_checkpoint");
		if (stunt_checkpoint.Current > stunt_checkpoint.Old) {
			if (vars.lastStartedMission == "stunt") {
				var stunt_type = vars.GetWatcher("stunt_type").Current;
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
		var tgs_chapter = vars.GetWatcher("tgs_chapter");
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
		// var trucking_current = vars.GetWatcher(0x6518DC.ToString()].Current + 1;
		// if (thread.Changed && thread.Current == "truck") {
		// 	var splitName = "Trucking "+trucking_current+" Started";
		// 	vars.TrySplit(splitName);
		// }
		// else if (vars.lastStartedMission == "truck") {
		// 	var trucking_leftcompound = vars.GetWatcher("trucking_leftcompound");
		// 	if (trucking_leftcompound.Current > trucking_leftcompound.Old) {
		// 		var splitName = "Trucking "+trucking_current+": Left Compound";
		// 		vars.TrySplit(splitName);
		// 	}
		// }
	#endregion
	#region Valet Parking
		//===================
		// Levels
		// var valet_level = vars.GetWatcher("valet_level");
		// if (valet_level.Current > valet_level.Old && valet_level.Old != 0) {
		// 	if (thread.Current == "valet") {
		// 		var splitName = "valet_level" + valet_level.Old;
		// 		vars.TrySplit(splitName);
		// 	}
		// }
		var valet_carstopark = vars.GetWatcher("valet_carstopark");
		var valet_carsparked = vars.GetWatcher("valet_carsparked");
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
		if (thread.Changed && thread.Current == "bcesar4" && !vars.Passed("Wu Zi Mu")) {
			vars.TrySplit("Wu Zi Mu Started");
		}
		if (race_index.Current == 8 && race_index.Old == 7 && !vars.Passed("Farewell, My Love")) {
			// If parking in the marker and starting FML during the fadein of WZM, currentthread will never change, so we have to detect its start like this
			vars.TrySplit("Farewell, My Love Started");
		}
	#endregion
	#region Vigilante
		//===============
		if (thread.Changed && thread.Current == "copcar") {
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
		// var hundo_achieved = vars.GetWatcher("100%_achieved");
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
			var progress = vars.GetWatcher("gf_"+gfName+"_progress");
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
		var gf_unlocked = vars.GetWatcher("gf_unlocked");
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

		// Busted/Deathwarp
		//=================
		var pedStatus = vars.GetWatcher("pedStatus");
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
	if (settings["NonLinear GI LS HP C RUS RTF"] && thread.Changed) {
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
}

start {
	//=============================================================================
	// Starting Timer
	//=============================================================================

	var playingTime = vars.GetWatcher("playingTime");
	var intro_cutsceneState = vars.GetWatcher("intro_cutsceneState");
	// var loading = vars.GetWatcher("loading");
	var intro_passed = vars.GetWatcher("intro_passed");

	/*
	 * Note:
	 * Tried to check which menu is selected, which at New Game usually seems to be 6, but doesn't really
	 * seem to work with the Steam version, so that was removed. (0x7A68A5)
	 */

	// Since values might change over the course of the game,
	// loading a Save can sometimes trigger New Game, so first check if
	// playingTime is low enough (240s) (intro cutscene length is about 213s).
	// Also check if the intro mission has been completed.
	if (playingTime.Current > 240000) {
		return false;
	}
	if (intro_passed.Current == 1) {
		return false;
	}

    // Timer start before cutscene
    //============================
	// A rudimentary playtime check should do the trick. Once it starts ticking up, that's when we
	// start ticking as well. It gets set to a fixed 300 during the main menu, and 301/302 during the loading.
	// When the loading finishes (bar disappears, fadeout starts) the timer gets set to 0 for a frame, then to
	// 300 again, then when the game begins proper it gets set to a value of 600 and counts from there.
	// if the game is restarted from the pause menu, the timer acts as expected, starting from 0.
    if (settings["startOnLoadFinish"]) {
		if (playingTime.Current == 300 && playingTime.Old == 0) {
			// Main menu loaded
			return false;
		}
		if ((playingTime.Current == 302 || playingTime.Current == 301) && playingTime.Old == 300) {
			// Starting or loading game from main menu
			return false;
		}
		if (playingTime.Current > playingTime.Old && playingTime.Old > 300) {
			// Regular timer tick
			return false;
		}
		if (playingTime.Current >= 600 && playingTime.Old == 300) {
			if (settings.ResetEnabled) {
				vars.DebugOutput("New Game (Game timer start from Main Menu), at "+playingTime.Current);
			}
			return true;
		}
		if (playingTime.Current < playingTime.Old && playingTime.Old >= 600) {
			if (settings.ResetEnabled) {
				vars.DebugOutput("New Game (Game timer reset from Pause Menu), at "+playingTime.Current);
			}
			return true;
		}
	}
	// Timer on cutscene skip or end
	//==============================
	// intro_cutsceneState is a variable only used in the intro mission, changing to
	// 1 when the cutscene is skipped. It gets set to other values during the
	// intro cutscene. If the cutscene is watched in full, the value will change
	// from 3 to 0.
	//
	// In the commonly used decompiled main.scm, this should be the variable $5353.
	//
	else if (intro_cutsceneState.Changed && playingTime.Current > 2000) {
		if (intro_cutsceneState.Current == 1 || (intro_cutsceneState.Current == 0 && intro_cutsceneState.Old == 3)) {
			if (settings.StartEnabled) {
				vars.DebugOutput("New Game (Intro cutscene over), at "+playingTime.Current);
			}
			return true;
		}
	}

	// Loaded Save
	//============
	// Optional starting the timer when loading a save. The "loading" value seems
	// to only be true when loading a game initially (so not loading screens during
	// the game).
	//
	// if (settings["startOnSaveLoad"] && !loading.Current && loading.Old)
	// {
	// 	vars.lastLoad = Environment.TickCount;
	// 	if (settings.StartEnabled)
	// 	{
	// 		vars.DebugOutput("New Game (Loaded Save)");
	// 	}
	// 	return true;
	// }
}

reset {
	var playingTime = vars.GetWatcher("playingTime");
	var intro_cutsceneState = vars.GetWatcher("intro_cutsceneState");
	// var loading = vars.GetWatcher("loading");
	var intro_passed = vars.GetWatcher("intro_passed");
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
	if (playingTime.Current > 240000) {
		return false;
	}
	if (intro_passed.Current == 1) {
		return false;
	}

    if (settings["startOnLoadFinish"]) {
		if (playingTime.Current == 300 && playingTime.Old == 0) {
			// Main menu loaded
			return false;
		}
		if ((playingTime.Current == 302 || playingTime.Current == 301) && playingTime.Old == 300) {
			// Starting or loading game from main menu
			return false;
		}
		if (playingTime.Current > playingTime.Old && playingTime.Old > 300) {
			// Regular timer tick
			return false;
		}
		if (playingTime.Current >= 600 && playingTime.Old == 300) {
			if (settings.ResetEnabled) {
				vars.DebugOutput("New Game (Game timer start from Main Menu), at "+playingTime.Current);
			}
			return true;
		}
		if (playingTime.Current < playingTime.Old && playingTime.Old >= 600) {
			if (settings.ResetEnabled) {
				vars.DebugOutput("Reset (Game timer reset from Pause Menu)");
			}
			return true;
		}
	}
	else if (intro_cutsceneState.Changed && playingTime.Current > 2000) {
		if (intro_cutsceneState.Current == 1 || (intro_cutsceneState.Current == 0 && intro_cutsceneState.Old == 3)) {
			if (settings.StartEnabled) {
				vars.DebugOutput("Reset (Intro cutscene over)");
			}
			return true;
		}
	}

	// if (settings["resetOnSaveLoad"]) {
	// 	if (math.abs(loading.Current - loading.Old) > 2000) {

	// 	}
	// }


	//  && !loading.Current && loading.Old)
	// {
	// 	vars.lastLoad = Environment.TickCount;
	// 	if (settings.StartEnabled)
	// 	{
	// 		vars.DebugOutput("Reset (Loaded Save)");
	// 	}
	// 	return true;
	// }
}
