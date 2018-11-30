Overview
--------

[MooSpec-1.0][project] is a library that provides information about player specializations and roles.

__MooSpec-1.0__ will track the following changes to units within the group:

* specialization
* role as determined by class and specialization
* role as assigned by the Dungeon Finder or as manually assigned in a raid group

__MooSpec-1.0__ can also inspect player units that are outside of the group as long as they have a valid unit ID.


API Methods
-----------

### GetBlizzardRole

Returns the assigned role for the GUID in a group formed via the Dungeon Finder, or the role manually assigned in a raid group.

    blizzardRole = lib:GetBlizzardRole(guid)

#### Arguments:

* `guid` - string: [GUID][]

#### Returns:

* `blizzardRole` - string: `"TANK"`, `"HEALER"`, `"DAMAGER"`, `"NONE"`

### GetClass

Returns the class for the GUID.

    class = lib:GetClass(guid)

#### Arguments:

* `guid` - string: [GUID][]

#### Returns:

* `class` - string: a class token, one of:
  * `"DEATHKNIGHT"`
  * `"DEMONHUNTER"`
  * `"DRUID"`
  * `"HUNTER"`
  * `"MAGE"`
  * `"MONK"`
  * `"PALADIN"`
  * `"PRIEST"`
  * `"ROGUE"`
  * `"SHAMAN"`
  * `"WARLOCK"`
  * `"WARRIOR"`

### GetRole

Returns the role for the GUID as determined by class and specialization.  This differentiates between melee and ranged DPS specializations.

    role = lib:GetRole(guid)

#### Arguments:

* `guid` - string: [GUID][]

#### Returns:

* `role` - string: `"tank"`, `"healer"`, `"melee"`, `"ranged"`, `"none"`

### GetSpecialization

Returns the specialization for the GUID.

    specialization, name = lib:GetSpecialization(guid)

#### Arguments:

* `guid` - string: [GUID][]

#### Returns:

* `specialization` - number: [specialization ID][]
* `name` - string: the name of the specialization, e.g., `"blood`", `"protection"`, `"arcane"`, etc.

### GetSpecializationName

Returns the name of the specialization by ID.

    name = lib:GetSpecializationName(specialization)

#### Arguments:

* `specialization` - number: [specialization ID][]

#### Returns:

* `name` - string: the name of the specialization, e.g., `"blood"`, `"protection"`, `"arcane"`, etc.

### InspectUnit

Queue a unit for asynchronous update of its specialization and role.

    lib:InspectUnit(unit)

#### Arguments:

* `unit` - string: [unit ID][], e.g., `"player"`, `"target"`, `"raid15"`, etc.

### InspectRoster

Queue each member of the group for asynchronous update of their specialization and role.

    lib:InspectRoster()

### RegisterCallback

Registers a function to handle the specified callback.

    lib.RegisterCallback(handler, callback, method, arg)

#### Arguments:

* `handler` - table/string: your addon object or another table containing a function at `handler[method]`, or a string identifying your addon
* `callback` - string: the name of the callback to be registered
* `method` - string/function/nil: a key into the `handler` table, or a function to be called, or `nil` if `handler` is a table and a function exists at `handler[callback]`
* `arg` - a value to be passed as the first argument to the callback function specified by `method`

#### Notes:

* If `handler` is a table, `method` is a string, and `handler[method]` is a function, then that function will be called with `handler` as its first argument, followed by the callback name and the callback-specific arguments.
* If `handler` is a table, `method` is nil, and `handler[callback]` is a function, then that function will be called with `handler` as its first argument, followed by the callback name and the callback-specific arguments.
* If `handler` is a string and `method` is a function, then that function will be called with the callback name as its first argument, followed by the callback-specific arguments.
* If `arg` is non-nil, then it will be passed to the specified function. If `handler` is a table, then `arg` will be passed as the second argument, pushing the callback name to the third position. Otherwise, `arg` will be passed as the first argument.

### UnregisterCallback

Unregisters a specified callback.

    lib.UnregisterCallback(handler, callback)

#### Arguments:

* `handler` - table/string: your addon object or a string identifying your addon
* `callback` - string: the name of the callback to be unregistered


Callbacks
---------

__MooSpec-1.0__ provides the following callbacks to notify interested addons.

### MooSpec_UnitBlizzardRoleChanged

Fires when the assigned role in a group formed via the Dungeon Finder or the role manually assigned in a raid group is changed.

#### Arguments:

* `guid` - string: [GUID][] of the unit whose role has changed
* `unit` - string: [unit ID], e.g., `"player"`, `"target"`, `"raid15"`, etc.
* `oldRole` - string: the previous assigned role, see [GetBlizzardRole](#getblizzardrole)
* `newRole` - string: the current assigned role, see [GetBlizzardRole](#getblizzardrole)

### MooSpec_UnitClass

Fires when the class for a unit has been resolved.

#### Arguments:

* `guid` - string: [GUID][] of the unit whose role has changed
* `unit` - string: [unit ID], e.g., `"player"`, `"target"`, `"raid15"`, etc.
* `class` - string: a class token, see [GetClass](#getclass)

### MooSpec_UnitRoleChanged

Fires when the role of a unit as determined by its class and specialization has changed.

#### Arguments:

* `guid` - string: [GUID][] of the unit whose role has changed
* `unit` - string: [unit ID], e.g., `"player"`, `"target"`, `"raid15"`, etc.
* `oldRole` - string: the previous role, see [GetRole](#getrole)
* `newRole` - string: the current role, see [GetRole](#getrole)

### MooSpec_UnitSpecializationChanged

Fires when the specialization of a unit has changed.

#### Arguments:

* `guid` - string: [GUID][] of the unit whose specialization has changed
* `unit` - string: [unit ID], e.g., `"player"`, `"target"`, `"raid15"`, etc.
* `oldSpecialization` - number: the previous [specialization ID][]
* `newSpecialization` - number: the current [specialization ID][]

License
-------
__MooSpec-1.0__ is released under the 2-clause BSD license.


Feedback
--------

+ [Report a bug or suggest a feature][project-issue-tracker].

  [project]: https://www.github.com/ultijlam/moospec-1-0
  [project-issue-tracker]: https://github.com/ultijlam/moospec-1-0/issues
  [GUID]: https://wow.gamepedia.org/GUID
  [specialization ID]: https://wow.gamepedia.com/API_GetInspectSpecialization
  [unit ID]: https://wow.gamepedia.com/UnitId