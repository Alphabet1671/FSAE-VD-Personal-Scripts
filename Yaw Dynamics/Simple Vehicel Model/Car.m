%% Louis Ye, Apr 2026
classdef Car
    properties
        Tire % read from 
        Aero % read from class
        % TODO: define aero map here, 3 4D lut matrices:
        % CL, CD, Balance over: front height, rear height, speed
        
        Mass
        Izz % inertias
        
        LLTD
        PitchGradient

        Drivetrain % read class

    end
    methods
    
        function obj = Car()

        end
    end
end