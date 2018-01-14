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



clear all
close all
clc
addpath('../Common')

%% SETUP

%LIST THE HARDWARE IDS OF THE CONNECTED SPSs IN ROW VECTOR
SPS_HW_IDS = [7 5 6];
%LIST THE TYPE OF EACH OF THE CONNECTED SPSs IN CELL OF STRINGS
%    HV: 24V and fan (21V 1.1A)
%    HC: 12V and fan (8V 2.1A)
%    NO: 12V no fan (8V 1.1A)
SPS_TYPES = {'NO' 'HC' 'HV'};
%LIST THE LABEL TO ATTACH TO EACH OF THE CONNECTED SPSs IN CELL OF STRINGS
%    IF MPPT USE 'MPPT x', IF PANEL USE 'PANEL x'
SPS_LABELS =  {'MPPT 1' 'MPPT 2' 'MPPT 3'};

%% RUN
% Load the devices
devices = LoadAllSPS(SPS_HW_IDS,SPS_TYPES,SPS_LABELS);

% Call spsGUI on each device to open a GUI on it!
for i = 1:length(devices)
    Manual_SPS_GUI(devices(i));
end




