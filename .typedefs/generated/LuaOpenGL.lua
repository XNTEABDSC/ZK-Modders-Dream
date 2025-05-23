
---!!! DO NOT MANUALLY EDIT THIS FILE !!!
---Generated by lua-doc-extractor 1.0.0
---https://github.com/rhys-vdw/lua-doc-extractor
---
---Source: LuaOpenGL.cpp
---
---@meta

---Lua OpenGL API
---
---@see rts/Lua/LuaOpenGL.cpp

---Text
---
---@section text

gl = {

}

---@param text string
---@param x number
---@param y number
---@param size number
---@param options string? concatenated string of option characters.
---
---- horizontal alignment:
---- 'c' = center
---- 'r' = right
---- vertical alignment:
---- 'a' = ascender
---- 't' = top
---- 'v' = vertical center
---- 'x' = baseline
---- 'b' = bottom
---- 'd' = descender
---- decorations:
---- 'o' = black outline
---- 'O' = white outline
---- 's' = shadow
---- other:
---- 'n' = don't round vertex coords to nearest integer (font may get blurry)
---@return nil
function gl.Text(text, x, y, size, options) end

---Draw Basics
---
---@section draw_basics

---@param r number Red
---@param g number Green
---@param b number Blue
---@param a number? Alpha (Default: 1.0f)
function gl.Color(r, g, b, a) end

---@param rgbs [number,number,number,number] Red, green, blue, alpha
function gl.Color(rgbs) end

---@param rgb [number,number,number] Red, green, blue
function gl.Color(rgb) end

---@class GLenum:number
---@class GLuint:number

---
---labels an object for use with debugging tools
---
---@param objectTypeIdentifier GLenum Specifies the type of object being labeled.
---@param objectID GLuint Specifies the name or ID of the object to label.
---@param label string A string containing the label to be assigned to the object.
---@return nil
function gl.ObjectLabel(objectTypeIdentifier, objectID, label) end

---
---pushes a debug marker for nVidia nSight 2024.04, does not seem to work when FBO's are raw bound
---
---@param id GLuint A numeric identifier for the group.
---@param message string A human-readable string describing the debug group.
---@param sourceIsThirdParty boolean Set the source tag, true for GL_DEBUG_SOURCE_THIRD_PARTY, false for GL_DEBUG_SOURCE_APPLICATION. default false
---@return nil
function gl.PushDebugGroup(id, message, sourceIsThirdParty) end

---@return nil
function gl.PopDebugGroup() end