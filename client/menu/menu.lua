local QBCore = exports['qb-core']:GetCoreObject()
local Open = {}
local Cachedata = nil
local currentVeh = {}

function Open:garage_menu()
     local openMenu = {
          {
               header = 'Personal Vehicles',
               txt = "List of owned vehicles",
               disabled = true,
          },
          {
               header = 'Shared Vehicles',
               txt = "List of shared vehicles",
               params = {
                    event = 'keep-jobgarages:menu:open:get_vehicles_list'
               }
          },
     }
     openMenu[#openMenu + 1] = {
          header = 'Leave',
          icon = 'fa-solid fa-circle-xmark',
          params = {
               event = "keep-jobgarages:client:close_menu"
          }
     }
     exports['qb-menu']:openMenu(openMenu)
end

local function isWhitelisted(currentgarage, model)
     if type(model) == "number" then model = tostring(model) end
     local list = Config.JobGarages[currentgarage].WhiteList
     if not list then return end
     for key, value in pairs(list) do
          if value.spawncode == model then
               return true, value
          end
     end
     return false
end

local function get_vehicle_label(currentgarage, model)
     local state, info = isWhitelisted(currentgarage, model)
     return info.name
end

function Open:categories(data)
     Cachedata = data
     local openMenu = {
          {
               header = "Go Back",
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-jobgarages:menu:open:garage_menu",
               }
          },
          {
               header = 'Leave',
               icon = 'fa-solid fa-circle-xmark',
               params = {
                    event = "keep-jobgarages:client:close_menu"
               }
          }
     }
     local currentgarage = GetCurrentgarage()
     for key, DISTINCT in pairs(data.DISTINCT) do
          openMenu[#openMenu + 1] = {
               header = get_vehicle_label(currentgarage, DISTINCT.model),
               txt = #data[DISTINCT.model] .. " Vehicles",
               params = {
                    event = "keep-jobgarages:menu:open:vehicles_list",
                    args = {
                         type = 'vehicles_inside_category',
                         model = DISTINCT.model -- local data
                    }
               }
          }
     end

     exports['qb-menu']:openMenu(openMenu)
end

function Open:vehicles_inside_category(data)
     if data.type == 'delete_already_out_vehicle' and data.veh then
          TriggerServerEvent('keep-jobgarages:server:update_out_vehicles', {
               type = 'remove',
               plate = data.plate
          })
          QBCore.Functions.DeleteVehicle(data.veh)
          while DoesEntityExist(data.veh) do Wait(50) end
     end
     local openMenu = {
          {
               header = "Go Back",
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-jobgarages:menu:open:get_vehicles_list",
               }
          },
     }

     for k, vehicle in pairs(Cachedata[data.model]) do
          local state = 'out'
          if vehicle.state == 1 then state = 'In' end
          local info = vehicle.plate .. ' | ' .. state
          openMenu[#openMenu + 1] = {
               header = vehicle.name,
               txt = info,
               -- disabled = state,
               params = {
                    event = "keep-jobgarages:menu:open:vehicle_actions",
                    args = {
                         type = 'vehicle_actions_menu',
                         model = data.model, -- local data
                         key = k,
                    }
               }
          }
     end

     exports['qb-menu']:openMenu(openMenu)
end

local function split(s, delimiter)
     local result = {};
     for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
          table.insert(result, match);
     end
     return result;
end

local function is_restricted_by_grades(vehicle)
     if string.len(vehicle.permissions.grades) == 0 then
          return false
     end
     return true
end

local function check_grades(vehicle)
     local grades = split(vehicle.permissions.grades, ",")
     for key, value in pairs(grades) do
          if GetJobInfo().grade.level == tonumber(value) then
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

function Open:vehicle_actions_menu(data)
     -- spawn shell
     local vehicle = Cachedata[data.model][data.key]
     local nearspawnpoint = GetNearspawnpoint()
     local currentgarage = GetCurrentgarage()

     if is_restricted_by_cid(vehicle) then
          if check_cids(vehicle) == false then
               QBCore.Functions.Notify('This vehicle is not allowed for you', 'error', 2500)
               TriggerEvent('keep-jobgarages:menu:open:vehicles_list', {
                    type = 'vehicles_inside_category',
                    model = data.model
               })
               return
          end
     end

     if is_restricted_by_grades(vehicle) then
          if check_grades(vehicle) == false then
               QBCore.Functions.Notify('This vehicle is not allowed for you current rank', 'error', 2500)
               TriggerEvent('keep-jobgarages:menu:open:vehicles_list', {
                    type = 'vehicles_inside_category',
                    model = data.model
               })
               return
          end
     end

     if vehicle.state == 0 then
          QBCore.Functions.Notify('Vehicle is already out!', 'error', 2500)
          -- check if this player is toke this vehicle out if yes then show menu else go back to last menu
          QBCore.Functions.TriggerCallback('keep-jobgarages:server:is_this_thePlayer_that_has_vehicle', function(result)
               if result then
                    take_out_menu(data, vehicle, nil, {
                         active = true,
                         data = ''
                    })
                    return
               end
               TriggerEvent('keep-jobgarages:menu:open:vehicles_list', {
                    type = 'vehicles_inside_category',
                    model = data.model
               })
          end, vehicle.plate)

          return
     end
     QBCore.Functions.TriggerCallback('keep-jobgarages:server:doesVehicleExist', function(result)
          if result == true then
               QBCore.Functions.Notify('Vehicle is already out!', 'error', 2500)
               TriggerEvent('keep-jobgarages:menu:open:vehicles_list', {
                    type = 'vehicles_inside_category',
                    model = data.model -- local data
               })
               take_out_menu(data, vehicle)
               return
          end
          QBCore.Functions.SpawnVehicle(data.model, function(veh)
               QBCore.Functions.SetVehicleProperties(veh, vehicle.mods)
               currentVeh = {
                    veh = veh,
                    plate = vehicle.plate
               }
               SetVehicleNumberPlateText(veh, vehicle.plate)
               SetEntityHeading(veh, Config.JobGarages[currentgarage].spawnPoint[nearspawnpoint].w)
               PlaceObjectOnGroundProperly(veh)
               FreezeEntityPosition(veh, true)
               -- add it to serverside list
               TriggerServerEvent('keep-jobgarages:server:update_out_vehicles', {
                    type = 'add',
                    netId = NetworkGetNetworkIdFromEntity(veh),
                    plate = vehicle.plate
               })
               take_out_menu(data, vehicle, veh)
               RecoverVehicleDamages(veh, vehicle)
          end, Config.JobGarages[currentgarage].spawnPoint[nearspawnpoint], true)
     end, vehicle.plate)
end

AddEventHandler('keep-jobgarages:client:take_out_menu', function(data)
     take_out_menu(data.data, data.vehicle, data.veh, data.Retrive)
end)

function take_out_menu(data, vehicle, veh, Retrive)
     if Retrive == nil then
          Retrive = {}
          Retrive.active = false
     end
     local engine = math.floor(vehicle.engine / 10)
     local body = math.floor(vehicle.body / 10)
     local fuel = vehicle.fuel

     local status = "Engine: " .. engine .. " | Body: " .. body .. " | fuel: " .. fuel
     local openMenu = {
          {
               header = "Go Back",
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-jobgarages:menu:open:vehicles_list",
                    args = {
                         type = 'delete_already_out_vehicle',
                         model = data.model, -- local data
                         veh = veh,
                         plate = vehicle.plate
                    }
               }
          },
          {
               header = 'Take Out Vehicle',
               disabled = Retrive.active,
               params = {
                    event = 'keep-jobgarages:client:take_out',
                    args = {
                         vehicle = veh,
                         fuel = fuel,
                         engine = engine,
                         body = body,
                         plate = vehicle.plate
                    }
               }
          },
          {
               header = 'Vehicle Status',
               txt = status,
               disabled = true
          },
          {
               header = 'Retrive Vehicle',
               disabled = not Retrive.active,
               params = {
                    event = "keep-jobgarages:client:retrive_vehicle",
                    args = vehicle.plate
               }
          },
          {
               header = 'Vehicle Parking Log',
               params = {
                    event = "keep-jobgarages:client:get_vehicle_log",
                    args = { plate = vehicle.plate, data = data, vehicle = vehicle, veh = veh, Retrive = Retrive }
               }
          },
     }
     exports['qb-menu']:openMenu(openMenu)
end

function Open:vehicle_parking_log(LOGS)

     local openMenu = {
          {
               header = "Go Back",
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-jobgarages:menu:open:vehicles_list",
                    data = '_type'
               }
          },
     }

     for key, log in pairs(LOGS) do
          local header = log.action .. ' | ' .. log.created
          local data = json.decode(log.data)
          local sub_header = data.charinfo.firstname .. " " .. data.charinfo.lastname
          openMenu[#openMenu + 1] = {
               header = header,
               txt = sub_header,
               icon = 'fa-solid fa-arrow-right-to-bracket'
          }
     end

     exports['qb-menu']:openMenu(openMenu)
end

AddEventHandler('keep-jobgarages:client:retrive_vehicle', function(plate)
     TriggerServerEvent('keep-jobgarages:server:retrive_vehicle', plate)
end)

local tabIndexOverflow = function(seed, table)
     -- This subtracts values from the table from seed until an overflow
     -- This can be used for probability :D
     for i = 1, #table do
          if seed - table[i] <= 0 then
               return i, seed
          end
          seed = seed - table[i]
     end
end

local getDate = function(unix)
     -- Given unix date, return string date
     assert(unix == nil or type(unix) == "number" or unix:find("/Date%((%d+)"), "Please input a valid number to \"getDate\"")
     local unix = (type(unix) == "string" and unix:match("/Date%((%d+)") / 1000 or unix or os.time()) -- This is for a certain JSON compatability. It works the same even if you don't need it

     local dayCount, year, days, month = function(yr) return (yr % 4 == 0 and (yr % 100 ~= 0 or yr % 400 == 0)) and 366 or 365 end, 1970, math.ceil(unix / 86400)

     while days >= dayCount(year) do days = days - dayCount(year)
          year = year + 1
     end -- Calculate year and days into that year

     month, days = tabIndexOverflow(days, { 31, (dayCount(year) == 366 and 29 or 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }) -- Subtract from days to find current month and leftover days

     --  hours = hours > 12 and hours - 12 or hours == 0 and 12 or hours -- Change to proper am or pm time
     --  local period = hours > 12 and "pm" or "am"

     --  Formats for you!
     --  string.format("%d/%d/%04d", month, days, year)
     --  string.format("%02d:%02d:%02d %s", hours, minutes, seconds, period)
     return { Month = month, day = days, year = year, hours = math.floor(unix / 3600 % 24), minutes = math.floor(unix / 60 % 60), seconds = math.floor(unix % 60) }
end

AddEventHandler('keep-jobgarages:client:get_vehicle_log', function(data)
     local openMenu = {
          {
               header = "Go Back",
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-jobgarages:client:take_out_menu",
                    args = { data = data.data, vehicle = data.vehicle, veh = data.veh, Retrive = data.Retrive }
               }
          },
     }

     QBCore.Functions.TriggerCallback('keep-jobgarages:server:get_vehicle_log', function(LOGS)
          local icons = {
               retrive = 'fa-solid fa-arrow-right-arrow-left',
               store = 'fa-solid fa-arrow-right-to-bracket',
               out = 'fa-solid fa-arrow-right-from-bracket'
          }
          if type(LOGS) == "table" then
               for key, log in pairs(LOGS) do

                    local header = log.action .. ' | ' .. log.Action_timestamp
                    local _data = json.decode(log.data)
                    local sub_header = "Name: " .. _data.charinfo.firstname .. " " .. _data.charinfo.lastname
                    openMenu[#openMenu + 1] = {
                         header = header,
                         txt = sub_header,
                         icon = icons[log.action],
                         disabled = true
                    }
               end

               exports['qb-menu']:openMenu(openMenu)
          end
     end, { plate = data.plate })
end)

AddEventHandler('keep-jobgarages:menu:open:garage_menu', function(option)
     Open:garage_menu()
end)

AddEventHandler('keep-jobgarages:menu:open:get_vehicles_list', function()
     local currentgarage = GetCurrentgarage()
     QBCore.Functions.TriggerCallback('keep-jobgarages:server:fetch_categories', function(result)
          Open:categories(result)
     end, {
          garage = currentgarage
     })
end)

AddEventHandler('keep-jobgarages:menu:open:vehicles_list', function(data)
     Open:vehicles_inside_category(data)
end)

AddEventHandler('keep-jobgarages:menu:open:vehicle_actions', function(vehicles_data)
     Open:vehicle_actions_menu(vehicles_data)
end)

AddEventHandler('keep-jobgarages:menu:open:vehicle_parking_log', function(option)
     Open:vehicle_parking_log()
end)

AddEventHandler('keep-jobgarages:client:take_out', function(data)
     local plate = QBCore.Functions.GetPlate(data.vehicle)
     FreezeEntityPosition(data.vehicle, false)
     SetEntityAsMissionEntity(data.vehicle, true, true)
     TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(data.vehicle))
     QBCore.Functions.TriggerCallback('keep-jobgarages:server:give_keys_to_all_same_job', function(result)
          for key, id in pairs(result) do
               TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys_2', plate, id)
          end
     end)
     exports['LegacyFuel']:SetFuel(data.vehicle, data.fuel)
     TriggerServerEvent('keep-jobgarages:server:update_state', data.plate, data)
end)

-- restricted functions

AddEventHandler('keep-jobgarages:client:close_menu', function()
     TriggerEvent('qb-menu:closeMenu')
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
          local vehcheck = QBCore.Functions.GetClosestVehicle(playercoord)
          -- local platecheck = QBCore.Functions.GetPlate(vehcheck)
          if vehcheck ~= nil and NetworkGetEntityIsNetworked(vehcheck) and DoesEntityExist(vehcheck) then
               veh = vehcheck
          end
     end

     if veh == nil then return end
     if IsInVehicle then
          TaskLeaveVehicle(plyped, veh, 0)
          while IsPedInAnyVehicle(plyped, false) do
               Wait(100)
          end
     end
     local c_car = QBCore.Functions.GetVehicleProperties(veh)
     c_car.metadata = GetVehicleDamages(veh)

     QBCore.Functions.TriggerCallback('keep-jobgarages:server:can_we_store_this_vehicle', function(result)
          if result ~= nil then
               local currentgarage = GetCurrentgarage()
               c_car.currentgarage = currentgarage
               TriggerServerEvent('keep-jobgarages:server:update_state', c_car.plate, c_car)
               Wait(150)
               TriggerEvent('keep-jobgarages:client:delete_if_exist', c_car.plate, veh)
               return
          end
          QBCore.Functions.Notify('You can not store this vehicle', 'error', 5000)
     end, c_car)
end)

--

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
          Open:garage_menu()
     end
end, false)

local radialMenuItemId = exports['qb-radialmenu']:AddOption({
     id = 'keep_put_back_to_garage',
     title = 'Park',
     icon = 'car',
     type = 'client',
     event = 'keep-jobgarages:client:keep_put_back_to_garage',
     shouldClose = true
})

AddEventHandler('onResourceStop', function(resourceName)
     if resourceName == GetCurrentResourceName() then
          exports['qb-radialmenu']:RemoveOption(radialMenuItemId)
     end
end)
