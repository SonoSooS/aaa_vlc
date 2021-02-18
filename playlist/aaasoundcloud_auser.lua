--[[--
  aaasoundcloud_auser.lua - SoundCloud user track player plugin
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
  
  This is a VLC playlist plugin to be able to play an user's tracks (limited to max 1024 tracks)
  
  Note: this script requires JSON.lua to be downloaded from http://regex.info/code/JSON.lua as VLC/lua/modules/JSON.lua
  
  An example user link: https://soundcloud.com/triplekyu
  
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
  
  if string.match(vlc.path, "soundcloud.com/oembed") then
    return false
  end
  
  local succ, mat = string.match( vlc.path, "(soundcloud%.com/[^/]+)/?([^/]*)$" )
  return (succ and (mat == nil or mat == "" or mat == "tracks")) and true or false
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
  
  line = string.match(line, "api.soundcloud.com%%2Fusers%%2F(%d+)")
  if not line then
    error("No UserID regex'd")
  end
  
  s, ejj = vlc.stream("https://api.soundcloud.com/users/" .. line .. "/tracks?limit=1024&client_id=" .. cid)
  if not s then
    error(ejj)
  end
  
  local buf = {}
  local cnt = 0
  line = s:read(1)
  repeat
    --print(line)
    if line then
      buf[#buf + 1] = line
      cnt = 0
    end
    
    line = s:read(1)
    if not line then
      cnt = cnt + 1
    end
  until cnt == 16
  
  if not buf[1] then
    error("================[NO DATA]==============")
  end
  
  line = table.concat(buf)
  
  local strr = tf(line)
  buf = {}
  for k,v in pairs(strr.main) do
    buf[#buf + 1 ] =
    {
      path = (v.stream_url .. "?client_id=" .. cid),
      name = v.title,
      arturl = (v.artwork_url and v.artwork_url or v.user.artwork_url),
      title = v.title,
      artist = (v.user.username .. " (" .. v.user.permalink.. ")"),
      genre = v.genre,
      copyright = v.license,
      description = v.description,
      date = v.created_at,
      url = v.permalink_url,
      meta = 
      {
        ["tag list"] = v.tag_list,
        ["creation time"] = v.created_at
      }
    }
  end
  
  return buf
end
