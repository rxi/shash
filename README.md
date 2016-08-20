# shash.lua
A simple, lightweight spatial hash for Lua.


## Functions

#### shash.new([cellsize])
Creates a new spatial hash; if `cellsize` is not specified a default value of
`64` is used.

#### :add(obj, x, y, w, h)
Adds an object with the given bounding box to the spatial hash.

#### :update(obj, x, y [, w, h])
Updates the object's bounding box.

#### :remove(obj)
Removes the object from the spatial hash.

#### :clear()
Removes all objects from the spatial hash.

#### :each(x, y, w, h, fn, ...)
#### :each(obj, fn, ...)
For each object which overlaps with the given bounding box or object, the
function `fn` is called. The first argument passed to `fn` is the overlapping
object, followed by any additional arguments passed to `each()`.

#### :info(opt, ...)
Returns information about the spatial hash which can be useful for debugging.
Available options and their arguments are as follows:

 Opt        | Args      | Description
------------|-----------|-------------------------------------------------------
 `entities` |           | Returns the total number of entities
 `cells`    |           | Returns the total number of cells
 `cell`     | `x`, `y`  | Returns the number of entities in the cell


## License
This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.
