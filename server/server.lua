local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('keep-jobgarages:server:get_vehicles_list', function(source, cb)
     local player = QBCore.Functions.GetPlayer(source)

     cb(player)
end)

QBCore.Functions.CreateCallback('keep-jobgarages:server:store_vehicle', function(source, cb)
     local player = QBCore.Functions.GetPlayer(source)

     cb(player)
end)

QBCore.Functions.CreateCallback('keep-jobgarages:server:take_out_vehicle', function(source, cb)
     local src = source
     local Player = QBCore.Functions.GetPlayer(src)
     local cashBalance = Player.PlayerData.money["cash"]
     local bankBalance = Player.PlayerData.money["bank"]

     local vehicle = data.vehicle

     MySQL.Async.fetchAll('SELECT * FROM player_vehicles WHERE plate = ?', { vehicle.plate }, function(result)
          if result[1] then
               if cashBalance >= result[1].depotprice then
                    Player.Functions.RemoveMoney("cash", result[1].depotprice, "paid-depot")
                    TriggerClientEvent("qb-garages:client:takeOutGarage", src, data)
               elseif bankBalance >= result[1].depotprice then
                    Player.Functions.RemoveMoney("bank", result[1].depotprice, "paid-depot")
                    TriggerClientEvent("qb-garages:client:takeOutGarage", src, data)
               else
                    TriggerClientEvent('QBCore:Notify', src, Lang:t("error.not_enough"), 'error')
               end
          end
     end)
end)


-- restricted functions
local function GeneralInsert(options)
     local sqlQuery = 'INSERT INTO keep_garage (citizenid,name,model,hash,mods,plate,fakeplate,garage,fuel,engine,body,state,driving_distance) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)'
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
     }
     return MySQL.Async.insert(sqlQuery, QueryData)
end

QBCore.Functions.CreateCallback('keep-jobgarages:server:save_vehicle', function(source, cb, data)
     -- check for existing one too
     local player = QBCore.Functions.GetPlayer(source)
     local ready_data = {}

     -- grades,cids

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

     GeneralInsert(ready_data)
     cb(true)
end)

QBCore.Functions.CreateCallback('keep-jobgarages:server:fetch_categories', function(source, cb, data)
     local DISTINCT = MySQL.Sync.fetchAll('SELECT DISTINCT model FROM keep_garage WHERE garage = ?', { data.garage })
     local CURRENT_GARAGE_VEHICLS = MySQL.Sync.fetchAll('SELECT * FROM keep_garage WHERE garage = ?', { data.garage })
     local tmp = {}
     for key, value in pairs(CURRENT_GARAGE_VEHICLS) do
          if tmp[value.model] == nil then
               tmp[value.model] = {}
          end
          value.mods = json.decode(value.mods)
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
     local STATE = MySQL.Sync.fetchScalar('SELECT state FROM keep_garage WHERE plate = ?', { plate })
     if STATE == 0 then
          -- save damages too
          if properties ~= nil then
               MySQL.Async.execute('UPDATE keep_garage SET state = ?,garage=?,fuel=?,engine = ?,body=? WHERE plate = ?', {
                    1,
                    properties.currentgarage,
                    math.floor(properties.fuelLevel),
                    math.floor(properties.engineHealth),
                    math.floor(properties.bodyHealth),
                    properties.plate
               }, function(result)
                    if result == 1 then
                         TriggerClientEvent('QBCore:Notify', src, 'Vehicle stored successfully', 'success')
                         return
                    end
               end)
               return
          end
          TriggerClientEvent('QBCore:Notify', src, 'Failed to get vehicle', 'error', 2500)
     else
          MySQL.Async.execute('UPDATE keep_garage SET state = ? WHERE plate = ?', { 0, plate })
          TriggerClientEvent('QBCore:Notify', src, 'Vehicle got out successfully', 'success')
     end
end)

RegisterNetEvent("qb-customs:server:updateVehicle", function(myCar)
     -- check for player job and grade to allow them to change customize cv
     MySQL.Async.execute('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(myCar), myCar.plate })
end)

-- RegisterNetEvent("keep-jobgarages:server:saveVehicle", function(myCar)
--      -- check for player job and grade to allow them to change customize cv
--      MySQL.Async.execute('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(myCar), myCar.plate })
-- end)

QBCore.Commands.Add('givemoney_2', 'Give A Person Your Money', { { name = 'id', help = 'Player ID' }, { name = 'amount', help = 'Amount of money' } }, true, function(source, args)
     local f_Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
     local c_Player = QBCore.Functions.GetPlayer(source)
     if f_Player and c_Player then
          if c_Player.Functions.RemoveMoney('cash', tonumber(args[2])) then
               f_Player.Functions.AddMoney('cash', tonumber(args[2]))
          end
     else
          TriggerClientEvent('QBCore:Notify', source, Lang:t('error.not_online'), 'error')
     end
end, 'user')

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
