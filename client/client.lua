local QBCore = exports['qb-core']:GetCoreObject()

local GarageLocation = {}
local inGarageStation = false
local currentgarage = 0
local nearspawnpoint = 0
local PlayerJob = {}
local onDuty = false
local receivedDoorData = false
local receivedData = nil

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

local displayNUIText = function(text)
     SendNUIMessage({ type = "display", text = text, color = '#f2b502' })
     Wait(1)
end

local hideNUI = function()
     SendNUIMessage({ type = "hide" })
     Wait(1)
end

CreateThread(function() -- Get nearest spawn point
     while true do
          Wait(1000)
          if IsOnDuty() and GetJobInfo().name == 'police' and inGarageStation and currentgarage ~= nil then
               nearspawnpoint = GetNearSpawnPoint()
               displayNUIText('Parking')
          else
               hideNUI()
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

local closeNUI = function()
     SetNuiFocus(false, false)
     SendNUIMessage({ type = "newDoorSetup", enable = false })
     Wait(10)
     receivedDoorData = nil
end

local function isWhitelisted(currentgarage, model)
     if type(model) == "number" then model = tostring(model) end
     local list = Config.JobGarages[currentgarage].WhiteList
     if not list then return end
     for key, value in pairs(list) do
          if key == model then
               return true, value
          end
     end
     return false
end

local function saveVehicle(d)
     local plyPed = PlayerPedId()
     local veh = GetVehiclePedIsIn(plyPed, false)
     local c_car = QBCore.Functions.GetVehicleProperties(veh)
     local state, info = isWhitelisted(currentgarage, c_car.model)
     if not state then
          QBCore.Functions.Notify('Could not store this vehicle', 'error', 5000)
          return false
     end

     local required_data = {
          vehicle = c_car,
          plate = d.platevalue,
          name = d.vehiclename,
          grades = d.grades,
          cids = d.cids,
          hash = GetHashKey(veh),
          garage = currentgarage,
          info = info
     }
     QBCore.Functions.TriggerCallback('keep-jobgarages:server:save_vehicle', function(result)
          if IsPedInAnyVehicle(plyPed, false) then
               TaskLeaveVehicle(plyPed, veh, 0)
               while IsPedInAnyVehicle(plyPed, false) do
                    Wait(100)
               end
               QBCore.Functions.DeleteVehicle(veh)
          end
     end, required_data)
end

RegisterNUICallback('saveNewVehicle', function(data, cb)
     receivedDoorData = true
     receivedData = data
     if saveVehicle(receivedData) == false then
          cb(false)

     end
     closeNUI()
     cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
     closeNUI()
     cb('ok')
end)

RegisterNetEvent('keep-jobgarages:client:newVehicleSetup', function()
     local plyPed = PlayerPedId()
     if not IsPedInAnyVehicle(plyPed, false) then
          QBCore.Functions.Notify('Your should be inside a vehicle to use this command', 'error', 5000)
          return
     end
     receivedDoorData = false
     SetNuiFocus(true, true)
     SendNUIMessage({ type = "newDoorSetup", enable = true })
     while receivedDoorData == false do Wait(250) DisableAllControlActions(0) end
     if receivedDoorData == nil then return end
end)


AddEventHandler('onResourceStart', function(resourceName)
     if resourceName == GetCurrentResourceName() then
          QBCore.Functions.GetPlayerData(function(PlayerData)
               PlayerJob = PlayerData.job
               if PlayerJob.name == 'police' then
                    onDuty = PlayerData.job.onduty
               end
          end)
          for k, v in pairs(Config.JobGarages) do
               GarageLocation[k] = PolyZone:Create(v.zones, {
                    name = 'GarageStation ' .. k,
                    minZ = v.minz,
                    maxZ = v.maxz,
                    debugPoly = false
               })
          end
     end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
     QBCore.Functions.GetPlayerData(function(PlayerData)
          PlayerJob = PlayerData.job
          if PlayerJob.name == 'police' then
               onDuty = PlayerData.job.onduty
          end
     end)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
     PlayerJob = JobInfo
     if PlayerJob.name == 'police' then
          onDuty = PlayerJob.onduty
          if PlayerJob.onduty then
               TriggerServerEvent("hospital:server:AddDoctor", PlayerJob.name)
          else
               TriggerServerEvent("hospital:server:RemoveDoctor", PlayerJob.name)
          end
     end
end)


RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
     if PlayerJob.name == 'police' and duty ~= onDuty then
          onDuty = duty
     end
end)

function IsOnDuty()
     return onDuty
end

function GetJobInfo()
     return PlayerJob
end

function GetNearspawnpoint()
     return nearspawnpoint
end

function GetCurrentgarage()
     return currentgarage
end

function GetInGarageStation()
     return inGarageStation
end
