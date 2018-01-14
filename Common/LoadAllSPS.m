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


function SPSoutput = LoadAllSPS(idlist,typelist,labellist)
% FUNCTION TO LOAD ALL SPSs CONNECTED TO THE PC. INPUT:
%   idlist: LIST THE HARDWARE IDS OF THE CONNECTED SPSs IN ROW VECTOR
%       eg: idlist = [7 6];
%   typelist: LIST THE TYPE OF EACH OF THE CONNECTED SPSs IN CELL OF STRINGS
%       HV: 24V and fan (21V 1.1A)
%       HC: 12V and fan (8V 2.1A)
%       NO: 12V no fan (8V 1A)
%       eg: typelist = {'NO' 'HV'};
%   labellist: LIST THE LABEL TO ATTACH TO EACH OF THE CONNECTED SPSs IN CELL 
%            OF STRINGS. USE FORMAT 'MPPT x' OR 'PANEL x'
%       eg: labellist = {'MPPT 1' 'MPPT 2'};


    assert(iscell(typelist))
    assert(iscell(labellist))
    assert(isnumeric(idlist))
    assert(length(idlist)==length(typelist))
    assert(length(idlist)==length(labellist))
    try
        load('SPSCalibrationData')
    catch
        disp('Could not load calibration data for devices')
    end

    try
        fclose(instrfind('Type', 'serial')); %Close all serial ports
    end

    % Get all serial ports available on system
    serialInfo = instrhwinfo('serial');
    COMports = serialInfo.SerialPorts;

    % Counter for found serial ports with SPSs
    numSPS = 0;

    clear SPSserial
    disp('Scanning COM ports')
    % For every available com port
    for i = 1:length(COMports)
        %Grab the serial port
        serials(i) = serial(COMports{i},'BaudRate',115200,'OutputBufferSize',10000,'Timeout',.5);
        %Open it
        fopen(serials(i));
        %Test device type
        fprintf(serials(i),'W\n');
        response = strtrim(fscanf(serials(i)));
        if ~strcmpi(response,'SPS')
            disp([serials(i).port ': No SPS'])
        else
            disp([serials(i).port ': Found SPS'])
            numSPS = numSPS+1;
            SPSserial(numSPS) = serials(i);
        end
    end

    %SPSserial now has all found SPSs and their serial ports.
    disp(['Found ' num2str(numSPS) ' Solar Panel Simulators'])
    
    %Load all SPSs as devices
    assert(numSPS>=length(idlist))
    clear SPSdevices
    for j = 1:numSPS
        SPSdevices(j) = deviceClassSPS(SPSserial(j));
    end
    
    clear SPSoutput
    %Get a list of all available hardware IDs
    foundHwIds = [SPSdevices.hardwareID];
    %Sort by hardware IDs and attach attributes
    for i = 1:length(idlist) 
        listPos = find(idlist(i)==foundHwIds);
        if ~isempty(listPos)
            % Save device in correct position in output struct
            SPSoutput(i) = SPSdevices(listPos);
            % Set correct input voltage type
            SPSoutput(i).setInputType(typelist{i});
            % Set label
            SPSoutput(i).setLabel(labellist{i});
            % Find and set calibration
            if exist('calibrationData','var')
                calibListPos = find(idlist(i)==calibrationData(:,1));
                if ~isempty(calibListPos)
                    SPSoutput(i).setCalibration(calibrationData(calibListPos,2:5));
                else
                    disp(['Did not find calibration for device with ID ' num2str(idlist(i))])
                end
            end
        else
            disp(['Could not find device with ID ' num2str(idlist(i))])
            assert(false)
        end
    end
end



