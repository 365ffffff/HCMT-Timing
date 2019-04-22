print("init lua is runed")


gpio.mode(2, gpio.INPUT);
gpio.mode(0, gpio.OUTPUT);  
gpio.mode(1, gpio.OUTPUT);
gpio.write(0,gpio.HIGH);  
gpio.write(1,gpio.HIGH);



dofile("webserver.lua")