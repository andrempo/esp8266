
-- Mapping between file extension (and request) and HTTP response
local extmap = {
  txt = "text/plain",
  htm = "text/html",
  pht = "text/html",
  gif = "image/gif",
  jpg = "imge/jpeg",
  png = "image/png",
  lua = "text/html"
}

local tags = '<%?lua(.-)%?>';

local basedir = "/"
reqdata = {}

-- Auxiliary function: execute the given code with a substituted "print"
-- that prints everything to a string, return the code output
local function docode(thecode)
  local strbuf = {}
  local oldprint, newprint =  print, function(...)
    local total, idx = select('#', ...)
    for idx = 1, total do
      strbuf[#strbuf + 1] = tostring(select(idx, ...)) .. (idx == total and '\n' or '\t')
    end
  end
  print = newprint
  local f = loadstring(thecode)
  if f then
    f()
  else
    print ">>> Invalid Lua code <<<"
  end
  print = oldprint
  collectgarbage('collect')
  return table.concat(strbuf)
end

function process(header, conn)

	print(header);
	-- look for first line
	print(header:find("[^\r]+\n"))
	local s, e = header:find("[^\n]+\n")
	local reqstr = header:sub(s, e)
	local respheader, respdata = '', ''
  
	reqdata = {}
	-- check if the request is valid, also keep the actual request
	local i, valid, req = 0, false
	for w in reqstr:gmatch("%S+") do
		valid = ( i == 0 and w == "GET" ) or valid
		req = ( i == 1 and w ) or req
		i = i + 1
	end

	-- valid is true if the request is valid, req has the request string
	if valid then
		-- now look for all parameters in this request (if any)
		local fname = ""

		if req:find("%?") then
			local rest
			_, _, fname, rest = req:find("(.*)%?(.*)")
			-- small trick: end "rest" with a "&" for easier processing
			-- now look for "var=value" pairs in the request (GET encoding)
			rest = rest .. "&";
			for crtpair in rest:gmatch("[^&]+") do
				local _, __, k, v = crtpair:find("(.*)=(.*)")
				-- replace all "%xx" characters with their actual value
				v = v:gsub("(%%%x%x)", function(s) return string.char(tonumber(s:sub(2, -1), 16)) end)
				reqdata[k] = v;
			end
		else
			fname = req
		end
		print(table.concat(reqdata));

		fname = ( fname == "/" ) and "index.pht" or fname:sub(2, -1)
		s, e = fname:find("%.[%a%d]+$")
		local ftype = fname:sub(s+1, e):lower()
		ftype = (#ftype > 0 and ftype) or "txt"
		--fname = basedir .. fname
    
		print(fname);
		-- now "fname" has the name of the requested file, and "reqdata" the actual request data
		-- also "ftype" holds the file type (actually its extension)

		if file.open(fname, "r") then
			conn:send("HTTP/1.1 200 OK\r\nConnection: close\r\nServer: eLua-miniweb\r\nContent-Type: " .. extmap[ftype or "txt"] .. "\r\n\r\n");
			-- Preprocess "lua" and "pht" files: run the Lua ones, parse the .htm ones for "<?lua ... ?>" sequences
			sendFileContents(conn,ftype);
		else
			conn:send("HTTP/1.1 404 Not Found\r\nConnection: close\r\nServer: eLua-miniweb\r\nContent-Type: text/html\r\n\r\nPage not found");
		end

	--valid
	else
		conn:send("HTTP/1.1 400 Bad Request\r\nConnection: close\r\nServer: eLua-miniweb\r\nContent-Type: text/html\r\n\r\n400 Invaild Request");
	end

end


sendFileContents = function(conn, type)
	repeat 
		local line=file.readline() 
		if line then 
			 if type == "pht" then
				-- single line only script tags, via readline... is there a alternative?
				conn:send(line:gsub(tags, docode));
			 else
				conn:send(line);
			 end
		end 
	until not line 
	file.close();
end

httpserver = function ()
 srv=net.createServer(net.TCP) 
    srv:listen(80,function(conn) 
      conn:on("receive",function(conn,payload) 
        process(payload,conn);
      end) 
      conn:on("sent",function(conn) 
		conn:close()  
		conn = nil;
	  end)
    end)
end
httpserver()



