--[[--
  aaasoundcloud_single.lua - SonundCloud track parser
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
  
  This is a VLC playlist plugin that can play SoundCloud tracks
  
  Note: if it's not working, download http://regex.info/code/JSON.lua as VLC/lua/modules/JSON.lua
  
  An example track link: https://soundcloud.com/user-978534184/do-you-remember
  
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
  if not ( vlc.access == "https" or vlc.access == "http" ) then
    return false
  end
  
  if string.match(vlc.path, "%.soundcloud%.com%/") then
    return false
  end
  
  if string.match(vlc.path, "soundcloud.com/oembed") then
    return false
  end
  
  return string.match( vlc.path, "(soundcloud%.com/[^/]+/[^?/]+)" )
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
  local s, ejj = vlc.stream("https://soundcloud.com/oembed?format=json&url=https://" .. vlc.path)
  if not s then
    error(ejj)
  end
  
  local line = s:readline()
  if not line then
    error("No oembed line")
  end
  
  line = string.match(line, "api.soundcloud.com%%2Ftracks%%2F(%d+)")
  if not line then
    error("No track regex'd")
  end
  
  return
  {{
    path = ("https://api-widget.soundcloud.com/tracks?ids=" .. line .. "&format=json&client_id=" .. cid)
  }}
end