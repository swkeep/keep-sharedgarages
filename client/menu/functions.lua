local function Round(num, dp)
     local mult = 10 ^ (dp or 0)
     return math.floor(num * mult + 0.5) / mult
end

local function get_door_damages(veh)
     local tmp = {}
     for i = 0, 5, 1 do
          tmp[tostring(i)] = IsVehicleDoorDamaged(veh, i)
     end
     return tmp
end

local function get_windows_damages(veh)
     local tmp = {}
     for i = 0, 7, 1 do
          tmp[tostring(i)] = IsVehicleWindowIntact(veh, i)
     end
     return tmp
end

local function get_vehicle_dirt_level(veh)
     return Round(GetVehicleDirtLevel(veh), 2)
end

local function get_tyres_health(veh)
     local tmp = {}
     local ids = { 0, 1, 2, 3, 4, 5, 45, 47 }
     for i, wheelIndex in pairs(ids) do
          tmp[tostring(wheelIndex)] = Round(GetTyreHealth(veh, wheelIndex), 2)
     end
     return tmp
end

local function recover_vehicle_door_state(veh, doorData)
     for key, value in pairs(doorData) do
          if value == 1 then
               SetVehicleDoorBroken(veh, tonumber(key), true)
          end
     end
end

local function recover_vehicle_windows_state(veh, doorData)
     for key, value in pairs(doorData) do
          if value == false then
               SmashVehicleWindow(veh, tonumber(key))
          end
     end
end

local function revocer_vehicle_dirt_level(veh, dirt_level)
     SetVehicleDirtLevel(veh, dirt_level)
end

local function recover_tyres_state(veh, wheelData)
     for wheelIndex, health in pairs(wheelData) do
          if health > 300.0 and health <= 400.0 then
               SetTyreHealth(veh, tonumber(wheelIndex), 350.0)
          elseif health <= 300.0 and health >= 0.0 then
               SetVehicleTyreBurst(veh, tonumber(wheelIndex), true, 1000.0)
          else
               SetTyreHealth(veh, tonumber(wheelIndex), 1000.0)
          end
     end
end

function GetVehicleDamages(veh)
     local all_damages = {}
     all_damages['doors'] = get_door_damages(veh)
     all_damages['windows'] = get_windows_damages(veh)
     all_damages['dirt_level'] = get_vehicle_dirt_level(veh)
     all_damages['tyres'] = get_tyres_health(veh)
     return all_damages
end

function RecoverVehicleDamages(veh, vehicle)
     local engine = vehicle.engine + 0.0
     local body = vehicle.body + 0.0

     if vehicle.metadata ~= 0 and type(vehicle.metadata) == "table" then
          recover_vehicle_door_state(veh, vehicle.metadata['doors'])
          recover_vehicle_windows_state(veh, vehicle.metadata['windows'])
          revocer_vehicle_dirt_level(veh, vehicle.metadata['dirt_level'])
          recover_tyres_state(veh, vehicle.metadata['tyres'])
     end

     SetVehicleEngineHealth(veh, engine)
     SetVehicleBodyHealth(veh, body)
end
