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



classdef Realtime_SPS_GUI < handle
% CLASS TO OPEN GUI WHICH ALLOWS CONTROL OF REALTIME ORBIT-LIKE SIMULATIONS
% ON SEVERAL SPSs. INPUT:
%   SPSs: Array of deviceClassSPS
%   simulationData: Struct with output of MIST software power simulator
% NOTE TO EXTERNAL USERS: This is an internal format, there is a sample
% of data in this folder. Contact us for help integrating your simulator.
    
    properties (SetAccess = private)
        figure
        plotpanel
        SPSs
        IVCurves
        timestepsMin
        
        currentIndex
        restartAtEnd = false
        running = false; %Flag weather to run
        startSimTime
        startRealTime
        
        playbutton
        pausebutton
        timeslider
        statustext
    end
    
    methods
        function obj = Realtime_SPS_GUI(SPSs,simulationData,restartAtEnd)
            if nargin > 2
                obj.restartAtEnd = restartAtEnd;
            end    
        
            obj.SPSs = SPSs;
            obj.figure = figure('Position',[360,500,1000,500],'MenuBar','none','ToolBar','none',...
                'Name','Realtime SPS Simulation','CloseRequestFcn',@obj.windowCloseCallback);
            
            % Get device labels
            for i = 1:length(SPSs)
                simDevices{i} = obj.SPSs(i).getLabel();
            end
                        
            % Unpack simulation data
            obj.timestepsMin = simulationData.sim_timesteps_minutes;
            % Match the labels to simulate with their hardware devices
            for i = 1:length(SPSs)
                device = strsplit(simDevices{i});
                switch strtrim(device{1})
                    case 'MPPT'
                        ind = str2num(device{2})*2;
                        obj.IVCurves(:,i*2-1:i*2,:) = simulationData.MPPT_IV_curves(:,ind-1:ind,:);
                    case 'PANEL'
                        ind = str2num(device{2})*2;
                        obj.IVCurves(:,i*2-1:i*2,:) = simulationData.solarpanels_IV_curves(:,ind-1:ind,:);
                    otherwise
                        disp(['Could not parse identifier ' simDevices{i}])
                        assert(false)
                end
            end
            
            obj.currentIndex = 1;
            obj.startSimTime = obj.timestepsMin(1);
            obj.startRealTime = datenum(datetime)*1440; %get current time (in minutes)

            uicontrol(obj.figure,'Style','pushbutton','Position',[800 0 200 50],'String','Disable Output','Callback',@obj.disableCallback)
            obj.pausebutton = uicontrol(obj.figure,'Style','pushbutton','Position',[900 50 100 50],'String','Pause','Callback',@obj.pauseCallback);
            obj.playbutton = uicontrol(obj.figure,'Style','pushbutton','Position',[800 50 100 50],'String','Play','Callback',@obj.playCallback);
            set(obj.pausebutton,'Enable','off')
            
            obj.timeslider = uicontrol(obj.figure,'Style','slider','Position',[0 50 800 50],...
                'Min',obj.timestepsMin(1),'Max',obj.timestepsMin(end),...
                'SliderStep',[1/length(obj.timestepsMin) 50/length(obj.timestepsMin)],'Callback',@obj.sliderCallback);
            
            obj.statustext = uicontrol(obj.figure,'Style','text','Position',[0 12 800 25],...
                'FontSize',12,'String',['Time: 0.0 minutes                  Index: 1/' num2str(length(obj.timestepsMin))]);
            
            obj.plotpanel = uipanel(obj.figure,'Position',[0 .2 1 .8]);
            for i = 1:length(obj.SPSs)
                subplot(1,length(obj.SPSs),i,'Parent',obj.plotpanel)
                plot(0,0)
                title([obj.SPSs(i).label ' on SPS ID' num2str(obj.SPSs(i).hardwareID)])
            end
        end
    end
    methods (Access = private)        
        %% Update the SPSs. Waits until real time is reached. Calls back on itself!
        % Set flag obj.running == false to stop the updating.
        function stepTime(obj,~,~)
            if obj.running          
                obj.timeslider.Value = obj.timestepsMin(obj.currentIndex);
                obj.statustext.String = ['Time: ' num2str(obj.timestepsMin(obj.currentIndex),'%.1f')...
                    ' minutes                  Index: ' num2str(obj.currentIndex)...
                    '/' num2str(length(obj.timestepsMin))];
                drawnow

                if obj.currentIndex <= length(obj.timestepsMin) %Valid index check
                    for i = 1:length(obj.SPSs)
                        if obj.running
                            obj.SPSs(i).setIVcurve(obj.IVCurves(:,i*2-1,obj.currentIndex),obj.IVCurves(:,i*2,obj.currentIndex));
                            subplot(1,length(obj.SPSs),i,'Parent',obj.plotpanel)
                            plot(obj.IVCurves(:,i*2,obj.currentIndex),obj.IVCurves(:,i*2-1,obj.currentIndex))
                            title([obj.SPSs(i).label ' on SPS ID' num2str(obj.SPSs(i).hardwareID)])
                            drawnow
                        end
                    end
                    
                    % Check if we reached the end! stop or restart?
                    if obj.currentIndex >= length(obj.timestepsMin) 
                      if obj.restartAtEnd
                          obj.currentIndex = 0;
                          obj.startRealTime = datenum(datetime)*1440; %get current time (in minutes)
                          obj.startSimTime = obj.timestepsMin(1);
                      else
                          obj.disableCallback()
                          return
                      end
                    end
                    
                    % Calculate when update should occur in real time
                    timeFromStart = obj.timestepsMin(obj.currentIndex+1) - obj.startSimTime;
                    realtimeToAdd = obj.startRealTime + timeFromStart - datenum(datetime)*1440;
                    pause(realtimeToAdd*60)
                    
                    obj.currentIndex = obj.currentIndex + 1;
                    obj.stepTime(); %Callback on itself!
                end
            end
        end
        
        %% Callbacks
        function disableCallback(obj,~,~)
            obj.pauseCallback()
            set(findall(obj.figure.Children,'-property','Enable'),'Enable','off')
            drawnow
            for i = 1:length(obj.SPSs)
                try
                    obj.SPSs(i).disable();
                    subplot(1,length(obj.SPSs),i,'Parent',obj.plotpanel)
                    plot(0,0)
                    title([obj.SPSs(i).label ' on SPS ID' num2str(obj.SPSs(i).hardwareID)])
                    drawnow
                catch
                    disp('FAILED TO DISABLE')
                end
            end
            set(findall(obj.figure.Children,'-property','Enable'),'Enable','on')
            set(obj.pausebutton,'Enable','off')
        end
        
        function playCallback(obj,~,~)
            set(obj.playbutton,'Enable','off')
            set(obj.timeslider,'Enable','off')
            set(obj.pausebutton,'Enable','on')
            drawnow
            obj.startRealTime = datenum(datetime)*1440; %get current time (in minutes)
            obj.startSimTime = obj.timestepsMin(obj.currentIndex);
            obj.running = true;
            obj.stepTime();
        end
        
        function pauseCallback(obj,~,~)
            set(obj.playbutton,'Enable','on')
            set(obj.timeslider,'Enable','on')
            set(obj.pausebutton,'Enable','off')
            drawnow
            obj.running = false;
        end  
        
        function sliderCallback(obj,~,~)
            %Discretise to only existing timepoints
            [~, ind] = min(abs(obj.timeslider.Value-obj.timestepsMin));
            obj.timeslider.Value = obj.timestepsMin(ind);
            obj.currentIndex = ind;
            obj.statustext.String = ['Time: ' num2str(obj.timestepsMin(obj.currentIndex),'%.1f')...
                    ' minutes                  Index: ' num2str(obj.currentIndex) ...
                    '/' num2str(length(obj.timestepsMin))];
        end
        
        function windowCloseCallback(obj,~,~)
            obj.running = false;
            obj.disableCallback();
            delete(obj.figure);
        end
    end
    
end

