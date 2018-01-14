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


classdef Manual_SPS_GUI < handle
% CLASS TO OPEN GUI WHICH ALLOWS MANUAL CONTROL OF SINGLE SPS. INPUT:
%   sps: deviceClassSPS object of the SPS to control
    
    properties (SetAccess = private)
        device
        figure
        maxcurr = 1.1;
        maxvolt = 8;
        UnitIVCurve;
        
        statustext
        currtext
        volttext
        currslider
        voltslider
    end
    
    methods
        %% Constructor
        function obj = Manual_SPS_GUI(sps)
            obj.device = sps;
            obj.figure = figure('Position',[360,500,400,200],'MenuBar','none','ToolBar','none',...
                'Name',['ID ' num2str(obj.device.hardwareID) ' ' obj.device.label],'CloseRequestFcn',@obj.windowCloseCallback);
            
            %Set the limits for the type
            %    HV: 24V and fan (21V 1.1A)
            %    HC: 12V and fan (8V 2.1A)
            %    NO: 12V no fan (8V 1.1A)
            if strcmp('HV',obj.device.inputType)
                obj.maxcurr = 1.1;
                obj.maxvolt = 21;
            elseif strcmp('HC',obj.device.inputType)
                obj.maxcurr = 2.1;
                obj.maxvolt = 8;
            elseif strcmp('NO',obj.device.inputType)
                obj.maxcurr = 1.1;
                obj.maxvolt = 8;
            end                            
            load('Reference_Cell_IV_curve.mat');
            obj.UnitIVCurve = UnitIVCurve;
            
            uicontrol(obj.figure,'Style','text','Position',[0 170 400 30],'String',...
                ['SPS ID: ' num2str(obj.device.hardwareID) ', LABEL: ' obj.device.label ...
                ', TYPE: ' obj.device.inputType],'FontSize',14)
            
            obj.statustext = uicontrol(obj.figure,'Style','text','Position',[0 0 200 170],'String',...
                ['Current setting:' newline ...
                    'S-C Current: 0.00 A' newline ...
                    'O-C Voltage: 0.0 V' newline ...
                    'MPP Current: 0.000 A' newline ...
                    'MPP Voltage: 0.00 V' newline ...
                    'PPT Power: 0.000 W'],'FontSize',12);
            
            uicontrol(obj.figure,'Style','pushbutton','Position',[0 0 200 50],'String','Disable Output','Callback',@obj.disableCallback)
            uicontrol(obj.figure,'Style','pushbutton','Position',[200 0 200 50],'String','Set Output','Callback',@obj.setCallback)
            obj.currslider = uicontrol(obj.figure,'Style','slider','Position',[200 120 200 20],'Value',0.01,...
                'Max',obj.maxcurr,'Min',0.01,'Callback',@obj.currSliderCallback,'SliderStep',[.01/obj.maxcurr .1/obj.maxcurr]);
            obj.currtext = uicontrol(obj.figure,'Style','text','Position',[200 140 200 15],'String','Short-Circuit Current: 0.01 A');
            obj.voltslider = uicontrol(obj.figure,'Style','slider','Position',[200 70 200 20],'Value',0.1,...
                'Max',obj.maxvolt,'Min',0.1,'Callback',@obj.voltSliderCallback,'SliderStep',[.1/obj.maxvolt 1/obj.maxvolt]);
            obj.volttext = uicontrol(obj.figure,'Style','text','Position',[200 90 200 15],'String','Open-Circuit Voltage: 0.1 V');
        end
    end
    methods (Access = private) 
        %%Callbacks
        function disableCallback(obj,~,~)
            set(obj.figure.Children,'Enable','off')
            drawnow
            obj.device.disable()
            obj.statustext.String = ['Current setting:' newline ...
                    'S-C Current: 0.00 A' newline ...
                    'O-C Voltage: 0.0 V' newline ...
                    'MPP Current: 0.000 A' newline ...
                    'MPP Voltage: 0.00 V' newline ...
                    'PPT Power: 0.000 W'];
            set(obj.figure.Children,'Enable','on')
        end
        
        function setCallback(obj,~,~)
            set(obj.figure.Children,'Enable','off')
            drawnow
            obj.device.setIVcurve(obj.UnitIVCurve(1,:)*obj.currslider.Value,obj.UnitIVCurve(2,:)*obj.voltslider.Value);
            obj.statustext.String = ['Current setting:' newline ...
                    'S-C Current: ' num2str(obj.currslider.Value) ' A' newline ...
                    'O-C Voltage: ' num2str(obj.voltslider.Value) ' V' newline ...
                    'MPP Current: ' num2str(obj.currslider.Value*.941,'%.3f') ' A' newline ...
                    'MPP Voltage: ' num2str(obj.voltslider.Value*.866,'%.2f') ' V' newline ...
                    'PPT Power: ' num2str(obj.voltslider.Value*.866*obj.currslider.Value*.941,'%.3f') ' W'];
            set(obj.figure.Children,'Enable','on')
        end
        
        function currSliderCallback(obj,~,~)
            obj.currslider.Value = round(obj.currslider.Value,2);
            obj.currtext.String = ['Short-Circuit Current: ' num2str(obj.currslider.Value) ' A'];
        end
        
        function voltSliderCallback(obj,~,~)
            obj.voltslider.Value = round(obj.voltslider.Value,1);
            obj.volttext.String = ['Open-Circuit Voltage: ' num2str(obj.voltslider.Value) ' V'];
        end
        
        function windowCloseCallback(obj,~,~)
            try
                obj.disableCallback();
            catch
                disp('FAILED TO DISABLE, CLOSING ANYWAYS')
            end
            delete(obj.figure);
        end
    end
    
end

