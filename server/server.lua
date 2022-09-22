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

local out_vehicles = {
     vehicles = {},
}

function out_vehicles:add(o)
     self.vehicles[string.upper(o.plate)] = { source = o.source, netId = o.netId }
end

function out_vehicles:remove(o)
     if not o.plate then return end
     if self.vehicles[string.upper(o.plate)] then
          self.vehicles[string.upper(o.plate)] = nil
     end
end

function out_vehicles:search(plate)
     if self.vehicles[string.upper(plate)] then
          return true, plate, elf.vehicles[string.upper(plate)]
     else
          return false, nil, nil
     end
end

RegisterNetEvent('keep-jobgarages:server:update_out_vehicles', function(o)
     o.source = source
     if o.type == 'add' then
          out_vehicles:add(o)
     else
          out_vehicles:remove(o)
     end
end)

local function cidWhiteListed(Player)
     for key, value in pairs(Config.AllowledList) do
          if value == Player.PlayerData.citizenid then
               return true
          end
     end
     return false
end

CreateCallback('keep-jobgarages:server:doesVehicleExist', function(source, cb, plate)
     local Player = QBCore.Functions.GetPlayer(source)
     if not Player then return end
     local state, data = out_vehicles:search(string.upper(plate))
     cb(state, cidWhiteListed(Player))
end)

local function vehicle_data_logger(options, cb)
     local sqlQuery = 'INSERT INTO keep_garage_logs (plate,action,citizenid,data) VALUES (?,?,?,?)'
     local tmp = {
          charinfo = options.charinfo,
          garage = options.garage,
          vehicle_info = {
               fuel = math.floor(options.fuel),
               engine = math.floor(options.engine),
               body = math.floor(options.body),
          }
     }
     local QueryData = {
          string.upper(options.plate),
          options.action,
          options.citizenid,
          json.encode(tmp)
     }
     MySQL.Async.insert(sqlQuery, QueryData, function()
          if cb then
               cb()
          end
     end)
end

CreateCallback('keep-jobgarages:server:get_vehicle_log', function(source, cb, data)
     local LOGS = MySQL.Sync.fetchAll('SELECT plate,action,citizenid,data,DATE_FORMAT(created,"%Y:%m:%d %h:%m:%s") AS Action_timestamp  FROM keep_garage_logs WHERE plate = ? order by Action_timestamp desc limit 15'
          , { data.plate })

     cb(LOGS)
end)

CreateCallback('keep-jobgarages:server:save_vehicle', function(source, cb, data)
     -- check for existing one too
     if not data.plate then
          print('No plate has been sent!')
          return
     end
     local player = QBCore.Functions.GetPlayer(source)
     data.VehicleProperties.plate = data.plate

     local sqlQuery = 'INSERT INTO keep_garage (citizenid,name,model,hash,mods,plate,garage,fuel,engine,body,state,permissions) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)'
     local QueryData = {
          player.PlayerData.citizenid,
          data.name or "No Name",
          data.info.spawncode,
          data.hash,
          json.encode(data.VehicleProperties),
          string.upper(data.plate),
          data.garage,
          Round(data.VehicleProperties.fuelLevel),
          Round(data.VehicleProperties.engineHealth),
          Round(data.VehicleProperties.bodyHealth),
          true, -- state true means nobody took the vehicle out!
          json.encode({
               grades = data.grades,
               cids = data.cids,
               job = data.job
          })
     }
     MySQL.Async.insert(sqlQuery, QueryData, function()
          cb(true)
     end)
end)

CreateCallback('keep-jobgarages:server:fetch_categories', function(source, cb, data)
     local player = QBCore.Functions.GetPlayer(source)
     local tmp = {}
     MySQL.Async.fetchAll('SELECT DISTINCT model FROM keep_garage WHERE garage = ?', { data.garage },
          function(DISTINCT)
               tmp.DISTINCT = DISTINCT
               MySQL.Async.fetchAll('SELECT * FROM keep_garage WHERE garage = ?', { data.garage },
                    function(CURRENT_GARAGE_VEHICLS)
                         for key, value in pairs(CURRENT_GARAGE_VEHICLS) do
                              if tmp[value.model] == nil then
                                   tmp[value.model] = {}
                              end
                              value.mods = json.decode(value.mods)
                              value.metadata = json.decode(value.metadata)
                              value.permissions = json.decode(value.permissions)
                              value.current_player_id = player.PlayerData.citizenid
                              tmp[value.model][#tmp[value.model] + 1] = value
                         end
                         cb(tmp)
                    end)
          end)
end)

CreateCallback('keep-jobgarages:server:can_we_store_this_vehicle', function(source, cb, data)
     MySQL.Async.fetchScalar('SELECT hash FROM keep_garage WHERE plate = ?', { data.VehicleProperties.plate },
          function(state)
               cb(state)
          end)
end)

RegisterNetEvent('keep-jobgarages:server:dupe', function(plate)
     local src = source
     local player = QBCore.Functions.GetPlayer(src)
     if not cidWhiteListed(player) then
          Notification(src, 'You are not whitelisted', 'error')
          return
     end
     local data = MySQL.Sync.fetchAll('SELECT * FROM `keep_garage` WHERE plate = ?', { plate })
     local sqlQuery = 'INSERT INTO keep_garage (citizenid,name,model,hash,mods,plate,garage,fuel,engine,body,state,permissions) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)'
     data = data[1]
     if data then
          local mods = json.decode(data.mods)
          local newplate = string.upper(RandomID(8))
          mods.plate = newplate
          local QueryData = {
               player.PlayerData.citizenid,
               data.name or "No Name",
               data.model,
               data.hash,
               json.encode(mods),
               newplate,
               data.garage,
               data.fuel,
               data.engine,
               data.body,
               true,
               data.permissions
          }
          MySQL.Async.insert(sqlQuery, QueryData, function()
               Notification(src, 'Vehicle duplicated successfully!', 'success')
          end)
     end
end)

RegisterNetEvent('keep-jobgarages:server:update_vehicle_name', function(new_name, plate)
     local src = source
     local player = QBCore.Functions.GetPlayer(src)
     if not cidWhiteListed(player) then
          Notification(src, 'You are not whitelisted', 'error')
          return
     end
     MySQL.Async.execute('UPDATE keep_garage SET name = ? WHERE plate = ?', { new_name or '', plate }, function()
          Notification(src, 'success', 'success')
     end)
end)

RegisterNetEvent('keep-jobgarages:server:update_vehicle_plate', function(new_plate, plate)
     local src = source
     local player = QBCore.Functions.GetPlayer(src)
     if not cidWhiteListed(player) then
          Notification(src, 'You are not whitelisted', 'error')
          return
     end
     MySQL.Async.execute('UPDATE keep_garage SET plate = ? WHERE plate = ?', { new_plate or plate, plate }, function()
          Notification(src, 'success', 'success')
     end)
end)

RegisterNetEvent('keep-jobgarages:server:set_is_customizable', function(state, plate)
     local src = source
     local player = QBCore.Functions.GetPlayer(src)
     if not cidWhiteListed(player) then
          Notification(src, 'You are not whitelisted', 'error')
          return
     end
     -- state might be no a bool value
     if state == 'false' then
          MySQL.Async.execute('UPDATE keep_garage SET is_customizable = ? WHERE plate = ?', { 0, plate }, function()
               Notification(src, 'success', 'success')
          end)
     else
          MySQL.Async.execute('UPDATE keep_garage SET is_customizable = ? WHERE plate = ?', { 1, plate }, function()
               Notification(src, 'success', 'success')
          end)
     end
end)

RegisterNetEvent('keep-jobgarages:server:delete', function(plate)
     local src = source
     local player = QBCore.Functions.GetPlayer(src)
     if not cidWhiteListed(player) then
          Notification(src, 'You are not whitelisted', 'error')
          return
     end
     -- state might be no a bool value
     MySQL.Async.execute('DELETE FROM keep_garage WHERE plate = ?', { plate }, function()
          Notification(src, 'success', 'success')
     end)

end)

RegisterNetEvent("keep-jobgarages:server:update_state", function(plate, properties)
     local src = source
     local Player = QBCore.Functions.GetPlayer(src)
     if not plate then
          print('no plate! (keep-jobgarages:server:update_state)')
          return
     end
     local STATE = MySQL.Sync.fetchScalar('SELECT state FROM keep_garage WHERE plate = ?', { plate })
     if STATE == 0 then
          -- save damages too
          if properties ~= nil then
               local s = 'UPDATE keep_garage SET state = ?, garage = ? ,fuel = ? ,engine = ?, body = ?, metadata = ? WHERE plate = ?'
               MySQL.Async.execute(s, {
                    1,
                    properties.currentgarage,
                    math.floor(properties.VehicleProperties.fuelLevel),
                    math.floor(properties.VehicleProperties.engineHealth),
                    math.floor(properties.VehicleProperties.bodyHealth),
                    json.encode(properties.metadata),
                    plate
               }, function(result)
                    if result == 1 then
                         Notification(src, 'Vehicle stored successfully', 'success')
                         vehicle_data_logger({
                              citizenid = Player.PlayerData.citizenid,
                              plate = plate,
                              charinfo = Player.PlayerData.charinfo,
                              action = 'store',
                              fuel = properties.VehicleProperties.fuelLevel,
                              engine = properties.VehicleProperties.engineHealth,
                              body = properties.VehicleProperties.bodyHealth
                         })
                         local sql = 'UPDATE keep_garage SET mods = ? WHERE plate = ? AND is_customizable = 1'
                         MySQL.Async.execute(sql, {
                              json.encode(properties.VehicleProperties),
                              plate
                         })
                         return
                    end
               end)
               return
          end

          Notification(src, 'Failed to get vehicle', 'error')
     else
          MySQL.Async.execute('UPDATE keep_garage SET state = ? WHERE plate = ?', { 0, plate })
          -- Notification(src, 'Vehicle got out successfully', 'success')
          vehicle_data_logger({
               citizenid = Player.PlayerData.citizenid,
               plate = plate,
               charinfo = Player.PlayerData.charinfo,
               action = 'out',
               fuel = properties.fuel, engine = properties.engine, body = properties.body
          })
     end
end)

QBCore.Commands.Add('saveInsideGarage', 'Save vehicle in shared garage', {
     {
          name = "job name",
          help = ""
     },
}, true, function(source, args)
     local src = source
     if not args[1] or not QBCore.Shared.Jobs[args[1]] then
          Notification(src, 'Job name is wrong!', 'error')
          return
     end
     local Player = QBCore.Functions.GetPlayer(src)
     if not cidWhiteListed(Player) then
          Notification(src, 'You are not whitelisted', 'error')
          return
     end
     TriggerClientEvent('keep-jobgarages:client:newVehicleSetup', src, args[1], QBCore.Shared.Jobs[args[1]].grades)
end, 'user')

CreateCallback('keep-jobgarages:server:give_keys_to_all_same_job', function(source, cb, PlayerJob)
     local players = QBCore.Functions.GetPlayers()
     local list_of_players_with_same_job = {}
     for _, id in pairs(players) do
          local player = QBCore.Functions.GetPlayer(id)
          if (player.PlayerData.job.name == PlayerJob.name) and (id ~= source) then
               list_of_players_with_same_job[#list_of_players_with_same_job + 1] = id
          end
     end
     cb(list_of_players_with_same_job)
end)

--- put all vehicles back to the garage
---@param resourceName any
RegisterNetEvent('onResourceStart', function(resourceName)
     if resourceName ~= GetCurrentResourceName() then return end
     MySQL.Async.execute('UPDATE keep_garage SET state = ? WHERE state = ?', { 1, 0 })
end)

RegisterNetEvent('keep-jobgarages:server:Notification', function(msg, _type)
     local src = source
     Notification(src, msg, _type)
end)
