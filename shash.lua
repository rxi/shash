--
-- shash.lua
--
-- Copyright (c) 2017 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local shash = { _version = "0.1.1" }
shash.__index = shash


function shash.new(cellsize)
  local self = setmetatable({}, shash)
  cellsize = cellsize or 64
  self.cellsize = cellsize
  self.tablepool = {}
  self.cells = {}
  self.entities = {}
  return self
end


local function coord_to_key(x, y)
  return x + y * 1e7
end


local function cell_position(cellsize, x, y)
  return math.floor(x / cellsize), math.floor(y / cellsize)
end


local function each_overlapping_cell(self, e, fn, ...)
  local cellsize = self.cellsize
  local sx, sy = cell_position(cellsize, e[1], e[2])
  local ex, ey = cell_position(cellsize, e[3], e[4])
  for y = sy, ey do
    for x = sx, ex do
      local idx = coord_to_key(x, y)
      fn(self, idx, ...)
    end
  end
end


local function add_entity_to_cell(self, idx, e)
  if not self.cells[idx] then
    self.cells[idx] = { e }
  else
    table.insert(self.cells[idx], e)
  end
end


local function remove_entity_from_cell(self, idx, e)
  local t = self.cells[idx]
  local n = #t
  -- Only one entity? Remove entity from cell and remove cell
  if n == 1 then
    self.cells[idx] = nil
    return
  end
  -- Find and swap-remove entity
  for i, v in ipairs(t) do
    if v == e then
      t[i] = t[n]
      t[n] = nil
      return
    end
  end
end


function shash:add(obj, x, y, w, h)
  -- Create entity. The table is used as an array as this offers a noticable
  -- performance increase on LuaJIT; the indices are as follows:
  -- [1] = left, [2] = top, [3] = right, [4] = bottom, [5] = object
  local e = { x, y, x + w, y + h, obj }
  -- Add to main entities table
  self.entities[obj] = e
  -- Add to cells
  each_overlapping_cell(self, e, add_entity_to_cell, e)
end


function shash:remove(obj)
  -- Get entity of obj
  local e = self.entities[obj]
  -- Remove from main entities table
  self.entities[obj] = nil
  -- Remove from cells
  each_overlapping_cell(self, e, remove_entity_from_cell, e)
end


function shash:update(obj, x, y, w, h)
  -- Get entity from obj
  local e = self.entities[obj]
  -- No width/height specified? Get width/height from existing bounding box
  w = w or e[3] - e[1]
  h = h or e[4] - e[2]
  -- Check the entity has actually changed cell-position, if it hasn't we don't
  -- need to touch the cells at all
  local cellsize = self.cellsize
  local ax1, ay1 = cell_position(cellsize, e[1], e[2])
  local ax2, ay2 = cell_position(cellsize, e[3], e[4])
  local bx1, by1 = cell_position(cellsize, x, y)
  local bx2, by2 = cell_position(cellsize, x + w, y + h)
  local dirty = ax1 ~= bx1 or ay1 ~= by1 or ax2 ~= bx2 or ay2 ~= by2
  -- Remove from old cells
  if dirty then
    each_overlapping_cell(self, e, remove_entity_from_cell, e)
  end
  -- Update entity
  e[1], e[2], e[3], e[4] = x, y, x + w, y + h
  -- Add to new cells
  if dirty then
    each_overlapping_cell(self, e, add_entity_to_cell, e)
  end
end


function shash:clear()
  -- Clear all cells and entities
  for k in pairs(self.cells) do
    self.cells[k] = nil
  end
  for k in pairs(self.entities) do
    self.entities[k] = nil
  end
end


local function overlaps(e1, e2)
  return e1[3] > e2[1] and e1[1] < e2[3] and e1[4] > e2[2] and e1[2] < e2[4]
end


local function each_overlapping_in_cell(self, idx, e, set, fn, ...)
  local t = self.cells[idx]
  if not t then
    return
  end
  for i, v in ipairs(t) do
    if e ~= v and overlaps(e, v) and not set[v] then
      fn(v[5], ...)
      set[v] = true
    end
  end
end


local function each_overlapping_entity(self, e, fn, ...)
  -- Init set for keeping track of which entities have already been handled
  local set = table.remove(self.tablepool) or {}
  -- Do overlap checks
  each_overlapping_cell(self, e, each_overlapping_in_cell, e, set, fn, ...)
  -- Clear set and return to pool
  for v in pairs(set) do
    set[v] = nil
  end
  table.insert(self.tablepool, set)
end


function shash:each(x, y, w, h, fn, ...)
  local e = self.entities[x]
  if e then
    -- Got object, use its entity
    each_overlapping_entity(self, e, y, w, h, fn, ...)
  else
    -- Got bounding box, make temporary entity
    each_overlapping_entity(self, { x, y, x + w, y + h }, fn, ...)
  end
end


function shash:info(opt, ...)
  if opt == "cells" or opt == "entities" then
    local n = 0
    for k in pairs(self[opt]) do
      n = n + 1
    end
    return n
  end
  if opt == "cell" then
    local t = self.cells[ coord_to_key(...) ]
    return t and #t or 0
  end
  error( string.format("invalid opt '%s'", opt) )
end


return shash
