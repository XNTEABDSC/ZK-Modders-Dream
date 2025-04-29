import py7zr
import os
import re
import lupa
from typing import Any
from lupa import LuaRuntime

lua=LuaRuntime()


def is_lua_table(obj):
    return obj.__class__.__name__ == '_LuaTable'

def valueToLuaString_Key(v):
    vType=type(v)
    if vType==int:
        return "["+str(v)+"]"
    if vType==str:
        return v
    raise

def valueToLuaStrings(v):
    vType=type(v)
    if vType==int: return [str(v)]
    if vType==str: return ['"'+v+'"']
    if is_lua_table(v):
        resStr=["{"]
        for key in v:
            value=v[key]
            keystrs=valueToLuaString_Key(key)
            valuestrs=valueToLuaStrings(value)
            valuestrlen=len(valuestrs)
            if valuestrlen==1:
                resStr.append("\t"+keystrs+"="+valuestrs[0]+",")
            else:
                resStr.append("\t"+keystrs+"="+valuestrs[0])
                for i in range(1,valuestrlen-1):
                    resStr.append("\t"+valuestrs[i])
                resStr.append("\t"+valuestrs[valuestrlen-1]+",")
            #resStr.append( valueToLuaString_Key(key) +"="+valueToLuaStrings(value)+",\n")
        resStr.append('}')
        return resStr
    raise

thisAbsPath=os.path.abspath(".")
thisDirName=os.path.split(thisAbsPath)[1]

thisModName="ZK Modders Dream"# str.replace(thisDirName," dev.sdd","")
thisModVersion=""
thisModFileName="ZK_Modders_Dream"
dependReplace={}

modinfo:Any=lua.execute(open("modinfo.lua","r").read())

thisModVersion=modinfo.version
modinfo.name=thisModName

for dependI in modinfo.depend:
    dependStr=modinfo.depend[dependI]
    for repFrom in dependReplace:
        repInto=dependReplace[repFrom]
        dependStr=re.sub(pattern=repFrom,repl=repInto,string=dependStr)
    modinfo.depend[dependI]=dependStr

open("_modinfo.lua","w").write("return " + "\n".join(valueToLuaStrings(modinfo)) )

def listToDict(list,v=True):
    dc={}
    for i in list:
        dc[i]=v
    return dc

ignoreFileNames=listToDict({
    "modinfo.lua","_modinfo.lua","settings.json","zip.bat","zip.py","LICENSE","README.md","7z.py","7z.bat",".gitignore"
})
ignoreFileEnds={".blend",".blend1",".txt",".py",".code-workspace",".bat"}

GameDirPath=os.path.split(thisAbsPath)[0]
outputfilename=thisModFileName+"_"+thisModVersion+".sd7"

zip=py7zr.SevenZipFile(os.path.join(GameDirPath,outputfilename),"w")
zip.write("_modinfo.lua","modinfo.lua")
for abspath,dirname,filenames in os.walk(thisAbsPath):
    path=abspath.replace(thisAbsPath,"")
    # print(path)
    if path.startswith("\\."):
        continue
    for filename in filenames:
        if filename.startswith("."):
            continue
        if ignoreFileNames.get(filename,False):
            continue
        Pass=True
        for i in ignoreFileEnds:
            if filename.endswith(i):
                Pass=False
                break
        if not Pass:
            continue
        zip.write(os.path.join(abspath,filename),os.path.join(path,filename))
zip.close()
