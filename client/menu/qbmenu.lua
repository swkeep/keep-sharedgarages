local QBCore = exports['qb-core']:GetCoreObject()

qb_menu = {}

function GetParamsTable(args, action)
    if type(args) ~= "table" then return end
    local paramsTable = {
        args = args,
        isAction = function ()
            if type(action) == "function" then return true end
            return false
        end,
        event = action
    }
    return paramsTable
end

function qb_menu:garage_menu()
    if not GetCurrentgarage() then return end
    local Menu = {}
    Menu = {
        {
            header = 'Shared Garage',
            txt = 'Current: ' .. Config.Garages[GetCurrentgarage()].label,
            icon = 'fa-solid fa-car-on',
            disabled = true
        },
        {
            header = 'Shared Vehicles',
            txt = 'List of shared vehicles',
            icon = 'fa-solid fa-car',
            params = GetParamsTable({}, function()
                qb_menu:categories()
            end)
        },
        {
            header = 'Leave',
            icon = 'fa-solid fa-circle-xmark',
            params = GetParamsTable({}, 'qb-menu:client:closeMenu')
        },
    }

    exports['qb-menu']:openMenu(Menu)
end

function qb_menu:categories()
    TriggerCallback('keep-sharedgarages:server:GET:garage_categories', function(categories)
        local Menu = {
             {
                header = "Go Back",
                params = GetParamsTable({}, function()
                    qb_menu:garage_menu()
                end)
             },
             {
                  header = 'Leave',
                  icon = 'fa-solid fa-circle-xmark',
                  params = GetParamsTable({}, 'qb-menu:client:closeMenu')
             },
        }

        for _, category in pairs(categories) do
             local header = category.name
             if category.name == 'default' then
                  header = 'Guests'
             end

             Menu[#Menu + 1] = {
                  header = header,
                  txt = category.count .. " Vehicles",
                  icon = category.icon or 'fa-solid fa-car-side',
                  params = GetParamsTable({}, function()
                    qb_menu:vehicles_inside_category(category)
                  end)
             }
        end

        if cidWhiteListed(GetCurrentgarage()) then
             Menu[#Menu + 1] = {
                  header = 'Add A New Category',
                  icon = 'fa-solid fa-square-plus',
                  params = GetParamsTable({}, function()
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
                                   qb_menu:categories()
                              end, inputData, GetCurrentgarage())
                         end
                    end)
                  end)
             }
        end

        exports['qb-menu']:openMenu(Menu)
   end, GetCurrentgarage())
end

function qb_menu:vehicles_inside_category(category)
    TriggerCallback('keep-sharedgarages:server:GET:vehicles_on_category', function(vehicles)
        local Menu = {
             {
                  header = "Go Back",
                  params = GetParamsTable({}, function()
                    qb_menu:categories()
                  end)
             },
             {
                header = 'Leave',
                icon = 'fa-solid fa-circle-xmark',
                params = GetParamsTable({}, 'qb-menu:client:closeMenu')
             },

        }

        local subheader = category.name
        if subheader == 'default' then
             subheader = 'Guests'
        end
        Menu[#Menu + 1] = {
             header = "-------- (List Of Vehicles) --------",
             txt = 'Category: ' .. subheader,
             disabled = true
        }
        for _, vehicle in pairs(vehicles) do
             local veh_data = get_vehicle_data(vehicle.model)
             if veh_data then
                  Menu[#Menu + 1] = {
                       header = 'Name: ' .. (vehicle.name or 'no-name'),
                       txt = 'Model: ' .. (veh_data.name or veh_data.model) .. string.format('</br>Plate: %s | State: %s', vehicle.plate, (vehicle.state and 'In' or 'Out')),
                       icon = category.icon,
                       params = GetParamsTable({}, function()
                        qb_menu:vehicle_actions_menu(vehicle, veh_data, category)
                       end)
                  }
             end
        end

        if cidWhiteListed(GetCurrentgarage()) then
             if category.name ~= 'default' then
                  Menu[#Menu + 1] = {
                       header = 'Edit Category',
                       icon = 'fa-solid fa-square-minus',
                       params = GetParamsTable({}, function()
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
                                       qb_menu:categories()
                                  end, 'name', inputData.name, category.name, GetCurrentgarage())
                             end
                        end)
                       end)
                  }

                  Menu[#Menu + 1] = {
                       header = 'Delete Category',
                       icon = 'fa-solid fa-square-minus',
                       params = GetParamsTable({}, function()
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
                                            qb_menu:categories()
                                       end, category.name, GetCurrentgarage())
                                  else
                                       TriggerServerEvent('keep-sharedgarages:server:Notification', "Ok, i won't delete it!", 'error')
                                  end
                             end
                        end)
                       end)
                  }
             end
        end

        exports['qb-menu']:openMenu(Menu)
   end, category.name, GetCurrentgarage())
end

function qb_menu:take_out_menu(data, vehicle, veh, per, category)
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
              params = GetParamsTable({}, function()
                TriggerServerEvent('keep-sharedgarages:server:update_out_vehicles', {
                     type = 'remove',
                     plate = vehicle.plate
                })
                QBCore.Functions.DeleteVehicle(veh)
                while DoesEntityExist(veh) do Wait(50) end
                qb_menu:vehicles_inside_category(category)
              end)
         },
         {
            header = 'Leave',
            icon = 'fa-solid fa-circle-xmark',
            params = GetParamsTable({}, 'qb-menu:client:closeMenu')
         },
         {
              header = 'Vehicle Status',
              icon = 'fa-solid fa-car-battery',
              txt = ('Name: %s </br> Model: %s'):format(vehicle.name, veh_data.label or veh_data.model) .. "</br>" .. status,
              isMenuHeader = true
         },
         {
              header = 'Take Out Vehicle',
              icon = 'fa-solid fa-arrow-right-from-bracket',
              params = GetParamsTable({}, function()
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
               end)
         },
         {
              header = 'Vehicle Parking Log',
              icon = 'fa-solid fa-clipboard-question',
              params = GetParamsTable({}, function()
               qb_menu:vehicle_parking_log({
                    plate = vehicle.plate,
                    data = data,
                    vehicle = vehicle,
                    veh = veh,
               }, per)
              end)
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
              params = GetParamsTable({}, function()
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
                         qb_menu:vehicles_inside_category(category)
                    end
               end)
         }

         Menu[#Menu + 1] = {
              header = "Change Category",
              icon = 'fa-solid fa-pen-to-square',
              params = GetParamsTable({}, function()
               TriggerCallback('keep-sharedgarages:server:GET:garage_categories', function(categories)
                    local _Menu = {
                         {
                              header = "Go Back",
                              icon = 'fa-solid fa-angle-left',
                              params = GetParamsTable({}, function()
                                   Wait(50)
                                   qb_menu:vehicles_inside_category(category)
                              end)
                         },
                         {
                              header = 'Leave',
                              icon = 'fa-solid fa-circle-xmark',
                              params = GetParamsTable({}, 'qb-menu:client:closeMenu')
                         },
                         {
                              header = 'Choose A New Category',
                              txt = 'Current: ' .. Config.Garages[GetCurrentgarage()].label .. '</br>Current Category: ' .. category.name,
                              icon = 'fa-solid fa-car-on',
                              disabled = true
                         },
                    }

                    for key, _category in pairs(categories) do
                         if _category.name ~= 'default' then
                              _Menu[#_Menu + 1] = {
                                   header = _category.name,
                                   icon = 'fa-solid fa-car-side',
                                   params = GetParamsTable({}, function()
                                        TriggerCallback('keep-sharedgarages:server:UPDATE:vehicle_category', function(result)
                                             Wait(50)
                                             qb_menu:vehicles_inside_category(category)
                                        end, vehicle.plate, _category.name, GetCurrentgarage())
                                   end),
                              }
                         end
                    end

                    exports['qb-menu']:openMenu(_Menu)
               end, GetCurrentgarage())
          end)
         }

         Menu[#Menu + 1] = {
              header = "Toggle Customizability",
              icon = 'fa-solid fa-pen-to-square',
              params = GetParamsTable({}, function()
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
                    qb_menu:vehicles_inside_category(category)
               end
              end)
         }

         Menu[#Menu + 1] = {
              header = "Delete Vehicle",
              txt = "You won't be able to get this vehicle back!",
              icon = 'fa-solid fa-pen-to-square',
              params = GetParamsTable({}, function()
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
                              qb_menu:vehicles_inside_category(category)
                         end
                    end
               end)
         }
    end

    local op = exports['qb-menu']:openMenu(Menu)
    if not op then
         TriggerServerEvent('keep-sharedgarages:server:update_out_vehicles', {
              type = 'remove',
              plate = vehicle.plate
         })
         QBCore.Functions.DeleteVehicle(veh)
    end
end

function qb_menu:vehicle_parking_log(data, per)
     local Menu = {
          {
               header = 'Logs',
               icon = 'fa-solid fa-car',
               disabled = true,
               isMenuHeader = true
          },
          {
               header = 'Leave',
               icon = 'fa-solid fa-circle-xmark',
               params = GetParamsTable({}, 'qb-menu:client:closeMenu')
          }
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
                    txt = sub_header .. "</br>" .. log.Action_timestamp,
                    icon = icons[log.action],
                    disabled = true
               }
          end

          local op = exports['qb-menu']:openMenu(Menu)

          if not op then
               TriggerServerEvent('keep-sharedgarages:server:update_out_vehicles', {
                    type = 'remove',
                    plate = data.plate
               })
               QBCore.Functions.DeleteVehicle(data.veh)
          end
     end, { plate = data.plate })
end