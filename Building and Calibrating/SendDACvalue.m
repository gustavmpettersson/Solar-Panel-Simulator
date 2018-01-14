% Copyright 2018 Gustav Pettersson, gustavpettersson@live.com
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.



% This script allows to send fixed value to set the DAC to on a SPS
% connected to the following COM port. Enter the value (0-4095) and press
% enter to send.

port = 'COM4';

try
fclose(instrfind('Type', 'serial')); %Close all serial ports
end
serialPort = serial(port,'BaudRate',115200,'OutputBufferSize',10000,'Timeout',10);
%% Initiate serial communication
fopen(serialPort)
flushinput(serialPort)
%Test device type
fprintf(serialPort,'W\n')
response = fscanf(serialPort);
assert(strcmp(strtrim(response),'SPS'))
%Test device version
fprintf(serialPort,'V\n')
response = fscanf(serialPort);
assert(strcmp(strtrim(response),'1'))
%Get device ID
fprintf(serialPort,'I\n')
response = fscanf(serialPort);
DeviceID = str2num(response);
assert(DeviceID>0 && DeviceID<256)
disp(['Connected to device with hardware ID ' num2str(DeviceID)])

data = zeros(1,4096,'uint16');

%% Stream data
while(true)
    user = input('Stream? ','s');
    if (length(user)>0)
        data = str2num(user)*ones(1,4096,'uint16');
    end
    tic
    SendDataToTeensy(data,serialPort)
    toc
end

%%
function SendDataToTeensy( data, serialPort )
%SENDDATATOTEENSY Sends dataset with lookup table to Teensy
%   data: uint16 array of length 4096. Each value must be 12 bit
%   serialPort: serial object connected to Teensy and opened
%   Throws exception if communication fails (check port is open).
%   Clears serial input buffer.

assert(length(data)==4096)
assert(isa(data,'uint16'))
assert(any(data<4096))

flushinput(serialPort) %Purge input buffer
fprintf(serialPort,'D\n') %Ask Teensy to ready
response = fscanf(serialPort);
assert(strcmp(strtrim(response),'OK')) %Now ready to receive

%Time to build datastructure of 8192 unsigned bytes
datastruct = uint8(zeros(1,4096*2));

activeBits = uint16(bin2dec('111111')); %Use only last 6 bits of a byte
msbID = uint8(bin2dec('10000000')); %Identify MSB by leading 10
lsbID = uint8(bin2dec('01000000')); %Identify LSB by leading 01

for i = 1:4096 %For every datapoint
    %Assemble bit structure
    msbs = bitor(uint8(bitand(bitshift(data(i),-6),activeBits)),msbID);
    lsbs = bitor(uint8(bitand(data(i),activeBits)),lsbID);
    %Add to output array
    datastruct(2*i-1:2*i) = [msbs lsbs];
end

fwrite(serialPort, datastruct, 'sync'); %Write array to Teensy
res = fscanf(serialPort);
assert(strcmp(strtrim(res),'F')) %Read and assert acknowledgement
end

