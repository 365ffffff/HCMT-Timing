--Timing System of HCMT Welding Machine V1.0
--UTF-8
--SMA
--2019-04-12
--WIFI.STATION

-----------------------------------------------------------------------

print("Start WIFI STATION and AP MODE")
wifi.setmode(wifi.STATIONAP)

apcfg={}
apcfg.ssid="TIG_1"
apcfg.pwd="hdgx8266"
wifi.ap.config(apcfg)

stacfg={}
stacfg.ssid="TP-LINK_SMA"
stacfg.pwd="ffffffff8"
wifi.sta.config(stacfg)
wifi.sta.connect()
print(wifi.sta.getip())


connect_state = 0
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
    connect_state = 0
	print("disconnected the router")
end)


wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
   if connect_state == 0 then
      print("connected IP="..T.IP)
   end
   connect_state = 1
end)

-------------------------------------------------------------------------

start_init = function()  
gpio.mode(2, gpio.INPUT,gpio.PULLUP);

gpio.mode(0, gpio.OUTPUT);  
gpio.mode(1, gpio.OUTPUT);
gpio.write(0,gpio.HIGH);  
gpio.write(1,gpio.HIGH);  
D1_state=0;
D0_state=0;
print("start_init ok")
end

---------------------------------------------------------------------

read_times_file=function(filename)
    if file.open(filename, "r") then
        working_name=file.readline()
        working_year=file.readline()
        working_month=file.readline()
        local s=file.readline()
        working_hours=file.readline()
        working_minutes=file.readline()
        working_seconds=file.readline()
        working_name=string.gsub(working_name,"\n","")
        working_year=string.gsub(working_year,"\n","")
        working_month=string.gsub(working_month,"\n","")
        working_hours=string.gsub(working_hours,"\n","")
        working_minutes=string.gsub(working_minutes,"\n","")
        working_seconds=string.gsub(working_seconds,"\n","")
        print("name=",working_name);
        print("year=",working_year);
        print("month=",working_month);
        print("hours=",working_hours);
        print("minutes=",working_minutes);
        print("seconds=",working_seconds);
        file.close()
    end
end

-----------------------------------------------------------------------


write_times_file=function(filename)
    if file.open(filename, "w") then
        file.writeline(working_name)
        file.writeline(working_year)
        file.writeline(working_month)
        file.writeline("")
        file.writeline(working_hours)
        file.writeline(working_minutes)
        file.writeline(working_seconds)
        file.close()
        print("worktimes.txt is saved.")
    end
end 

----------------------------------------------------------------------------

sendFileContents = function(conn, filename)      
if file.open(filename, "r") then
	--conn:send(responseHeader("200 OK","text/html"));          
	repeat           
	local line=file.readline()           
	if line then               
		conn:send(line);          
	end           
	until not line           
	file.close();      
	else
	conn:send(responseHeader("404 Not Found","text/html"));          
	conn:send("Page not found");              
	end  
end 

-------------------------------------------------------------------------------------

responseHeader = function(code, type)      
	return "HTTP/1.1 " .. code .. "\r\nConnection: close\r\nServer: nunu-Luaweb\r\nContent-Type: " .. 
	type .. "\r\n\r\n";   
end 

----------------------------------------------------------------------------------

httpserver = function ()      
	start_init();   
	srv=net.createServer(net.TCP)       
	srv:listen(80,function(conn)         
		conn:on("receive",function(conn,request)           
			conn:send(responseHeader("200 OK","text/html"));          
			if string.find(request,"MSG=0") then              
				clean_time=1 
                print("clean time=1")     
			elseif string.find(request,"MSG=1") then              
				save_name=1
                
                msg=string.find(request,"MSG=1")
                
                pht=string.find(request,".pht")
                
                name_str=string.sub(request,(msg+6),(pht-1))
                
                local function urlDecode(s)
                    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
                    return s
                end
                working_name=urlDecode(name_str)
                print("decode_name=",working_name)

            elseif string.find(request,"MSG=2") then              
                save_ym=1
                msg1=string.find(request,"MSG=2")
                
                pht1=string.find(request,".pht")
                
                yearmonth_str=string.sub(request,(msg1+6),(pht1-1))
                working_year=string.sub(yearmonth_str,1,4)
                working_month=string.sub(yearmonth_str,6,-1)
                
                print("save ym=1",working_year,working_month)          
			end              
				
			 
				sendFileContents(conn,"header.htm");
                
				conn:send("<div><font size=\"10\">使用者:<input type=\"text\"  value=" .. working_name .. " ");
                conn:send("readonly  style=\"font-size:36px;border:3px solid #000000;width:200px;\" size=\"5\">  ") ;
                
                conn:send("<br><br>统计年月份:<input type=\"number\"  value=" .. working_year .. " ");
                conn:send("readonly  style=\"font-size:36px;border:3px solid #000000;width:120px;\" size=\"5\"> 年 ") ;
                
                conn:send("<input type=\"number\"  value=" .. working_month .. " ");
                conn:send("readonly  style=\"font-size:36px;border:3px solid #000000;width:120px;\" size=\"3\"> 月 <br><br>累计: ") ;
                
                conn:send("<input type=\"number\"  value=" .. working_hours .. " ");
                conn:send("readonly  style=\"font-size:36px;border:3px solid #000000;width:120px;\" size=\"5\"> h ") ;
                
                conn:send("<input type=\"number\"  value=" .. working_minutes .. " ");
                conn:send("readonly  style=\"font-size:36px;border:3px solid #000000;width:120px;\" size=\"5\"> m <br><br>状态: ") ;
                
                conn:send("<input type=\"number\"  value=" .. working_seconds .. " "); 
                conn:send("readonly  style=\"font-size:36px;border:3px solid #000000;width:120px;\" size=\"5\"> s " .. work_state .. "  <br><br></font></div> ") ;        
			          
			print('request data=\n',request);
		end)
         
		conn:on("sent",function(conn)           
						conn:close();           
						conn = nil;              
						end)   
						   
	end)  

end    

------------------------progrem start---------------------------------------------------


working_name="测试者"
read_times_file("worktimes.txt");
led_state=0;
workflag_d2=gpio.read(2)
work_state="resting"
clean_time=0
save_name=0
save_ym=0


httpserver();



------------------------------------------------------------------------------------

mytimer = tmr.create()
mytimer:register(10000, tmr.ALARM_AUTO, function() 
    print(work_state .. " " .. working_year .. "y " .. working_month .. "m  total: " .. working_hours .. "h " .. working_minutes .. "m " .. working_seconds .. "s") 
    if clean_time==1 then
        working_hours=0;
        working_minutes=0;
        working_seconds=0;
        clean_time=0;
    end        
    workflag_d2=gpio.read(2);
    if workflag_d2==0 then
        work_state="wroking";
        if led_state==0 then
            gpio.write(0,gpio.HIGH);
            led_state=1;
            working_seconds=working_seconds+10;
            working_minutes=working_seconds/60;
            if working_seconds>=3600 and working_minutes>=60 then
                working_hours=working_hours+1;
                working_minutes=0;
                working_seconds=0;
            end
        else 
            gpio.write(0,gpio.LOW);
            led_state=0;
            working_seconds=working_seconds+10;
            working_minutes=working_seconds/60;
            if working_seconds>=3600 and working_minutes>=60 then
                working_hours=working_hours+1;
                working_minutes=0;
                working_seconds=0;
            end
            write_times_file("worktimes.txt");
        end
    else
        work_state="resting";
        print(work_state)
    end
    end)
mytimer:interval(10000) -- actually, 3 seconds is better!
mytimer:start()


