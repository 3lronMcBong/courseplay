
function courseplay:isSpecialSprayer(workTool)
	return	Utils.endsWith(workTool.configFileName, "Abbey_AP900.xml") 
		or Utils.endsWith(workTool.configFileName, "Abbey_3000R.xml") 
		or Utils.endsWith(workTool.configFileName, "Abbey_2000R.xml")
		or Utils.endsWith(workTool.configFileName, "Abbey_3000_Nurse.xml")
end;
function courseplay:isSpecialChopper(workTool)
	if Utils.endsWith(workTool.configFileName, "JF_1060.xml") then
		if workTool.grainTankFillLevel == nil then
			workTool.grainTankFillLevel = 0;
		end;
		if workTool.grainTankCapacity == nil then
			workTool.grainTankCapacity = 0;
		end;
		if workTool.cp.isChopper == nil then
			workTool.cp.isChopper = true
		end
		return true;
	end
	return false
end

function courseplay:isSpecialBaler(workTool)
	return Utils.endsWith(workTool.configFileName, "Claas_Quadrant_1200.xml")
end


function courseplay:isSpecialCombine(workTool, specialType, fileNames)
	if specialType ~= nil then
		if specialType == "sugarBeetLoader" then
			if (Utils.endsWith(workTool.configFileName, "RopaEuroMaus.xml") or Utils.endsWith(workTool.configFileName, "HolmerTerraFelis.xml")) and workTool.unloadingTrigger ~= nil and workTool.unloadingTrigger.node ~= nil then
				if workTool.grainTankFillLevel == nil then
					workTool.grainTankFillLevel = 0;
				end;
				if workTool.grainTankCapacity == nil then
					workTool.grainTankCapacity = 0;
				end;
				return true;
			end;
		end;
	end;
	
	--[[if fileNames ~= nil and table.getn(fileNames) > 0 then
		for i=1, table.getn(fileNames) do
			if Utils.endsWith(workTool.configFileName, fileNames[i] .. ".xml") then
				return true;
			end;
		end;
		return false;
	end;]]
	
	return Utils.endsWith(workTool.configFileName, "JF_1060.xml");
end


function courseplay:handleSpecialTools(self,workTool,unfold,lower,turnOn,allowedToDrive,cover,unload)
	if workTool.PTOId then
		workTool:setPTO(false)
	end
	
	--Claas Quadrant 1200
	if Utils.endsWith(workTool.configFileName, "Claas_Quadrant_1200.xml") then
		if unfold ~= nil and turnOn ~= nil and lower ~= nil then
			if not unfold then
				workTool:emptyBaler(true);
				workTool:setPTO(true)
			end
			local pickup = lower and turnOn
			if workTool.sl.isOpen ~= unfold then
				workTool:openSlide(unfold);
			end
			if workTool.pu.bDown ~= pickup then
				workTool:releasePickUp(pickup)
			end
			if workTool.isTurnedOn ~= unfold then
				workTool.isTurnedOn = unfold
			end

			--speed regulation
			if workTool.isBlocked then 
				allowedToDrive = false
			end
			workTool.blockMaxTime = 10000
			if workTool.actLoad2 == 1 then
				if workTool.blockTimer > workTool.blockMaxTime *0.8 then
					self.cp.maxFieldSpeed = 7/3600
					allowedToDrive = false
				end
			end
			if workTool.actLoad_IntSend < 0.8 and not workTool.isBlocked and workTool.actLoad_IntSend ~= 0 then
				self.cp.maxFieldSpeed = self.cp.maxFieldSpeed + 0.02/3600
			end
			if workTool.actLoad_IntSend == 0 and self.cp.maxFieldSpeed == 0 then
				self.cp.maxFieldSpeed = 4/3600
			end
			if workTool.actLoad_IntSend > 0.9 and self.cp.maxFieldSpeed > 1/3600 then
				self.cp.maxFieldSpeed = self.cp.maxFieldSpeed - 0.05/3600
			end
			--speed regulation END

		end
		
		return true ,allowedToDrive

	--Ursus Z586 BaleWrapper
	elseif Utils.endsWith(workTool.configFileName, "ursusZ586.xml") then
		
		if workTool.baleWrapperState == 4 then
			workTool:doStateChange(5)
		end
		if workTool.baleWrapperState ~= 0 then 
			allowedToDrive = false
		end

		return false ,allowedToDrive
	
	--JF_FCT1060_ProTec
	elseif Utils.endsWith(workTool.configFileName, "JF_1060.xml") then
		if unfold ~= nil and turnOn ~= nil and lower ~= nil then
			if unfold ~= workTool.isArmOneOn and not workTool.isTurnedOn then
				workTool:setArmOne(unfold);
			end
			if unfold ~= workTool.isTransRotOn and not workTool.isTurnedOn  then
				workTool:setTransRot(unfold);
			end
			if workTool.isTurnedOn then
				workTool:setPickup(lower);
			end
			if workTool.isTransRotOn and workTool.isArmOneOn then
				workTool:setIsTurnedOn(unfold);
			end
		end
		local targetTrailer = workTool:findAutoAimTrailerToUnload(workTool.currentFruitType);
		if targetTrailer == nil then
			allowedToDrive = false
		end		
		
		return true ,allowedToDrive

	--Abbey 3000 NurseTanker
	elseif Utils.endsWith(workTool.configFileName, "Abbey_3000_Nurse.xml") then

		local x,y,z = getRotation(workTool.boomArmY)
		local a,b,c = getRotation(workTool.boomArmX)
		if unload ~= nil then
			if unload then
				
				if y >= -1.56 then
					workTool.isEntered = true
					InputBinding.actions[InputBinding.BOOM_RIGHT].lastIsPressed = true 
				else
					workTool.isEntered = false
				end				
				if workTool.isSpreaderInRange ~= nil then
					local fillable = workTool.isSpreaderInRange
					local fillableHasAttacherVehicle = fillable.attacherVehicle ~= nil;
					if fillableHasAttacherVehicle then
						fillable.attacherVehicle.cp.stopForLoading = true;
					end;
					if fillable.fillLevel >= fillable.capacity  or workTool.fillLevel <= 5 then
						workTool:setIsTurnedOn(false)
						if fillableHasAttacherVehicle then
							fillable.attacherVehicle.cp.stopForLoading = false
							fillable.attacherVehicle.wait = false
						end;
					elseif not workTool.isTurnedOn then
						workTool:setIsTurnedOn(true)
					end
				end
			else
				if y < -0.01 then
					workTool.isEntered = true
					InputBinding.actions[InputBinding.BOOM_LEFT].lastIsPressed = true
				elseif y > 0.01 then
					workTool.isEntered = true
					InputBinding.actions[InputBinding.BOOM_RIGHT].lastIsPressed = true
				elseif a < -0.00 then
					workTool.isEntered = true
					InputBinding.actions[InputBinding.BOOM_DOWN].lastIsPressed = true
				else
					workTool.isEntered = false
				end
			end
		end
		
		return true, allowedToDrive
	--Abbey 2000/3000R
	elseif Utils.endsWith(workTool.configFileName, "Abbey_3000R.xml") or Utils.endsWith(workTool.configFileName, "Abbey_2000R.xml") then
		if workTool.PTOId then
			workTool:setPTO(false)
		end
		if cover ~= nil then
			local Cover = -1
			if cover then
				Cover = 1
			end
			workTool:setFoldDirection(Cover);
		end				
		
		if lower ~= nil and turnOn ~= nil then				
			local spray = lower and turnOn
			if workTool.setIsTurnedOn ~= nil and not workTool.isTurnedOn then
				workTool:setIsTurnedOn(spray, false);
			end
			if workTool.setIsTurnedOn ~= nil and workTool.isTurnedOn and not spray then
				workTool:setIsTurnedOn(spray, false);
			end
		end

		return true, allowedToDrive

	--Abbey AP900  workwith 5.8m offset-4,1m
	elseif Utils.endsWith(workTool.configFileName, "Abbey_AP900.xml")	then
		if workTool.PTOId then
			workTool:setPTO(false)
		end
		if unfold == true then
			if workTool.animationParts[1].currentPosition <= 3001 then
				workTool:setAnimationTime(1, workTool.animationParts[1].currentPosition+(workTool.animationParts[1].offSet*(3)));
			end
		else
			if workTool.animationParts[1].currentPosition > 0 then
				workTool:setAnimationTime(1, workTool.animationParts[1].currentPosition-(workTool.animationParts[1].offSet*(3)));
			end
		end			

		return false, allowedToDrive
		
	--gueldnerG40Frontloader free DLC classics
	elseif workTool.animatedFrontloader ~= nil then
		workTool:releaseShovel(unfold);
	

	-- Claas liner 4000
	elseif Utils.endsWith(workTool.configFileName, "liner4000.xml") then
		local isReadyToWork = workTool.rowerFoldingParts[1].isDown;
		local manualReset = false
		if workTool.cp.unfoldOrderIsGiven == nil then
			workTool.cp.unfoldOrderIsGiven = false
			workTool.cp.foldOrderIsGiven = false
		end
		if unfold == false and isReadyToWork then
			workTool.cp.foldOrderIsGiven = true
		end
		--lower
		if workTool.foldAnimTime > 0.99 then
			if isReadyToWork then
				for k, part in pairs(workTool.rowerFoldingParts) do
					workTool:setIsArmDown(k, lower);
				end;
				if workTool.cp.unfoldOrderIsGiven or workTool.cp.foldOrderIsGiven then
					--turn OnOff
					workTool:setIsTurnedOn(turnOn);
					workTool.cp.unfoldOrderIsGiven = false
				end
			end
		else
			allowedToDrive = false
		end
		--unfold			
		if (unfold and workTool.isTransport) or (workTool.cp.foldOrderIsGiven and isReadyToWork)  then
			workTool:setTransport(not unfold)
			if workTool.isReadyToTransport or workTool.cp.foldOrderIsGiven then
				if workTool.foldMoveDirection > 0.1 or (workTool.foldMoveDirection == 0 and workTool.foldAnimTime > 0.5) then
					workTool:setFoldDirection(-1)	
				else
					workTool:setFoldDirection(1)
				end;
				workTool.cp.foldOrderIsGiven = false
			end;
			workTool.cp.unfoldOrderIsGiven = true
			
		end
		if workTool.foldAnimTime == 0 then
			allowedToDrive = true
		end
		return true, allowedToDrive



	--Tebbe HS180 (Maurus)
	elseif Utils.endsWith(workTool.configFileName, "TebbeHS180.xml") then
		local flap = 0
		if workTool.setDoorHigh ~= nil and workTool.doorhigh ~= nil then
			if turnOn then 
				flap = 3
			end
			workTool:setDoorHigh(flap);
		end
		if workTool.setFlapOpen ~= nil and workTool.flapopen then
			workTool:setFlapOpen(turnOn)
		end
		return false, allowedToDrive


	--Fuchsfass
	elseif workTool.isFuchsFass and workTool.setdeckelAnimationisPlaying ~= nil then
		if cover ~= nil then
			workTool:setdeckelAnimationisPlaying(cover);
		end
		return false, allowedToDrive

	--Poettinger Alpha
	elseif workTool.alpMot ~= nil and workTool.setTurnedOn ~= nil and workTool.setLiftUp ~= nil and workTool.setTransport ~= nil then
		--fold/unfold
		workTool:setTransport(not unfold);
		if workTool.alpMot.isTransport ~= nil then
			if (unfold and workTool.alpMot.isTransport) or (not unfold and not workTool.alpMot.isTransport) then
				allowedToDrive = false;
			end;
		end;
		
		--lower/raise
		workTool:setLiftUp(not lower);
		if workTool.alpMot.isLiftUp ~= nil and workTool.alpMot.isLiftDown ~= nil then
			if (lower and workTool.alpMot.isLiftUp) or (not lower and workTool.alpMot.isLiftDown) then
				allowedToDrive = false;
			end;
		end;

		--turn on/off
		workTool:setTurnedOn(turnOn);
		
		return true, allowedToDrive;



	--Poettinger X8
	elseif workTool.x8 ~= nil and workTool.x8.mowers ~= nil and workTool.setTurnedOn ~= nil and workTool.setLiftUp ~= nil and workTool.setTransport ~= nil and workTool.setSelection ~= nil then
		workTool:setSelection(3);
		
		local isFolded = workTool.x8.mowers[1].isTransport and workTool.x8.mowers[2].isTransport;
		local isRaised = workTool.x8.mowers[1].isLiftUp and workTool.x8.mowers[2].isLiftUp;
		
		--fold/unfold
		workTool:setTransport(not unfold);
		if (unfold and isFolded) or (not unfold and not isFolded) then
			allowedToDrive = false;
		end;
		
		--lower/raise
		workTool:setLiftUp(not lower);
		if (lower and isRaised) or (not lower and not isRaised) then
			allowedToDrive = false;
		end;

		--turn on/off
		workTool:setTurnedOn(turnOn);
		
		return true, allowedToDrive;
	end;



	return false, allowedToDrive;
end
function courseplay:askForSpecialSettings(self,object)
	
	if Utils.endsWith(self.configFileName, "KirovetsK700A.xml") then
		self.cp.DirectionNode = self.rootNode
		self.cp.isKasi = 2.5
	elseif Utils.endsWith(object.configFileName, "grimmeSE75-55.xml") then
		self.cp.aiTurnNoBackward = true
		self.WpOffsetX = -2.1
		print("Grimme SE 75-55 workwidth: 0.7 m");
	elseif Utils.endsWith(object.configFileName, "grimmeRootster604.xml") then
		self.cp.aiTurnNoBackward = true
		self.WpOffsetX = -0.9
		print("Grimme Rootster 604 workwidth: 2.8 m");
	elseif Utils.endsWith(object.configFileName, "poettingerMex6.xml") then
		self.cp.aiTurnNoBackward = true
		self.WpOffsetX = -2.5
		print("Pöttinger Mex 6 workwidth: 2.0 m");
	elseif Utils.endsWith(object.configFileName, "Abbey_AP900.xml") then
		self.cp.aiTurnNoBackward = true
		self.WpOffsetX = -4.1
		print("Abbey AP900 workwidth: 5.8 m");
	elseif Utils.endsWith(object.configFileName, "JF_1060.xml") then
		self.cp.aiTurnNoBackward = true
		self.WpOffsetX = -2.5
	elseif Utils.endsWith(object.configFileName, "claasConspeed.xml") then
		object.cp.inversedFoldDirection = true;
	elseif Utils.endsWith(object.configFileName, "ursusZ586.xml") then
		self.cp.aiTurnNoBackward = true
		self.cp.noStopOnEdge = true
		self.cp.noStopOnTurn = true
		self.WpOffsetX = -2.5
	end

end

