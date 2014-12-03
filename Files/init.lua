local extmap = {
  txt = "text/plain",
  htm = "text/html",
  pht = "text/html",
  gif = "image/gif",
  jpg = "imge/jpeg",
  png = "image/png",
  lua = "text/html",
  html = "text/html"
}

local requestToConsole = false;

local reqTypes = {
	GET = true,
	POST = true
}

local tags = '<%?lua(.-)%?>';
local basedir = "/"
reqdata = {}

local function docode(thecode)
  local strbuf = {};
  local oldprint, newprint =  print, function(...)
    local total, idx = select('#', ...)
    for idx = 1, total do
      strbuf[#strbuf + 1] = tostring(select(idx, ...)) .. (idx == total and '\n' or '\t');
    end
  end
  print = newprint;
  local f = loadstring(thecode);
  local status, error = pcall(f);
  if status == false then
		print (">>Error: " .. error .. "<<");
  end
  print = oldprint;
  
  return table.concat(strbuf);
end

function process(request, conn)

	local respheader, respdata = '', '';
	reqdata = {};

	_, _, method, req, major, minor  = string.find(request, "([A-Z]+) (.+) HTTP/(%d).(%d)");

	if reqTypes[method] then

		if method == "POST" then
			print("post");
		else

		local fname = ""
		if req:find("%?") then
			local rest
			_, _, fname, rest = req:find("(.*)%?(.*)");
			rest = rest .. "&";
			for crtpair in rest:gmatch("[^&]+") do
				local _, __, k, v = crtpair:find("(.*)=(.*)");
				-- replace all "%xx" characters with their actual value
				v = v:gsub("(%%%x%x)", function(s) return string.char(tonumber(s:sub(2, -1), 16)) end);
				reqdata[k] = v;
			end
		else
			fname = req;
		end

		fname = ( fname == "/" ) and "index.pht" or fname:sub(2, -1);
		s, e = fname:find("%.[%a%d]+$");
		local ftype = fname:sub(s+1, e):lower();
		ftype = (#ftype > 0 and ftype) or "txt";

		if requestToConsole then
			print(method .. ":" .. fname);
		end

		if file.open(fname, "r") then
			conn:send("HTTP/1.1 200 OK\r\nConnection: close\r\nServer: eLua-miniweb\r\nContent-Type: " .. extmap[ftype or "txt"] .. "\r\n\r\n");
			sendFileContents(conn,ftype);
		else
			conn:send("HTTP/1.1 404 Not Found\r\nConnection: close\r\nServer: eLua-miniweb\r\nContent-Type: text/html\r\n\r\nPage not found");
		end

		end
	else
		conn:send("HTTP/1.1 400 Bad Request\r\nConnection: close\r\nServer: eLua-miniweb\r\nContent-Type: text/html\r\n\r\n400 Invaild Request");
	end

end


sendFileContents = function(conn, type)
	repeat 
		local line=file.readline() 
		if line then 
			 if type == "pht" then
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



