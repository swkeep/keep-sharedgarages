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
PlayerGang = {}
local onDuty = false
local radialmenu = nil

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
     return Config.Garages[currentgarage]
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

local function does_player_same_gang_as_garage()
     local current_garage = GetCurrentgarageData()
     local name = PlayerGang.name

     for key, value in pairs(current_garage.gang) do
          if value == name then
               return true
          end
     end
     return false
end

function CanPlayerUseGarage()
     local garage = GetCurrentgarageData()
     if garage and garage.type == 'job' then
          -- is a job garage
          if does_player_same_job_as_garage() then
               return check_player_duty()
          else
               return false
          end
     elseif garage and garage.type == 'gang' then
          return does_player_same_gang_as_garage()
     else
          return true
     end
end

-- Events
RegisterNetEvent('keep-sharedgarages:client:newVehicleSetup', function(job, grades, categories, random_plate)
     local function saveVehicle(d, veh)
          if not veh then return end
          local VehicleProperties = QBCore.Functions.GetVehicleProperties(veh)
          local data = {
               VehicleProperties = VehicleProperties,
               plate = d.vehicle_plate,
               name = d.vehicle_name,
               grades = d.grades,
               cids = d.citizenids,
               job = d.job_name,
               category = d.category,
               model = GetEntityModel(veh),
               hash = GetHashKey(veh),
               garage = currentgarage
          }

          TriggerCallback('keep-sharedgarages:server:save_vehicle', function(res)
               if not res then return end
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

     local plyPed = PlayerPedId()
     if not IsPedInAnyVehicle(plyPed, false) then
          TriggerServerEvent('keep-sharedgarages:server:Notification', 'You should be inside a vehicle to use this command', 'error')
          return
     end

     local veh = GetVehiclePedIsIn(plyPed, false)
     if not inGarageStation then
          TriggerServerEvent('keep-sharedgarages:server:Notification', 'You must be in garage zone!', 'error')
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
                    force_value = random_plate,
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

     local function create_grades()
          local index = #Input.inputs + 1
          Input.inputs[index] = {
               isRequired = true,
               title = 'Allowed Grades',
               name = "grades", -- name of the input should be unique
               type = "checkbox",
               options = {},
          }

          -- sort grades
          local temp_grages = {}
          for key, value in pairs(grades) do
               temp_grages[tonumber(key + 1)] = value
          end

          for key, value in pairs(temp_grages) do
               Input.inputs[index].options[#Input.inputs[index].options + 1] = {
                    value = key - 1,
                    text = value.name .. ' (' .. key .. ')'
               }
          end
     end

     local function create_categories()
          local index = #Input.inputs + 1
          Input.inputs[index] = {
               isRequired = true,
               title = 'Categories',
               name = "category", -- name of the input should be unique
               type = "radio",
               options = {},
          }

          for key, value in pairs(categories) do
               Input.inputs[index].options[#Input.inputs[index].options + 1] = { value = key,
                    text = value.name .. ' (' .. key .. ')' }
          end
     end

     create_grades()
     create_categories()

     local inputData, reason = exports['keep-input']:ShowInput(Input)
     if reason == 'submit' then
          inputData.job_name = job
          inputData.category = categories[tonumber(inputData.category)]
          inputData.vehicle_plate = random_plate
          saveVehicle(inputData, veh)
     end
end)

local function InitGarageZone()
     for k, v in pairs(Config.Garages) do
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
                              event = 'keep-sharedgarages:client:keep_put_back_to_garage',
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
          PlayerGang = PlayerData.gang
          onDuty = PlayerData.job.onduty
          InitGarageZone()
     end)
end)

RegisterNetEvent('onResourceStop', function(resourceName)
     if resourceName ~= GetCurrentResourceName() then return end
     if radialmenu then
          exports['qb-radialmenu']:RemoveOption(radialmenu)
     end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
     QBCore.Functions.GetPlayerData(function(PlayerData)
          PlayerJob = PlayerData.job
          PlayerGang = PlayerData.gang
          onDuty = PlayerData.job.onduty
          InitGarageZone()
     end)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
     PlayerJob = JobInfo
     onDuty = PlayerJob.onduty
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo)
     PlayerGang = GangInfo
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
     onDuty = duty
end)

CreateThread(function()
     for _, cat in pairs(Config.VehicleWhiteList) do
          if not cat.allow_all then
               for key, vehicle in pairs(cat) do
                    vehicle.hash = GetHashKey(vehicle.spawncode)
               end
          end
     end
end)

RegisterNetEvent('keep-sharedgarages:client:get_current_garage', function(event, data)
     TriggerServerEvent(event, GetCurrentgarage(), data)
end)

CreateThread(function()
     for garage_name, garage in pairs(Config.Garages) do
          for key, value in pairs(garage.WhiteList) do
               if key ~= 'allow_all' then
                    Config.Garages[garage_name].WhiteList[key].hash = GetHashKey(value.model:lower())
               end
          end
     end
end)
