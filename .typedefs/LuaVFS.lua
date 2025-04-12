
---!!! DO NOT MANUALLY EDIT THIS FILE !!!
---Generated by lua-doc-extractor 1.0.0
---https://github.com/rhys-vdw/lua-doc-extractor
---
---Source: LuaVFS.cpp
---
---@meta

---Virtual File System
---
---@see rts/Lua/LuaVFS.cpp

VFS={}
---Load, compiles, run, return
---@param filename string
---@param enviroment table|nil
---@param mode number|nil
---@return any
function VFS.Include(filename,enviroment ,mode ) end

---check whether a file exist
---@param filename string
---@param mode number|nil
---@return boolean
function VFS.FileExists(filename,mode) end

---get a list of files
---@param directory string
---@param pattern string|nil
---@param mode number|nil
---@return {[integer]:string}
function VFS.DirList(directory,pattern,mode ) end

---get a list of dirs
---@param directory string
---@param pattern string|nil
---@param mode number|nil
---@return {[integer]:string}
function VFS.SubDirs(directory,pattern,mode)end