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
  
  This is a required helper script, so there is no example, since most plugins should resolfe to this plugin.
  
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
  
  if not string.match(vlc.path, "(api[^.]*%.soundcloud%.com%/)") then
    return false
  end
  
  return false
    or string.match(vlc.path, "(soundcloud.com/tracks)")
    or string.match(vlc.path, "(soundcloud.com/media/soundcloud:tracks:[^?/]+/)")
    or string.match(vlc.path, "(soundcloud.com/stream/users/[^?/]+%?)")
    or false
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
    local ret = s and s:read(1024) or vlc.read(1024)
    if ret == nil or ret == 0 then
      break
    end
    
    buf = buf .. ret
  end
  
  return buf
end

-- Parse function.
function parse()
    local line = shitty_readall(nil)
    
    local strr = tf(line)
    
    vlc.msg.err(type(strr.main))
    
    if strr.main.collection or #strr.main > 0 then
      local buf = {}
      
      local main = strr.main
      
      if strr.main.collection then
        main = strr.main.collection
      end
      
      for k,v in ipairs(main) do
        if v.playlist and type(v.playlist) == "table" then
          -- uncomment to enable inline playlists
          --[[--
          buf[#buf + 1] =
          {
            path = v.playlist.permalink_url
          }
          --]]--
        else
          if v.track then
            v = v.track
          end
          
          if v.media and v.media.transcodings and #v.media.transcodings >= 2 then
            buf[#buf + 1] =
            {
              path = (v.media.transcodings[2].url .. "?client_id=" .. cid),
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
        end
      end
      
      if strr.main.next_href then
        buf[#buf + 1] =
        {
          path = strr.main.next_href
        }
      end
      
      return buf
    else
      
    end
    
    vlc.msg.dbg(strr.main.url)
    
    local ret =
    {{
      path = strr.main.url
    }}
    
    return ret
end
