Config = Config or {}

Config.fuel_script = 'LegacyFuel' --LegacyFuel

Config.MagicTouch = false

Config.VehicleWhiteList = {
     ['defaultPolice'] = {
          { label = 'Sheriff', model = 'Sheriff2' },
          { label = 'Sheriff', model = 'Sheriff' },
          { label = 'Riot', model = 'Riot' },
          { label = 'Policeb', model = 'Policeb' },
          { label = 'PBus', model = 'PBus' },
          { label = 'Police', model = 'Police' },
          { label = 'Police2', model = 'Police2' },
          { label = 'Police3', model = 'Police3' },
          { label = 'Police4', model = 'Police4' },
     },
     ['heliPolice'] = {
          { label = 'Police Maverick', model = 'Polmav' }
     },
     ['gas_station'] = {
          { label = 'Adder', model = 'adder' },
          { label = 'Glendale', model = 'glendale' },
     },
     ['vagos_yard'] = {
          -- by using qb-core/shared/vehicles.lua
          allow_all = true,
          { label = 'Sheriff', model = 'Sheriff2' }, -- #TODO add support for additions
     },
}

Config.Garages = {
     --Job Garage:
     ['mrpd'] = {
          label = 'Police Garage (mrpd)',
          type = 'job',
          job = { 'police' }, -- accpets just one job
          onDuty = false,
          spawnPoint = {
               vector4(445.92, -996.92, 24.96, 270.5),
               vector4(445.92, -994.25, 24.96, 270.33),
               vector4(446.08, -991.53, 24.96, 269.54),
               vector4(445.94, -994.25, 25.12, 270.9),
               vector4(445.73, -988.81, 25.12, 269.94),
               vector4(446.24, -986.16, 25.12, 269.11),
               -- flip
               vector4(437.0, -986.11, 25.12, 88.82),
               vector4(437.06, -988.91, 25.12, 89.17),
               vector4(437.16, -991.66, 25.12, 88.86),
               vector4(437.31, -994.24, 25.12, 89.62),
               vector4(437.1, -997.01, 25.12, 89.27),
               vector4(425.99, -976.17, 25.08, 90.6),
               vector4(425.76, -979.0, 25.08, 90.9),
               vector4(425.92, -981.54, 25.08, 90.12),
               vector4(425.89, -984.25, 25.08, 89.43),
               vector4(425.77, -988.98, 25.08, 90.47),
               vector4(425.68, -991.71, 25.08, 89.45),
               vector4(425.66, -994.37, 25.09, 89.49),
               vector4(425.77, -997.05, 25.09, 88.9)
          },
          zones = {
               vector2(423, -1000),
               vector2(450, -999),
               vector2(449, -983),
               vector2(428, -982),
               vector2(428, -973),
               vector2(423, -973)
          },
          minz = 24.66,
          maxz = 28.66,
          WhiteList = Config.VehicleWhiteList['defaultPolice'],
          garage_management = {
               -- access to garage management
               ['IFD87837'] = true
          }
     },
     ['mrpd_out'] = {
          label = 'Police Garage (mrpd)',
          type = 'job',
          job = { 'police' },
          onDuty = false,
          spawnPoint = {
               vec4(435.481201, -1026.593750, 27.842340, 185.000000),
               vec4(438.973846, -1026.226074, 27.777569, 185.000000),
               vec4(442.466492, -1025.858521, 27.712795, 185.000000),
               vec4(445.959137, -1025.490845, 27.648024, 185.000000),
               vec4(449.451782, -1025.123169, 27.583252, 185.000000),
          },
          zones = {
               vector2(455, -1027.8),
               vector2(455, -1020),
               vector2(430, -1020),
               vector2(430, -1030.9)
          },
          minz = 26.66,
          maxz = 32.66,
          WhiteList = Config.VehicleWhiteList['defaultPolice'],
          garage_management = {
               -- access to garage management
               ['GBC74362'] = true
          }
     },
     ['mrpd_back'] = {
          label = 'Police Garage (mrpd)',
          type = 'job',
          job = { 'police' },
          spawnPoint = {
               vector4(475.95, -1026.46, 27.49, 329.57),
               vector4(479.38, -1026.41, 27.42, 329.81),
               vector4(483.16, -1025.68, 27.39, 328.76)
          },
          zones = {
               vector2(472, -1030.2),
               vector2(487, -1028.4),
               vector2(487, -1017),
               vector2(472, -1017)
          },
          minz = 27,
          maxz = 30.95,
          WhiteList = Config.VehicleWhiteList['defaultPolice']
     },
     ['mrpd_heli_pad'] = {
          label = 'Police Heli Pad (mrpd)',
          type = 'job',
          job = { 'police' },
          spawnPoint = {
               vector4(449.22, -981.24, 43.69, 91.21)
          },
          zones = {
               vector2(459.4, -975.1),
               vector2(441.9, -974.7),
               vector2(442.1, -988.7),
               vector2(459.5, -989.1)
          },
          minz = 42.5,
          maxz = 50.95,
          WhiteList = Config.VehicleWhiteList['heliPolice']
     },
     ['gas_station'] = {
          label = 'Gas Station',
          type = 'job',
          job = { 'oilwell' },
          spawnPoint = {
               vector4(298.68, -1241.99, 28.88, 359.68),
               vector4(294.98, -1241.8, 28.87, 0.73),
               vector4(291.94, -1241.92, 28.84, 0.5),
               vector4(288.66, -1241.81, 28.83, 358.8),
               vector4(285.18, -1241.85, 28.81, 0.51),
               vector4(281.55, -1241.91, 28.8, 2.78),
               vector4(278.7, -1241.89, 28.79, 358.64)
          },
          zones = {
               vector2(273.80, -1247.66),
               vector2(273.86, -1236.66),
               vector2(301.53, -1236.18),
               vector2(301.69, -1249.62)
          },
          minz = 28.0,
          maxz = 30.0,
          WhiteList = Config.VehicleWhiteList['gas_station']
     },
     ['vagos_yard'] = {
          label = 'Vagos',
          type = 'gang',
          gang = { 'vagos' }, -- accpets just one gang
          spawnPoint = {
               vector4(306.6, -2022.9, 19.92, 141.33),
               vector4(308.74, -2024.99, 19.99, 141.96),
               vector4(318.66, -2020.07, 20.3, 322.45)
          },
          zones = {
               vector2(301.20172119141, -2023.0167236328),
               vector2(311.47695922852, -2008.5593261719),
               vector2(344.26721191406, -2036.0698242188),
               vector2(332.54577636719, -2050.0180664062)
          },
          minz = 19.0,
          maxz = 24.0,
          WhiteList = Config.VehicleWhiteList['vagos_yard'],
          garage_management = {
               -- access to garage management
               ['IFD87837'] = true
          }
     },
}

function Notification(source, msg, _type)
     TriggerClientEvent('QBCore:Notify', source, msg, _type)
end

CreateThread(function()
     for garage_name, garage in pairs(Config.Garages) do
          for key, value in pairs(garage.WhiteList) do
               if key ~= 'allow_all' then
                    Config.Garages[garage_name].WhiteList[key].hash = GetHashKey(value.model:lower())
               end
          end
     end
end)
