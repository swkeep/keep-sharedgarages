local QBCore = exports['qb-core']:GetCoreObject()
Open = {}

local function doCarDamage(currentVehicle, veh)
     local engine = veh.engine + 0.0
     local body = veh.body + 0.0

     Wait(100)

     if body < 900.0 then
          SmashVehicleWindow(currentVehicle, 0)
          SmashVehicleWindow(currentVehicle, 1)
          SmashVehicleWindow(currentVehicle, 2)
          SmashVehicleWindow(currentVehicle, 3)
          SmashVehicleWindow(currentVehicle, 4)
          SmashVehicleWindow(currentVehicle, 5)
          SmashVehicleWindow(currentVehicle, 6)
          SmashVehicleWindow(currentVehicle, 7)
     end

     if body <= 800.0 then
          SetVehicleDoorBroken(currentVehicle, 0, true)
          SetVehicleDoorBroken(currentVehicle, 1, true)
     end
     if body <= 700.0 then
          SetVehicleDoorBroken(currentVehicle, 2, true)
          SetVehicleDoorBroken(currentVehicle, 3, true)
     end
     if body <= 600.0 then
          SetVehicleDoorBroken(currentVehicle, 4, true)
          SetVehicleDoorBroken(currentVehicle, 5, true)
          SetVehicleDoorBroken(currentVehicle, 6, true)
     end
     -- if engine < 700.0 then
     --      SetVehicleTyreBurst(currentVehicle, 1, false, 990.0)
     --      SetVehicleTyreBurst(currentVehicle, 2, false, 990.0)
     --      SetVehicleTyreBurst(currentVehicle, 3, false, 990.0)
     --      SetVehicleTyreBurst(currentVehicle, 4, false, 990.0)
     -- end
     if engine < 500.0 then
          SetVehicleTyreBurst(currentVehicle, 0, false, 990.0)
          -- SetVehicleTyreBurst(currentVehicle, 5, false, 990.0)
          -- SetVehicleTyreBurst(currentVehicle, 6, false, 990.0)
          -- SetVehicleTyreBurst(currentVehicle, 7, false, 990.0)
     end
     SetVehicleEngineHealth(currentVehicle, engine)
     SetVehicleBodyHealth(currentVehicle, body)

end

local tmp_vehicle = nil
Cachedata = nil

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

local function get_vehicle_label(model)
     for key, value in pairs(Config.VehicleWhiteList[currentgarage]) do
          if value.spawncode == model then return value.name end
     end
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

     for key, DISTINCT in pairs(data.DISTINCT) do
          openMenu[#openMenu + 1] = {
               header = get_vehicle_label(DISTINCT.model),
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

     -- openMenu[#openMenu + 1] = {
     --      header = 'Leave',
     --      icon = 'fa-solid fa-circle-xmark',
     --      params = {
     --           event = "keep-jobgarages:client:close_menu"
     --      }
     -- }

     exports['qb-menu']:openMenu(openMenu)
end

function Open:vehicles_inside_category(data)
     if data.type == 'delete_already_out_vehicle' and data.veh then
          DeleteEntity(data.veh)
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
          local out = 'out'
          local state = true
          if vehicle.state == 1 then out = 'In' end
          if vehicle.state == 1 then state = false end
          local info = vehicle.plate .. ' | ' .. out
          openMenu[#openMenu + 1] = {
               header = vehicle.name,
               txt = info,
               disabled = state,
               params = {
                    event = "keep-jobgarages:menu:open:vehicle_actions",
                    args = {
                         type = 'vehicle_actions_menu',
                         model = data.model, -- local data
                         key = k
                    }
               }
          }
     end

     exports['qb-menu']:openMenu(openMenu)
end

function Open:vehicle_actions_menu(data)
     -- spawn shell
     local vehicle = Cachedata[data.model][data.key]

     QBCore.Functions.SpawnVehicle(data.model, function(veh)
          if vehicle.plate then
               tmp_vehicle = veh
          end

          QBCore.Functions.SetVehicleProperties(veh, vehicle.mods)
          SetVehicleNumberPlateText(veh, vehicle.plate)
          SetEntityHeading(veh, Config.JobGarages[currentgarage].spawnPoint[nearspawnpoint].w)
          PlaceObjectOnGroundProperly(veh)
          FreezeEntityPosition(veh, true)

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
                              veh = veh
                         }
                    }
               },
               {
                    header = 'Take Out Vehicle',
                    params = {
                         event = 'keep-jobgarages:client:take_out',
                         args = {
                              vehicle = veh,
                              fuel = fuel,
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

          doCarDamage(veh, vehicle)
     end, Config.JobGarages[currentgarage].spawnPoint[nearspawnpoint], true)

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

AddEventHandler('keep-jobgarages:menu:open:get_vehicles_list', function()
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
     tmp_vehicle = nil
     FreezeEntityPosition(data.vehicle, false)
     SetEntityAsMissionEntity(data.vehicle, true, true)
     TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(data.vehicle))
     exports['LegacyFuel']:SetFuel(data.vehicle, data.fuel)
     TriggerServerEvent('keep-jobgarages:server:update_state', data.plate, nil)
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
                    event = "keep-jobgarages:client:close_menu"
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

AddEventHandler('keep-jobgarages:client:close_menu', function()
     TriggerEvent('qb-menu:closeMenu')
end)

AddEventHandler('keep-jobgarages:client:delete_if_exist', function()
     if tmp_vehicle ~= nil then DeleteEntity(tmp_vehicle) end
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
     c_car.currentgarage = currentgarage
     TriggerServerEvent('keep-jobgarages:server:update_state', c_car.plate, c_car)
     Wait(150)
     DeleteEntity(veh)
end)

--

local radialMenuItemId = exports['qb-radialmenu']:AddOption({
     id = 'keep_put_back_to_garage',
     title = 'Park',
     icon = 'car',
     type = 'client',
     event = 'keep-jobgarages:client:keep_put_back_to_garage',
     shouldClose = true
})

local ResourceName = GetCurrentResourceName()
AddEventHandler('onResourceStop', function(resourceName)
     if resourceName == ResourceName then
          exports['qb-radialmenu']:RemoveOption(radialMenuItemId)
     end
end)
