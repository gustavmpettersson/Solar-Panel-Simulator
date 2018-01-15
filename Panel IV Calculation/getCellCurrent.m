% FUNCTION TO CALCULATE A SINGLE SOLAR CELL'S CURRENT AT A GIVEN VOLTAGE
% AND ILLUMINATION. INPUT:
%   Vc: Voltage(s) to calculate at, column vector.
%   i: Illumination to calculate at, scalar.
% OUTPUT:
%   Ic: Current(s) calculated, column vector.


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


function Ic = getCellCurrent( Vc,i )
% Cell parameters in SI units
Imax = 0.5009;
Vd_t = 0.1135;
Id_sat = 10^-10;
Vb_t = 0.03;
Ib_sat = 1e-3;
Rs = 0.04;
Rp = 400;

theta = @(V,Ipv) (Rs*Id_sat)/Vd_t * exp((Rs*Ipv+V)/Vd_t);
I = @(V,Ipv) Ipv -V/Rp -Vd_t/Rs*lambertw(theta(V,Ipv)) +Ib_sat*(exp(-V/Vb_t)-1);

Ic = I(Vc,i*Imax);
end

