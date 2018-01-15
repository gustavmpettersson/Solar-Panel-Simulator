close all
clear all


[Ip, Vp] = getPanelIVCurve([.25 .5 .75 1],2,2);
plot(Vp,Ip)
axis([0 6 0 1])
xlabel('Voltage [V]')
ylabel('Current [A]')
grid on

figure
Vc = linspace(0,3);
Ic = getCellCurrent(linspace(0,3),1);
plot(Vc,Ic)
axis([0 3 0 .6])
xlabel('Voltage [V]')
ylabel('Current [A]')
grid on

