-- init.lua
local IDLE_AT_STARTUP_MS = 4500;

tmr.alarm(1, IDLE_AT_STARTUP_MS, tmr.ALARM_SINGLE, function()
    dofile("application.lua") 
end) 
