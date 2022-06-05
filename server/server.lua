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
     for key, value in pairs(self.vehicles) do
          if key == plate then
               return true, value, key
          end
     end
     return false, nil, nil
end

QBCore.Functions.CreateCallback('keep-jobgarages:server:is_this_thePlayer_that_has_vehicle', function(source, cb, plate)
     local state, data, source_player = out_vehicles:search(plate)
     if data == nil then
          cb(true)
          return
     end
     if state and source_player == source then
          cb(true)
          return
     end
     cb(false)
end)


RegisterNetEvent('keep-jobgarages:server:update_out_vehicles', function(o)
     o.source = source
     if o.type == 'add' then
          out_vehicles:add(o)
     else
          out_vehicles:remove(o)
     end
end)


QBCore.Functions.CreateCallback('keep-jobgarages:server:doesVehicleExist', function(source, cb, plate)
     local state, data = out_vehicles:search(string.upper(plate))
     cb(state)
end)

local function Round(num, dp)
     local mult = 10 ^ (dp or 0)
     return math.floor(num * mult + 0.5) / mult
end

-- restricted functions
local function GeneralInsert(options)
     local sqlQuery = 'INSERT INTO keep_garage (citizenid,name,model,hash,mods,plate,fakeplate,garage,fuel,engine,body,state,driving_distance,permissions) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)'
     local QueryData = {
          options.citizenid,
          options.name,
          options.model,
          options.hash,
          json.encode(options.mods),
          options.plate,
          options.fakeplate,
          options.garage,
          options.fuel,
          options.engine,
          options.body,
          options.state,
          options.driving_distance,
          json.encode(options.permissions)
     }
     return MySQL.Async.insert(sqlQuery, QueryData)
end

local function vehicle_data_logger(options)
     local sqlQuery = 'INSERT INTO keep_garage_logs (plate,action,citizenid,data) VALUES (?,?,?,?)'
     local tmp = {
          charinfo = options.charinfo,
          garage = options.garage,
          vehicle_info = {
               fuel = Round(options.fuel, 2),
               engine = Round(options.engine, 2),
               body = Round(options.body, 2),
          }
     }
     local QueryData = {
          string.upper(options.plate),
          options.action,
          options.citizenid,
          json.encode(tmp)
     }
     return MySQL.Async.insert(sqlQuery, QueryData)
end

QBCore.Functions.CreateCallback('keep-jobgarages:server:get_vehicle_log', function(source, cb, data)
     local player = QBCore.Functions.GetPlayer(source)
     local LOGS = MySQL.Sync.fetchAll('SELECT plate,action,citizenid,data,DATE_FORMAT(created,"%Y:%m:%d %h:%m:%s") AS Action_timestamp  FROM keep_garage_logs WHERE plate = ? order by Action_timestamp desc limit 15', { data.plate })

     cb(LOGS)
end)

QBCore.Functions.CreateCallback('keep-jobgarages:server:save_vehicle', function(source, cb, data)
     -- check for existing one too
     local player = QBCore.Functions.GetPlayer(source)
     local ready_data = {}

     ready_data.citizenid = player.PlayerData.citizenid
     ready_data.name = data.name or "placeholder"
     ready_data.model = data.info.spawncode
     ready_data.hash = data.hash
     ready_data.mods = data.vehicle
     ready_data.plate = data.plate or data.vehicle.plate
     ready_data.fakeplate = nil
     ready_data.garage = data.garage
     ready_data.fuel = data.vehicle.fuelLevel
     ready_data.engine = data.vehicle.engineHealth
     ready_data.body = data.vehicle.bodyHealth
     ready_data.state = true
     ready_data.driving_distance = 0.0
     ready_data.state = true -- true means vehicle is inside garage

     ready_data.permissions = {
          grades = data.grades,
          cids = data.cids,
          job = data.job
     }

     GeneralInsert(ready_data)
     cb(true)
end)

QBCore.Functions.CreateCallback('keep-jobgarages:server:fetch_categories', function(source, cb, data)
     local player = QBCore.Functions.GetPlayer(source)
     local DISTINCT = MySQL.Sync.fetchAll('SELECT DISTINCT model FROM keep_garage WHERE garage = ?', { data.garage })
     local CURRENT_GARAGE_VEHICLS = MySQL.Sync.fetchAll('SELECT * FROM keep_garage WHERE garage = ?', { data.garage })
     local tmp = {}
     for key, value in pairs(CURRENT_GARAGE_VEHICLS) do
          if tmp[value.model] == nil then
               tmp[value.model] = {}
          end
          value.mods = json.decode(value.mods)
          value.metadata = json.decode(value.metadata)
          value.permissions = json.decode(value.permissions)
          value.current_player_id = player.PlayerData.citizenid
          table.insert(tmp[value.model], value)
     end
     tmp.DISTINCT = DISTINCT
     cb(tmp)
end)

QBCore.Functions.CreateCallback('keep-jobgarages:server:can_we_store_this_vehicle', function(source, cb, data)
     local state = MySQL.Sync.fetchScalar('SELECT hash FROM keep_garage WHERE plate = ?', { data.plate })
     cb(state)
end)

RegisterNetEvent("keep-jobgarages:server:update_state", function(plate, properties)
     local src = source
     local Player = QBCore.Functions.GetPlayer(src)
     local STATE = MySQL.Sync.fetchScalar('SELECT state FROM keep_garage WHERE plate = ?', { plate })
     if STATE == 0 then
          -- save damages too
          if properties ~= nil then
               MySQL.Async.execute('UPDATE keep_garage SET state = ?, garage = ? ,fuel = ? ,engine = ?, body = ?, metadata = ? WHERE plate = ?', {
                    1,
                    properties.currentgarage,
                    math.floor(properties.fuelLevel),
                    math.floor(properties.engineHealth),
                    math.floor(properties.bodyHealth),
                    json.encode(properties.metadata),
                    properties.plate
               }, function(result)
                    if result == 1 then
                         TriggerClientEvent('QBCore:Notify', src, 'Vehicle stored successfully', 'success')
                         vehicle_data_logger({
                              citizenid = Player.PlayerData.citizenid,
                              plate = plate,
                              charinfo = Player.PlayerData.charinfo,
                              action = 'store',
                              fuel = properties.fuelLevel, engine = properties.engineHealth, body = properties.bodyHealth
                         })
                         return
                    end
               end)
               return
          end
          TriggerClientEvent('QBCore:Notify', src, 'Failed to get vehicle', 'error', 2500)
     else
          MySQL.Async.execute('UPDATE keep_garage SET state = ? WHERE plate = ?', { 0, plate })
          TriggerClientEvent('QBCore:Notify', src, 'Vehicle got out successfully', 'success')
          vehicle_data_logger({
               citizenid = Player.PlayerData.citizenid,
               plate = plate,
               charinfo = Player.PlayerData.charinfo,
               action = 'out',
               fuel = properties.fuel, engine = properties.engine, body = properties.body
          })
     end
end)

RegisterNetEvent("keep-jobgarages:server:retrive_vehicle", function(plate)
     local src = source
     local Player = QBCore.Functions.GetPlayer(src)
     local STATE = MySQL.Sync.fetchScalar('SELECT state FROM keep_garage WHERE plate = ?', { plate })

     if STATE == 0 then
          if not Player.Functions.RemoveMoney("bank", Config.RetrivePrice, 'retrive_vehicle') then
               TriggerClientEvent('QBCore:Notify', src, "You need to pay " .. Config.RetrivePrice .. "$ to retrive vehicle", 'error', 2500)
               return
          end
          MySQL.Async.execute('UPDATE keep_garage SET state = ?,fuel=?,engine=?,body = ? WHERE plate = ?', { 1, 15, 400, 100, plate }, function(result)
               if result == 1 then
                    TriggerClientEvent('QBCore:Notify', src, 'Vehicle retrived successfully', 'success')
                    vehicle_data_logger({
                         citizenid = Player.PlayerData.citizenid,
                         plate = plate,
                         charinfo = Player.PlayerData.charinfo,
                         action = 'retrive',
                         fuel = 15, engine = 400, body = 100
                    })
                    out_vehicles:remove({ plate = plate })
                    return
               end
          end)
          return
     else
          TriggerClientEvent('QBCore:Notify', src, 'You can not request retrive on this vehicle ', 'error')
     end
end)

RegisterNetEvent("qb-customs:server:updateVehicle", function(myCar)
     MySQL.Async.execute('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(myCar), myCar.plate })
end)

QBCore.Commands.Add('saveInsideGarage', 'Save a vehicle as shared vehicle inside a garage', {}, true, function(source, args)
     local Player = QBCore.Functions.GetPlayer(source)

     for key, value in pairs(Config.AllowledList) do
          if value == Player.PlayerData.citizenid then
               TriggerClientEvent('keep-jobgarages:client:newVehicleSetup', source)
               return
          end
     end
     TriggerClientEvent('QBCore:Notify', source, 'You are not whitelisted', 'error')
end, 'user')
