---------------- Main program

----------------------
-- Configuration Access Point WiFi
print("WiFi starting...")
ipcfg = {}
ipcfg.ip="192.168.1.1"
ipcfg.netmask="255.255.255.0"
ipcfg.gateway="192.168.1.1"
wifi.ap.setip(ipcfg) 
cfg={}
cfg.ssid="pogoda"
cfg.max=1
wifi.ap.config(cfg) 
wifi.setmode(wifi.SOFTAP)
print("WiFi started")
----------------------

----------------------
-- Global Variables
counter = 0
responseOK = "HTTP/1.1 200 OK \r\nContent-Type: text/html\r\n\r\n"
lastRequestWether = false
temp = 0
humi = 0
temp_dec = 0
humi_dec = 0
pin = 4
----------------------

----------------------
-- Functions
-- DHT11:
function readDataFromDHT()
	status, temp, humi, temp_dec, humi_dec = dht.read(pin)
	if status == dht.OK then
		print( "DHT data read" )
	elseif status == dht.ERROR_CHECKSUM then
		print("DHT Checksum error")
	elseif status == dht.ERROR_TIMEOUT then
		print("DHT timed out")
	end
end
-- WWW:
function readPage(fileName)
    file.open(fileName)
    local page=file.read()
    file.close()
	return page
end

function sendResponse(socket, page)
	socket:on("sent", function(sck) sck:close() end)    
	socket:send(page)
end

function prepareMainPage(data)
    local page = responseOK..readPage("index.html")
    page = string.gsub(page, "#VV", counter)
    counter = counter + 1
    page = string.gsub(page, "#PP", data)
    return page
end

function prepareWeather()
    local page = readPage("pogoda.html")
	local data = string.format("%d.%01d",
      			math.floor(temp),
      			temp_dec)
    page = string.gsub(page, "#TI", data)
    page = string.gsub(page, "#TO", "--" )
	data = string.format("%d",
      			math.floor(humi))
    page = string.gsub(page, "#HH", data)
    return page
end
----------------------

----------------------
-- Server receiver
function receiver(socket, data)
    local i
    local j
	local page = nil
    if string.find(data,"favicon")==nil then    
        print(data)
    end
    i,j=string.find(data, "\n")
    data=string.sub(data, 1,j) 
    if string.find(data, " / HTTP") then
		page = prepareMainPage(prepareWeather())
		lastRequestWether = true
    end     
    if string.find(data, "index.html") then
		page = prepareMainPage(prepareWeather())
		lastRequestWether = true
    end   
    if string.find(data, "weather") then
		page = prepareMainPage(prepareWeather())
		lastRequestWether = true
    end
    if string.find(data, "info") then
		page = prepareMainPage(readPage("info.html"))
		lastRequestWether = false
    end
	if string.find(data, "page") then
		if lastRequestWether then
		    page = prepareWeather()
		else
		    socket:close()
		end
    end
	if string.find(data, "style.css") then
		page = readPage("style.css")
    end
	if string.find(data, "script.js") then
		page = readPage("script.js")
    end
    if page ~= nil then
	    sendResponse(socket, page)
    end
    collectgarbage("collect")       
end
----------------------

----------------------
-- DHT cyclic timer
tmr.alarm(1, 20000, tmr.ALARM_AUTO, readDataFromDHT) 

-- read DHT at startup
readDataFromDHT()

----------------------
-- Setting up a server
if sv then                
    print("Server is already running") 
else                      
    print("Setting up the server")
    sv = net.createServer(net.TCP, 30)
end

-- listening on port 80
if sv then
  sv:listen(80, function(connection)
    connection:on("receive", receiver)    
  end)
end
print("Listening on port 80")

print("End of code")
----------------------
