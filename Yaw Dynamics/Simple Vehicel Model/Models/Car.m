%% Louis Ye, Apr 2026
classdef Car
    properties
        tire % class
        aero % class
        drivetrain % read class

        mass %kg
        driverMass %kg 
        Izz % inertias
        
        LLTD
		rollGradient
        pitchGradient % rad/(m/s^2)

    end
    methods
    
        function obj = Car(properties, tire, aero, drivetrain)
            % properties definition:
			%{
				mass, drivermass, LLTD, roll gradient, pitch gradient

			%}
			obj.aero = aero;
            obj.tire = tire;
            obj.drivetrain = drivetrain;

			
        end
    end
end