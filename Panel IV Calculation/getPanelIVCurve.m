% FUNCTION TO CALCULATE THE IV CURVE OF A SOLAR PANEL WITH KNOWN 
% ILLUMINATION. INPUT:
%   i: Illumination of each cell, row vector. Order cells by which series
%   string they belong to.
%   nSer: Number of cells in series.
%   nPar: Number of cells in parallel.
%   N: Number of sampling points. Defaults to 50. (Outputs nSer*N points).
% OUTPUT:
%   [Ip, Vp]: Current and voltage sample points, column vectors.


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


function [Ip,Vp,Ic,Vc,Is,Vs] = getPanelIVCurve(i,nSer,nPar,N)
nCells = length(i);

if nargin < 4
    N = 50;
end

% Parameters
Vrng = [-.4 2.6];
Irng = [0 0.6];
Vt_spd = .03;
Isat_spd = 1e-3;

%%%%% START
assert(length(i) == nSer*nPar)
% Sample each cell
Vc = linspace(Vrng(1),Vrng(2),N)';
Vp = linspace(0,Vrng(2)*nSer,N*nSer)';
Ip = zeros(N*nSer,1);
Ic = zeros(N,nCells);
for j = 1:nCells
    Ic(:,j) = getCellCurrent(Vc,i(j));
end

for k = 1:nPar
    a = (1:nSer)+nSer*(k-1);
    Icells = Ic(:,a);
    IoldInside = (Icells>Irng(1))&(Icells<Irng(2));
    Iold = unique(Icells(IoldInside));
    Inew = linspace(Irng(1),Irng(2),(nSer+1)*N-length(Iold))';
    Is = sort([Iold;Inew]);
    Vs = -Vt_spd*log(Is/Isat_spd+1); %Series diode
    for l = 1:nSer %Add each cell
        Vs = Vs + interp1(Ic(:,a(l)),Vc,Is,'pchip');
    end
    Ip = Ip + interp1(Vs,Is,Vp,'pchip',0);
end
end