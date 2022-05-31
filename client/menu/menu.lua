local QBCore = exports['qb-core']:GetCoreObject()
Open = {}
local CacheDataRes = nil
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
     exports['qb-menu']:openMenu(openMenu)
end

local function tablelength(T)
     local count = 0
     for _ in pairs(T) do count = count + 1 end
     return count
end

local function get_vehicle_label(model)
     for key, value in pairs(Config.VehicleWhiteList[currentgarage]) do
          if value.spawncode == model then return value.name end
     end
end

function Open:get_vehicles_list(data)
     local models_count = tablelength(data)
     CacheDataRes = data
     local openMenu = {
          {
               header = "Go Back",
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-jobgarages:menu:open:garage_menu",
               }
          },
     }
     for key, DISTINCT in pairs(data.DISTINCT) do
          local size = #data[DISTINCT.model]
          openMenu[#openMenu + 1] = {
               header = get_vehicle_label(DISTINCT.model),
               txt = size .. " Vehicles",
               params = {
                    event = "keep-jobgarages:menu:open:vehicles_list",
                    args = CacheDataRes
               }
          }
     end

     exports['qb-menu']:openMenu(openMenu)
end

function Open:make_vehicles_list(vehicles_list)
     local openMenu = {
          {
               header = "Go Back",
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-jobgarages:menu:open:get_vehicles_list",
                    data = '_type'
               }
          },
     }
     for k, vehicle in pairs(vehicles_list.vehicles_data) do
          local out = 'out'
          if vehicle.state == 1 then out = 'In' end
          local info = vehicle.plate .. ' | ' .. out
          openMenu[#openMenu + 1] = {
               header = vehicle.name,
               txt = info,
               params = {
                    event = "keep-jobgarages:menu:open:vehicle_actions",
                    args = vehicle
               }
          }
     end
     exports['qb-menu']:openMenu(openMenu)
end

OutsideVehicles = {}
function Open:vehicle_actions(vehicle_data)
     -- spawn shell
     print_table(vehicle_data)

     QBCore.Functions.SpawnVehicle(vehicle_data.model, function(veh)
          if vehicle_data.plate then
               OutsideVehicles[vehicle_data.plate] = veh
               -- TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
          end

          QBCore.Functions.SetVehicleProperties(veh, vehicle_data.mods)
          SetVehicleNumberPlateText(veh, vehicle_data.plate)
          SetEntityHeading(veh, 270.5)
          local engine = math.floor(vehicle_data.engine / 10)
          local body = math.floor(vehicle_data.body / 10)
          local fuel = vehicle_data.fuel

          local status = "Engine: " .. engine .. " | Body: " .. body .. " | fuel: " .. fuel
          local openMenu = {
               {
                    header = "Go Back",
                    icon = 'fa-solid fa-angle-left',
                    params = {
                         event = "keep-jobgarages:menu:open:vehicles_list",
                         args = {
                              type = 'delete_vehicle',
                              veh = veh
                         }
                    }
               },
               {
                    header = 'Take Out Vehicle',
               },
               {
                    header = 'Vehicle Status',
                    txt = status,
                    disabled = true
               },
               {
                    header = 'Retrive Vehicle',
                    disabled = true
               },
               {
                    header = 'Vehicle Parking Log',
                    params = {
                         event = "keep-jobgarages:menu:open:vehicle_parking_log",
                         data = '_type'
                    }
               },
          }
          exports['qb-menu']:openMenu(openMenu)


          -- exports['LegacyFuel']:SetFuel(veh, vehicle_data.fuel)
          -- doCarDamage(veh, vehicle)
          -- SetEntityAsMissionEntity(veh, true, true)
          -- TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle_data.plate, vehicle_data.garage)
          -- closeMenuFull()
          -- TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)

          -- TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))

          -- SetVehicleEngineOn(veh, true, true)
     end, vector3(445.92, -996.92, 24.96), true)
end

function Open:vehicle_parking_log()
     local openMenu = {
          {
               header = "Go Back",
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-jobgarages:menu:open:vehicles_list",
                    data = '_type'
               }
          },
          {
               header = 'to In    | 17:56PM',
               txt = "Eddie Keep (sergeant) | 20% | 100%",
               icon = 'fa-solid fa-arrow-right-to-bracket'
          },
          {
               header = 'to Out | 16:56PM',
               txt = "Eddie Keep (sergeant) | 90% | 500%",
               icon = 'fa-solid fa-arrow-right-from-bracket'
          },
     }
     exports['qb-menu']:openMenu(openMenu)
end

RegisterKeyMapping('+garage_menu', 'garage_menu', 'keyboard', 'u')
RegisterCommand('+garage_menu', function()
     if not IsPauseMenuActive() then
          -- save vehicle
          if IsPedInAnyVehicle(PlayerPedId(), false) and Config.AllowledList[1] then
               Open:save_menu()
               return
          end
          -- -- store vehicle
          -- if IsPedInAnyVehicle(PlayerPedId(), false) then
          --      print('store')
          --      return
          -- end

          Open:garage_menu()
     end
end, false)

AddEventHandler('keep-jobgarages:menu:open:garage_menu', function(option)
     Open:garage_menu()
end)

AddEventHandler('keep-jobgarages:menu:open:get_vehicles_list', function(data)
     QBCore.Functions.TriggerCallback('keep-jobgarages:server:fetch_categories', function(result)
          Open:get_vehicles_list(result)
     end, {
          garage = currentgarage
     })
end)

AddEventHandler('keep-jobgarages:menu:open:vehicles_list', function(vehicles_list)
     Open:make_vehicles_list(vehicles_list)
end)

AddEventHandler('keep-jobgarages:menu:open:vehicle_actions', function(vehicles_data)
     Open:vehicle_actions(vehicles_data)
end)

AddEventHandler('keep-jobgarages:menu:open:vehicle_parking_log', function(option)
     Open:vehicle_parking_log()
end)

-- restricted functions

local function saveVehicle()
     local plyPed = PlayerPedId()
     local veh = GetVehiclePedIsIn(plyPed, false)
     local c_car = QBCore.Functions.GetVehicleProperties(veh)
     if not Config.VehicleWhiteList[currentgarage][tostring(c_car.model)] then return end

     local required_data = {
          vehicle = c_car,
          name = 'Sup',
          hash = GetHashKey(veh),
          garage = currentgarage,
          info = Config.VehicleWhiteList[currentgarage][tostring(c_car.model)]
     }
     QBCore.Functions.TriggerCallback('keep-jobgarages:server:save_vehicle', function(result)
          print(result)
     end, required_data)
end

function Open:save_menu()
     local openMenu = {
          {
               header = 'Current Vehicle',
               txt = "Something",
          },
          {
               header = 'Save Vehicle',
               params = {
                    event = "keep-jobgarages:client:save_order"
               }
          },
          {
               header = 'Leave',
               icon = 'fa-solid fa-circle-xmark',
               params = {
                    event = "qb-menu:closeMenu"
               }
          }
     }
     exports['qb-menu']:openMenu(openMenu)
end

AddEventHandler('keep-jobgarages:menu:open:save_menu', function(option)
     if not IsPedInAnyVehicle(PlayerPedId(), false) then return end
     Open:save_menu()
end)

AddEventHandler('keep-jobgarages:client:save_order', function(option)
     saveVehicle()
end)
