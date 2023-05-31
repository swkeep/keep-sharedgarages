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
local currentVeh = {}
keep_menu = {}

function Open_menu()
     if Config.Menu == "qb-menu" then return qb_menu:garage_menu() end

     keep_menu:garage_menu()
end

AddEventHandler('keep-sharedgarages:menu:open:garage_menu', function(option)
     Open_menu()
end)

---------------------------------------------------- functions ------------------------------------------

function split(s, delimiter)
     if s == '' then return end
     local result = {};
     for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
          table.insert(result, match);
     end
     return result;
end

function is_restricted_by_grades(vehicle)
     for key, value in pairs(vehicle.permissions.grades) do
          if value then
               return value
          end
     end
     return false
end

function check_grades(vehicle)
     local garage = GetCurrentgarageData()
     if garage and garage.type == 'job' then
          for key, value in pairs(vehicle.permissions.grades) do
               if GetJobInfo().grade.level == tonumber(key) and value == true then
                    return true
               end
          end
     elseif garage and garage.type == 'gang' then
          for key, value in pairs(vehicle.permissions.grades) do
               if PlayerGang.grade.level == tonumber(key) and value == true then
                    return true
               end
          end
     end
     return false
end

function is_restricted_by_cid(vehicle)
     if string.len(vehicle.permissions.cids) == 0 then
          return false
     end
     return true
end

function check_cids(vehicle)
     local cids = split(vehicle.permissions.cids, ",")
     for key, value in pairs(cids) do
          if vehicle.current_player_id == value then
               return true
          end
     end
     return false
end

function cidWhiteListed(garage)
     if not Config.Garages[garage] then return false end
     if not Config.Garages[garage].garage_management then return false end
     local citizenid = QBCore.Functions.GetPlayerData().citizenid
     if Config.Garages[garage].garage_management[citizenid] then
          if Config.Garages[garage].garage_management[citizenid] == true then
               return true
          end
          return false
     else
          return false
     end
end

---------------------------------------------------- keep-menu ------------------------------------------

function keep_menu:garage_menu()
     if not GetCurrentgarage() then return end
     local Menu = {}
     Menu = {
          {
               header = 'Shared Garage',
               subheader = 'Current: ' .. Config.Garages[GetCurrentgarage()].label,
               icon = 'fa-solid fa-car-on',
               disabled = true
          },
          {
               header = 'Shared Vehicles',
               subheader = 'List of shared vehicles',
               icon = 'fa-solid fa-car',
               action = function()
                    keep_menu:categories()
               end,
               submenu = true,
          },
          {
               header = 'Leave',
               leave = true
          },
     }

     exports['keep-menu']:createMenu(Menu)
end

function keep_menu:categories()
     TriggerCallback('keep-sharedgarages:server:GET:garage_categories', function(categories)
          local Menu = {
               {
                    header = "Go Back",
                    action = function()
                         keep_menu:garage_menu()
                    end,
                    back = true
               },
               {
                    header = 'Leave',
                    leave = true
               },
          }

          for _, category in pairs(categories) do
               local header = category.name
               if category.name == 'default' then
                    header = 'Guests'
               end

               Menu[#Menu + 1] = {
                    header = header,
                    subheader = category.count .. " Vehicles",
                    icon = category.icon or 'fa-solid fa-car-side',
                    action = function()
                         keep_menu:vehicles_inside_category(category)
                    end
               }
          end

          if cidWhiteListed(GetCurrentgarage()) then
               Menu[#Menu + 1] = {
                    header = 'Add A New Category',
                    icon = 'fa-solid fa-square-plus',
                    action = function()
                         TriggerCallback('keep-sharedgarages:server:GET:player_job_gang', function(metadata)
                              local detail = metadata[Config.Garages[GetCurrentgarage()].type]
                              local grades = metadata.extra[Config.Garages[GetCurrentgarage()].type]

                              local Input = {
                                   inputs = {
                                        {
                                             type = 'text',
                                             isRequired = true,
                                             name = 'category',
                                             text = "name of new category",
                                             icon = 'fa-solid fa-money-bill-trend-up',
                                             title = 'Category Name',
                                        },
                                        {
                                             type = 'text',
                                             name = 'icon',
                                             icon = 'fa-solid fa-money-bill-trend-up',
                                             title = 'font icon',
                                             text = 'fa-solid fa-car-side',
                                             force_value = 'fa-solid fa-car-side'
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

                              -- sort grades
                              local temp_grages = {}
                              for key, value in pairs(grades) do
                                   temp_grages[tonumber(key + 1)] = value
                              end

                              for key, value in pairs(temp_grages) do
                                   Input.inputs[index].options[#Input.inputs[index].options + 1] = {
                                        value = key - 1,
                                        text = value.name
                                   }
                              end

                              local inputData, reason = exports['keep-input']:ShowInput(Input)
                              if reason == 'submit' then
                                   if inputData.citizenids then
                                        inputData.citizenids = split(inputData.citizenids, ",")
                                   end
                                   inputData.type_name = Config.Garages[GetCurrentgarage()].type
                                   TriggerCallback('keep-sharedgarages:server:POST:create_category', function(result)
                                        Wait(50)
                                        keep_menu:categories()
                                   end, inputData, GetCurrentgarage())
                              end
                         end)
                    end
               }
          end

          exports['keep-menu']:createMenu(Menu)
     end, GetCurrentgarage())
end

function get_vehicle_data(model)
     local list = Config.Garages[GetCurrentgarage()].WhiteList
     model = tonumber(model)
     if list.allow_all then
          for key, veh in pairs(QBCore.Shared.Vehicles) do
               if veh.hash == model then
                    return veh
               end
          end
          return false
     end

     for key, value in pairs(list) do
          if value.hash == model then
               return value
          end
     end
     return false
end

function keep_menu:vehicles_inside_category(category)
     TriggerCallback('keep-sharedgarages:server:GET:vehicles_on_category', function(vehicles)
          local Menu = {
               {
                    header = "Go Back",
                    action = function()
                         keep_menu:categories()
                    end,
                    back = true
               },
               {
                    header = 'Leave',
                    leave = true
               },

          }

          local subheader = category.name
          if subheader == 'default' then
               subheader = 'Guests'
          end
          Menu[#Menu + 1] = {
               header = "-------- (List Of Vehicles) --------",
               subheader = 'Category: ' .. subheader,
               disabled = true
          }
          for _, vehicle in pairs(vehicles) do
               local veh_data = get_vehicle_data(vehicle.model)
               if veh_data then
                    Menu[#Menu + 1] = {
                         header = 'Name: ' .. (vehicle.name or 'no-name'),
                         subheader = 'Model: ' .. (veh_data.name or veh_data.model),
                         footer = string.format('Plate: %s | State: %s', vehicle.plate, (vehicle.state and 'In' or 'Out')),
                         icon = category.icon,
                         action = function()
                              keep_menu:vehicle_actions_menu(vehicle, veh_data, category)
                         end
                    }
               end
          end

          if cidWhiteListed(GetCurrentgarage()) then
               if category.name ~= 'default' then
                    Menu[#Menu + 1] = {
                         header = 'Edit Category',
                         icon = 'fa-solid fa-square-minus',
                         action = function()
                              TriggerCallback('keep-sharedgarages:server:GET:player_job_gang', function(metadata)
                                   local detail = metadata[Config.Garages[GetCurrentgarage()].type]
                                   local Input = {
                                        inputs = {
                                             {
                                                  type = 'text',
                                                  isRequired = true,
                                                  name = 'name',
                                                  text = "Type new name here",
                                                  icon = 'fa-solid fa-money-bill-trend-up',
                                                  title = 'Name',
                                             },
                                        }
                                   }

                                   local inputData, reason = exports['keep-input']:ShowInput(Input)
                                   if reason == 'submit' then
                                        TriggerCallback('keep-sharedgarages:server:POST:edit_category', function(result)
                                             Wait(50)
                                             keep_menu:categories()
                                        end, 'name', inputData.name, category.name, GetCurrentgarage())
                                   end
                              end)
                         end
                    }

                    Menu[#Menu + 1] = {
                         header = 'Delete Category',
                         icon = 'fa-solid fa-square-minus',
                         action = function()
                              TriggerCallback('keep-sharedgarages:server:GET:player_job_gang', function(metadata)
                                   local detail = metadata[Config.Garages[GetCurrentgarage()].type]
                                   local Input = {
                                        inputs = {
                                             {
                                                  type = 'text',
                                                  isRequired = true,
                                                  name = 'conf',
                                                  text = "Type Confirm (^.^)",
                                                  icon = 'fa-solid fa-money-bill-trend-up',
                                                  title = 'Confirm',
                                             },
                                        }
                                   }

                                   local inputData, reason = exports['keep-input']:ShowInput(Input)
                                   if reason == 'submit' then
                                        if inputData.conf == 'Confirm' then
                                             TriggerCallback('keep-sharedgarages:server:DELETE:category', function(result)
                                                  Wait(50)
                                                  keep_menu:categories()
                                             end, category.name, GetCurrentgarage())
                                        else
                                             TriggerServerEvent('keep-sharedgarages:server:Notification', "Ok, i won't delete it!", 'error')
                                        end
                                   end
                              end)
                         end
                    }
               end
          end

          exports['keep-menu']:createMenu(Menu)
     end, category.name, GetCurrentgarage())
end

function keep_menu:vehicle_actions_menu(vehicle, veh_data, category)
     local nearspawnpoint = GetNearspawnpoint()
     local currentgarage = GetCurrentgarage()

     if is_restricted_by_cid(vehicle) then
          if check_cids(vehicle) == false then
               TriggerServerEvent('keep-sharedgarages:server:Notification', 'This vehicle is not allowed for you', 'error')
               if Config.Menu == "keep-menu" then 
                    keep_menu:vehicles_inside_category(category)
               elseif Config.Menu == "qb-menu" then
                    qb_menu:vehicles_inside_category(category)
               end
               return
          end
     end

     if is_restricted_by_grades(vehicle) then
          if check_grades(vehicle) == false then
               TriggerServerEvent('keep-sharedgarages:server:Notification', 'This vehicle is not allowed for your rank', 'error')
               if Config.Menu == "keep-menu" then 
                    keep_menu:vehicles_inside_category(category)
               elseif Config.Menu == "qb-menu" then
                    qb_menu:vehicles_inside_category(category)
               end
               return
          end
     end

     if vehicle.state == 0 then
          TriggerServerEvent('keep-sharedgarages:server:Notification', 'Vehicle is already out!', 'error')
          if Config.Menu == "keep-menu" then 
               keep_menu:vehicles_inside_category(category)
          elseif Config.Menu == "qb-menu" then
               qb_menu:vehicles_inside_category(category)
          end
          return
     end

     TriggerCallback('keep-sharedgarages:server:doesVehicleExist', function(result, per)
          if result == true then
               TriggerServerEvent('keep-sharedgarages:server:Notification', 'Vehicle is already out!', 'error')
               if Config.Menu == "keep-menu" then 
                    keep_menu:vehicles_inside_category(category)
               elseif Config.Menu == "qb-menu" then
                    qb_menu:vehicles_inside_category(category)
               end
               return
          end

          if not currentgarage or not nearspawnpoint then
               TriggerServerEvent('keep-sharedgarages:server:Notification', 'Try to find a free spot!', 'error')
               return
          end

          QBCore.Functions.SpawnVehicle(veh_data.model, function(veh)
               SetEntityAlpha(veh, 100, true)
               QBCore.Functions.SetVehicleProperties(veh, vehicle.mods)
               currentVeh = {
                    veh = veh,
                    plate = vehicle.plate
               }
               SetVehicleNumberPlateText(veh, vehicle.plate)
               SetNetworkIdAlwaysExistsForPlayer(NetworkGetNetworkIdFromEntity(veh), PlayerPedId(), true)
               SetEntityHeading(veh, Config.Garages[currentgarage].spawnPoint[nearspawnpoint].w)
               PlaceObjectOnGroundProperly(veh)
               FreezeEntityPosition(veh, true)
               -- add it to serverside list
               TriggerServerEvent('keep-sharedgarages:server:update_out_vehicles', {
                    type = 'add',
                    netId = NetworkGetNetworkIdFromEntity(veh),
                    plate = vehicle.plate
               })
               RecoverVehicleDamages(veh, vehicle)
               if Config.Menu == "keep-menu" then
                    keep_menu:take_out_menu(veh_data, vehicle, veh, per, category)
               elseif Config.Menu == "qb-menu" then
                    qb_menu:take_out_menu(veh_data, vehicle, veh, per, category)
               end
          end, Config.Garages[currentgarage].spawnPoint[nearspawnpoint], true)
     end, vehicle.plate, GetCurrentgarage())
end

function RGB(condtition)
     local num_in_255 = function(num)
          if num == 0 then return 0 end
          return math.ceil((num * 255) / 100)
     end

     local color_rgb = function(num)
          return string.format('rgb(%d,  %d,  %d)', (255 - num_in_255(num)), (num_in_255(num)), 0)
     end

     return color_rgb(condtition)
end

function keep_menu:take_out_menu(data, vehicle, veh, per, category)
     local veh_data = get_vehicle_data(vehicle.model)
     if not veh_data then
          print('FAILED to get vehicles model or lable')
          return
     end
     local engine = math.floor(vehicle.engine / 10)
     local body = math.floor(vehicle.body / 10)
     local fuel = vehicle.fuel

     local status = string.format("--------- Detail --------- </br> Engine:<span style='color:%s'> %s </span> </br> Body:<span style='color:%s'> %s </span> </br> Fuel:<span style='color:%s'> %s </span>"
          , RGB(engine), engine, RGB(body), body, RGB(fuel), fuel)

     local Menu = {
          {
               header = "Go Back",
               icon = 'fa-solid fa-angle-left',
               action = function()
                    TriggerServerEvent('keep-sharedgarages:server:update_out_vehicles', {
                         type = 'remove',
                         plate = vehicle.plate
                    })
                    QBCore.Functions.DeleteVehicle(veh)
                    while DoesEntityExist(veh) do Wait(50) end
                    keep_menu:vehicles_inside_category(category)
               end
          },
          {
               header = 'Leave',
               leave = true
          },
          {
               header = 'Vehicle Status',
               icon = 'fa-solid fa-car-battery',
               subheader = ('Name: %s </br> Model: %s'):format(vehicle.name, veh_data.label or veh_data.model),
               footer = status,
               is_header = true
          },
          {
               header = 'Take Out Vehicle',
               icon = 'fa-solid fa-arrow-right-from-bracket',
               args = { 'take-out' },
               action = function()
                    ResetEntityAlpha(veh)
                    FreezeEntityPosition(veh, false)
                    SetEntityCollision(veh, true, true)
                    SetEntityAsMissionEntity(veh, true, true)
                    TriggerEvent("vehiclekeys:client:SetOwner", vehicle.plate)
                    exports[Config.fuel_script]:SetFuel(veh, fuel)
                    TriggerCallback('keep-sharedgarages:server:give_keys_to_all_same_job', function(receivers)
                         for _, id in pairs(receivers) do
                              TriggerServerEvent('qb-vehiclekeys:server:GiveVehicleKeys', id, vehicle.plate)
                         end
                    end, PlayerJob)
                    TriggerServerEvent('keep-sharedgarages:server:update_state', vehicle.plate, {
                         vehicle = veh,
                         fuel = fuel,
                         engine = engine,
                         body = body,
                         plate = vehicle.plate,
                    })
               end
          },
          {
               header = 'Vehicle Parking Log',
               icon = 'fa-solid fa-clipboard-question',
               action = function()
                    keep_menu:vehicle_parking_log({
                         plate = vehicle.plate,
                         data = data,
                         vehicle = vehicle,
                         veh = veh,
                    }, per)
               end
          },
     }

     if cidWhiteListed(GetCurrentgarage()) then
          Menu[#Menu + 1] = {
               header = 'Edit',
               icon = 'fa-solid fa-pen-to-square',
               disabled = true
          }

          Menu[#Menu + 1] = {
               header = "Modify Vehicle's Name",
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
                         TriggerServerEvent('keep-sharedgarages:server:update_vehicle_name', inputData.vehicle_name, vehicle.plate, GetCurrentgarage())
                         Wait(50)
                         keep_menu:vehicles_inside_category(category)
                    end
               end
          }

          Menu[#Menu + 1] = {
               header = "Change Category",
               icon = 'fa-solid fa-pen-to-square',
               action = function()
                    TriggerCallback('keep-sharedgarages:server:GET:garage_categories', function(categories)
                         local _Menu = {
                              {
                                   header = "Go Back",
                                   icon = 'fa-solid fa-angle-left',
                                   action = function()
                                        Wait(50)
                                        keep_menu:vehicles_inside_category(category)
                                   end
                              },
                              {
                                   header = 'Leave',
                                   leave = true
                              },
                              {
                                   header = 'Choose A New Category',
                                   subheader = 'Current: ' .. Config.Garages[GetCurrentgarage()].label,
                                   footer = 'Current Category: ' .. category.name,
                                   icon = 'fa-solid fa-car-on',
                                   disabled = true
                              },
                         }

                         for key, _category in pairs(categories) do
                              if _category.name ~= 'default' then
                                   _Menu[#_Menu + 1] = {
                                        header = _category.name,
                                        icon = 'fa-solid fa-car-side',
                                        action = function()
                                             TriggerCallback('keep-sharedgarages:server:UPDATE:vehicle_category', function(result)
                                                  Wait(50)
                                                  keep_menu:vehicles_inside_category(category)
                                             end, vehicle.plate, _category.name, GetCurrentgarage())
                                        end,

                                        submenu = true,
                                   }
                              end
                         end

                         exports['keep-menu']:createMenu(_Menu)
                    end, GetCurrentgarage())
               end
          }

          Menu[#Menu + 1] = {
               header = "Toggle Customizability",
               icon = 'fa-solid fa-pen-to-square',
               action = function()
                    local Input = {
                         inputs = {
                              {
                                   isRequired = true,
                                   name = 'customizability',
                                   title = "Modify Vehicle's Customizability",
                                   force_value = vehicle.plate,
                                   type = "radio",
                                   options = {
                                        { value = true, text = 'Yes' },
                                        { value = false, text = 'No' },
                                   },
                              },
                         }
                    }

                    local inputData, reason = exports['keep-input']:ShowInput(Input)
                    if reason == 'submit' then
                         if not inputData.customizability then return end
                         TriggerServerEvent('keep-sharedgarages:server:set_is_customizable', inputData.customizability, vehicle.plate, GetCurrentgarage())
                         Wait(50)
                         keep_menu:vehicles_inside_category(category)
                    end
               end
          }

          Menu[#Menu + 1] = {
               header = "Delete Vehicle",
               subheader = "You won't be able to get this vehicle back!",
               icon = 'fa-solid fa-pen-to-square',
               action = function()
                    local Input = {
                         inputs = {
                              {
                                   isRequired = true,
                                   name = 'delete',
                                   title = "Delete Vehicle",
                                   force_value = vehicle.plate,
                                   type = "radio",
                                   options = {
                                        { value = true, text = 'Yes' },
                                        { value = false, text = 'No' },
                                   },
                              },
                         }
                    }

                    local inputData, reason = exports['keep-input']:ShowInput(Input)
                    if reason == 'submit' then
                         if not inputData.delete then return end
                         if inputData.delete == 'true' then
                              TriggerServerEvent('keep-sharedgarages:server:delete', vehicle.plate, GetCurrentgarage())
                              Wait(50)
                              keep_menu:vehicles_inside_category(category)
                         end
                    end
               end
          }
     end

     local op = exports['keep-menu']:createMenu(Menu)
     if op == 'take-out' then return end
     if not op then
          TriggerServerEvent('keep-sharedgarages:server:update_out_vehicles', {
               type = 'remove',
               plate = vehicle.plate
          })
          QBCore.Functions.DeleteVehicle(veh)
     end
end

function keep_menu:vehicle_parking_log(data, per)
     local Menu = {
          {
               header = 'Leave',
               leave = true
          },
          {
               header = 'Logs',
               icon = 'fa-solid fa-car',
               disabled = true,
               is_header = true
          },
     }

     TriggerCallback('keep-sharedgarages:server:get_vehicle_log', function(LOGS)
          local icons = {
               retrive = 'fa-solid fa-arrow-right-arrow-left',
               store = 'fa-solid fa-arrow-right-to-bracket',
               out = 'fa-solid fa-arrow-right-from-bracket'
          }

          if not (type(LOGS) == "table") then return end

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
               TriggerServerEvent('keep-sharedgarages:server:update_out_vehicles', {
                    type = 'remove',
                    plate = data.plate
               })
               QBCore.Functions.DeleteVehicle(data.veh)
          end
     end, { plate = data.plate })
end

AddEventHandler('keep-sharedgarages:client:take_out', function(data)
     data = data[1]
     local plate = QBCore.Functions.GetPlate(data.vehicle)
     ResetEntityAlpha(data.vehicle)
     FreezeEntityPosition(data.vehicle, false)
     SetEntityCollision(veh, true, true)
     SetEntityAsMissionEntity(data.vehicle, true, true)
     TriggerEvent("vehiclekeys:client:SetOwner", plate)
     exports[Config.fuel_script]:SetFuel(data.vehicle, data.fuel)
     TriggerCallback('keep-sharedgarages:server:give_keys_to_all_same_job', function(receivers)
          for _, id in pairs(receivers) do
               TriggerServerEvent('qb-vehiclekeys:server:GiveVehicleKeys', id, plate)
          end
     end, PlayerJob)
     TriggerServerEvent('keep-sharedgarages:server:update_state', data.plate, data)
end)

AddEventHandler('keep-sharedgarages:client:delete_if_exist', function(plate, veh)
     if not plate and not veh then
          plate = currentVeh.plate
          veh = currentVeh.veh
     end
     TriggerServerEvent('keep-sharedgarages:server:update_out_vehicles', {
          type = 'remove',
          plate = plate
     })
     QBCore.Functions.DeleteVehicle(veh)
end)

AddEventHandler('keep-sharedgarages:client:keep_put_back_to_garage', function(e)
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
                    TriggerEvent('keep-sharedgarages:client:keep_put_back_to_garage')
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
     TriggerCallback('keep-sharedgarages:server:can_we_store_this_vehicle', function(result)
          if result ~= nil then
               local currentgarage = GetCurrentgarage()
               VehicleProperties.currentgarage = currentgarage
               TriggerServerEvent('keep-sharedgarages:server:update_state', VehicleProperties.VehicleProperties.plate, VehicleProperties)
               TriggerEvent('keep-sharedgarages:client:delete_if_exist', VehicleProperties.VehicleProperties.plate, veh)
               return
          end
          TriggerServerEvent('keep-sharedgarages:server:Notification', "This garage doesn't accept this vehicle!", 'error')
     end, VehicleProperties)
end)

RegisterKeyMapping('+garage_menu', 'garage_menu', 'keyboard', 'u')
RegisterCommand('+garage_menu', function()
     local plyped = PlayerPedId()
     local inGarageStation = GetInGarageStation()
     if CanPlayerUseGarage() and not IsPauseMenuActive() and inGarageStation then
          -- store vehicle
          if IsPedInAnyVehicle(plyped, false) then
               TriggerEvent('keep-sharedgarages:client:keep_put_back_to_garage')
               return
          end
          Open_menu()
     end
end, false)
