local QBCore = exports['qb-core']:GetCoreObject()

local GarageLocation = {}
local inGarageStation = false
currentgarage = 0
nearspawnpoint = 0

for k, v in pairs(Config.JobGarages) do
     GarageLocation[k] = PolyZone:Create(v.zones, {
          name = 'GarageStation ' .. k,
          minZ = v.minz,
          maxZ = v.maxz,
          debugPoly = true
     })
end

local function SetVehicleModifications(vehicle, props) -- Apply all modifications to a vehicle entity
     if DoesEntityExist(vehicle) then
          SetVehicleModKit(vehicle, 0)
          -- plate:
          if props.plate then
               SetVehicleNumberPlateText(vehicle, props.plate)
          end
          if props.plateIndex then
               SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
          end
          -- lockStatus:
          if props.lockstatus then
               SetVehicleDoorsLocked(vehicle, props.lockstatus)
          end
          -- colours:
          if props.color1 and props.color2 then
               SetVehicleColours(vehicle, props.color1, props.color2)
          end
          if props.customprimarycolor then
               SetVehicleCustomPrimaryColour(vehicle, props.customprimarycolor.r, props.customprimarycolor.g, props.customprimarycolor.b)
          end
          if props.customsecondarycolor then
               SetVehicleCustomSecondaryColour(vehicle, props.customsecondarycolor.r, props.customsecondarycolor.g, props.customsecondarycolor.b)
          end
          if props.interiorColor then
               SetVehicleInteriorColor(vehicle, props.interiorColor)
          end
          if props.dashboardColor then
               SetVehicleDashboardColour(vehicle, props.dashboardColor)
          end
          if props.pearlescentColor and props.wheelColor then
               SetVehicleExtraColours(vehicle, props.pearlescentColor, props.wheelColor)
          end
          if props.tyreSmokeColor then
               SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
          end
          -- wheels:
          if props.wheels then
               SetVehicleWheelType(vehicle, props.wheels)
          end
          -- windows:
          if props.windowTint then
               SetVehicleWindowTint(vehicle, props.windowTint)
          end
          -- neonlight:
          if props.neonEnabled then
               SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
               SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
               SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
               SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
          end
          if props.neonColor then
               SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
          end
          -- mods:
          if props.modSpoilers then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 0, props.modSpoilers, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 0, props.modSpoilers, false)
               end
          end
          if props.modFrontBumper then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 1, props.modFrontBumper, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 1, props.modFrontBumper, false)
               end
          end
          if props.modRearBumper then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 2, props.modRearBumper, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 2, props.modRearBumper, false)
               end
          end
          if props.modSideSkirt then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 3, props.modSideSkirt, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 3, props.modSideSkirt, false)
               end
          end
          if props.modExhaust then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 4, props.modExhaust, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 4, props.modExhaust, false)
               end
          end
          if props.modFrame then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 5, props.modFrame, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 5, props.modFrame, false)
               end
          end
          if props.modGrille then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 6, props.modGrille, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 6, props.modGrille, false)
               end
          end
          if props.modHood then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 7, props.modHood, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 7, props.modHood, false)
               end
          end
          if props.modFender then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 8, props.modFender, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 8, props.modFender, false)
               end
          end
          if props.modRightFender then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 9, props.modRightFender, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 9, props.modRightFender, false)
               end
          end
          if props.modRoof then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 10, props.modRoof, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 10, props.modRoof, false)
               end
          end
          if props.modEngine then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 11, props.modEngine, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 11, props.modEngine, false)
               end
          end
          if props.modBrakes then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 12, props.modBrakes, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 12, props.modBrakes, false)
               end
          end
          if props.modTransmission then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 13, props.modTransmission, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 13, props.modTransmission, false)
               end
          end
          if props.modHorns then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 14, props.modHorns, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 14, props.modHorns, false)
               end
          end
          if props.modSuspension then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 15, props.modSuspension, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 15, props.modSuspension, false)
               end
          end
          if props.modArmor then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 16, props.modArmor, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 16, props.modArmor, false)
               end
          end
          if props.modTurbo then
               ToggleVehicleMod(vehicle, 18, props.modTurbo)
          end
          if props.modSmokeEnabled then
               ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled)
          end
          if props.modXenon then
               ToggleVehicleMod(vehicle, 22, props.modXenon)
          end
          if props.modFrontWheels then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 23, props.modFrontWheels, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 23, props.modFrontWheels, false)
               end
          end
          if props.modBackWheels then
               if props.modCustomTiresR then
                    SetVehicleMod(vehicle, 24, props.modBackWheels, props.modCustomTiresR)
               else
                    SetVehicleMod(vehicle, 24, props.modBackWheels, false)
               end
          end
          if props.modPlateHolder then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 25, props.modPlateHolder, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 25, props.modPlateHolder, false)
               end
          end
          if props.modVanityPlate then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 26, props.modVanityPlate, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 26, props.modVanityPlate, false)
               end
          end
          if props.modTrimA then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 27, props.modTrimA, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 27, props.modTrimA, false)
               end
          end
          if props.modOrnaments then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 28, props.modOrnaments, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 28, props.modOrnaments, false)
               end
          end
          if props.modDashboard then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 29, props.modDashboard, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 29, props.modDashboard, false)
               end
          end
          if props.modDial then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 30, props.modDial, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 30, props.modDial, false)
               end
          end
          if props.modDoorSpeaker then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 31, props.modDoorSpeaker, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false)
               end
          end
          if props.modSeats then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 32, props.modSeats, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 32, props.modSeats, false)
               end
          end
          if props.modSteeringWheel then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 33, props.modSteeringWheel, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 33, props.modSteeringWheel, false)
               end
          end
          if props.modShifterLeavers then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 34, props.modShifterLeavers, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 34, props.modShifterLeavers, false)
               end
          end
          if props.modAPlate then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 35, props.modAPlate, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 35, props.modAPlate, false)
               end
          end
          if props.modSpeakers then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 36, props.modSpeakers, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 36, props.modSpeakers, false)
               end
          end
          if props.modTrunk then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 37, props.modTrunk, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 37, props.modTrunk, false)
               end
          end
          if props.modHydrolic then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 38, props.modHydrolic, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 38, props.modHydrolic, false)
               end
          end
          if props.modEngineBlock then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 39, props.modEngineBlock, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 39, props.modEngineBlock, false)
               end
          end
          if props.modAirFilter then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 40, props.modAirFilter, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 40, props.modAirFilter, false)
               end
          end
          if props.modStruts then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 41, props.modStruts, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 41, props.modStruts, false)
               end
          end
          if props.modArchCover then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 42, props.modArchCover, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 42, props.modArchCover, false)
               end
          end
          if props.modAerials then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 43, props.modAerials, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 43, props.modAerials, false)
               end
          end
          if props.modTrimB then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 44, props.modTrimB, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 44, props.modTrimB, false)
               end
          end
          if props.modTank then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 45, props.modTank, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 45, props.modTank, false)
               end
          end
          if props.modWindows then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 46, props.modWindows, props.modCustomTiresF)
               else
                    SetVehicleMod(vehicle, 46, props.modWindows, false)
               end
          end
          if props.modLivery then
               if props.modCustomTiresF then
                    SetVehicleMod(vehicle, 48, props.modLivery, props.modCustomTiresF)
                    SetVehicleLivery(vehicle, props.modLivery)
               else
                    SetVehicleMod(vehicle, 48, props.modLivery, false)
                    SetVehicleLivery(vehicle, props.modLivery)
               end
          end
          -- extras:
          if props.extras then
               for id, enabled in pairs(props.extras) do
                    if enabled then
                         SetVehicleExtra(vehicle, tonumber(id), 0)
                    else
                         SetVehicleExtra(vehicle, tonumber(id), 1)
                    end
               end
          end
          -- stats:
          if props.health then
               SetEntityHealth(vehicle, props.health + 0.0)
          end
          if props.bodyHealth then
               SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0)
          end
          if props.engineHealth then
               SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0)
          end
          if props.engineHealth and renderScorched and props.engineHealth < -3999.0 then
               TriggerServerEvent('MojiaGarages:server:renderScorched', NetworkGetNetworkIdFromEntity(vehicle), true)
          end
          if props.tankHealth then
               SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0)
          end
          if props.tankHealth and renderScorched and props.tankHealth < -999.0 then
               TriggerServerEvent('MojiaGarages:server:renderScorched', NetworkGetNetworkIdFromEntity(vehicle), true)
          end
          if props.dirtLevel then
               SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
          end
          if props.fuelLevel then
               SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
          end
          -- doors:
          if props.doorsmissing then
               for id, state in pairs(props.doorsmissing) do
                    if state then
                         SetVehicleDoorBroken(vehicle, tonumber(id), state)

                    end
               end
          end
          -- tires
          SetVehicleTyresCanBurst(vehicle, not props.bulletprooftires)
          if not props.bulletprooftires and props.tiresburst then
               for id, state in pairs(props.tiresburst) do
                    SetVehicleTyreBurst(vehicle, tonumber(id), state, 1000.0)
               end
          end
          -- windows:
          if props.windowsbroken then
               for id, state in pairs(props.windowsbroken) do
                    if not state then
                         SmashVehicleWindow(vehicle, tonumber(id))
                    end
               end
          end
          -- xenon lights:
          if props.xenonColor then
               SetVehicleXenonLightsColor(vehicle, props.xenonColor)
          end
     end
end

-- Events
local function isVehicleExistInRealLife(plate)
     local gameVehicles = QBCore.Functions.GetVehicles()
     local check = false
     for i = 1, #gameVehicles do
          local vehicle = gameVehicles[i]
          if DoesEntityExist(vehicle) then
               if QBCore.Functions.GetPlate(vehicle) == plate then
                    check = true
               end
          end
     end
     return check
end

local function EnumerateEntitiesWithinDistance(entities, isPlayerEntities, coords, maxDistance)
     local nearbyEntities = {}
     if coords then
          coords = vector3(coords.x, coords.y, coords.z)
     else
          local playerPed = PlayerPedId()
          coords = GetEntityCoords(playerPed)
     end
     for k, entity in pairs(entities) do
          local distance = #(coords - GetEntityCoords(entity))
          if distance <= maxDistance then
               nearbyEntities[#nearbyEntities + 1] = isPlayerEntities and k or entity
          end
     end
     return nearbyEntities
end

local function GetVehiclesInArea(coords, maxDistance) -- Vehicle inspection in designated area
     return EnumerateEntitiesWithinDistance(QBCore.Functions.GetVehicles(), false, coords, maxDistance)
end

local function IsSpawnPointClear(coords, maxDistance) -- Check the spawn point to see if it's empty or not:
     return #GetVehiclesInArea(coords, maxDistance) == 0
end

RegisterNetEvent('MojiaGarages:client:spawnOutsiteVehicle', function(properties)
     if properties then
          if properties.modifications then
               if isVehicleExistInRealLife(properties.modifications.plate) then
               else
                    if IsSpawnPointClear(properties.position, 2.5) then
                         QBCore.Functions.SpawnVehicle(properties.model, function(veh)
                              SetVehicleModifications(veh, properties.modifications)
                              SetEntityRotation(veh, properties.rotation)
                              exports['LegacyFuel']:SetFuel(veh, properties.modifications.fuelLevel)
                         end, properties.position, true)
                    else
                         local vehcheck = QBCore.Functions.GetClosestVehicle(properties.position)
                         local platecheck = QBCore.Functions.GetPlate(vehcheck)
                         if vehcheck ~= nil and NetworkGetEntityIsNetworked(vehcheck) and DoesEntityExist(vehcheck) then

                         end
                    end
               end
          end
     end
end)

local function GetNearSpawnPoint() -- Get nearest spawn point
     local near = nil
     local distance = 50
     if inGarageStation and currentgarage ~= nil then
          for k, v in pairs(Config.JobGarages[currentgarage].spawnPoint) do
               if IsSpawnPointClear(vector3(v.x, v.y, v.z), 2.5) then
                    local ped = PlayerPedId()
                    local pos = GetEntityCoords(ped)
                    local cur_distance = #(pos - vector3(v.x, v.y, v.z))
                    if cur_distance < distance then
                         distance = cur_distance
                         near = k
                    end
               end
          end
     end
     return near
end

CreateThread(function() -- Get nearest spawn point
     while true do
          Wait(1000)
          if inGarageStation and currentgarage ~= nil then
               nearspawnpoint = GetNearSpawnPoint()
          end
     end
end)

CreateThread(function() -- Check if the player is in the garage area or not
     while true do
          local Ped = PlayerPedId()
          local coord = GetEntityCoords(Ped)
          if Ped and coord and GarageLocation and next(GarageLocation) ~= nil then
               for k, v in pairs(GarageLocation) do
                    if GarageLocation[k] then
                         if GarageLocation[k]:isPointInside(coord) then
                              inGarageStation = true
                              currentgarage = k
                              while inGarageStation do
                                   local InZoneCoordS = GetEntityCoords(Ped)
                                   if not GarageLocation[k]:isPointInside(InZoneCoordS) then
                                        inGarageStation = false
                                        currentgarage = nil
                                   end
                                   Wait(1000)
                              end
                         end
                    end
               end
          end
          Wait(1000)
     end
end)

local receivedDoorData = false
local receivedData = nil

local closeNUI = function()
     SetNuiFocus(false, false)
     SendNUIMessage({ type = "newDoorSetup", enable = false })
     Wait(10)
     receivedDoorData = nil
end

RegisterNUICallback('saveNewVehicle', function(data, cb)
     receivedDoorData = true
     receivedData = data
     closeNUI()
     cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
     closeNUI()
     cb('ok')
end)

local displayNUIText = function(text)
     local selectedColor = closestDoor.data.locked and Config.LockedColor or Config.UnlockedColor
     SendNUIMessage({ type = "display", text = text, color = selectedColor })
     Wait(1)
end

local hideNUI = function()
     SendNUIMessage({ type = "hide" })
     Wait(1)
end

local function saveVehicle(receivedDoorData)
     local plyPed = PlayerPedId()
     local veh = GetVehiclePedIsIn(plyPed, false)
     local c_car = QBCore.Functions.GetVehicleProperties(veh)
     if not Config.VehicleWhiteList[currentgarage][tostring(c_car.model)] then return end

     local required_data = {
          vehicle = c_car,
          plate = receivedDoorData.platevalue,
          name = receivedDoorData.vehiclename,
          grades = receivedDoorData.grades,
          cids = receivedDoorData.cids,
          hash = GetHashKey(veh),
          garage = currentgarage,
          info = Config.VehicleWhiteList[currentgarage][tostring(c_car.model)]
     }
     QBCore.Functions.TriggerCallback('keep-jobgarages:server:save_vehicle', function(result)
          print(result)
     end, required_data)
end

RegisterNetEvent('keep-jobgarages:client:newVehicleSetup', function()
     receivedDoorData = false
     SetNuiFocus(true, true)
     SendNUIMessage({ type = "newDoorSetup", enable = true })
     while receivedDoorData == false do Wait(250) DisableAllControlActions(0) end
     if receivedDoorData == nil then return end
     saveVehicle(receivedDoorData)
end)
-- --Garage Thread
-- CreateThread(function()
--      Wait(1000)
--      while true do
--           local sleep = 1000
--           if inGarage and PlayerJob.name == "police" then
--                -- if onDuty then sleep = 250 end
--                if IsPedInAnyVehicle(PlayerPedId(), false) then
--                     if IsControlJustReleased(0, 38) then
--                          QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
--                     end
--                end
--           else
--                sleep = 1000
--           end
--           Wait(sleep)
--      end
-- end)
