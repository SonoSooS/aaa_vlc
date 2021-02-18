--[[--
  bandcamp.lua - Bandcamp album/track player plugin
  Copyright (C) 2016-2021 Sono (https://github.com/SonoSooS)
  
  This program is free software: you can redistribute it and/or modify  
  it under the terms of the GNU General Public License as   
  published by the Free Software Foundation, either version 3, or
  (at your option) any later version.
  
  This program is distributed in the hope that it will be useful, but 
  WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
  General Lesser Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program. If not, see <http://www.gnu.org/licenses/>.
  
  
  Note: this script requires JSON.lua to be downloaded from http://regex.info/code/JSON.lua as VLC/lua/modules/JSON.lua
  
  An example album link: https://gilvasunner.bandcamp.com/album/cd-grand-beta
  An example track link: https://aavepyora.bandcamp.com/track/valo-voima-ja-vapaus
  
  My GitHub page:     https://github.com/SonoSooS
  My Youtube channel: https://youtube.com/user/mCucc
  
--]]--

local json = require("JSON"):new()
function json.assert(wat, msg)
	if wat then
		vlc.msg.dbg(msg)
	else
		vlc.msg.err(msg)
	end
end

-- Probe function.
function probe()
    return ( vlc.access == "https" or vlc.access == "http" )
        and (string.match( vlc.path, "([^%.]%.bandcamp%.com/album/[^/]+)$")
            or string.match( vlc.path, "([^%.]%.bandcamp%.com/track/[^/]+)$"))
end

local function tf(s)
  local t = {}
  local ejj
  
  t.main, _, ejj = json:decode(s, 1, nil)
  if not t.main then
    local _, charnum = ejj:match("column (%d)+")
    charnum = tonumber(charnum)
    vlc.msg.err("================[NO PARSER]================")
    vlc.msg.err(ejj)
    vlc.msg.err("================[JSON DUMP]================")
    vlc.msg.err(s:sub(charnum - 10, charnum + 10))
    vlc.msg.err("================[JSON DUMP]================")
    error(ejj)
  end
  
  return t
end

local function shitty_readline(s) -- yay for working around ancient VLC bugs!
  local buf = ""
  
  while true do
    local ret = s:read(1)
    if ret == 0 then -- lol, not nil
      break
    end
    
    if ret == "\r" then
      ret = s:read(1)
    end
    
    if ret == "\n" then
      break
    end
    
    buf = buf .. ret
  end
  
  return buf
end

-- Parse function.
function parse()
    local line = vlc.readline()
    while line ~= nil do
      line = line:match("content=\"(https://bandcamp.com/EmbeddedPlayer/[^\"]+)")
      if line then
        break
      end
      
      line = vlc.readline()
    end
    
    if not line then
      error("No EmbeddedPlayer!")
    end
    
    vlc.msg.dbg("EmbeddedPlayer: " .. line)
    local s, ejj = vlc.stream(line)
    if not s then
      error(ejj)
    end
    
    line = shitty_readline(s)
    while line ~= nil do
      line = line:match("var playerdata = (.*);$")
      if line then
        break
      end
      
      line = shitty_readline(s)
    end
    
    if not line then
      error("No playerdata!")
    end
    
    local strr = tf(line)
    buf = {}
    for k,v in pairs(strr.main.tracks) do
      buf[#buf + 1 ] =
      {
        path = v.file["mp3-128"],
        name = v.title,
        arturl = (strr.main.album_art_lg and strr.main.album_art_lg or strr.main.album_art),
        title = v.title,
        artist = v.artist,
        url = v.title_link
      }
    end
    return buf
end
