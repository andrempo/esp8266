httpserver = function ()
  srv=net.createServer(net.TCP) srv:listen(80,function(conn) 
    conn:on("receive",function(conn,payload) 

    rt = string.match(payload, "^[^\/]*"):gsub( "%s$", "");

	if rt == "GET" then

		print(payload);
		header = "HTTP/1.1 200 OK\n"
		conn:send(header) 
		header = nil;


		--data = "[".. tmr.now() ..",".. node.heap() ..",".. gpio.read(8) ..",".. gpio.read(9) ..",".. adc.read(0) .."]"
		--data = "<html><head></head><body><form><input type=\"submit\" name=\"GoData\" value=\"Go\"></form><body></html>"



		ct = "Content-Type: text/html \n\n";
		conn:send(ct);
		ct=nil;

		conn:send("<html>")
		conn:send("<body>")
		conn:send("<form method=\"post\">")
		conn:send("<input type=\"submit\" value=\"GoGo\" name=\"Val\" />")
		conn:send("<form>")
		conn:send("</body>")
		conn:send("</html>")

		print(node.heap())
		 

		--length = "Content-Length: " .. string.len(data) .. "\n"
		--conn:send(length);
		--length=nil;


		--conn:send(data)
		--data=nil

	elseif rt == "POST" then

		ind =  string.match("test\n\nval=n&b=t&t=h", '\n\n.-$'):gsub( "\n", "");
		for word in string.gmatch(ind, "&.-$") do print(word) end
		print(payload);

	end

    conn:on("sent",function(conn) 
		conn:close() 
		conn=nil 
		collectgarbage("collect") 
	end) 
    end)
  end)
end
httpserver()