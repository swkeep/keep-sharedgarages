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

local function init_database()
     local array = {
          [[
          CREATE TABLE IF NOT EXISTS `keep_garage` (
               `id` int(11) NOT NULL AUTO_INCREMENT,
               `id_keep_garage_categories` int(11) NOT NULL,
               `citizenid` varchar(50) DEFAULT NULL,
               `name` varchar(50) DEFAULT NULL,
               `model` varchar(50) DEFAULT NULL,
               `hash` varchar(50) DEFAULT NULL,
               `mods` LONGTEXT NOT NULL ,
               `plate` varchar(50) DEFAULT NULL,
               `garage` varchar(50) DEFAULT NULL,
               `fuel` TINYINT DEFAULT NULL,
               `engine` FLOAT DEFAULT NULL,
               `body` FLOAT DEFAULT NULL,
               `state` BOOLEAN NOT NULL DEFAULT TRUE,
               `is_customizable` BOOLEAN NOT NULL DEFAULT TRUE,
               `metadata` LONGTEXT DEFAULT NULL,
               `permissions` TEXT NOT NULL,
               PRIMARY KEY (`id`),
               KEY `plate` (`plate`)
             ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;
     ]]    ,
          [[
          CREATE TABLE IF NOT EXISTS `keep_garage_logs` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `plate` varchar(50) DEFAULT NULL,
          `action` varchar(50) DEFAULT NULL,
          `citizenid` varchar(50) DEFAULT NULL,
          `data` TEXT DEFAULT NULL,
          `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `plate` (`plate`)
          ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;
     ]]    , [[
          CREATE TABLE IF NOT EXISTS `keep_garage_categories` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `name` varchar(50) DEFAULT NULL,
          `citizenid` TEXT DEFAULT NULL,
          `icon` varchar(50) DEFAULT NULL,
          `garage` varchar(50) DEFAULT NULL,
          `type` varchar(50) DEFAULT NULL,
          `grades` TEXT DEFAULT NULL,
          PRIMARY KEY (`id`),
          KEY `name` (`name`)
          ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;
     ]]
     }

     local function trim1(s)
          return (s:gsub("^%s*(.-)%s*$", "%1"))
     end

     for key, query in pairs(array) do
          MySQL.Sync.fetchScalar(trim1(query), {})
     end
end

CreateThread(function()
     init_database()
end)

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
          return true, plate, self.vehicles[string.upper(plate)]
     else
          return false, nil, nil
     end
end

RegisterNetEvent('keep-sharedgarages:server:update_out_vehicles', function(o)
     o.source = source
     if o.type == 'add' then
          out_vehicles:add(o)
     else
          out_vehicles:remove(o)
     end
end)

local function cidWhiteListed(Player, garage)
     if not Config.Garages[garage] then return false end
     if not Config.Garages[garage].garage_management then print('garage : ' .. garage .. "Doesn't have garage_management") return false end
     local citizenid = Player.PlayerData.citizenid
     if Config.Garages[garage].garage_management[citizenid] then
          if Config.Garages[garage].garage_management[citizenid] == true then
               return true
          end
          return false
     else
          return false
     end
end

CreateCallback('keep-sharedgarages:server:doesVehicleExist', function(source, cb, plate, current_garage)
     local Player = QBCore.Functions.GetPlayer(source)
     if not Player then return end
     local state, data = out_vehicles:search(string.upper(plate))
     cb(state, cidWhiteListed(Player, current_garage))
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

CreateCallback('keep-sharedgarages:server:get_vehicle_log', function(source, cb, data)
     local LOGS = MySQL.Sync.fetchAll('SELECT plate,action,citizenid,data,DATE_FORMAT(created,"%Y:%m:%d %h:%m:%s") AS Action_timestamp  FROM keep_garage_logs WHERE plate = ? order by Action_timestamp desc limit 15'
          , { data.plate })
     cb(LOGS)
end)

local function vehicle_plate_is_owned(plate)
     -- we can combine this two queries but nope i'm not gonna do it!
     -- check for vehicles owned by players
     local result = MySQL.Sync.fetchScalar('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
     -- check for vehicles saved inside garages
     local result2 = MySQL.Sync.fetchScalar('SELECT plate FROM keep_garage WHERE plate = ?', { plate })
     return (result or result2)
end

CreateCallback('keep-sharedgarages:server:save_vehicle', function(source, cb, data)
     -- local functions
     local function isWhitelisted()
          local list = Config.Garages[data.garage].WhiteList
          if not list then
               print(("FetalERROR: ( %s ) Doesn't have vehicle white list!"):format(data.garage))
               cb(false)
               return
          end
          local veh_model = tonumber(data.model)
          if not list then return end

          -- allow all
          if list.allow_all then
               -- #TODO add sup for additions
               return true
          end

          -- check garage white list
          for key, value in ipairs(list) do
               if value.hash == veh_model then
                    return true
               end
          end
          return false
     end

     if not isWhitelisted() then
          Notification(source, 'This vehicle is not listed on this garage!', 'error')
          return
     end

     -- check for existing one too
     if not data.plate then return end
     if vehicle_plate_is_owned(data.current_vehicle_plate) then
          Notification(source, 'Your ownership has been removed!', 'error')
          MySQL.Sync.execute('DELETE FROM player_vehicles WHERE plate = ?', { data.current_vehicle_plate })
          data.plate = data.current_vehicle_plate -- if we remove owned vehicle we can now use its plate right?!
     end

     local player = QBCore.Functions.GetPlayer(source)
     -- replace VehicleProperties's plate it will bug out if they are not same
     data.VehicleProperties.plate = data.plate

     local function get_category_id(Callback)
          if not data.category or not data.category.name then
               Notification(source, 'Did you forget category name?!', 'error')
               cb(false)
               return
          end
          if data.category.name and data.category.name == 'default' then
               Callback(0)
               return
          end
          MySQL.Async.fetchScalar('SELECT id FROM keep_garage_categories WHERE name = ? AND garage = ?', { data.category.name, data.garage }, function(id)
               if not id then cb({}) return end
               Callback(id)
          end)
     end

     local function save_in_category(category_id)
          local sqlQuery = 'INSERT INTO keep_garage (id_keep_garage_categories,citizenid,name,model,hash,mods,plate,garage,fuel,engine,body,state,permissions) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)'
          local QueryData = {
               category_id, -- id of category
               player.PlayerData.citizenid, -- who saved the vehicle
               data.name or "No Name",
               data.model, -- model hash
               data.hash, -- vehicle's hash (to just have and random number)
               json.encode(data.VehicleProperties),
               string.upper(data.plate),
               data.garage,
               100, -- fuel
               1000, -- engine
               1000, -- body
               true, -- state true means nobody took the vehicle out!
               json.encode({
                    grades = data.grades,
                    cids = data.cids,
                    job = data.job
               })
          }
          MySQL.Async.insert(sqlQuery, QueryData, function(insert)
               if insert then
                    Notification(source, 'Success', 'success')
                    cb(true)
               else
                    Notification(source, 'Failed', 'error')
                    cb(false)
               end
          end)
     end

     get_category_id(save_in_category)
end)

CreateCallback('keep-sharedgarages:server:can_we_store_this_vehicle', function(source, cb, data)
     MySQL.Async.fetchScalar('SELECT hash FROM keep_garage WHERE plate = ?', { data.VehicleProperties.plate }, function(state)
          cb(state)
     end)
end)

RegisterNetEvent('keep-sharedgarages:server:update_vehicle_name', function(new_name, plate, current_garage)
     local src = source
     local player = QBCore.Functions.GetPlayer(src)
     if not cidWhiteListed(player, current_garage) then
          Notification(src, 'You are not whitelisted', 'error')
          return
     end
     MySQL.Async.execute('UPDATE keep_garage SET name = ? WHERE plate = ?', { new_name or '', plate }, function()
          Notification(src, 'success', 'success')
     end)
end)

RegisterNetEvent('keep-sharedgarages:server:update_vehicle_plate', function(new_plate, plate, current_garage)
     -- this should check for already existing vehicls for potential dupe
     local src = source
     local player = QBCore.Functions.GetPlayer(src)
     if not cidWhiteListed(player, current_garage) then
          Notification(src, 'You are not whitelisted', 'error')
          return
     end
     MySQL.Async.execute('UPDATE keep_garage SET plate = ? WHERE plate = ?', { new_plate or plate, plate }, function()
          Notification(src, 'success', 'success')
     end)
end)

RegisterNetEvent('keep-sharedgarages:server:set_is_customizable', function(state, plate, current_garage)
     local src = source
     local player = QBCore.Functions.GetPlayer(src)
     if not cidWhiteListed(player, current_garage) then
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

RegisterNetEvent('keep-sharedgarages:server:delete', function(plate, current_garage)
     local src = source
     local player = QBCore.Functions.GetPlayer(src)
     if not cidWhiteListed(player, current_garage) then
          Notification(src, 'You are not whitelisted', 'error')
          return
     end
     -- state might be no a bool value
     MySQL.Async.execute('DELETE FROM keep_garage WHERE plate = ?', { plate }, function()
          Notification(src, 'success', 'success')
     end)
end)

RegisterNetEvent("keep-sharedgarages:server:update_state", function(plate, properties)
     local src = source
     local Player = QBCore.Functions.GetPlayer(src)
     if not plate then
          print('no plate! (keep-sharedgarages:server:update_state)')
          return
     end
     local STATE = MySQL.Sync.fetchScalar('SELECT state FROM keep_garage WHERE plate = ?', { plate })
     if STATE == false then
          -- save damages too
          if properties ~= nil then
               local s = 'UPDATE keep_garage SET state = ?, garage = ? ,fuel = ? ,engine = ?, body = ?, metadata = ? WHERE plate = ?'
               MySQL.Async.execute(s, {
                    1,
                    properties.currentgarage,
                    math.floor(properties.VehicleProperties.fuelLevel or 0),
                    math.floor(properties.VehicleProperties.engineHealth or 100.0),
                    math.floor(properties.VehicleProperties.bodyHealth or 100.0),
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

QBCore.Commands.Add('saveInsideGarage', 'Save vehicle in shared garage', {}, false, function(source, args)
     local src = source
     -- auth
     TriggerClientEvent('keep-sharedgarages:client:get_current_garage', src, 'keep-sharedgarages:server:saveInsideGarage')
end, 'user')

function GeneratePlate()
     local plate = RandomID(8):upper()
     local result = MySQL.Sync.fetchScalar('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
     if result then Wait(1) GeneratePlate() else return plate:upper() end
end

RegisterNetEvent('keep-sharedgarages:server:saveInsideGarage', function(current_garage)
     local src = source
     local function save(_type, _grades, random_plate)
          TriggerClientEvent('keep-sharedgarages:client:get_current_garage', src, 'keep-sharedgarages:server:saveInsideGarage_after', { _type, _grades, random_plate })
     end

     -- auth
     local Player = QBCore.Functions.GetPlayer(src)
     if not cidWhiteListed(Player, current_garage) then
          Notification(src, 'You are not whitelisted', 'error')
          return
     end

     if not current_garage then Notification(src, 'are you in a garage!?', 'error') return end
     if not Config.Garages[current_garage] then Notification(src, "Garage doesn't exsit!", 'error') return end
     local grades = {}
     local garage = Config.Garages[current_garage]


     local random_plate = GeneratePlate()
     if garage.job then
          grades = QBCore.Shared.Jobs[garage.job[1]].grades
          save(garage.job[1], grades, random_plate)
     elseif garage.gang then
          grades = QBCore.Shared.Gangs[garage.gang[1]].grades
          save(garage.gang[1], grades, random_plate)
     else
          Notification(src, "Job or Gang value doesn't exist for this garage!", 'error')
     end
end)

RegisterNetEvent('keep-sharedgarages:server:saveInsideGarage_after', function(current_garage, data)
     local src = source
     MySQL.Async.fetchAll('SELECT * FROM keep_garage_categories WHERE garage = ?', { current_garage }, function(res)
          TriggerClientEvent('keep-sharedgarages:client:newVehicleSetup', src, data[1], data[2], res, data[3])
     end)
end)

CreateCallback('keep-sharedgarages:server:give_keys_to_all_same_job', function(source, cb, PlayerJob)
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

RegisterNetEvent('keep-sharedgarages:server:Notification', function(msg, _type)
     local src = source
     Notification(src, msg, _type)
end)

-- category maker
CreateCallback('keep-sharedgarages:server:GET:category', function(source, cb, data)
     MySQL.Async.fetchAll('SELECT * FROM keep_garage_categories', {}, function(categories)
          for key, c in pairs(categories) do
               c.id = nil
          end
          cb(categories)
     end)
end)

CreateCallback('keep-sharedgarages:server:POST:create_category', function(source, cb, inputData, currentgarage)
     local Player = QBCore.Functions.GetPlayer(source)
     if not cidWhiteListed(Player, currentgarage) then
          Notification(source, 'You are not whitelisted', 'error')
          return
     end
     if not currentgarage then
          Notification(source, 'You must be inside a garage!', 'error')
          return
     end
     if not inputData.type_name == 'gang' or not inputData.type_name == 'job' then return end
     MySQL.Async.insert('INSERT INTO keep_garage_categories (name , citizenid, garage, icon, type, grades) VALUES (?,?,?,?,?,?)', {
          inputData.category or 'no-name',
          json.encode(inputData.citizenids or {}),
          currentgarage,
          inputData.icon or "fa-solid fa-car-side",
          inputData.type_name or 'job',
          json.encode(inputData.grades or {})
     }, function(res)
          Notification(source, 'Done', 'success')
          cb(res)
     end)
end)

CreateCallback('keep-sharedgarages:server:GET:player_job_gang', function(source, cb)
     local src = source
     local Player = QBCore.Functions.GetPlayer(src)
     cb({
          job = Player.PlayerData.job,
          gang = Player.PlayerData.gang,
          extra = {
               job = QBCore.Shared.Jobs[Player.PlayerData.job.name].grades,
               gang = QBCore.Shared.Gangs[Player.PlayerData.gang.name].grades
          }
     })
end)

CreateCallback('keep-sharedgarages:server:GET:garage_categories', function(source, cb, current_garage)
     local function count_guest_vehicles(res)
          local q = ''
          local qq = 'SELECT COUNT(id_keep_garage_categories) FROM keep_garage WHERE garage = ? '
          for key, c in ipairs(res) do
               local string = 'AND id_keep_garage_categories != ' .. c.id
               if key > 1 then
                    string = ' AND id_keep_garage_categories != ' .. c.id
               end
               q = q .. string
          end
          qq = qq .. q
          -- check for default but for guest vehicles
          return MySQL.Sync.fetchScalar(qq, { current_garage })
     end

     MySQL.Async.fetchAll('SELECT * FROM keep_garage_categories WHERE garage = ?', { current_garage }, function(res)
          for key, c in pairs(res) do
               c.count = MySQL.Sync.fetchScalar('SELECT COUNT(id_keep_garage_categories) FROM keep_garage WHERE id_keep_garage_categories = ?', { c.id })
          end

          -- check for default category
          local default_count = MySQL.Sync.fetchScalar('SELECT COUNT(id_keep_garage_categories) FROM keep_garage WHERE id_keep_garage_categories = ?', { 0 })
          local default_index = #res + 1
          if default_count > 0 then
               res[default_index] = {
                    id = 0,
                    name = 'default',
                    count = default_count
               }
          end

          -- guest vehicles are vehicles that doesn't belong to this garage
          local guests = count_guest_vehicles(res)

          if guests > 0 then
               local count = 0
               if not res[default_index] then
                    count = 0 + guests
               else
                    count = res[default_index].count + guests
               end
               res[default_index] = {
                    id = 0,
                    name = 'default',
                    count = count
               }
          end

          cb(res)
     end)
end)

CreateCallback('keep-sharedgarages:server:GET:vehicles_on_category', function(source, cb, category_name, current_garage)
     local src = source
     local Player = QBCore.Functions.GetPlayer(src)

     local function get_category_id(Callback)
          if category_name and category_name == 'default' then
               Callback(0)
               return
          end
          MySQL.Async.fetchScalar('SELECT id FROM keep_garage_categories WHERE name = ? AND garage = ?', { category_name, current_garage }, function(id)
               if not id then cb({}) return end
               Callback(id)
          end)
     end

     local function get_guest_vehicles(res)
          local q = ''
          local qq = 'SELECT * FROM keep_garage WHERE garage = ? '
          for key, c in ipairs(res) do
               local string = 'AND id_keep_garage_categories != ' .. c.id
               if key > 1 then
                    string = ' AND id_keep_garage_categories != ' .. c.id
               end
               q = q .. string
          end
          qq = qq .. q
          -- check for default but for guest vehicles
          return MySQL.Sync.fetchAll(qq, { current_garage })
     end

     local function send_vehicles_list(category_id)
          local tmp = {}
          MySQL.Async.fetchAll('SELECT * FROM keep_garage WHERE id_keep_garage_categories = ? AND garage = ?', { category_id, current_garage }, function(vehicles)
               if category_id == 0 then
                    MySQL.Async.fetchAll('SELECT * FROM keep_garage_categories WHERE garage = ?', { current_garage }, function(res)
                         local guests = get_guest_vehicles(res)

                         for key, vehicle in pairs(guests) do
                              if tmp[vehicle.model] == nil then
                                   tmp[vehicle.model] = {}
                              end
                              vehicle.mods = json.decode(vehicle.mods)
                              vehicle.metadata = json.decode(vehicle.metadata)
                              vehicle.permissions = json.decode(vehicle.permissions)
                              vehicle.current_player_id = Player.PlayerData.citizenid
                              tmp[#tmp + 1] = vehicle
                         end

                         -- vehicles the are acually on default category
                         for key, vehicle in pairs(vehicles) do
                              if tmp[vehicle.model] == nil then
                                   tmp[vehicle.model] = {}
                              end
                              vehicle.mods = json.decode(vehicle.mods)
                              vehicle.metadata = json.decode(vehicle.metadata)
                              vehicle.permissions = json.decode(vehicle.permissions)
                              vehicle.current_player_id = Player.PlayerData.citizenid
                              tmp[#tmp + 1] = vehicle
                         end
                         cb(tmp)
                    end)
                    return
               end

               for key, vehicle in pairs(vehicles) do
                    if tmp[vehicle.model] == nil then
                         tmp[vehicle.model] = {}
                    end
                    vehicle.mods = json.decode(vehicle.mods)
                    vehicle.metadata = json.decode(vehicle.metadata)
                    vehicle.permissions = json.decode(vehicle.permissions)
                    vehicle.current_player_id = Player.PlayerData.citizenid
                    tmp[#tmp + 1] = vehicle
               end

               cb(tmp)
          end)
     end

     get_category_id(send_vehicles_list)
end)

CreateCallback('keep-sharedgarages:server:POST:edit_category', function(source, cb, _type, new_data, current_data, currentgarage)
     -- #TODO check for permissions
     if not current_data then cb(false) return end

     local sql = ''
     local sql_data = { new_data, current_data, currentgarage }
     if _type == 'name' then
          if current_data == 'default' then Notification(src, 'you can not remove default category', 'error') return end

          sql = 'UPDATE keep_garage_categories SET name = ? WHERE name = ? AND garage = ?'
     elseif _type == 'icon' then
          sql = 'UPDATE keep_garage_categories SET icon = ? WHERE icon = ? AND garage = ?'
     elseif _type == 'grades' then
          sql = 'UPDATE keep_garage_categories SET grades = ? WHERE grades = ? AND garage = ?'
     else
          return
     end
     MySQL.Async.execute(sql, sql_data, function(res)
          if res then
               Notification(source, 'Done!', 'success')
          end
          cb(true)
     end)
end)

CreateCallback('keep-sharedgarages:server:DELETE:category', function(source, cb, category_name, current_garage)
     local src = source
     if not category_name then return end
     if category_name == 'default' then Notification(src, 'you can not remove default category', 'error') return end

     local function get_category_id(Callback)
          MySQL.Async.fetchScalar('SELECT id FROM keep_garage_categories WHERE name = ? AND garage = ?', { category_name, current_garage }, function(id)
               if not id then return end
               Callback(id)
          end)
     end

     local function fetch_vehicles_on_the_category(id)
          local sql = 'UPDATE keep_garage SET id_keep_garage_categories = ? WHERE id = ?'
          MySQL.Async.fetchAll('SELECT id FROM keep_garage WHERE id_keep_garage_categories = ? AND garage = ?', { id, current_garage }, function(vehicles)
               for _, veh in pairs(vehicles) do
                    MySQL.Async.execute(sql, { 0, veh.id })
               end
          end)
     end

     -- find id_keep_garage_categories and then check the garage name
     -- and then put them on an default category and then delete the category

     get_category_id(fetch_vehicles_on_the_category)

     MySQL.Async.execute('DELETE FROM keep_garage_categories WHERE name = ? AND garage = ?', { category_name, current_garage }, function(res)
          Notification(src, category_name .. ' is deleted!', 'success')
          cb(true)
     end)
end)

CreateCallback('keep-sharedgarages:server:UPDATE:vehicle_category', function(source, cb, plate, new_category, current_garage)
     local src = source
     if not new_category then return end
     if new_category == 'default' then Notification(src, 'you can not use default category', 'error') return end

     local function get_category_id(Callback)
          MySQL.Async.fetchScalar('SELECT id FROM keep_garage_categories WHERE name = ? AND garage = ?', { new_category, current_garage }, function(id)
               if not id then cb(false) return end
               Callback(id)
          end)
     end

     local function fetch_vehicles_on_the_category(category_id)
          local sql = 'UPDATE keep_garage SET id_keep_garage_categories = ? WHERE id = ?'
          MySQL.Async.fetchScalar('SELECT id FROM keep_garage WHERE plate = ? AND garage = ?', { plate, current_garage }, function(id)
               MySQL.Async.execute(sql, { category_id, id }, function(res)
                    if res then
                         Notification(src, 'Done!', 'success')
                         cb(true)
                    else
                         Notification(src, 'Failed!', 'error')
                         cb(false)
                    end
               end)
          end)
     end

     get_category_id(fetch_vehicles_on_the_category)
end)
