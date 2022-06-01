Config = Config or {}

Config.AllowledList = {
     'RGZ12054'
}

Config.JobGarages = {
     --Job Garage:
     ['mrpd'] = {
          label = 'Police Garage',
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
               vector4(437.1, -997.01, 25.12, 89.27)
          },
          blippoint = vector3(441.64, -984.96, 25.7),
          showBlip = false,
          blipsprite = 357,
          blipscale = 0.65,
          blipcolour = 3,
          job = 'police',
          fullfix = {
               active = true,
               price = 250,
          },
          canStoreVehicle = {
               ''
          },
          zones = {
               vector2(423.16, -1000.29),
               vector2(463.7, -1000.29),
               vector2(463.7, -973.04),
               vector2(423.16, -973.04),
          },
          minz = 24.66,
          maxz = 28.66,
     },
     ['mrpd_out'] = {
          label = 'Police Garage',
          spawnPoint = {
               vector4(449.54, -1025.0, 27.96, 186.01),
               vector4(446.05, -1025.0, 28.03, 184.5),
               vector4(442.55, -1026.0, 28.09, 184.49),
               vector4(439.1, -1026.0, 28.16, 185.11),
               vector4(435.67, -1026.0, 28.22, 184.95)
          },
          blippoint = vector3(441.64, -984.96, 25.7),
          showBlip = false,
          blipsprite = 357,
          blipscale = 0.65,
          blipcolour = 3,
          job = 'police',
          fullfix = {
               active = true,
               price = 250,
          },
          canStoreVehicle = {
               ''
          },
          zones = {
               vector2(455.4, -1028.0),
               vector2(455.0, -1012.7),
               vector2(430.5, -1014.3),
               vector2(430.9, -1029.8)
          },
          minz = 26.66,
          maxz = 32.66,
     },
     ['mrpd_back'] = {
          label = 'Police Garage',
          spawnPoint = {
               vector4(475.95, -1026.46, 27.49, 329.57),
               vector4(479.38, -1026.41, 27.42, 329.81),
               vector4(483.16, -1025.68, 27.39, 328.76)
          },
          blippoint = vector3(441.64, -984.96, 25.7),
          showBlip = false,
          blipsprite = 357,
          blipscale = 0.65,
          blipcolour = 3,
          job = 'police',
          fullfix = {
               active = true,
               price = 250,
          },
          canStoreVehicle = {
               ''
          },
          zones = {
               vector2(472, -1030.2),
               vector2(487, -1028.4),
               vector2(487, -1017),
               vector2(472, -1017)
          },
          minz = 27,
          maxz = 30.95,
     },
}

Config.VehicleWhiteList = {
     ['mrpd'] = {
          ['-1716760427'] = {
               name = 'CGT',
               spawncode = 'cgt',
          },
          ['-901056903'] = {
               name = 'Nopixel Vic',
               spawncode = 'npolvic',
          },
          ['1947925897'] = {
               name = 'Rhino',
               spawncode = 'bcat',
          },
          ['719025956'] = {
               name = 'Ford Explorer',
               spawncode = 'npolexp',
          },
     }
}

-- edit menu too
