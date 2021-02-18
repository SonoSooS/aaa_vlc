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
		print(msg)
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

-- Parse function.
function parse()
    local line = vlc.readline()
    while true do
      if not line then break end
      line = line:match("content=\"(https://bandcamp.com/EmbeddedPlayer/[^\"]+)")
      if line then break end
      line = vlc.readline()
    end
    
    if line == nil then
      error("No EmbeddedPlayer!")
    end
    
    local s, ejj = vlc.stream(line)
    if s == nil then
      error(ejj)
    end
    
    line = s:readline()
    while true do
      if not line then
        break
      end
      
      line = line:match("var playerdata = (.*);$")
      if line then
        break
      end
      
      line = s:readline()
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
