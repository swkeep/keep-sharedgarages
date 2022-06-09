local QBCore = exports['qb-core']:GetCoreObject()

local GarageLocation = {}
local inGarageStation = false
local currentgarage = 0
local nearspawnpoint = 0
local PlayerJob = {}
local onDuty = false
local receivedDoorData = false
local receivedData = nil

-- Functions

local function doesVehicleExist(plate)
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
          job = d.job,
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
               local plate = QBCore.Functions.GetPlate(veh)
               TriggerServerEvent('keep-jobgarages:client:delete_if_exist', plate, veh)
          end
     end, required_data)
end

function IsOnDuty()
     return true
     -- return onDuty
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

function GetCurrentgarageData()
     return Config.JobGarages[GetCurrentgarage()]
end

function GetInGarageStation()
     return inGarageStation
end

local function getCurrentgarageType()
     if Config.JobGarages[GetCurrentgarage()] then
          return Config.JobGarages[GetCurrentgarage()].type
     end
     return false
end

local function is_garage_a_job_garage()
     if getCurrentgarageType() == 'job' then
          return true
     end
     return false
end

local function has_player_same_job_as_garage()
     local current_garage = GetCurrentgarageData()
     local job_name = GetJobInfo().name

     for key, value in pairs(current_garage.job) do
          if value == job_name then
               return true
          end
     end
     return false
end

local function does_player_need_to_be_on_duty()
     if GetCurrentgarageData().onDuty then return true end
     return false
end

local function check_player_duty()
     if does_player_need_to_be_on_duty() then
          if IsOnDuty() then return true end
          return false
     end
     return true
end

local function can_player_use_garage()
     if is_garage_a_job_garage() then
          -- is a job garage
          if has_player_same_job_as_garage() then
               return check_player_duty()
          else
               return false
          end
     end
     return true
end

function CanPlayerUseGarage()
     return can_player_use_garage()
end

-- NUI

local function displayNUIText(text)
     SendNUIMessage({ type = "display", text = text, color = '#f2b502' })
     Wait(1)
end

local function hideNUI()
     SendNUIMessage({ type = "hide" })
     Wait(1)
end

local function closeNUI()
     SetNuiFocus(false, false)
     SendNUIMessage({ type = "newDoorSetup", enable = false })
     Wait(10)
     receivedDoorData = nil
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

-- script Threads
local rad = false
local radialMenuItemId
CreateThread(function() -- Get nearest spawn point
     while true do
          Wait(1000)
          if not can_player_use_garage() then
               goto skip
          end
          if inGarageStation and currentgarage ~= nil then
               displayNUIText('Parking')
               nearspawnpoint = GetNearSpawnPoint()
               if rad == false then
                    rad = true
                    radialMenuItemId = exports['qb-radialmenu']:AddOption({
                         id = 'keep_put_back_to_garage',
                         title = 'Park (Job)',
                         icon = 'car',
                         type = 'client',
                         event = 'keep-jobgarages:client:keep_put_back_to_garage',
                         shouldClose = true
                    })
               end
          else
               rad = false
               if radialMenuItemId then
                    exports['qb-radialmenu']:RemoveOption(radialMenuItemId)
                    radialMenuItemId = nil
               end
               hideNUI()
          end
          ::skip::
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

-- Events

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

RegisterNetEvent('onResourceStart', function(resourceName)
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
     for k, v in pairs(Config.JobGarages) do
          GarageLocation[k] = PolyZone:Create(v.zones, {
               name = 'GarageStation ' .. k,
               minZ = v.minz,
               maxZ = v.maxz,
               debugPoly = true
          })
     end
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
