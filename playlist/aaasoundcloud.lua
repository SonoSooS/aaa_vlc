--[[--
  aaasoundcloud.lua - SonundCloud set (playlist) parser
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
  
  This is a VLC playlist plugin to be able to play SoundCloud sets
  
  Note: this script requires JSON.lua to be downloaded from http://regex.info/code/JSON.lua as VLC/lua/modules/JSON.lua
  
  An example set link: https://soundcloud.com/pe-mahhieux/sets/savant
  
  My GitHub page:     https://github.com/SonoSooS
  My Youtube channel: https://youtube.com/user/mCucc
  
--]]--

-- SoundCloud ClientID
local cid = "3QTGpplEzSE4b5LvHHLO7Qs7NndUVXwa"

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
      and string.match( vlc.path, "(soundcloud%.com%/[^/]+%/sets%/[^?/]+)" )
end

local function tf(s)
  local t = {}
  local ejj
  
  t.main, _, ejj = json:decode(s, 1, nil)
  if not t.main then
    vlc.msg.err(s)
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

local function shitty_readall(s)
  local buf = ""
  
  while true do
    local ret = s:read(1024)
    if ret == nil or ret == 0 then
      break
    end
    
    buf = buf .. ret
  end
  
  return buf
end

-- Parse function.
function parse()
    local s, ejj = vlc.stream("https://soundcloud.com/oembed?format=json&url=https%3A%2F%2F" .. vlc.path:gsub("/", "%%2F"))
    if not s then
      error(ejj)
    end
    
    local line = shitty_readall(s)
    if not line then
      error("No oembed line")
    end
    
    line = string.match(line, "api.soundcloud.com%%2Fplaylists%%2F(%d+)")
    if not line then
      error("No track regex'd")
    end
    
    s, ejj = vlc.stream("https://api-widget.soundcloud.com/playlists/" .. line .. "?representation=full&format=json&client_id=" .. cid)
    if not s then
      error(ejj)
    end
    
    local playlistid = line
    
    line = shitty_readall(s)
    
    strr = tf(line)
    buf = {}
    for k,v in pairs(strr.main.tracks) do
      if v.id then
        buf[#buf + 1 ] =
        {
          path = ("https://api-widget.soundcloud.com/tracks?ids=" .. v.id .. "&playlistId=" .. playlistid .. "&playlistSecretToken&format=json&client_id=" .. cid)
        }
      end
    end
    
    return buf
end
