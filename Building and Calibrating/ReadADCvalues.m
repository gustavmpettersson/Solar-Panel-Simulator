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



% This script will ask the Teensy to dump it's ADC values and print them to
% the terminal. You need to run SendDACvalue first to initiate
% communication (then Ctrl-C out of it).
% MUST RUN ReadADCvaluesStop AFTER THIS SCRIPT TO STOP THE TEENSY WRITING


fprintf(serialPort,'P\n')

while(true)
    disp(strtrim(fscanf(serialPort)))
end