function courseplay.prerequisitesPresent(specializations)
	return true;
end

function courseplay:load(xmlFile)
	
	self.setCourseplayFunc = SpecializationUtil.callSpecializationsFunction("setCourseplayFunc");

	--SEARCH AND SET self.name IF NOT EXISTING
	if self.name == nil then
		local nameSearch = { "vehicle.name." .. g_languageShort, "vehicle.name.en", "vehicle.name", "vehicle#type" };
		for i,xmlPath in pairs(nameSearch) do
			self.name = getXMLString(xmlFile, xmlPath);
			if self.name ~= nil then
				courseplay:debug(nameNum(self) .. ": self.name was nil, got new name from " .. xmlPath .. " in XML", 12);
				break;
			end;
		end;
		if self.name == nil then
			self.name = g_i18n:getText("UNKNOWN");
			courseplay:debug(tostring(self.configFileName) .. ": self.name was nil, new name is " .. self.name, 12);
		end;
	end;

	self.cp = {};

	courseplay:setNameVariable(self);
	self.cp.isCombine = courseplay:isCombine(self);
	self.cp.isChopper = courseplay:isChopper(self);
	self.cp.isHarvesterSteerable = courseplay:isHarvesterSteerable(self);
	self.cp.isKasi = nil
	self.cp.isSugarBeetLoader = courseplay:isSpecialCombine(self, "sugarBeetLoader");
	if self.cp.isCombine then
		self.cp.mode7Unloading = false
		self.cp.driverPriorityUseFillLevel = false;
	end
	if self.isRealistic then
		self.cp.trailerPushSpeed = 0
	end
	
	--turn maneuver
	self.cp.waitForTurnTime = 0.00   --float
	self.cp.turnStage = 0 --int
	self.cp.aiTurnNoBackward = false --bool
	self.cp.backMarkerOffset = nil --float
	self.cp.aiFrontMarker = nil --float
	self.cp.turnTimer = 8000 --int
	self.cp.noStopOnEdge = false --bool
	self.cp.noStopOnTurn = false --bool

	self.toggledTipState = 0;
	self.cp.closestTipDistance = math.huge

	self.cp.combineOffsetAutoMode = true
	self.drive = false
	self.runOnceStartCourse = false;
	self.cp.stopAtEnd = false
	self.calculated_course = false

	self.recordnumber = 1
	self.cp.last_recordnumber = 1;
	self.tmr = 1
	self.startlastload = 1
	self.timeout = 1
	self.timer = 0.00
	self.cp.timers = {}; 
	self.drive_slow_timer = 0
	self.courseplay_position = nil
	self.waitPoints = 0
	self.cp.waitTime = 0
	self.crossPoints = 0
	self.cp.visualWaypointsMode = 1
	self.cp.beaconLightsMode = 1
	self.cp.workWidthChanged = 0
	-- saves the shortest distance to the next waypoint (for recocnizing circling)
	self.shortest_dist = nil

	self.Waypoints = {}

	self.play = false --can drive course (has >4 waypoints, is not recording)
	self.cp.coursePlayerNum = nil;

	self.cp.infoText = nil -- info text on tractor

	-- global info text - also displayed when not in vehicle
	local git = courseplay.globalInfoText;
	self.cp.globalInfoTextOverlay = Overlay:new(string.format("globalInfoTextOverlay%d", self.rootNode), git.backgroundImg, git.backgroundX, git.backgroundY, 0.1, git.fontSize);
	local buttonHeight = git.fontSize;
	local buttonWidth = buttonHeight * 1080 / 1920;
	local buttonX = git.backgroundX - git.backgroundPadding - buttonWidth;
	local buttonIdx = #courseplay_manager.buttons.globalInfoText + 1;
	local buttonY = git.posY + ((buttonIdx - 1) * git.lineHeight);
	courseplay_manager.buttons:registerButton('globalInfoText', 'goToVehicle', buttonIdx, 'pageNav_7.png', buttonX, buttonY, buttonWidth, buttonHeight);
	courseplay_manager.buttons.globalInfoTextClickArea = {
		x1 = buttonX;
		x2 = buttonX + buttonWidth;
		y1 = git.posY,
		y2 = git.posY + (buttonIdx * git.lineHeight);
	};
	-- ai mode: 1 abfahrer, 2 kombiniert
	self.cp.aiMode = 1
	self.follow_mode = 1
	self.ai_state = 0
	self.next_ai_state = nil
	self.cp.startWork = nil
	self.cp.stopWork = nil
	self.cp.abortWork = nil
	self.cp.hasUnloadingRefillingCourse = false;
	self.wait = true
	self.waitTimer = nil
	self.cp.realisticDriving = true;
	self.cp.canSwitchMode = false;
	self.cp.startAtFirstPoint = false;

	self.cp.stopForLoading = false;

	self.cp.attachedCombineIdx = nil;

	-- ai mode 9: shovel
	self.cp.shovelEmptyPoint = nil;
	self.cp.shovelFillStartPoint = nil;
	self.cp.shovelFillEndPoint = nil;
	self.cp.shovelState = 1;
	self.cp.shovelStateRot = {};
	self.cp.shovel = {};
	self.cp.shovelStopAndGo = false;
	self.cp.shovelLastFillLevel = nil;

	-- our arrow is displaying dirction to waypoints
	self.cp.directionArrowOverlay = Overlay:new("Arrow", Utils.getFilename("img/arrow.png", courseplay.path), 0.55, 0.05, 0.250, 0.250);

	-- Visual i3D waypoint signs
	self.cp.signs = {
		crossing = {};
		current = {};
	};
	courseplay:updateWaypointSigns(self);

	-- course name for saving
	self.current_course_name = nil
	self.courseID = 0
	-- array for multiple courses
	self.loaded_courses = {}
	self.cp.drivingDirReverse = false
	-- forced waypoints
	self.target_x = nil
	self.target_y = nil
	self.target_z = nil

	self.next_targets = {}

	-- speed limits
	self.cp.speeds = {
		useRecordingSpeed = true;
		unload =  6 / 3600; -- >3
		turn =   10 / 3600; -- >5
		field =  24 / 3600; -- >5
		max =    50 / 3600; -- >5
		sl = 3;
	};

	self.tools_dirty = false

	self.cp.orgRpm = nil;

	-- data basis for the Course list
	self.cp.reloadCourseItems = true
	self.cp.sorted = {item={}, info={}}	
	self.cp.folder_settings = {}
	courseplay.settings.update_folders(self)

	if self.aiTrafficCollisionTrigger == nil and getNumOfChildren(self.rootNode) > 0 then
		if getChild(self.rootNode, "trafficCollisionTrigger") ~= 0 then
			self.aiTrafficCollisionTrigger = getChild(self.rootNode, "trafficCollisionTrigger");
		else
			for i=0,getNumOfChildren(self.rootNode)-1 do
				local child = getChildAt(self.rootNode, i);
				if getChild(child, "trafficCollisionTrigger") ~= 0 then
					self.aiTrafficCollisionTrigger = getChild(child, "trafficCollisionTrigger");
					break;
				end;
			end;
		end;
	end;

	--Direction 
	local DirectionNode = nil;
	if self.aiTractorDirectionNode ~= nil then
		DirectionNode = self.aiTractorDirectionNode;
	elseif self.aiTreshingDirectionNode ~= nil then
		DirectionNode = self.aiTreshingDirectionNode;
	else
		if courseplay:isWheelloader(self)then
			DirectionNode = getParent(self.shovelTipReferenceNode)
			if self.wheels[1].rotMax ~= 0 then
				DirectionNode = self.rootNode;
			end
			if DirectionNode == nil then
				for i=1, table.getn(self.attacherJoints) do
					if self.rootNode ~= getParent(self.attacherJoints[i].jointTransform) then
						DirectionNode = getParent(self.attacherJoints[i].jointTransform)
						break
					end
				end
			end
		end
		if DirectionNode == nil then
			DirectionNode = self.rootNode;
		end
	end;
	self.cp.DirectionNode = DirectionNode;

	-- traffic collision
	self.onTrafficCollisionTrigger = courseplay.cponTrafficCollisionTrigger;
	--self.aiTrafficCollisionTrigger = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiTrafficCollisionTrigger#index"));
	self.steering_angle = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.wheels.wheel(1)" .. "#rotMax"), 30)
	self.cp.tempCollis = {}
	self.CPnumCollidingVehicles = 0;
	--	self.numToolsCollidingVehicles = {};
	--	self.trafficCollisionIgnoreList = {};
	self.cpTrafficCollisionIgnoreList = {};
	self.cp.TrafficBrake = false
	self.cp.inTraffic = false
	-- tipTrigger
	self.findTipTriggerCallback = courseplay.findTipTriggerCallback;
	self.findTrafficCollisionCallback = courseplay.findTrafficCollisionCallback;
	self.findBlockingObjectCallbackLeft = courseplay.findBlockingObjectCallbackLeft
	self.findBlockingObjectCallbackRight = courseplay.findBlockingObjectCallbackRight
	

	if self.numCollidingVehicles == nil then
		self.numCollidingVehicles = {};
	end
	if self.trafficCollisionIgnoreList == nil then
		self.trafficCollisionIgnoreList = {}
	end

	courseplay:askForSpecialSettings(self,self)


	-- tippers
	self.tippers = {}
	self.tipper_attached = false
	self.currentTrailerToFill = nil
	self.lastTrailerToFillDistance = nil
	self.unloaded = false
	self.loaded = false
	self.unloading_tipper = nil
	self.last_fill_level = nil
	self.tipRefOffset = 0;
	self.cp.tipLocation = 1;
	self.cp.tipperHasCover = false;
	self.cp.tippersWithCovers = {};
	self.cp.tipperFillLevel = nil;
	self.cp.tipperCapacity = nil;

	self.selected_course_number = 0
	self.course_Del = false

	-- combines
	self.reachable_combines = {}
	self.active_combine = nil

	self.cp.offset = nil --self = combine [flt]
	self.cp.combineOffset = 0.0
	self.cp.tipperOffset = 0.0

	self.forced_side = nil
	self.forced_to_stop = false

	self.allow_following = false
	self.cp.followAtFillLevel = 50
	self.cp.driveOnAtFillLevel = 90

	self.turn_factor = nil
	self.cp.turnRadius = 10;
	self.cp.turnRadiusAuto = 10;
	self.cp.turnRadiusAutoMode = true;

	--Offset
	self.cp.laneOffset = 0;
	self.cp.toolOffsetX = 0;
	self.cp.toolOffsetZ = 0;
	self.cp.totalOffsetX = 0;
	self.cp.symmetricLaneChange = false;
	self.cp.switchLaneOffset = false;
	self.cp.switchToolOffset = false;

	self.cp.workWidth = 3

	self.search_combine = true
	self.saved_combine = nil
	self.selected_combine_number = 0
	
	self.cp.EifokLiquidManure = {
		targetRefillObject = {};
		searchMapHoseRefStation = {
			pull = true;
			push = true;
		};
	};
	--Copy course
	self.cp.hasFoundCopyDriver = false;
	self.cp.copyCourseFromDriver = nil;
	self.cp.selectedDriverNumber = 0;

	--Course generation
	self.cp.startingCorner = 0;
	self.cp.hasStartingCorner = false;
	self.cp.startingDirection = 0;
	self.cp.hasStartingDirection = false;
	self.cp.returnToFirstPoint = false;
	self.cp.hasGeneratedCourse = false;
	self.cp.hasValidCourseGenerationData = false;
	self.cp.ridgeMarkersAutomatic = true;
	self.cp.headland = {
		numLanes = 0;
	};

	self.cp.fieldEdge = {
		selectedField = {
			fieldNum = 0;
			numPoints = 0;
			buttonsCreated = false;
		};
		customField = {
			points = nil;
			numPoints = 0;
			isCreated = false;
			show = false;
			fieldNum = 0;
			selectedFieldNumExists = false;
		};
	};

	self.cp.mouseCursorActive = false


	local w16px, h16px = 16/1920, 16/1080;
	local w24px, h24px = 24/1920, 24/1080;
	local w32px, h32px = 32/1920, 32/1080;

	-- HUD
	self.cp.hud = {
		background = Overlay:new("hudInfoBaseOverlay", Utils.getFilename("img/hud_bg.dds", courseplay.path), courseplay.hud.infoBasePosX - 10/1920, courseplay.hud.infoBasePosY - 10/1920, courseplay.hud.infoBaseWidth, courseplay.hud.infoBaseHeight);
		currentPage = 1;
		show = false;
		openWithMouse = true;
		content = {
			global = {};
			pages = {};
		};
		mouseWheel = {
			icon = Overlay:new("cpMouseWheelIcon", "dataS2/menu/mouseControlsHelp/mouseMMB.png", 0, 0, w32px, h32px);
			render = false;
		};

		--3rd party huds backup
		ESLimiterOrigPosY = nil; --[table]
		ThreshingCounterOrigPosY = nil; --[table]
		OdometerOrigPosY = nil; --[table]
		AllradOrigPosY = nil; --[table]
	};

	for page=0,courseplay.hud.numPages do
		self.cp.hud.content.pages[page] = {};
		for line=1,courseplay.hud.numLines do
			self.cp.hud.content.pages[page][line] = {
				{ text = nil, isHovered = false, indention = 0 },
				{ text = nil, posX = courseplay.hud.col2posX[page] }
			};
			if courseplay.hud.col2posXforce[page] ~= nil and courseplay.hud.col2posXforce[page][line] ~= nil then
				self.cp.hud.content.pages[page][line][2].posX = courseplay.hud.col2posXforce[page][line];
			end;
		end;
	end;
	
	-- course list
	self.cp.hud.filterEnabled = true;
	self.cp.hud.filter = "";
	self.cp.hud.choose_parent = false
	self.cp.hud.showFoldersOnly = false
	self.cp.hud.showZeroLevelFolder = false
	self.cp.hud.courses = {}
	self.cp.hud.courseListPrev = false;
	self.cp.hud.courseListNext = false; -- will be updated after loading courses into the hud
	self.cp.hud.reloadPage = {}
	self.cp.hud.reloadPage[-1] = true -- reload all

	-- clickable buttons
	self.cp.buttons = {};
	self.cp.buttons.global = {};
	self.cp.buttons["-2"] = {};
	for page=0, courseplay.hud.numPages do
		self.cp.buttons[tostring(page)] = {};
	end;

	--Camera backups: allowTranslation
	self.cp.camerasBackup = {};
	for camIndex, camera in pairs(self.cameras) do
		if camera.allowTranslation then
			self.cp.camerasBackup[camIndex] = camera.allowTranslation;
		end;
	end;

	--default hud conditional variables
	self.cp.HUD0noCourseplayer = false;
	self.cp.HUD0wantsCourseplayer = false;
	self.cp.HUD0tractorName = "";
	self.cp.HUD0tractorForcedToStop = false;
	self.cp.HUD0tractor = false;
	self.cp.HUD0combineForcedSide = nil;
	self.cp.HUD0isManual = false;
	self.cp.HUD0turnStage = 0;
	self.cp.HUD1notDrive = false;
	self.cp.HUD1goOn = false;
	self.cp.HUD1noWaitforFill = false;
	self.cp.HUD4combineName = "";
	self.cp.HUD4hasActiveCombine = false;
	self.cp.HUD4savedCombine = nil;
	self.cp.HUD4savedCombineName = "";

	courseplay:setMinHudPage(self, nil);

	--Hud titles
	if courseplay.hud.hudTitles == nil then
		courseplay.hud.hudTitles = {
			[0] = courseplay:get_locale(self, "CPCombineManagement"), -- Combine Controls
			[1] = courseplay:get_locale(self, "CPSteering"), -- "Abfahrhelfer Steuerung"
			[2] = { courseplay:get_locale(self, "CPManageCourses"), courseplay:get_locale(self, "CPchooseFolder"), courseplay:get_locale(self, "CPcoursesFilterTitle") }, -- "Kurse verwalten"
			[3] = courseplay:get_locale(self, "CPCombiSettings"), -- "Einstellungen Combi Modus"
			[4] = courseplay:get_locale(self, "CPManageCombines"), -- "Drescher verwalten"
			[5] = courseplay:get_locale(self, "CPSpeedLimit"), -- "Speeds"
			[6] = courseplay:get_locale(self, "CPSettings"), -- "General settings"
			[7] = courseplay:get_locale(self, "CPHud7"), -- "Driving settings"
			[8] = courseplay:get_locale(self, "CPcourseGeneration"), -- "Course Generation"
			[9] = courseplay:get_locale(self, "CPShovelPositions") --Schaufel progammieren
		};
	end;


	-- ## BUTTONS FOR HUD ##
	local mouseWheelArea = {
		x = courseplay.hud.infoBasePosX + 0.005,
		w = courseplay.hud.visibleArea.x2 - courseplay.hud.visibleArea.x1 - (2 * 0.005),
		h = courseplay.hud.lineHeight
	};

	local listArrowX = courseplay.hud.visibleArea.x2 - (2 * 0.005) - w24px;

	-- Page nav
	local pageNav = {
		buttonW = w32px;
		buttonH = h32px;
		paddingRight = 0.005;
		posY = courseplay.hud.infoBasePosY + 0.271;
	};
	pageNav.totalWidth = ((courseplay.hud.numPages + 1) * pageNav.buttonW) + (courseplay.hud.numPages * pageNav.paddingRight); --numPages=9, real numPages=10
	pageNav.baseX = courseplay.hud.infoBaseCenter - pageNav.totalWidth/2;
	for p=0, courseplay.hud.numPages do
		local posX = pageNav.baseX + (p * (pageNav.buttonW + pageNav.paddingRight));
		courseplay:register_button(self, "global", string.format("pageNav_%d.dds", p), "setHudPage", p, posX, pageNav.posY, pageNav.buttonW, pageNav.buttonH);
	end;

	courseplay:register_button(self, "global", "navigate_left.dds", "switch_hud_page", -1, courseplay.hud.infoBasePosX + 0.035, courseplay.hud.infoBasePosY + 0.2395, w24px, h24px); --ORIG: +0.242
	courseplay:register_button(self, "global", "navigate_right.dds", "switch_hud_page", 1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.infoBasePosY + 0.2395, w24px, h24px);

	courseplay:register_button(self, "global", "close.dds", "openCloseHud", false, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.infoBasePosY + 0.255, w24px, h24px);

	courseplay:register_button(self, "global", "disk.dds", "showSaveCourseForm", 'course', listArrowX - 15/1920 - w24px, courseplay.hud.infoBasePosY + 0.056, w24px, h24px);

	--Page 0: Combine controls
	for i=1, courseplay.hud.numLines do
		courseplay:register_button(self, 0, "blank.dds", "rowButton", i, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[i], courseplay.hud.visibleArea.width, 0.015, i, nil, true);
	end;


	--Page 1
	--ai_mode quickSwitch
	local aiModeQuickSwitch = {
		w = w32px;
		h = h32px;
		numColumns = 3;
		maxX = courseplay.hud.visibleArea.x2 - 0.01;
	};
	aiModeQuickSwitch.minX = aiModeQuickSwitch.maxX - (aiModeQuickSwitch.numColumns * aiModeQuickSwitch.w);
	for i=1, courseplay.numAiModes do
		local icon = string.format("quickSwitch_mode%d.dds", i);

		local l = math.ceil(i/aiModeQuickSwitch.numColumns);
		local col = i;
		while col > aiModeQuickSwitch.numColumns do
			col = col - aiModeQuickSwitch.numColumns;
		end;

		local posX = aiModeQuickSwitch.minX + (aiModeQuickSwitch.w * (col-1));
		local posY = courseplay.hud.linesPosY[1] + courseplay.hud.lineHeight --[[(20/1080)]] - (aiModeQuickSwitch.h * l);

		courseplay:register_button(self, 1, icon, "setAiMode", i, posX, posY, aiModeQuickSwitch.w, aiModeQuickSwitch.h);
	end;

	for i=1, courseplay.hud.numLines do
		courseplay:register_button(self, 1, "blank.dds", "rowButton", i, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[i], aiModeQuickSwitch.minX - courseplay.hud.infoBasePosX - 0.005, 0.015, i, nil, true);
	end;

	--Custom field edge path
	courseplay:register_button(self, 1, "cancel.png", "clearCustomFieldEdge", nil, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[3], w16px, h16px, 3, nil, false);
	courseplay:register_button(self, 1, "eye.png", "toggleCustomFieldEdgePathShow", nil, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[3], w16px, h16px, 3, nil, false);

	courseplay:register_button(self, 1, "navigate_minus.png", "setCustomFieldEdgePathNumber", -1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[4], w16px, h16px, 4, -5, false);
	courseplay:register_button(self, 1, "navigate_plus.png",  "setCustomFieldEdgePathNumber",  1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[4], w16px, h16px, 4,  5, false);
	courseplay:register_button(self, 1, nil, "setCustomFieldEdgePathNumber", 1, mouseWheelArea.x, courseplay.hud.linesButtonPosY[4], mouseWheelArea.w, mouseWheelArea.h, 4, 5, true, true);


	--Page 2: Course management
	--course navigation
	courseplay:register_button(self, 2, "navigate_up.dds",   "shiftHudCourses", -courseplay.hud.numLines, listArrowX, courseplay.hud.linesPosY[1] - 0.003,                       w24px, h24px, nil, -courseplay.hud.numLines*2);
	courseplay:register_button(self, 2, "navigate_down.dds", "shiftHudCourses",  courseplay.hud.numLines, listArrowX, courseplay.hud.linesPosY[courseplay.hud.numLines] - 0.003, w24px, h24px, nil,  courseplay.hud.numLines*2);

	local courseListMouseWheelArea = {
		x = mouseWheelArea.x,
		y = courseplay.hud.linesPosY[courseplay.hud.numLines],
		width = mouseWheelArea.w,
		height = courseplay.hud.linesPosY[1] + courseplay.hud.lineHeight - courseplay.hud.linesPosY[courseplay.hud.numLines]
	};
	courseplay:register_button(self, 2, nil, "shiftHudCourses",  -1, courseListMouseWheelArea.x, courseListMouseWheelArea.y, courseListMouseWheelArea.width, courseListMouseWheelArea.height, nil, -courseplay.hud.numLines, nil, true);

	--reload courses
	if g_server ~= nil then
		--courseplay:register_button(self, 2, "refresh.dds", "reloadCoursesFromXML", nil, courseplay.hud.infoBasePosX + 0.258, courseplay.hud.infoBasePosY + 0.24, w16px, h16px);
	end;

	--course actions
	local pad = w16px*10/16 --old padding = 0.009667 ~ 18.5px
	local buttonX = {};
	buttonX[0] = courseplay.hud.infoBasePosX + 0.005;
	buttonX[4] = listArrowX - (2 * pad) - w16px;
	buttonX[3] = buttonX[4] - pad - w16px;
	buttonX[2] = buttonX[3] - pad - w16px;
	buttonX[1] = buttonX[2] - pad - w16px;
	local hoverAreaWidth = buttonX[3] + w16px - buttonX[1];
	if g_server ~= nil then
		hoverAreaWidth = buttonX[4] + w16px - buttonX[1];
	end;
	for i=1, courseplay.hud.numLines do
		local expandButtonIndex = courseplay:register_button(self, -2, "folder_expand.png", "expandFolder", i, buttonX[0], courseplay.hud.linesButtonPosY[i], w16px, h16px, i, nil, false);
		courseplay.button.addOverlay(self.cp.buttons["-2"][expandButtonIndex], 2, "folder_reduce.png");
		courseplay:register_button(self, -2, "courseLoadAppend.png", "load_sorted_course", i, buttonX[1], courseplay.hud.linesButtonPosY[i], w16px, h16px, i, nil, false);
		courseplay:register_button(self, -2, "courseAdd.png", "add_sorted_course", i, buttonX[2], courseplay.hud.linesButtonPosY[i], w16px, h16px, i, nil, false);
		local linkParentButtonIndex = courseplay:register_button(self, -2, "folder_parent_from.png", "link_parent", i, buttonX[3], courseplay.hud.linesButtonPosY[i], w16px, h16px, i, nil, false);
		courseplay.button.addOverlay(self.cp.buttons["-2"][linkParentButtonIndex], 2, "folder_parent_to.png");
		if g_server ~= nil then
			courseplay:register_button(self, -2, "delete.png", "delete_sorted_item", i, buttonX[4], courseplay.hud.linesButtonPosY[i], w16px, h16px, i, nil, false);
		end;
		courseplay:register_button(self, -2, nil, nil, nil, buttonX[1], courseplay.hud.linesButtonPosY[i], hoverAreaWidth, mouseWheelArea.h, i, nil, true, false);
	end
	self.cp.hud.filterButtonIndex = courseplay:register_button(self, 2, "searchGlass.png", "showSaveCourseForm", "filter", buttonX[2], courseplay.hud.infoBasePosY + 0.2395, w24px, h24px);
	courseplay.button.addOverlay(self.cp.buttons["2"][self.cp.hud.filterButtonIndex], 2, "cancel.png");
	courseplay:register_button(self, 2, "folder_new.png", "showSaveCourseForm", 'folder', listArrowX, courseplay.hud.infoBasePosY + 0.056, w24px, h24px);

	--Page 3
	courseplay:register_button(self, 3, "navigate_minus.dds", "change_combine_offset", -0.1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[1], w16px, h16px, 1, -0.5, false);
	courseplay:register_button(self, 3, "navigate_plus.dds",  "change_combine_offset",  0.1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[1], w16px, h16px, 1,  0.5, false);
	courseplay:register_button(self, 3, nil, "change_combine_offset", 0.1, mouseWheelArea.x, courseplay.hud.linesButtonPosY[1], mouseWheelArea.w, mouseWheelArea.h, 1, 0.5, true, true);

	courseplay:register_button(self, 3, "navigate_minus.dds", "change_tipper_offset", -0.1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[2], w16px, h16px, 2, -0.5, false);
	courseplay:register_button(self, 3, "navigate_plus.dds",  "change_tipper_offset",  0.1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[2], w16px, h16px, 2,  0.5, false);
	courseplay:register_button(self, 3, nil, "change_tipper_offset", 0.1, mouseWheelArea.x, courseplay.hud.linesButtonPosY[2], mouseWheelArea.w, mouseWheelArea.h, 2, 0.5, true, true);

	courseplay:register_button(self, 3, "navigate_minus.dds", "changeTurnRadius", -1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[3], w16px, h16px, 3, -5, false);
	courseplay:register_button(self, 3, "navigate_plus.dds",  "changeTurnRadius",  1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[3], w16px, h16px, 3,  5, false);
	courseplay:register_button(self, 3, nil, "changeTurnRadius", 1, mouseWheelArea.x, courseplay.hud.linesButtonPosY[3], mouseWheelArea.w, mouseWheelArea.h, 3, 5, true, true);

	courseplay:register_button(self, 3, "navigate_minus.dds", "change_required_fill_level", -5, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[4], w16px, h16px, 4, -10, false);
	courseplay:register_button(self, 3, "navigate_plus.dds",  "change_required_fill_level",  5, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[4], w16px, h16px, 4,  10, false);
	courseplay:register_button(self, 3, nil, "change_required_fill_level", 5, mouseWheelArea.x, courseplay.hud.linesButtonPosY[4], mouseWheelArea.w, mouseWheelArea.h, 4, 10, true, true);

	courseplay:register_button(self, 3, "navigate_minus.dds", "change_required_fill_level_for_drive_on", -5, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[5], w16px, h16px, 5, -10, false);
	courseplay:register_button(self, 3, "navigate_plus.dds",  "change_required_fill_level_for_drive_on",  5, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[5], w16px, h16px, 5,  10, false);
	courseplay:register_button(self, 3, nil, "change_required_fill_level_for_drive_on", 5, mouseWheelArea.x, courseplay.hud.linesButtonPosY[5], mouseWheelArea.w, mouseWheelArea.h, 5, 10, true, true);

	--Page 4: Combine management
	courseplay:register_button(self, 4, "navigate_up.dds",   "switch_combine", -1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[1], w16px, h16px, 1, nil, false);
	courseplay:register_button(self, 4, "navigate_down.dds", "switch_combine",  1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[1], w16px, h16px, 1, nil, false);
	courseplay:register_button(self, 4, nil, nil, nil, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[1], 0.015 + w16px, mouseWheelArea.h, 1, nil, true, false);

	courseplay:register_button(self, 4, "blank.dds", "switch_search_combine", nil, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[2], courseplay.hud.visibleArea.width, 0.015, 2, nil, true);

	--Page 5: Speeds
	courseplay:register_button(self, 5, "navigate_minus.dds", "change_turn_speed",   -1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[1], w16px, h16px, 1, -5, false);
	courseplay:register_button(self, 5, "navigate_plus.dds",  "change_turn_speed",    1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[1], w16px, h16px, 1,  5, false);
	courseplay:register_button(self, 5, nil, "change_turn_speed", 1, mouseWheelArea.x, courseplay.hud.linesButtonPosY[1], mouseWheelArea.w, mouseWheelArea.h, 1, 5, true, true);

	courseplay:register_button(self, 5, "navigate_minus.dds", "change_field_speed",  -1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[2], w16px, h16px, 2, -5, false);
	courseplay:register_button(self, 5, "navigate_plus.dds",  "change_field_speed",   1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[2], w16px, h16px, 2,  5, false);
	courseplay:register_button(self, 5, nil, "change_field_speed", 1, mouseWheelArea.x, courseplay.hud.linesButtonPosY[2], mouseWheelArea.w, mouseWheelArea.h, 2, 5, true, true);

	courseplay:register_button(self, 5, "navigate_minus.dds", "change_max_speed",    -1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[3], w16px, h16px, 3, -5, false);
	courseplay:register_button(self, 5, "navigate_plus.dds",  "change_max_speed",     1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[3], w16px, h16px, 3,  5, false);
	courseplay:register_button(self, 5, nil, "change_max_speed", 1, mouseWheelArea.x, courseplay.hud.linesButtonPosY[3], mouseWheelArea.w, mouseWheelArea.h, 3, 5, true, true);

	courseplay:register_button(self, 5, "navigate_minus.dds", "change_unload_speed", -1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[4], w16px, h16px, 4, -5, false);
	courseplay:register_button(self, 5, "navigate_plus.dds",  "change_unload_speed",  1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[4], w16px, h16px, 4,  5, false);
	courseplay:register_button(self, 5, nil, "change_unload_speed", 1, mouseWheelArea.x, courseplay.hud.linesButtonPosY[4], mouseWheelArea.w, mouseWheelArea.h, 4, 5, true, true);

	courseplay:register_button(self, 5, "blank.dds", "change_use_speed",1, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[5], courseplay.hud.visibleArea.width, 0.015, 5, nil, true);


	--Page 6: General settings
	courseplay:register_button(self, 6, "blank.dds", "toggleRealisticDriving", nil, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[1], courseplay.hud.visibleArea.width, 0.015, 1, nil, true);
	courseplay:register_button(self, 6, "blank.dds", "toggleOpenHudWithMouse", nil, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[2], courseplay.hud.visibleArea.width, 0.015, 2, nil, true);
	courseplay:register_button(self, 6, "blank.dds", "change_WaypointMode", 1, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[3], courseplay.hud.visibleArea.width, 0.015, 3, nil, true);
	courseplay:register_button(self, 6, "blank.dds", "changeBeaconLightsMode", 1, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[4], courseplay.hud.visibleArea.width, 0.015, 4, nil, true);

	courseplay:register_button(self, 6, "navigate_minus.dds", "changeWaitTime", -5, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[5], w16px, h16px, 5, -10, false);
	courseplay:register_button(self, 6, "navigate_plus.dds",  "changeWaitTime",  5, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[5], w16px, h16px, 5,  10, false);
	courseplay:register_button(self, 6, nil, "changeWaitTime", 5, mouseWheelArea.x, courseplay.hud.linesButtonPosY[5], mouseWheelArea.w, mouseWheelArea.h, 5, 10, true, true);

	local dbgW, dbgH = 22/1920, 22/1080;
	local dbgPosY = courseplay.hud.linesPosY[6] - 0.004;
	local dbgMaxX = courseplay.hud.infoBasePosX + 0.285 - 0.01;
	for dbg=1, courseplay.numAvailableDebugChannels do
		local col = ((dbg-1) % courseplay.numDebugChannelButtonsPerLine) + 1;
		local dbgPosX = dbgMaxX - (courseplay.numDebugChannelButtonsPerLine * dbgW) + ((col-1) * dbgW);
		courseplay:register_button(self, 6, "debugChannelButtons.png", "toggleDebugChannel", dbg, dbgPosX, dbgPosY, dbgW, dbgH);
	end;
	courseplay:register_button(self, 6, "navigate_up.png",   "changeDebugChannelSection", -1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[6], w16px, h16px, -1, nil, false);
	courseplay:register_button(self, 6, "navigate_down.png", "changeDebugChannelSection",  1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[6], w16px, h16px,  1, nil, false);

	--Page 7: Driving settings
	courseplay:register_button(self, 7, "navigate_left.dds",  "changeLaneOffset", -0.1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[1], w16px, h16px, 1, -0.5, false);
	courseplay:register_button(self, 7, "navigate_right.dds", "changeLaneOffset",  0.1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[1], w16px, h16px, 1,  0.5, false);
	courseplay:register_button(self, 7, nil, "changeLaneOffset", 0.1, mouseWheelArea.x, courseplay.hud.linesButtonPosY[1], mouseWheelArea.w, mouseWheelArea.h, 1, 0.5, true, true);

	courseplay:register_button(self, 7, "blank.dds", "toggleSymmetricLaneChange", nil, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[2], courseplay.hud.visibleArea.width, 0.015, 2, nil, true);

	courseplay:register_button(self, 7, "navigate_left.dds",  "changeToolOffsetX", -0.1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[3], w16px, h16px, 3,  -0.5, false);
	courseplay:register_button(self, 7, "navigate_right.dds", "changeToolOffsetX",  0.1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[3], w16px, h16px, 3,   0.5, false);
	courseplay:register_button(self, 7, nil, "changeToolOffsetX", 0.1, mouseWheelArea.x, courseplay.hud.linesButtonPosY[3], mouseWheelArea.w, mouseWheelArea.h, 3, 0.5, true, true);

	courseplay:register_button(self, 7, "navigate_down.dds", "changeToolOffsetZ", -0.1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[4], w16px, h16px, 4,  -0.5, false);
	courseplay:register_button(self, 7, "navigate_up.dds",   "changeToolOffsetZ",  0.1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[4], w16px, h16px, 4,   0.5, false);
	courseplay:register_button(self, 7, nil, "changeToolOffsetZ", 0.1, mouseWheelArea.x, courseplay.hud.linesButtonPosY[4], mouseWheelArea.w, mouseWheelArea.h, 4, 0.5, true, true);


	courseplay:register_button(self, 7, "navigate_up.dds",   "switchDriverCopy", -1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[5], w16px, h16px, 5, nil, false);
	courseplay:register_button(self, 7, "navigate_down.dds", "switchDriverCopy",  1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[5], w16px, h16px, 5, nil, false);
	courseplay:register_button(self, 7, nil, nil, nil, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[5], 0.015 + w16px, mouseWheelArea.h, 5, nil, true, false);
	courseplay:register_button(self, 7, "copy.png",          "copyCourse",      nil, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[6], w16px, h16px);

	--Page 8: Course generation
	--Note: line 1 (field edges) will be applied in first updateTick() runthrough

	courseplay:register_button(self, 8, "navigate_minus.dds", "changeWorkWidth", -0.1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[2], w16px, h16px, 2,  -0.5, false);
	courseplay:register_button(self, 8, "navigate_plus.dds",  "changeWorkWidth",  0.1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[2], w16px, h16px, 2,   0.5, false);
	courseplay:register_button(self, 8, nil, "changeWorkWidth", 0.1, mouseWheelArea.x, courseplay.hud.linesButtonPosY[2], mouseWheelArea.w, mouseWheelArea.h, 2, 0.5, true, true);

	courseplay:register_button(self, 8, "blank.dds", "switchStartingCorner",     nil, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[3], courseplay.hud.visibleArea.width, 0.015, 3, nil, true);
	courseplay:register_button(self, 8, "blank.dds", "switchStartingDirection",  nil, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[4], courseplay.hud.visibleArea.width, 0.015, 4, nil, true);
	courseplay:register_button(self, 8, "blank.dds", "switchReturnToFirstPoint", nil, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[5], courseplay.hud.visibleArea.width, 0.015, 5, nil, true);

	courseplay:register_button(self, 8, "navigate_up.dds",   "setHeadlandLanes",   1, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[6], w16px, h16px, 5, nil, false);
	courseplay:register_button(self, 8, "navigate_down.dds", "setHeadlandLanes",  -1, courseplay.hud.infoBasePosX + 0.300, courseplay.hud.linesButtonPosY[6], w16px, h16px, 6, nil, false);
	courseplay:register_button(self, 8, nil, nil, nil, courseplay.hud.infoBasePosX + 0.285, courseplay.hud.linesButtonPosY[6], 0.015 + w16px, mouseWheelArea.h, 6, nil, true, false);

	--courseplay:register_button(self, 8, "blank.dds", "generateCourse",           nil, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[6], courseplay.hud.visibleArea.width, 0.015, 6, nil, true);
	courseplay:register_button(self, 8, "pageNav_8.png", "generateCourse", nil, listArrowX - 15/1920 - w24px - 15/1920 - w24px, courseplay.hud.infoBasePosY + 0.056, w24px, h24px, nil, nil, false);

	--Page 9: Shovel settings
	local wTemp = 22/1920;
	local hTemp = 22/1080;
	courseplay:register_button(self, 9, "shovelLoading.dds",      "saveShovelStatus", 2, courseplay.hud.infoBasePosX + 0.200, courseplay.hud.linesButtonPosY[1] - 0.003, wTemp, hTemp, 1, 2, true);
	courseplay:register_button(self, 9, "shovelTransport.dds",    "saveShovelStatus", 3, courseplay.hud.infoBasePosX + 0.200, courseplay.hud.linesButtonPosY[2] - 0.003, wTemp, hTemp, 2, 3, true);
	courseplay:register_button(self, 9, "shovelPreUnloading.dds", "saveShovelStatus", 4, courseplay.hud.infoBasePosX + 0.200, courseplay.hud.linesButtonPosY[3] - 0.003, wTemp, hTemp, 3, 4, true);
	courseplay:register_button(self, 9, "shovelUnloading.dds",    "saveShovelStatus", 5, courseplay.hud.infoBasePosX + 0.200, courseplay.hud.linesButtonPosY[4] - 0.003, wTemp, hTemp, 4, 5, true);

	courseplay:register_button(self, 9, "blank.dds", "setShovelStopAndGo", nil, courseplay.hud.infoBasePosX, courseplay.hud.linesPosY[5], courseplay.hud.visibleArea.width, 0.015, 5, nil, true);
	--END Page 9


	self.fold_move_direction = 1;

	courseplay:validateCanSwitchMode(self);
	courseplay:buttonsActiveEnabled(self, "all");
end

function courseplay:onLeave()
	if self.cp.mouseCursorActive then
		courseplay:setMouseCursor(self, false);
	end

	--hide visual i3D waypoint signs only when in vehicle
	courseplay:setSignsVisibility(self, false);
end

function courseplay:onEnter()
	if self.cp.mouseCursorActive then
		courseplay:setMouseCursor(self, true);
	end

	if self.drive and self.steeringEnabled then
	  self.steeringEnabled = false
	end

	--show visual i3D waypoint signs only when in vehicle
	courseplay:setSignsVisibility(self);
end

function courseplay:draw()
	if self.dcheck and table.getn(self.Waypoints) > 1 then
		courseplay:dcheck(self);
	end

	--WORKWIDTH DISPLAY
	if self.cp.workWidthChanged > self.timer then
		courseplay:showWorkWidth(self);
	end;

	--KEYBOARD ACTIONS and HELP BUTTON TEXTS
	--Note: located in draw() instead of update() so they're not displayed/executed for *all* vehicles but rather only for *self*
	if self:getIsActive() and self.isEntered then
		local kb = courseplay.inputBindings.keyboard;
		local mouse = courseplay.inputBindings.mouse;

		if (self.play or not self.cp.hud.openWithMouse) and not InputBinding.isPressed(InputBinding.COURSEPLAY_MODIFIER) then
			g_currentMission:addHelpButtonText(courseplay:get_locale(self, "COURSEPLAY_FUNCTIONS"), InputBinding.COURSEPLAY_MODIFIER);
		end;

		if self.cp.hud.show then
			if self.cp.mouseCursorActive then
				g_currentMission:addExtraPrintText(courseplay.inputBindings.mouse.COURSEPLAY_MOUSEACTION_SECONDARY.displayName .. ": " .. courseplay:get_locale(self, "COURSEPLAY_MOUSEARROW_HIDE"));
			else
				g_currentMission:addExtraPrintText(courseplay.inputBindings.mouse.COURSEPLAY_MOUSEACTION_SECONDARY.displayName .. ": " .. courseplay:get_locale(self, "COURSEPLAY_MOUSEARROW_SHOW"));
			end;
		end;

		if self.cp.hud.openWithMouse then
			if not self.cp.hud.show then
				g_currentMission:addExtraPrintText(courseplay.inputBindings.mouse.COURSEPLAY_MOUSEACTION_SECONDARY.displayName .. ": " .. courseplay:get_locale(self, "COURSEPLAY_HUD_OPEN"));
			end;
		else
			if InputBinding.isPressed(InputBinding.COURSEPLAY_MODIFIER) then
				if not self.cp.hud.show then
					g_currentMission:addHelpButtonText(courseplay:get_locale(self, "COURSEPLAY_HUD_OPEN"), InputBinding.COURSEPLAY_HUD);
				else
					g_currentMission:addHelpButtonText(courseplay:get_locale(self, "COURSEPLAY_HUD_CLOSE"), InputBinding.COURSEPLAY_HUD);
				end;
			end;

			if InputBinding.hasEvent(InputBinding.COURSEPLAY_HUD_COMBINED) then
				--courseplay:openCloseHud(self, not self.cp.hud.show);
				self:setCourseplayFunc("openCloseHud", not self.cp.hud.show);
			end;
		end;

		if self.play then
			if self.drive then
				if InputBinding.hasEvent(InputBinding.COURSEPLAY_START_STOP_COMBINED) then
					self:setCourseplayFunc("stop", nil);
				elseif self.cp.HUD1goOn and InputBinding.hasEvent(InputBinding.COURSEPLAY_DRIVEON_COMBINED) then
					self:setCourseplayFunc("drive_on", nil);
				elseif self.cp.HUD1noWaitforFill and InputBinding.hasEvent(InputBinding.COURSEPLAY_DRIVENOW_COMBINED) then
					self:setCourseplayFunc("setIsLoaded", true);
				end;

				if InputBinding.isPressed(InputBinding.COURSEPLAY_MODIFIER) then
					g_currentMission:addHelpButtonText(courseplay:get_locale(self, "CoursePlayStop"), InputBinding.COURSEPLAY_START_STOP);
					if self.cp.HUD1goOn then
						g_currentMission:addHelpButtonText(courseplay:get_locale(self, "CourseWaitpointStart"), InputBinding.COURSEPLAY_DRIVEON);
					end;
					if self.cp.HUD1noWaitforFill then
						g_currentMission:addHelpButtonText(courseplay:get_locale(self, "NoWaitforfill"), InputBinding.COURSEPLAY_DRIVENOW);
					end;
				end;
			else
				if InputBinding.hasEvent(InputBinding.COURSEPLAY_START_STOP_COMBINED) then
					self:setCourseplayFunc("start", nil);
				end;

				if InputBinding.isPressed(InputBinding.COURSEPLAY_MODIFIER) then
					g_currentMission:addHelpButtonText(courseplay:get_locale(self, "CoursePlayStart"), InputBinding.COURSEPLAY_START_STOP);
				end;
			end;
		end;
	end; -- self:getIsActive() and self.isEntered

	--RENDER
	courseplay:renderInfoText(self);
	if g_server ~= nil then
		self.cp.infoText = nil;
	end

	if self:getIsActive() then
		if self.cp.hud.show then
			courseplay:setHudContent(self);
			courseplay:renderHud(self);

			if self.cp.mouseCursorActive then
				InputBinding.setShowMouseCursor(self.cp.mouseCursorActive);
			end;
		end;
	end;
end; --END draw()

function courseplay:showWorkWidth(vehicle)
	local left =  vehicle.cp.workWidthDisplayPoints.left;
	local right = vehicle.cp.workWidthDisplayPoints.right;
	drawDebugPoint(left.x, left.y, left.z, 1, 1, 0, 1);
	drawDebugPoint(right.x, right.y, right.z, 1, 1, 0, 1);
	drawDebugLine(left.x, left.y, left.z, 1, 0, 0, right.x, right.y, right.z, 1, 0, 0);
end;

-- is been called everey frame
function courseplay:update(dt)
	-- we are in record mode
	if self.record then
		courseplay:record(self);
	end

	-- we are in drive mode
	if self.drive then
		courseplay:drive(self, dt);
	end
	 
	if self.cp.onSaveClick and not self.cp.doNotOnSaveClick then
		inputCourseNameDialogue:onSaveClick()
		self.cp.onSaveClick = false
		self.cp.doNotOnSaveClick = false
	end

	if g_server ~= nil  then 
		if self.drive then
			self.cp.HUD1goOn = (self.Waypoints[self.cp.last_recordnumber] ~= nil and self.Waypoints[self.cp.last_recordnumber].wait and self.wait) or (self.cp.stopAtEnd and (self.recordnumber == self.maxnumber or self.cp.currentTipTrigger ~= nil));
			self.cp.HUD1noWaitforFill = not self.loaded and self.cp.aiMode ~= 5;
		end;

		if self.cp.hud.currentPage == 0 then
			local combine = self;
			if self.cp.attachedCombineIdx ~= nil and self.tippers ~= nil and self.tippers[self.cp.attachedCombineIdx] ~= nil then
				combine = self.tippers[self.cp.attachedCombineIdx];
			end;
			if combine.courseplayers == nil then
				self.cp.HUD0noCourseplayer = true
				combine.courseplayers = {};
			else
				self.cp.HUD0noCourseplayer = table.getn(combine.courseplayers) == 0
			end
			self.cp.HUD0wantsCourseplayer = combine.wants_courseplayer
			self.cp.HUD0combineForcedSide = combine.forced_side
			self.cp.HUD0isManual = not self.drive and not combine.isAIThreshing 
			self.cp.HUD0turnStage = self.cp.turnStage
			local tractor = combine.courseplayers[1]
			if tractor ~= nil then
				self.cp.HUD0tractorForcedToStop = tractor.forced_to_stop
				self.cp.HUD0tractorName = tostring(tractor.name)
				self.cp.HUD0tractor = true
			else
				self.cp.HUD0tractorForcedToStop = nil
				self.cp.HUD0tractorName = nil
				self.cp.HUD0tractor = false
			end

		elseif self.cp.hud.currentPage == 1 then
			if not self.play and self.cp.fieldEdge.customField.show and self.cp.fieldEdge.customField.points ~= nil then
				courseplay:showFieldEdgePath(self, "customField");
			end;

		elseif self.cp.hud.currentPage == 4 then
			self.cp.HUD4hasActiveCombine = self.active_combine ~= nil
			if self.cp.HUD4hasActiveCombine == true then
				self.cp.HUD4combineName = self.active_combine.name
			end
			self.cp.HUD4savedCombine = self.saved_combine ~= nil and self.saved_combine.rootNode ~= nil
			if self.saved_combine ~= nil then
			 self.cp.HUD4savedCombineName = self.saved_combine.name
			end

		elseif self.cp.hud.currentPage == 8 then
			if self.cp.fieldEdge.selectedField.show and self.cp.fieldEdge.selectedField.fieldNum > 0 then
				courseplay:showFieldEdgePath(self, "selectedField");
			end;
		end;
	end;


	if g_server ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer then 
		for _,v in pairs(courseplay.checkValues) do
			self.cp[v .. "Memory"] = courseplay:checkForChangeAndBroadcast(self, "self.cp." .. v , self.cp[v], self.cp[v .. "Memory"]);
		end;
	end;
end; --END update()

function courseplay:updateTick(dt)
	if not self.cp.fieldEdge.selectedField.buttonsCreated and courseplay.fields.numAvailableFields > 0 then
		courseplay:createFieldEdgeButtons(self);
	end;

	--attached or detached implement?
	if self.tools_dirty then
		courseplay:reset_tools(self)
	end

	self.timer = self.timer + dt
	--courseplay:debug(string.format("timer: %f", self.timer ), 2)
end

function courseplay:delete()
	if self.aiTrafficCollisionTrigger ~= nil then
		removeTrigger(self.aiTrafficCollisionTrigger);
	end;

	if self.cp ~= nil then
		if self.cp.hud.background ~= nil then
			self.cp.hud.background:delete();
		end;
		if self.cp.directionArrowOverlay ~= nil then
			self.cp.directionArrowOverlay:delete();
		end;
		if self.cp.buttons ~= nil then
			courseplay.button.deleteButtonOverlays(self);
		end;
		if self.cp.globalInfoTextOverlay ~= nil then
			self.cp.globalInfoTextOverlay:delete();
		end;
		if self.cp.signs ~= nil then
			for _,section in pairs(self.cp.signs) do
				for k,signData in pairs(section) do
					courseplay.utils.signs.deleteSign(signData.sign);
				end;
			end;
			self.cp.signs = nil;
		end;
	end;
end;

function courseplay:set_timeout(self, interval)
	self.timeout = self.timer + interval
end


function courseplay:get_locale(self, key)
	return Utils.getNoNil(courseplay.locales[key], key);
end;


function courseplay:readStream(streamId, connection)
	courseplay:debug("id: "..tostring(self.id).."  base: readStream", 5)

	self.cp.aiMode = streamDebugReadInt32(streamId)
	self.cp.turnRadiusAuto = streamDebugReadFloat32(streamId)
	self.cp.combineOffsetAutoMode = streamDebugReadBool(streamId);
	self.cp.combineOffset = streamDebugReadFloat32(streamId)
	self.cp.hasStartingCorner = streamDebugReadBool(streamId);
	self.cp.hasStartingDirection = streamDebugReadBool(streamId);
	self.cp.hasValidCourseGenerationData = streamDebugReadBool(streamId);
	self.cp.headland.numLanes = streamDebugReadInt32(streamId)
	self.cp.infoText = streamDebugReadString(streamId);
	self.cp.returnToFirstPoint = streamDebugReadBool(streamId);
	self.cp.ridgeMarkersAutomatic = streamDebugReadBool(streamId);
	self.cp.shovelStopAndGo = streamDebugReadBool(streamId);
	self.drive = streamDebugReadBool(streamId)
	self.cp.hud.openWithMouse = streamDebugReadBool(streamId)
	self.cp.realisticDriving = streamDebugReadBool(streamId);
	self.cp.driveOnAtFillLevel = streamDebugReadFloat32(streamId)
	self.cp.followAtFillLevel = streamDebugReadFloat32(streamId)
	self.cp.tipperOffset = streamDebugReadFloat32(streamId)
	self.cp.workWidth = streamDebugReadFloat32(streamId) 
	self.cp.turnRadiusAutoMode = streamDebugReadBool(streamId);
	self.cp.turnRadius = streamDebugReadFloat32(streamId)
	self.cp.speeds.useRecordingSpeed = streamDebugReadBool(streamId) 
	self.cp.coursePlayerNum = streamReadFloat32(streamId)
	self.cp.laneOffset = streamDebugReadFloat32(streamId)
	self.cp.toolOffsetX = streamDebugReadFloat32(streamId)
	self.cp.toolOffsetZ = streamDebugReadFloat32(streamId)
	self.cp.hud.currentPage = streamDebugReadInt32(streamId)
	self.cp.HUD0noCourseplayer = streamDebugReadBool(streamId)
	self.cp.HUD0wantsCourseplayer = streamDebugReadBool(streamId)
	self.cp.HUD0combineForcedSide = streamDebugReadString(streamId);
	self.cp.HUD0isManual = streamDebugReadBool(streamId)
	self.cp.HUD0turnStage = streamDebugReadInt32(streamId)
	self.cp.HUD0tractorForcedToStop = streamDebugReadBool(streamId)
	self.cp.HUD0tractorName = streamDebugReadString(streamId);
	self.cp.HUD0tractor = streamDebugReadBool(streamId)
	self.cp.HUD1goON = streamDebugReadBool(streamId)
	self.cp.HUD1noWaitforFill = streamDebugReadBool(streamId)
	self.cp.HUD4hasActiveCombine = streamDebugReadBool(streamId)
	self.cp.HUD4combineName = streamDebugReadString(streamId);
	self.cp.HUD4savedCombine = streamDebugReadBool(streamId)
	self.cp.HUD4savedCombineName = streamDebugReadString(streamId);

	local saved_combine_id = streamDebugReadInt32(streamId)
	if saved_combine_id then
		self.saved_combine = networkGetObject(saved_combine_id)
	end

	local active_combine_id = streamDebugReadInt32(streamId)
	if active_combine_id then
		self.active_combine = networkGetObject(active_combine_id)
	end

	local current_trailer_id = streamDebugReadInt32(streamId)
	if current_trailer_id then
		self.currentTrailerToFill = networkGetObject(current_trailer_id)
	end

	local unloading_tipper_id = streamDebugReadInt32(streamId)
	if unloading_tipper_id then
		self.unloading_tipper = networkGetObject(unloading_tipper_id)
	end

	courseplay:reinit_courses(self)


	-- kurs daten
	local courses = streamDebugReadString(streamId) -- 60.
	if courses ~= nil then
		self.loaded_courses = Utils.splitString(",", courses);
		courseplay:reload_courses(self, true)
	end

	local debugChannelsString = streamDebugReadString(streamId)
	for k,v in pairs(Utils.splitString(",", debugChannelsString)) do
		courseplay.debugChannels[k] = v == "true";
	end;
end

function courseplay:writeStream(streamId, connection)
	courseplay:debug("id: "..tostring(networkGetObjectId(self)).."  base: write stream", 5)

	streamDebugWriteInt32(streamId,self.cp.aiMode)
	streamDebugWriteFloat32(streamId,self.cp.turnRadiusAuto)
	streamWriteBool(streamId, self.cp.combineOffsetAutoMode);
	streamDebugWriteFloat32(streamId,self.cp.combineOffset)
	streamWriteFloat32(streamId, self.cp.globalInfoTextLevel);
	streamDebugWriteBool(streamId, self.cp.hasStartingCorner);
	streamDebugWriteBool(streamId, self.cp.hasStartingDirection);
	streamDebugWriteBool(streamId, self.cp.hasValidCourseGenerationData);
	streamDebugWriteInt32(streamId,self.cp.headland.numLanes);
	streamDebugWriteString(streamId, self.cp.infoText);
	streamDebugWriteBool(streamId, self.cp.returnToFirstPoint);
	streamDebugWriteBool(streamId, self.cp.ridgeMarkersAutomatic);
	streamDebugWriteBool(streamId, self.cp.shovelStopAndGo);
	streamDebugWriteBool(streamId,self.drive)
	streamDebugWriteBool(streamId,self.cp.hud.openWithMouse)
	streamDebugWriteBool(streamId, self.cp.realisticDriving);
	streamDebugWriteFloat32(streamId,self.cp.driveOnAtFillLevel)
	streamDebugWriteFloat32(streamId,self.cp.followAtFillLevel)
	streamDebugWriteFloat32(streamId,self.cp.tipperOffset)
	streamDebugWriteFloat32(streamId,self.cp.workWidth);
	streamDebugWriteBool(streamId,self.cp.turnRadiusAutoMode)
	streamDebugWriteFloat32(streamId,self.cp.turnRadius)
	streamDebugWriteBool(streamId,self.cp.speeds.useRecordingSpeed)
	streamDebugWriteFloat32(streamId,self.cp.coursePlayerNum);
	streamDebugWriteFloat32(streamId,self.cp.laneOffset)
	streamDebugWriteFloat32(streamId,self.cp.toolOffsetX)
	streamDebugWriteFloat32(streamId,self.cp.toolOffsetZ)
	streamDebugWriteInt32(streamId,self.cp.hud.currentPage)
	streamDebugWriteBool(streamId,self.cp.HUD0noCourseplayer)
	streamDebugWriteBool(streamId,self.cp.HUD0wantsCourseplayer)
	streamDebugWriteString(streamId,self.cp.HUD0combineForcedSide)
	streamDebugWriteBool(streamId,self.cp.HUD0isManual)
	streamDebugWriteInt32(streamId,self.cp.HUD0turnStage)
	streamDebugWriteBool(streamId,self.cp.HUD0tractorForcedToStop)
	streamDebugWriteString(streamId,self.cp.HUD0tractorName)
	streamDebugWriteBool(streamId,self.cp.HUD0tractor)
	streamDebugWriteBool(streamId,self.cp.HUD1goON)
	streamDebugWriteBool(streamId,self.cp.HUD1noWaitforFill)
	streamDebugWriteBool(streamId,self.cp.HUD4hasActiveCombine)
	streamDebugWriteString(streamId,self.cp.HUD4combineName)
	streamDebugWriteBool(streamId,self.cp.HUD4savedCombine)
	streamDebugWriteString(streamId,self.cp.HUD4savedCombineName)

	local saved_combine_id = nil
	if self.saved_combine ~= nil then
		saved_combine_id = networkGetObject(self.saved_combine)
	end
	streamDebugWriteInt32(streamId, saved_combine_id)

	local active_combine_id = nil
	if self.active_combine ~= nil then
		active_combine_id = networkGetObject(self.active_combine)
	end
	streamDebugWriteInt32(streamId, active_combine_id)

	local current_trailer_id = nil
	if self.currentTrailerToFill ~= nil then
		current_trailer_id = networkGetObject(self.currentTrailerToFill)
	end
	streamDebugWriteInt32(streamId, current_trailer_id)

	local unloading_tipper_id = nil
	if self.unloading_tipper ~= nil then
		unloading_tipper_id = networkGetObject(self.unloading_tipper)
	end
	streamDebugWriteInt32(streamId, unloading_tipper_id)

	local loaded_courses = nil
	if table.getn(self.loaded_courses) then
		loaded_courses = table.concat(self.loaded_courses, ",")
	end
	streamDebugWriteString(streamId, loaded_courses) -- 60.

	local debugChannelsString = table.concat(table.map(courseplay.debugChannels, tostring), ",");
	streamDebugWriteString(streamId, debugChannelsString) 

end


function courseplay:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	if not resetVehicles and g_server ~= nil then
		--courseplay
		local curKey = key .. '.courseplay';
		courseplay:setAiMode(self, Utils.getNoNil(getXMLInt(xmlFile, curKey .. '#aiMode'), 1));
		self.cp.hud.openWithMouse = Utils.getNoNil(getXMLBool(xmlFile, curKey .. '#openHudWithMouse'), true);
		self.cp.beaconLightsMode = Utils.getNoNil(getXMLInt(xmlFile, curKey .. "#beacon"), 1);
		self.cp.waitTime = Utils.getNoNil(getXMLInt(xmlFile, curKey .. "#waitTime"), 0);
		local courses = Utils.getNoNil(getXMLString(xmlFile, curKey .. '#courses'), '');
		self.loaded_courses = Utils.splitString(",", courses);
		self.selected_course_number = 0;
		courseplay:reload_courses(self, true);

		--speeds
		curKey = key .. '.courseplay.speeds';
		self.cp.speeds.useRecordingSpeed = Utils.getNoNil(getXMLBool(xmlFile, curKey .. '#useRecordingSpeed'), true);
		self.cp.speeds.unload = Utils.getNoNil(getXMLFloat(xmlFile, curKey .. '#unload'), 6/3600);
		self.cp.speeds.turn = Utils.getNoNil(getXMLFloat(xmlFile, curKey .. '#turn'), 10/3600);
		self.cp.speeds.field = Utils.getNoNil(getXMLFloat(xmlFile, curKey .. '#field'), 24/3600);
		self.cp.speeds.max = Utils.getNoNil(getXMLFloat(xmlFile, curKey .. '#max'), 50/3600);

		--mode 2
		curKey = key .. '.courseplay.combi';
		self.cp.tipperOffset = Utils.getNoNil(getXMLFloat(xmlFile, curKey .. '#tipperOffset'), 0);
		self.cp.combineOffset = Utils.getNoNil(getXMLFloat(xmlFile, curKey .. '#combineOffset'), 0);
		self.cp.followAtFillLevel = Utils.getNoNil(getXMLInt(xmlFile, curKey .. '#fillFollow'), 50);
		self.cp.driveOnAtFillLevel = Utils.getNoNil(getXMLInt(xmlFile, curKey .. '#fillDriveOn'), 90);
		self.cp.turnRadius = Utils.getNoNil(getXMLInt(xmlFile, curKey .. '#turnRadius'), 10);
		self.cp.realisticDriving = Utils.getNoNil(getXMLBool(xmlFile, curKey .. '#realisticDriving'), true);

		--modes 4 / 6
		curKey = key .. '.courseplay.fieldWork';
		self.cp.workWidth = Utils.getNoNil(getXMLFloat(xmlFile, curKey .. '#workWidth'), 3);
		self.cp.ridgeMarkersAutomatic = Utils.getNoNil(getXMLBool(xmlFile, curKey .. '#ridgeMarkersAutomatic'), true);
		self.cp.abortWork = Utils.getNoNil(getXMLInt(xmlFile, curKey .. '#abortWork'), 0);
		if self.cp.abortWork == 0 then
			self.cp.abortWork = nil;
		end;
		local offsetData = Utils.getNoNil(getXMLString(xmlFile, curKey .. '#offsetData'), '0;0;0;false'); -- 1=laneOffset, 2=toolOffsetX, 3=toolOffsetZ, 4=symmetricalLaneChange
		offsetData = Utils.splitString(';', offsetData);
		courseplay:changeLaneOffset(self, nil, tonumber(offsetData[1]));
		courseplay:changeToolOffsetX(self, nil, tonumber(offsetData[2]), true);
		courseplay:changeToolOffsetZ(self, nil, tonumber(offsetData[3]));
		courseplay:toggleSymmetricLaneChange(self, offsetData[4] == 'true');

		--shovel rots
		curKey = key .. '.courseplay.shovel';
		local shovelRots = getXMLString(xmlFile, curKey .. '#rots');
		if shovelRots ~= nil then
			courseplay:debug(tableShow(self.cp.shovelStateRot, nameNum(self) .. ' shovelStateRot (before loading)', 10), 10);
			self.cp.shovelStateRot = {};
			local shovelStates = Utils.splitString(';', shovelRots);
			if #(shovelStates) == 4 then
				for i=1,4 do
					local shovelStateSplit = table.map(Utils.splitString(' ', shovelStates[i]), tonumber);
					self.cp.shovelStateRot[tostring(i+1)] = shovelStateSplit;
				end;
				courseplay:debug(tableShow(self.cp.shovelStateRot, nameNum(self) .. ' shovelStateRot (after loading)', 10), 10);
				courseplay:buttonsActiveEnabled(self, 'shovel');
			end;
		end;

		--combine
		if self.cp.isCombine then
			curKey = key .. '.courseplay.combine';
			self.cp.driverPriorityUseFillLevel = Utils.getNoNil(getXMLBool(xmlFile, curKey .. '#driverPriorityUseFillLevel'), false);
		end;


		courseplay:validateCanSwitchMode(self);
	end;
	return BaseMission.VEHICLE_LOAD_OK;
end


function courseplay:getSaveAttributesAndNodes(nodeIdent)
	local attributes = "";

	--Shovel positions
	local shovelRotsTmp, shovelRotsAttrNodes = {}, "";
	local hasAllShovelRots = self.cp.shovelStateRot ~= nil and self.cp.shovelStateRot["2"] ~= nil and self.cp.shovelStateRot["3"] ~= nil and self.cp.shovelStateRot["4"] ~= nil and self.cp.shovelStateRot["5"] ~= nil;
	if hasAllShovelRots then
		courseplay:debug(tableShow(self.cp.shovelStateRot, nameNum(self) .. " shovelStateRot (before saving)", 10), 10);
		local shovelStateRotSaveTable = {};
		for a=1,4 do
			shovelStateRotSaveTable[a] = {};
			local rotTable = self.cp.shovelStateRot[tostring(a+1)];
			for i=1,table.getn(rotTable) do
				shovelStateRotSaveTable[a][i] = courseplay:round(rotTable[i], 4);
			end;
			table.insert(shovelRotsTmp, tostring(table.concat(shovelStateRotSaveTable[a], " ")));
		end;
		if table.getn(shovelRotsTmp) > 0 then
			shovelRotsAttrNodes = tostring(table.concat(shovelRotsTmp, ";"));
			courseplay:debug(nameNum(self) .. ": shovelRotsAttrNodes=" .. shovelRotsAttrNodes, 10);
		end;
	end;

	--Offset data
	local offsetData = string.format('%.1f;%.1f;%.1f;%s', self.cp.laneOffset, self.cp.toolOffsetX, self.cp.toolOffsetZ, tostring(self.cp.symmetricLaneChange));


	--NODES
	local cpOpen = string.format('<courseplay aiMode="%s" courses="%s" openHudWithMouse="%s" beacon="%s" waitTime="%s">', tostring(self.cp.aiMode), tostring(table.concat(self.loaded_courses, ",")), tostring(self.cp.hud.openWithMouse), tostring(self.cp.beaconLightsMode), tostring(self.cp.waitTime));
	local speeds = string.format('<speeds useRecordingSpeed="%s" unload="%.5f" turn="%.5f" field="%.5f" max="%.5f" />', tostring(self.cp.speeds.useRecordingSpeed), self.cp.speeds.unload, self.cp.speeds.turn, self.cp.speeds.field, self.cp.speeds.max);
	local combi = string.format('<combi tipperOffset="%.1f" combineOffset="%.1f" fillFollow="%d" fillDriveOn="%d" turnRadius="%d" realisticDriving="%s" />', self.cp.tipperOffset, self.cp.combineOffset, self.cp.followAtFillLevel, self.cp.driveOnAtFillLevel, self.cp.turnRadius, tostring(self.cp.realisticDriving));
	local fieldWork = string.format('<fieldWork workWidth="%.1f" ridgeMarkersAutomatic="%s" offsetData="%s" abortWork="%d" />', self.cp.workWidth, tostring(self.cp.ridgeMarkersAutomatic), offsetData, Utils.getNoNil(self.cp.abortWork, 0));
	local shovels, combine = "", "";
	if hasAllShovelRots then
		shovels = string.format('<shovel rots="%s" />', shovelRotsAttrNodes);
	end;
	if self.cp.isCombine then
		combine = string.format('<combine driverPriorityUseFillLevel="%s" />', tostring(self.cp.driverPriorityUseFillLevel));
	end;
	local cpClose = '</courseplay>';

	indent = '   ';
	local nodes = nodeIdent .. cpOpen .. '\n';
	nodes = nodes .. nodeIdent .. indent .. speeds .. '\n';
	nodes = nodes .. nodeIdent .. indent .. combi .. '\n';
	nodes = nodes .. nodeIdent .. indent .. fieldWork .. '\n';
	if hasAllShovelRots then
		nodes = nodes .. nodeIdent .. indent .. shovels .. '\n';
	end;
	if self.cp.isCombine then
		nodes = nodes .. nodeIdent .. indent .. combine .. '\n';
	end;
	nodes = nodes .. nodeIdent .. cpClose;

	courseplay:debug(nameNum(self) .. ": getSaveAttributesAndNodes(): nodes\n" .. nodes, 10)

	return attributes, nodes;
end

