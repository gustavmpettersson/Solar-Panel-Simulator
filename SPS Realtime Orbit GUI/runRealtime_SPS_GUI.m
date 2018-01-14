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




% This file will load a simulation and run it on the SPS hardware in real
% time. Needs to have a file with simulationData (in the output format of
% the solar power simulation software) to load and a list of the hardware
% ids, input types, and what to simulate on these.

clc
clear all
close all
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

% Load saved simulation data
load('simulationData_MIST_sample.mat');

%% RUN
% Load the devices
SPSs = LoadAllSPS(SPS_HW_IDS,SPS_TYPES,SPS_LABELS);

% Load the GUI to run the simulation
Realtime_SPS_GUI(SPSs,simulationData,SPS_LABELS);




