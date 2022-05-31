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
          }
     }
}
