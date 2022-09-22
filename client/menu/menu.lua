local QBCore = exports['qb-core']:GetCoreObject()
local keep_menu = {}
local Cachedata = nil
local currentVeh = {}

function Open_menu()
     Config.menu = 'keep-menu'
     if Config.menu == 'keep-menu' then
          keep_menu:garage_menu()
          return
     end
end

AddEventHandler('keep-jobgarages:menu:open:garage_menu', function(option)
     Open_menu()
end)

---------------------------------------------------- functions ------------------------------------------

local function isWhitelisted(currentgarage, model)
     if type(model) == "number" then model = tostring(model) end
     local list = Config.JobGarages[currentgarage].WhiteList
     if not list then return end
     for _, value in ipairs(list) do
          if value.spawncode == model then
               return true, value
          end
     end
     return false, nil
end

local function get_vehicle(currentgarage, model)
     local state, info = isWhitelisted(currentgarage, model)
     if not state then
          print('error: check the vehiclewhite list')
          print('helper: vehicle that is saved in this is not in whitelist anymore')
          print('helper: remove that vehicle in database or add it back to whitelist')
          TriggerServerEvent('keep-jobgarages:server:Notification', 'Vehiclewhite error', 'error')

          return '', ''
     end
     return info.label, info.icon
end

local function split(s, delimiter)
     local result = {};
     for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
          table.insert(result, match);
     end
     return result;
end

local function is_restricted_by_grades(vehicle)
     for key, value in pairs(vehicle.permissions.grades) do
          if value then
               return value
          end
     end
     return false
end

local function check_grades(vehicle)
     for key, value in pairs(vehicle.permissions.grades) do
          if GetJobInfo().grade.level == tonumber(key) and value == true then
               return true
          end
     end
     return false
end

local function is_restricted_by_cid(vehicle)
     if string.len(vehicle.permissions.cids) == 0 then
          return false
     end
     return true
end

local function check_cids(vehicle)
     local cids = split(vehicle.permissions.cids, ",")
     for key, value in pairs(cids) do
          if vehicle.current_player_id == value then
               return true
          end
     end
     return false
end

---------------------------------------------------- keep-menu ------------------------------------------

function keep_menu:garage_menu()
     local Menu = {}
     Menu = {
          {
               header = 'Shared Garage',
               subheader = 'Current: ' .. Config.JobGarages[GetCurrentgarage()].label,
               icon = 'fa-solid fa-car-on',
               disabled = true
          },
          {
               header = 'Shared Vehicles',
               subheader = 'List of shared vehicles',
               icon = 'fa-solid fa-car',
               args = { 2 },
               action = function(args)
                    local currentgarage = GetCurrentgarage()
                    TriggerCallback('keep-jobgarages:server:fetch_categories', function(result)
                         Cachedata = result
                         keep_menu:categories(result)
                    end, {
                         garage = currentgarage
                    })
               end,
               submenu = true,
          },
          {
               header = 'Leave',
               event = 'keep-menu:closeMenu',
               leave = true
          },
     }

     exports['keep-menu']:createMenu(Menu)
end

function keep_menu:categories(data)
     local Menu = {}
     Menu = {
          {
               header = "Go Back",
               args = { 0 },
               action = function()
                    keep_menu:garage_menu()
               end,
               back = true
          },
          {
               header = 'Leave',
               event = "keep-menu:closeMenu",
               leave = true
          },
     }

     local currentgarage = GetCurrentgarage()
     for _, DISTINCT in pairs(data.DISTINCT) do
          local lebel, icon = get_vehicle(currentgarage, DISTINCT.model)
          Menu[#Menu + 1] = {
               header = lebel,
               subheader = #data[DISTINCT.model] .. " Vehicles",
               icon = icon,
               args = { DISTINCT.model, lebel, icon },
               action = function(args)
                    keep_menu:vehicles_inside_category(args[1], args[2], args[3])
               end
          }
     end

     exports['keep-menu']:createMenu(Menu)
end

function keep_menu:vehicles_inside_category(model, lebel, icon)
     local Menu = {
          {
               header = "Go Back",
               args = { 0 },
               action = function()
                    keep_menu:categories(Cachedata)
               end,
               back = true
          },
     }

     for k, vehicle in pairs(Cachedata[model]) do
          local state = 'out'
          if vehicle.state == 1 then state = 'In' end
          Menu[#Menu + 1] = {
               header = 'Name: ' .. vehicle.name,
               subheader = 'Model: ' .. lebel,
               footer = string.format('Plate: %s | State: %s', vehicle.plate, state),
               icon = icon,
               args = {
                    {
                         type = 'vehicle_actions_menu',
                         model = model, -- local data
                         lebel = lebel,
                         key = k,
                         icon = icon
                    }
               },
               action = function(args)
                    keep_menu:vehicle_actions_menu(args[1])
               end
          }
     end

     exports['keep-menu']:createMenu(Menu)
end

function keep_menu:take_out_menu(data, vehicle, veh, per)
     local engine = math.floor(vehicle.engine / 10)
     local body = math.floor(vehicle.body / 10)
     local fuel = vehicle.fuel

     local status = "Engine: " .. engine .. " | Body: " .. body .. " | fuel: " .. fuel
     local Menu = {
          {
               header = "Go Back",
               icon = 'fa-solid fa-angle-left',
               args = {
                    {
                         model = data.model,
                         veh = veh,
                         plate = vehicle.plate
                    }
               },
               action = function(args)
                    TriggerServerEvent('keep-jobgarages:server:update_out_vehicles', {
                         type = 'remove',
                         plate = args[1].plate
                    })
                    QBCore.Functions.DeleteVehicle(args[1].veh)
                    while DoesEntityExist(args[1].veh) do Wait(50) end
                    local lebel, icon = get_vehicle(GetCurrentgarage(), args[1].model)
                    keep_menu:vehicles_inside_category(args[1].model, lebel, icon)
               end
          },
          {
               header = 'Take Out Vehicle',
               event = 'keep-jobgarages:client:take_out',
               icon = 'fa-solid fa-arrow-right-from-bracket',
               args = {
                    {
                         vehicle = veh,
                         fuel = fuel,
                         engine = engine,
                         body = body,
                         plate = vehicle.plate,
                    }
               }
          },
          {
               header = 'Vehicle Status',
               icon = 'fa-solid fa-car-battery',
               subheader = status,
               disabled = true
          },
          {
               header = 'Vehicle Parking Log',
               icon = 'fa-solid fa-clipboard-question',
               args = { { plate = vehicle.plate, data = data, vehicle = vehicle, veh = veh } },
               action = function(args)
                    keep_menu:vehicle_parking_log(args[1])
               end
          },
     }

     if per then
          Menu[#Menu + 1] = {
               header = 'Duplicate The Vehicle',
               type = 'server',
               event = 'keep-jobgarages:server:dupe',
               icon = 'fa-solid fa-clone',
               args = { vehicle.plate }
          }

          Menu[#Menu + 1] = {
               header = "Modify Vehicle's Name",
               type = 'server',
               event = 'keep-jobgarages:server:dupe',
               icon = 'fa-solid fa-pen-to-square',
               action = function()
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
                         }
                    }

                    local inputData, reason = exports['keep-input']:ShowInput(Input)
                    if reason == 'submit' then
                         if not inputData.vehicle_name then return end
                         TriggerServerEvent('keep-jobgarages:server:update_vehicle_name', inputData.vehicle_name,
                              vehicle.plate)
                    end
               end
          }

          Menu[#Menu + 1] = {
               header = "Modify Vehicle's Plate",
               type = 'server',
               event = 'keep-jobgarages:server:dupe',
               icon = 'fa-solid fa-pen-to-square',
               action = function()
                    local Input = {
                         inputs = {
                              {
                                   type = 'text',
                                   isRequired = true,
                                   name = 'vehicle_plate',
                                   text = "What vehicle's name will be?",
                                   icon = 'fa-solid fa-money-bill-trend-up',
                                   title = 'Vehicle Plate',
                                   force_value = vehicle.plate,
                              },
                         }
                    }

                    local inputData, reason = exports['keep-input']:ShowInput(Input)
                    if reason == 'submit' then
                         if not inputData.vehicle_plate then return end
                         TriggerServerEvent('keep-jobgarages:server:update_vehicle_plate', inputData.vehicle_plate,
                              vehicle.plate)
                    end
               end
          }
     end

     local op = exports['keep-menu']:createMenu(Menu)
     if not op or op == vehicle.plate then
          if op == vehicle.plate then
               TriggerServerEvent('keep-jobgarages:server:dupe', vehicle.plate)
          end
          TriggerServerEvent('keep-jobgarages:server:update_out_vehicles', {
               type = 'remove',
               plate = vehicle.plate
          })
          QBCore.Functions.DeleteVehicle(veh)
     end
end

function keep_menu:vehicle_actions_menu(data)
     local vehicle = Cachedata[data.model][data.key]
     local nearspawnpoint = GetNearspawnpoint()
     local currentgarage = GetCurrentgarage()

     if is_restricted_by_cid(vehicle) then
          if check_cids(vehicle) == false then
               TriggerServerEvent('keep-jobgarages:server:Notification', 'This vehicle is not allowed for you', 'error')
               keep_menu:vehicles_inside_category(data.model, data.lebel, data.icon)
               return
          end
     end

     if is_restricted_by_grades(vehicle) then
          if check_grades(vehicle) == false then
               TriggerServerEvent('keep-jobgarages:server:Notification',
                    'This vehicle is not allowed for you current rank', 'error')
               keep_menu:vehicles_inside_category(data.model, data.lebel, data.icon)
               return
          end
     end

     if vehicle.state == 0 then
          TriggerServerEvent('keep-jobgarages:server:Notification', 'Vehicle is already out!', 'error')
          keep_menu:vehicles_inside_category(data.model, data.lebel, data.icon)
          return
     end

     TriggerCallback('keep-jobgarages:server:doesVehicleExist', function(result, per)
          if result == true then
               TriggerServerEvent('keep-jobgarages:server:Notification', 'Vehicle is already out!', 'error')
               TriggerEvent('keep-jobgarages:menu:open:vehicles_list', {
                    type = 'vehicles_inside_category',
                    model = data.model -- local data
               })
               return
          end

          if not currentgarage or not nearspawnpoint then
               TriggerServerEvent('keep-jobgarages:server:Notification', 'Try to find a free spot!', 'error')
               return
          end

          QBCore.Functions.SpawnVehicle(data.model, function(veh)
               SetEntityAlpha(veh, 100, true)
               QBCore.Functions.SetVehicleProperties(veh, vehicle.mods)
               currentVeh = {
                    veh = veh,
                    plate = vehicle.plate
               }
               SetVehicleNumberPlateText(veh, vehicle.plate)
               if veh and vehicle.plate then
                    SetNetworkIdAlwaysExistsForPlayer(NetworkGetNetworkIdFromEntity(veh), PlayerPedId(), true)
               end
               SetEntityHeading(veh, Config.JobGarages[currentgarage].spawnPoint[nearspawnpoint].w)
               PlaceObjectOnGroundProperly(veh)
               FreezeEntityPosition(veh, true)
               -- add it to serverside list
               TriggerServerEvent('keep-jobgarages:server:update_out_vehicles', {
                    type = 'add',
                    netId = NetworkGetNetworkIdFromEntity(veh),
                    plate = vehicle.plate
               })
               RecoverVehicleDamages(veh, vehicle)
               keep_menu:take_out_menu(data, vehicle, veh, per)
          end, Config.JobGarages[currentgarage].spawnPoint[nearspawnpoint], true)
     end, vehicle.plate)
end

function keep_menu:vehicle_parking_log(data)
     local Menu = {
          {
               header = "Go Back",
               icon = 'fa-solid fa-angle-left',
               args = { { data = data.data, vehicle = data.vehicle, veh = data.veh } },
               action = function(args)
                    keep_menu:take_out_menu(args[1].data, args[1].vehicle, args[1].veh)
               end
          },
     }

     TriggerCallback('keep-jobgarages:server:get_vehicle_log', function(LOGS)
          local icons = {
               retrive = 'fa-solid fa-arrow-right-arrow-left',
               store = 'fa-solid fa-arrow-right-to-bracket',
               out = 'fa-solid fa-arrow-right-from-bracket'
          }
          if type(LOGS) == "table" then
               for _, log in pairs(LOGS) do

                    local header = log.action
                    local _data = json.decode(log.data)
                    local sub_header = "Name: " .. _data.charinfo.firstname .. " " .. _data.charinfo.lastname
                    Menu[#Menu + 1] = {
                         header = header,
                         subheader = sub_header,
                         footer = log.Action_timestamp,
                         icon = icons[log.action],
                         disabled = true
                    }
               end

               local op = exports['keep-menu']:createMenu(Menu)

               if not op then
                    TriggerServerEvent('keep-jobgarages:server:update_out_vehicles', {
                         type = 'remove',
                         plate = data.plate
                    })
                    QBCore.Functions.DeleteVehicle(data.veh)
               end
          end
     end, { plate = data.plate })
end

AddEventHandler('keep-jobgarages:client:take_out', function(data)
     data = data[1]
     local plate = QBCore.Functions.GetPlate(data.vehicle)
     ResetEntityAlpha(data.vehicle)
     FreezeEntityPosition(data.vehicle, false)
     SetEntityCollision(veh, true, true)
     SetEntityAsMissionEntity(data.vehicle, true, true)
     TriggerEvent("vehiclekeys:client:SetOwner", plate)
     exports[Config.fuel_script]:SetFuel(data.vehicle, data.fuel)
     TriggerCallback('keep-jobgarages:server:give_keys_to_all_same_job', function(receivers)
          for _, id in pairs(receivers) do
               TriggerServerEvent('qb-vehiclekeys:server:GiveVehicleKeys', id, plate)
          end
     end, PlayerJob)
     TriggerServerEvent('keep-jobgarages:server:update_state', data.plate, data)
end)

AddEventHandler('keep-jobgarages:client:delete_if_exist', function(plate, veh)
     if not plate and not veh then
          plate = currentVeh.plate
          veh = currentVeh.veh
     end
     TriggerServerEvent('keep-jobgarages:server:update_out_vehicles', {
          type = 'remove',
          plate = plate
     })
     QBCore.Functions.DeleteVehicle(veh)
end)

AddEventHandler('keep-jobgarages:client:keep_put_back_to_garage', function(e)
     local plyped = PlayerPedId()
     local IsInVehicle = IsPedInAnyVehicle(plyped, false)
     local playercoord = GetEntityCoords(plyped)
     local veh = nil

     if IsInVehicle then
          veh = GetVehiclePedIsIn(plyped, false)
     else
          local vehcheck, distance = QBCore.Functions.GetClosestVehicle(playercoord)
          if distance < 3.0 then
               if vehcheck ~= nil and NetworkGetEntityIsNetworked(vehcheck) and DoesEntityExist(vehcheck) and
                   IsEntityAVehicle(vehcheck) then
                    veh = vehcheck
               end
          else
               veh = nil
          end

     end
     if veh == nil then
          local inGarageStation = GetInGarageStation()
          if CanPlayerUseGarage() and not IsPauseMenuActive() and inGarageStation then
               -- store vehicle
               if IsPedInAnyVehicle(plyped, false) then
                    TriggerEvent('keep-jobgarages:client:keep_put_back_to_garage')
                    return
               end
               Open_menu()
          end
          return
     end
     if IsInVehicle then
          TaskLeaveVehicle(plyped, veh, 0)
          while IsPedInAnyVehicle(plyped, false) do
               Wait(100)
          end
          Wait(500)
     end

     local VehicleProperties = {}
     VehicleProperties.metadata = GetVehicleDamages(veh)
     VehicleProperties.VehicleProperties = QBCore.Functions.GetVehicleProperties(veh)
     TriggerCallback('keep-jobgarages:server:can_we_store_this_vehicle', function(result)
          if result ~= nil then
               local currentgarage = GetCurrentgarage()
               VehicleProperties.currentgarage = currentgarage
               TriggerServerEvent('keep-jobgarages:server:update_state', VehicleProperties.VehicleProperties.plate,
                    VehicleProperties)
               TriggerEvent('keep-jobgarages:client:delete_if_exist', VehicleProperties.VehicleProperties.plate, veh)
               return
          end
          TriggerServerEvent('keep-jobgarages:server:Notification', 'You can not store this vehicle', 'error')
     end, VehicleProperties)
end)

RegisterKeyMapping('+garage_menu', 'garage_menu', 'keyboard', 'u')
RegisterCommand('+garage_menu', function()
     local plyped = PlayerPedId()
     local inGarageStation = GetInGarageStation()
     if CanPlayerUseGarage() and not IsPauseMenuActive() and inGarageStation then
          -- store vehicle
          if IsPedInAnyVehicle(plyped, false) then
               TriggerEvent('keep-jobgarages:client:keep_put_back_to_garage')
               return
          end
          Open_menu()
     end
end, false)
