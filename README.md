# Dependencies

- [qb-core]()
- [keep-menu](https://github.com/swkeep/keep-menu)
- [keep-input](https://github.com/swkeep/keep-input)
- [qb-radialmenu](https://github.com/qbcore-framework/qb-radialmenu)

- [qb-menu] support will be in future updates
- Support for [qb-input] will not be added most likely

## Preview

- [Click Here (current V2.0.2)](https://youtu.be/4_DZP_9iZTY)
- [Version 1.0.0](https://youtu.be/51rRVQtvedI)

## Features

- Better condition saving (most windshields, doors and wheel damages)
- Shared vehicle garages (jobs and gangs)
- Allow or disallow vehicle customization
- Ability to move vehicles under custom categories.
- and more

## Installation

- Drag and drop resource in your server!
- (don't do it on version +2.x.x it's doing it automatically) run the sql.sql on your database.
- setup the config file.
- done!
- now you can use /saveinsidegarage command while you're inside a vehicle
- and save it as shared vehicle inside the garage

# Fix: inventory doesn't saves vehicles data 
- open qb-inventory/server/main.lua
- search for `IsVehicleOwned`
- replace it with code below

```lua
local function IsVehicleOwned(plate)
	local result = MySQL.scalar.await('SELECT 1 from player_vehicles WHERE plate = ?', { plate })
	local result2 = MySQL.scalar.await('SELECT 1 from keep_garage WHERE plate = ?', { plate })
	return result or result2
end
```