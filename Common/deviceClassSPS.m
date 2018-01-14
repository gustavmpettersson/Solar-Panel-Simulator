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


classdef deviceClassSPS < handle  
% CLASS TO CONTROL A SINGLE SPS. INPUT
%   port: An open serial object which connected to the SPS
    properties (SetAccess = private)
        serialPort
        serialPortName
        currentCalib = [1881 0];        %Ideal calibration curves
        voltageCalib = [.00537 0];      %loaded as defaults
        hardwareID
        LUT
        inputType = 'NO';     %Set to HV or HC to allow more than (8V 1.1A)
        label = '';
    end
    
    methods
        function obj = deviceClassSPS(port)
            assert(isa(port,'serial'))
            obj.serialPort = port;
            obj.serialPortName = port.Port;
            assert(strcmpi(obj.serialPort.Status,'open'))
            %Test device type
            fprintf(obj.serialPort,'W\n')
            response = fscanf(obj.serialPort);
            assert(strcmp(strtrim(response),'SPS'))
            %Test device version
            fprintf(obj.serialPort,'V\n')
            response = fscanf(obj.serialPort);
            assert(strcmp(strtrim(response),'1'))
            %Get device ID
            fprintf(obj.serialPort,'I\n')
            response = fscanf(obj.serialPort);
            obj.hardwareID = str2num(response);
            assert(obj.hardwareID>0 && obj.hardwareID<256)
            %Set the output to zero
            obj.disable();
        end

        function setIVcurve(obj,Ipoints,Vpoints)
            % Sets the LUT in the device. Uses calibration if entered. 
            % Truncates output based on if set to HV (21V 1.1A) or HC 
            % (8V 2.1A) (or none). Voltage points must be unique.
            obj.LUT = zeros(1,4096,'uint16');
            ADC = 0:4095;
            % Keep only finite values in the input
            goodInds = isfinite(Ipoints);
            Ipoints = Ipoints(goodInds);
            Vpoints = Vpoints(goodInds);
            if length(unique(Vpoints))>1 %If there are two or more sample points
                % Use calibration to find voltages for each ADC value
                voltages = polyval(obj.voltageCalib,ADC);
                % Use IV curve to find currents at these voltages
                currents = interp1(Vpoints,Ipoints,voltages,'pchip',0);
                % Use calibration to find DAC values for these currents
                obj.LUT = uint16(polyval(obj.currentCalib,currents));
                % Clean up the values on low end
                obj.LUT(currents<=0) = 0;
                obj.LUT(obj.LUT<0) = 0;
                % Limit the output based on type
                switch strtrim(obj.inputType)
                    case 'HC'
                        % Limit to(8V, 2.1A)
                        obj.LUT(obj.LUT>4000) = 4000;
                        obj.LUT(1601:end) = 0;
                    case 'HV'
                        % Limit to(21V, 1.1A)
                        obj.LUT(obj.LUT>2100) = 2100;
                        obj.LUT(3901:end) = 0;
                    otherwise
                        % Limit by both if undefined version (8V, 1A)
                        obj.LUT(obj.LUT>2100) = 2100;
                        obj.LUT(1601:end) = 0;
                end
            end
                
            % Send the data
            try
                obj.SendDataToTeensy()
            catch
                throw(MException('SPSdevice:failedToSend','Failed to send IV curve to Teensy'))
            end
        end
        
        function disable(obj)
            obj.LUT = zeros(1,4096,'uint16');
            try
                obj.SendDataToTeensy()
            catch
                throw(MException('SPSdevice:failedToSend','Failed to send IV curve to Teensy'))
            end
        end
        
        %% Set and get properties
        function setCalibration(obj,calib)
            assert(length(calib) == 4)
            obj.currentCalib = calib(1:2);
            obj.voltageCalib = calib(3:4);
        end
        function calib = getCalibration(obj)
            calib = [obj.currentCalib obj.voltageCalib];
        end
        
        function setHardwareID(obj,id)
            obj.hardwareID = id;
        end
        function id = getHardwareID(obj)
            id = obj.hardwareID;
        end
        
        function setLabel(obj,str)
            obj.label = str;
        end
        function str = getLabel(obj)
            str = obj.label;
        end
        
        function setInputType(obj,str)
            obj.inputType = str;
        end
        function str = getInputType(obj)
            str = obj.inputType;
        end
        
    end
    methods (Access = private)        
        function SendDataToTeensy(obj)
            %SENDDATATOTEENSY Sends dataset with lookup table to Teensy
            %   data: uint16 array of length 4096
            %   serialPort: serial object connected to Teensy and opened
            %Throws exception if communication fails (check port is open).
            %Clears serial input buffer.

            %tic
            assert(length(obj.LUT)==4096)
            assert(isa(obj.LUT,'uint16'))
            assert(any(obj.LUT<4096))


            flushinput(obj.serialPort) %Purge input buffer
            fprintf(obj.serialPort,'D\n') %Ask Teensy to ready
            response = fscanf(obj.serialPort);
            assert(strcmp(strtrim(response),'OK')) %Now ready to receive

            %Time to build datastructure of 8192 unsigned bytes
            datastruct = uint8(zeros(1,4096*2));

            activeBits = uint16(bin2dec('111111')); %Use only last 6 bits of a byte
            msbID = uint8(bin2dec('10000000')); %Identify MSB by leading 10
            lsbID = uint8(bin2dec('01000000')); %Identify LSB by leading 01

            for i = 1:4096 %For every datapoint
                %Assemble bit structure
                msbs = bitor(uint8(bitand(bitshift(obj.LUT(i),-6),activeBits)),msbID);
                lsbs = bitor(uint8(bitand(obj.LUT(i),activeBits)),lsbID);
                %Add to output array
                datastruct(2*i-1:2*i) = [msbs lsbs];
            end

            fwrite(obj.serialPort, datastruct, 'sync'); %Write array to Teensy
            res = fscanf(obj.serialPort);
            assert(strcmp(strtrim(res),'F')) %Read and assert acknowledgement
        end
    end
end

