function courseplay:handle_mode6(self, allowedToDrive, workArea, workSpeed, fill_level, last_recordnumber, lx , lz )
	local workTool --= self.tippers[1] -- to do, quick, dirty and unsafe
	local active_tipper = nil
	local specialTool = false

	--[[
	if self.attachedCutters ~= nil then
		for cutter, implement in pairs(self.attachedCutters) do
			AICombine.addCutterTrigger(self, cutter);
		end;
	end;
	--]]

	workArea = (self.recordnumber > self.startWork) and (self.recordnumber < self.stopWork)

	if workArea then
		workSpeed = 1;
	end
	if (self.recordnumber == self.stopWork or last_recordnumber == self.stopWork) and self.abortWork == nil and not self.loaded then
		allowedToDrive = false
		courseplay:setGlobalInfoText(self, courseplay:get_locale(self, "CPWorkEnd"), 1);
	end
	
	local returnToStartPoint = false;
	if  self.Waypoints[self.stopWork].cx == self.Waypoints[self.startWork].cx 
	and self.Waypoints[self.stopWork].cz == self.Waypoints[self.startWork].cz 
	and self.recordnumber > self.stopWork - 5
	and self.recordnumber <= self.stopWork then
		returnToStartPoint = true;
	end;
	
	--calculate total fillLevel for UBT (in case of multiple trailers)
	local hasUBT = false;
	local fillLevelUBT = 0;
	for i=1, table.getn(self.tippers) do
		if courseplay:isUBT(self.tippers[i]) then
			hasUBT = true;
			fillLevelUBT = fillLevelUBT + (self.tippers[i].fillLevel * 100 / self.tippers[i].fillLevelMax);
		end;
	end;
	if hasUBT then 
		fill_level = fillLevelUBT;
	end;
	--END UBT fillLevel


	for i=1, table.getn(self.tippers) do
		workTool = self.tippers[i];
		local tool = self
		if courseplay:isAttachedCombine(workTool) then
			tool = workTool
		end
		
		-- stop while folding
		if courseplay:isFoldable(workTool) then
			if courseplay:isFolding(workTool) and self.cp.turnStage == 0 then 
				allowedToDrive = false;
				--courseplay:debug(tostring(workTool.name) .. ": isFolding -> allowedToDrive == false", 3);
			end;
		end;

		-- implements, no combine or chopper
		if workTool ~= nil and tool.grainTankCapacity == nil then
			-- balers
			if courseplay:isBaler(workTool) then
				if self.recordnumber >= self.startWork + 1 and self.recordnumber < self.stopWork then
					-- automatic opening for balers
					if workTool.balerUnloadingState ~= nil then
						if courseplay:isRoundbaler(workTool) and fill_level > 95 and fill_level < 100 and workTool.balerUnloadingState == Baler.UNLOADING_CLOSED then
							workSpeed = 0.5;
						elseif fill_level == 100 and workTool.balerUnloadingState == Baler.UNLOADING_CLOSED then
							allowedToDrive = false
							workTool:setIsTurnedOn(false, false);
							if table.getn(workTool.bales) > 0 then
								workTool:setIsUnloadingBale(true, false)
							end
						elseif workTool.balerUnloadingState ~= Baler.UNLOADING_CLOSED then
							allowedToDrive = false
							if workTool.balerUnloadingState == Baler.UNLOADING_OPEN then
								workTool:setIsUnloadingBale(false)
							end
						elseif fill_level >= 0 and not workTool.isTurnedOn and workTool.balerUnloadingState == Baler.UNLOADING_CLOSED then
							workTool:setIsTurnedOn(true, false);
						end
					end
				end
				
				if last_recordnumber == self.stopWork -1  and workTool.isTurnedOn and workTool.balerUnloadingState == Baler.UNLOADING_CLOSED then
					workTool:setIsTurnedOn(false, false);
				end
			-- baleloader, copied original code parts				
			elseif courseplay:is_baleLoader(workTool) or courseplay:isUBT(workTool) then
				if not courseplay:isUBT(workTool) then
					if workArea then
						-- automatic stop for baleloader
						if workTool.grabberIsMoving or workTool:getIsAnimationPlaying("rotatePlatform") then
							allowedToDrive = false
						end
						if not workTool.isInWorkPosition and fill_level ~= 100 then
							--g_client:getServerConnection():sendEvent(BaleLoaderStateEvent:new(workTool, BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT));
							workTool.grabberIsMoving = true
							workTool.isInWorkPosition = true
							BaleLoader.moveToWorkPosition(workTool)
						end
					end

					if (fill_level == 100 and self.maxnumber ~= self.stopWork or self.recordnumber == self.stopWork) and workTool.isInWorkPosition and not workTool:getIsAnimationPlaying("rotatePlatform") then
						workTool.grabberIsMoving = true
						workTool.isInWorkPosition = false
						-- move to transport position
						BaleLoader.moveToTransportPosition(workTool)
					end

					if fill_level == 100 and self.maxnumber == self.stopWork then
						allowedToDrive = false
						courseplay:setGlobalInfoText(self, courseplay:get_locale(self, "CPUnloadBale"));
					end

					-- automatic unload
					if self.Waypoints[last_recordnumber].wait and (self.wait or fill_level == 0) then
						if not courseplay:isUBT(workTool) then
							if workTool.emptyState ~= BaleLoader.EMPTY_NONE then
								if workTool.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
									-- BaleLoader.CHANGE_DROP_BALES
									g_server:broadcastEvent(BaleLoaderStateEvent:new(workTool, BaleLoader.CHANGE_DROP_BALES), true, nil, workTool)
								elseif workTool.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
									-- BaleLoader.CHANGE_SINK
									g_server:broadcastEvent(BaleLoaderStateEvent:new(workTool, BaleLoader.CHANGE_SINK), true, nil, workTool)
								elseif workTool.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
									-- BaleLoader.CHANGE_EMPTY_REDO
									g_server:broadcastEvent(BaleLoaderStateEvent:new(workTool, BaleLoader.CHANGE_EMPTY_REDO), true, nil, workTool);
								end
							else
								--BaleLoader.CHANGE_EMPTY_START
								if BaleLoader.getAllowsStartUnloading(workTool) then
									g_server:broadcastEvent(BaleLoaderStateEvent:new(workTool, BaleLoader.CHANGE_EMPTY_START), true, nil, workTool)
								end
							end
						end;
					end;				
				
				elseif courseplay:isUBT(workTool) then
					if not workTool.fillLevelMax == workTool.numAttachers[workTool.typeOnTrailer] then
						workTool.fillLevelMax = workTool.numAttachers[workTool.typeOnTrailer];
					end;
					if workTool.capacity == nil or (workTool.capacity ~= nil and workTool.capacity ~= workTool.fillLevelMax) then
						workTool.capacity = workTool.fillLevelMax;
					end;
					
					if workArea then
						if (workTool.fillLevel == workTool.fillLevelMax or (workTool.capacity ~= nil and workTool.fillLevel == workTool.capacity) or fill_level == 100) then
							if self.maxnumber == self.stopWork then
								if workTool.loadingIsActive then
									workTool.loadingIsActive = false;
								end;

								allowedToDrive = false;
								courseplay:setGlobalInfoText(self, "UBT " .. courseplay:get_locale(self, "CPUnloadBale"));
							end;
							--print("UBT is full (" .. tostring(workTool.fillLevel) .. "/" .. tostring(workTool.fillLevelMax) .. ")"); -- WORKS
						else
							if not workTool.loadingIsActive then
								--print("UBT activating loadingIsActive"); -- WORKS
								workTool.loadingIsActive = true;
							end;
						end;
						
						if not workTool.autoLoad then
							--print("UBT activating autoLoad"); -- WORKS
							workTool.autoLoad = true;
						end;
					else
						if workTool.loadingIsActive then
							workTool.loadingIsActive = false;
						end;

						-- automatic unload
						if self.Waypoints[last_recordnumber].wait and (self.wait or fill_level == 0 or workTool.fillLevel == 0) then
							--call unload function
							for i=1, workTool.numAttachers[workTool.typeOnTrailer] do
								if workTool.attacher[workTool.typeOnTrailer][i].attachedObject ~= nil then

									--ORIG: if workTool.ulRef[workTool.ulMode][1] == g_i18n:getText("UNLOAD_TRAILER") then
									if workTool.ulRef[workTool.ulMode][3] == 0 then --verrrrry dirty: unload on trailer
										local x,y,z = getWorldTranslation(workTool.attacher[workTool.typeOnTrailer][i].attachedObject);
										local rx,ry,rz = getWorldRotation(workTool.attacher[workTool.typeOnTrailer][i].attachedObject);
										local root = getRootNode();
										setRigidBodyType(workTool.attacher[workTool.typeOnTrailer][i].attachedObject,"Dynamic");
										setTranslation(workTool.attacher[workTool.typeOnTrailer][i].attachedObject,x,y,z);
										setRotation(workTool.attacher[workTool.typeOnTrailer][i].attachedObject,rx,ry,rz);
										link(root,workTool.attacher[workTool.typeOnTrailer][i].attachedObject);
										workTool.attacher[workTool.typeOnTrailer][i].attachedObject = nil;
										workTool.fillLevel = workTool.fillLevel - 1;
									else
										local x,y,z = getWorldTranslation(workTool.attacher[workTool.typeOnTrailer][i].attachedObject);
										local rx,ry,rz = getWorldRotation(workTool.attacher[workTool.typeOnTrailer][i].attachedObject);
										local nx,ny,nz = getWorldTranslation(workTool.attacherLevel[workTool.typeOnTrailer]);
										local tx,ty,tz = getWorldTranslation(workTool.ulRef[workTool.ulMode][3]);
										local x = x + (tx - nx);
										local y = y + (ty - ny);
										local z = z + (tz - nz);
										local tH = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z);
										local relHeight = ny - tH;
										local root = getRootNode();
										setRigidBodyType(workTool.attacher[workTool.typeOnTrailer][i].attachedObject,"Dynamic");
										setTranslation(workTool.attacher[workTool.typeOnTrailer][i].attachedObject,x,(y - relHeight),z);
										setRotation(workTool.attacher[workTool.typeOnTrailer][i].attachedObject,rx,ry,rz);
										link(root,workTool.attacher[workTool.typeOnTrailer][i].attachedObject);
										workTool.attacher[workTool.typeOnTrailer][i].attachedObject = nil;
										workTool.fillLevel = workTool.fillLevel - 1;
									end;
								end;
							end;
						end;				
					
					end;
				end;
			--END baleloader	


			-- other worktools, tippers, e.g. forage wagon	
			else
				if workArea and fill_level ~= 100 and ((self.abortWork == nil) or (self.abortWork ~= nil and last_recordnumber == self.abortWork) or (self.runOnceStartCourse)) and self.cp.turnStage == 0  and not returnToStartPoint then
								--courseplay:handleSpecialTools(self,workTool,unfold,lower,turnOn,allowedToDrive,cover,unload)
					specialTool, allowedToDrive = courseplay:handleSpecialTools(self,workTool,true,true,true,allowedToDrive,nil,nil)
					if allowedToDrive then
						if not specialTool then
							--unfold
							local recordnumber = math.min(self.recordnumber+2 ,self.maxnumber)
							local forecast = Utils.getNoNil(self.Waypoints[recordnumber].ridgeMarker,0)
							local marker = Utils.getNoNil(self.Waypoints[self.recordnumber].ridgeMarker,0)
							local waypoint = math.max(marker,forecast)
							if courseplay:isFoldable(workTool) and not courseplay:isFolding(workTool) then
								if not SpecializationUtil.hasSpecialization(Plough, workTool.specializations) then
									workTool:setFoldDirection(-1);
									self.runOnceStartCourse = false; 
								elseif waypoint == 2 and self.runOnceStartCourse then --wegpunkte finden und richtung setzen...
									workTool:setFoldDirection(-1);
									if workTool:getIsPloughRotationAllowed() then
										AITractor.aiRotateLeft(self);
										self.runOnceStartCourse = false;
									end
								elseif self.runOnceStartCourse then
									workTool:setFoldDirection(-1);
									self.runOnceStartCourse = false; 
								end
							end;
							

							if not courseplay:isFolding(workTool) and not waitForSpecialTool then
								--lower
								if workTool.needsLowering and workTool.aiNeedsLowering then
									self:setAIImplementsMoveDown(true);
								end;
							
								--turn on
								if workTool.setIsTurnedOn ~= nil and not workTool.isTurnedOn then
									workTool:setIsTurnedOn(true, false);
									self.runOnceStartCourse = false
									courseplay:setMarkers(self, workTool);
								end;

								if workTool.setIsPickupDown ~= nil then
									if self.pickup.isDown == nil or (self.pickup.isDown ~= nil and not self.pickup.isDown) then
										workTool:setIsPickupDown(true, false);
									end;
								end;
							end;
						end;
					end
				elseif not workArea or self.abortWork ~= nil or self.loaded or last_recordnumber == self.stopWork or returnToStartPoint then
					workSpeed = 0;
					specialTool, allowedToDrive = courseplay:handleSpecialTools(self,workTool,false,false,false,allowedToDrive,nil,nil)
					if not specialTool then
						if not courseplay:isFolding(workTool) then
							--turn off
							if workTool.setIsTurnedOn ~= nil and workTool.isTurnedOn then
								workTool:setIsTurnedOn(false, false);
							end;
							if workTool.setIsPickupDown ~= nil then
								if self.pickup.isDown == nil or (self.pickup.isDown ~= nil and self.pickup.isDown) then
									workTool:setIsPickupDown(false, false);
								end;
							end;

							--raise
							if workTool.needsLowering and workTool.aiNeedsLowering and self.cp.turnStage == 0 then
								self:setAIImplementsMoveDown(false);
							end;
						end;

						--fold
						if courseplay:isFoldable(workTool) then
							workTool:setFoldDirection(1);
							--workTool:setFoldDirection(-workTool.turnOnFoldDirection);
						end;
					end;
				end;

				-- done tipping
				local tipper_fill_level, tipper_capacity = self:getAttachedTrailersFillLevelAndCapacity()

				if tipper_fill_level ~= nil and tipper_capacity ~= nil then
					if self.unloading_tipper ~= nil and self.unloading_tipper.fillLevel == 0 then
						self.unloading_tipper = nil

						if tipper_fill_level == 0 then
							self.unloaded = true
							self.max_speed_level = 3
							self.currentTipTrigger = nil
						end
					end

					-- damn, i missed the trigger!
					if self.currentTipTrigger ~= nil then
						local trigger_id = self.currentTipTrigger.triggerId

						if self.currentTipTrigger.specialTriggerId ~= nil then
							trigger_id = self.currentTipTrigger.specialTriggerId
						end

						local trigger_x, trigger_y, trigger_z = getWorldTranslation(trigger_id)
						local ctx, cty, ctz = getWorldTranslation(self.rootNode);
						local distance_to_trigger = courseplay:distance(ctx, ctz, trigger_x, trigger_z)
						if distance_to_trigger > 60 then
							self.currentTipTrigger = nil
						end
					end

					-- tipper is not empty and tractor reaches TipTrigger
					if tipper_fill_level > 0 and self.currentTipTrigger ~= nil and self.recordnumber > 3 then
						self.max_speed_level = 1
						allowedToDrive, active_tipper = courseplay:unload_tippers(self)
						self.cp.infoText = courseplay:get_locale(self, "CPTriggerReached") -- "Abladestelle erreicht"		
					end
				end;
			end; --END other tools

			-- Begin Work   or goto abortWork
			if last_recordnumber == self.startWork and fill_level ~= 100 then
				if self.abortWork ~= nil then
					if self.abortWork < 5 then
						self.abortWork = 6
					end
					self.recordnumber = self.abortWork 
					if self.recordnumber < 2 then
						self.recordnumber = 2
					end
				end
			end
			-- last point reached restart
			if self.abortWork ~= nil then
				if (last_recordnumber == self.abortWork ) and fill_level ~= 100 then
					self.recordnumber = self.abortWork + 2  -- drive to waypoint after next waypoint
					self.abortWork = nil
				end
			end
			-- safe last point
			if (fill_level == 100 or self.loaded) and workArea and self.abortWork == nil and self.maxnumber ~= self.stopWork and not courseplay:isBaler(workTool) then
				self.abortWork = last_recordnumber - 10
				self.recordnumber = self.stopWork - 4
				if self.recordnumber < 1 then
					self.recordnumber = 1
				end
				--	courseplay:debug(string.format("Abort: %d StopWork: %d",self.abortWork,self.stopWork), 2)
			end;
			
		else  --COMBINES
		
			--Start combine
			local pipeState = tool:getCombineTrailerInRangePipeState();
			if workArea and not tool.isAIThreshing and self.abortWork == nil and self.cp.turnStage == 0 then
				specialTool, allowedToDrive = courseplay:handleSpecialTools(self,workTool,true,true,true,allowedToDrive,nil,nil)
				if not specialTool then
					local weatherStop = not tool:getIsThreshingAllowed(true)
					if tool.grainTankCapacity == 0 then
						if courseplay:isFoldable(workTool) and not tool.isThreshing then
							if workTool.cp.inversedFoldDirection then
								workTool:setFoldDirection(1);
							else
								workTool:setFoldDirection(-1);
							end;
						end;
						if not courseplay:isFolding(workTool) and not tool.isThreshing then
							tool:setIsThreshing(true, true);
							if pipeState > 0 then
								tool:setPipeState(pipeState);
							else
								tool:setPipeState(2);
							end;
						end
						if pipeState == 0 and self.cp.turnStage == 0 then
							tool.cp.waitingForTrailerToUnload = true
						end
					else
						if courseplay:isFoldable(workTool) and not tool.isThreshing then
							workTool:setFoldDirection(-1);
						end;
						if not courseplay:isFolding(workTool) and tool.grainTankFillLevel < tool.grainTankCapacity and not tool.waitingForDischarge and not tool.isThreshing and not weatherStop then
							tool:setIsThreshing(true, true);
						end
						
						if tool.grainTankFillLevel >= tool.grainTankCapacity or tool.waitingForDischarge then
							tool.waitingForDischarge = true
							allowedToDrive = false;
							tool:setIsThreshing(false, true);
							if tool.grainTankFillLevel < tool.grainTankCapacity*0.8 then
								tool.waitingForDischarge = false
							end
						end

						if weatherStop then
							allowedToDrive = false;
							tool:setIsThreshing(false, true);
							courseplay:setGlobalInfoText(self, courseplay:get_locale(self, "CPwaitingForWeather"));
						end
							
					end
				end
			 --Stop combine
			elseif self.recordnumber == self.stopWork then 
				local isEmpty = tool.grainTankFillLevel == 0
				if self.abortWork == nil then
					allowedToDrive = false;
				end
				if isEmpty then
					specialTool, allowedToDrive = courseplay:handleSpecialTools(self,workTool,false,false,false,allowedToDrive,nil)
				else
					specialTool, allowedToDrive = courseplay:handleSpecialTools(self,workTool,true,false,false,allowedToDrive,nil)
				end
				if not specialTool then
					tool:setIsThreshing(false, true);
					if courseplay:isFoldable(workTool) and isEmpty then
						if workTool.cp.inversedFoldDirection then
							workTool:setFoldDirection(-1);
						else
							workTool:setFoldDirection(1);
						end;
					end;
					tool:setPipeState(1)
				end
			end
			
			if tool.cp.isCombine and tool.isThreshing and tool.grainTankFillLevel >= tool.grainTankCapacity*0.8  or pipeState > 0 or courseplay:isAttachedCombine(workTool) then
				tool:setPipeState(2)
			elseif  pipeState == 0 then 
				tool:setPipeState(1)
			end
			if tool.cp.waitingForTrailerToUnload then
				allowedToDrive = false;
				if tool.cp.isCombine or courseplay:isAttachedCombine(workTool) then
					if tool.isCheckedIn == nil or (pipeState == 0 and tool.grainTankFillLevel == 0) then
						tool.cp.waitingForTrailerToUnload = false
					end
				elseif tool.cp.isChopper then
					if (tool.pipeParticleSystems[9].isEmitting or pipeState > 0) then
						self.cp.waitingForTrailerToUnload = false
					end
				end
			end

			local dx,_,dz = localDirectionToWorld(self.cp.DirectionNode, 0, 0, 1);
			local length = Utils.vector2Length(dx,dz);
			if self.cp.turnStage == 0 then
				self.aiThreshingDirectionX = dx/length;
				self.aiThreshingDirectionZ = dz/length;
			else
				self.aiThreshingDirectionX = -(dx/length);
				self.aiThreshingDirectionZ = -(dz/length);
			end				
			
		end
	end; --END for i in self.tippers
	
	return allowedToDrive, workArea, workSpeed, active_tipper
end