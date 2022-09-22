--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
local QBCore = exports['qb-core']:GetCoreObject()

local GarageLocation = {}
local inGarageStation = false
local currentgarage
PlayerJob = {}
local onDuty = false
local radialmenu = nil

local function isWhitelisted(_currentgarage, model)
     if type(model) == "number" then model = tostring(model) end
     local list = Config.JobGarages[_currentgarage].WhiteList
     if not list then return end
     for key, value in pairs(list) do
          if tonumber(value.hash) == tonumber(model) then
               return true, value
          end
     end
     return false
end

function IsOnDuty()
     return onDuty
end

function GetJobInfo()
     return PlayerJob
end

function GetNearspawnpoint()
     return GetNearSpawnPoint(inGarageStation, currentgarage)
end

function GetCurrentgarage()
     return currentgarage
end

function GetCurrentgarageData()
     return Config.JobGarages[currentgarage]
end

function GetInGarageStation()
     return inGarageStation
end

local function does_player_same_job_as_garage()
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
     if GetCurrentgarageData().onDuty then
          return true
     else
          return false
     end
end

local function check_player_duty()
     if does_player_need_to_be_on_duty() then
          if IsOnDuty() then return true end
          return false
     else
          return true
     end
end

function CanPlayerUseGarage()
     if not GetCurrentgarageData().type == 'job' then
          -- is a job garage
          if does_player_same_job_as_garage() then
               return check_player_duty()
          else
               return false
          end
     else
          return true
     end
end

local function saveVehicle(d, veh)
     if not veh then return end
     local VehicleProperties = QBCore.Functions.GetVehicleProperties(veh)
     local state, info = isWhitelisted(currentgarage, VehicleProperties.model)
     if not state then
          TriggerServerEvent('keep-jobgarages:server:Notification', 'Could not store this vehicle (not whitelisted)',
               'error')
          return
     end
     local data = {
          VehicleProperties = VehicleProperties,
          plate = d.vehicle_plate,
          name = d.vehicle_name,
          grades = d.grades,
          cids = d.citizenids,
          job = d.job_name,
          hash = GetHashKey(veh),
          garage = currentgarage,
          info = info
     }

     TriggerCallback('keep-jobgarages:server:save_vehicle', function(result)
          local plyPed = PlayerPedId()
          if IsPedInAnyVehicle(plyPed, false) then
               TaskLeaveVehicle(plyPed, veh, 0)
               while IsPedInAnyVehicle(plyPed, false) do
                    Wait(100)
               end
               Wait(750)
               DeleteEntity(veh)
          end
     end, data)
end

-- Events

RegisterNetEvent('keep-jobgarages:client:newVehicleSetup', function(job, grades)
     local plyPed = PlayerPedId()
     if not IsPedInAnyVehicle(plyPed, false) then
          TriggerServerEvent('keep-jobgarages:server:Notification', 'Your should be inside a vehicle to use this command'
               , 'error')
          return
     end
     local veh = GetVehiclePedIsIn(plyPed, false)
     if not inGarageStation then
          TriggerServerEvent('keep-jobgarages:server:Notification', 'You must be in garage zone!', 'error')
          return
     end
     local Input = {
          inputs = {
               {
                    type = 'text',
                    isRequired = true,
                    name = 'vehicle_name',
                    text = "What vehicle's name will be?",
                    icon = 'fa-solid fa-money-bill-trend-up',
                    title = 'Vehicle Name',
               },
               {
                    type = 'text',
                    isRequired = true,
                    name = 'vehicle_plate',
                    icon = 'fa-solid fa-money-bill-trend-up',
                    title = 'Vehicle Plate',
                    force_value = RandomID(8):upper(),
                    disabled = true
               },
               {
                    type = 'text',
                    isRequired = true,
                    name = 'job_name',
                    icon = 'fa-solid fa-money-bill-trend-up',
                    title = 'Job Name',
                    force_value = job,
                    disabled = true
               },
               {
                    type = 'text',
                    name = 'citizenids',
                    icon = 'fa-solid fa-money-bill-trend-up',
                    title = 'CitizenID Whitelist',
                    text = 'PZT37891,PZT37891,....'
               },
          }
     }

     local index = #Input.inputs + 1
     Input.inputs[index] = {
          isRequired = true,
          title = 'Allowed Grades',
          name = "grades", -- name of the input should be unique
          type = "checkbox",
          options = {},
     }

     for key, value in pairs(grades) do
          Input.inputs[index].options[#Input.inputs[index].options + 1] = { value = key,
               text = value.name .. ' (' .. key .. ')' }
     end

     local inputData, reason = exports['keep-input']:ShowInput(Input)
     if reason == 'submit' then
          saveVehicle(inputData, veh)
     end
end)

local function InitGarageZone()
     for k, v in pairs(Config.JobGarages) do
          GarageLocation[k] = PolyZone:Create(v.zones, {
               name = 'GarageStation ' .. k,
               minZ = v.minz,
               maxZ = v.maxz,
               debugPoly = Config.MagicTouch
          })
          GarageLocation[k]:onPlayerInOut(function(isPointInside)
               if isPointInside then
                    currentgarage = k
                    if CanPlayerUseGarage() then
                         inGarageStation = true
                         radialmenu = exports['qb-radialmenu']:AddOption({
                              id = 'keep_put_back_to_garage',
                              title = 'Park (Job)',
                              icon = 'car',
                              type = 'client',
                              event = 'keep-jobgarages:client:keep_put_back_to_garage',
                              shouldClose = true
                         })
                         exports['qb-core']:DrawText('Job Parking')
                    end
               else
                    currentgarage = ''
                    inGarageStation = false
                    if radialmenu then
                         exports['qb-radialmenu']:RemoveOption(radialmenu)
                    end
                    exports['qb-core']:HideText()
               end
          end)
     end
end

RegisterNetEvent('onResourceStart', function(resourceName)
     if resourceName ~= GetCurrentResourceName() then return end
     QBCore.Functions.GetPlayerData(function(PlayerData)
          PlayerJob = PlayerData.job
          onDuty = PlayerData.job.onduty
          InitGarageZone()
     end)
end)

RegisterNetEvent('onResourceStop', function(resourceName)
     if resourceName ~= GetCurrentResourceName() then return end
     exports['qb-radialmenu']:RemoveOption(radialmenu)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
     QBCore.Functions.GetPlayerData(function(PlayerData)
          PlayerJob = PlayerData.job
          onDuty = PlayerData.job.onduty
          InitGarageZone()
     end)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
     PlayerJob = JobInfo
     onDuty = PlayerJob.onduty
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
     onDuty = duty
end)

CreateThread(function()
     for _, cat in pairs(Config.VehicleWhiteList) do
          for key, vehicle in pairs(cat) do
               vehicle.hash = GetHashKey(vehicle.spawncode)
          end
     end
end)
