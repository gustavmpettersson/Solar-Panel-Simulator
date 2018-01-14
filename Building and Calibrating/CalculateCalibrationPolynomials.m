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


close all
clear all
%% Script for generating calibration polynomials
% Enter ADC values from voltage testing here (at corresponding voltages)
adc = [16 43 90 181 367 552 737 922 1107 1293 1478 1663 1849 ...
    2033 2219 2404 2591 2776 2961 3145 3331 3516 3702 3886]';
volt = [.1 .25 .5 1:21]';
% Enter measured current in mA during current testing here (at corresponding dac values)
amp = [3 8 22 48 102 209 314 421 528 634 741 847 954 ...
       1060 1167 1274 1380 1487 1593 1700 1806 1912 2018 2125]';
amp = amp/1000; %make into A
dac = [10 25 50 100 200:200:4000]';
   
% Rest of the script:

voltP = polyfit(adc,volt,1)
figure
plotADC = 0:4095;
plot(adc,volt,'rx',plotADC,polyval(voltP,plotADC),'b-','LineWidth',1,'MarkerSize',8);
xlabel('ADC value'); ylabel('Voltage [V]');
legend('Measurements','Calibration curve','Location','NW')
axis([0 4095 0 21])
grid on
box off


ampP = polyfit(amp,dac,1)
figure
plotA = linspace(0,2.2,1000);
plot(amp,dac,'rx',plotA,polyval(ampP,plotA),'b-','LineWidth',1,'MarkerSize',8);
xlabel('Current [A]'); ylabel('DAC value');
axis([0 2.2 0 4095])
legend('Measurements','Calibration curve','Location','NW')
grid on
box off


disp('Calibration string: ')
[sprintf('%.5g',ampP(1)) ' ' sprintf('%.5g',ampP(2)) ' ' ...
    sprintf('%.5g',voltP(1)) ' ' sprintf('%.5g',voltP(2))]


