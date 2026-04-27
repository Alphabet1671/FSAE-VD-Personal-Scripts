classdef Drivetrain
	%DRIVETRAIN Creates an instance of an AMK AWD EV drivetrain
	%   Detailed explanation goes here
	
	properties
		% battery % Struct or class
		motor % Struct or class
		inverterEfficiency
		frontGearRatio
		rearGearRatio
		brakes
	end
	
	methods
		function wheeltorque = CalcTqThrottle(APPS)
            %{

                So basically the common thing that a drivetrain would do is it takes control inputs and turn it into motor torque
				a car can't actually have individual wheel torque control, so it's 1DoF constrained by power distribution
				
				
			%}

			% Drivetrain.battery.discharge() <- interface with battery class, ignore from now
			
		end

		function wheeltorque = CalcTqBrake()
			
			% The same thing, but with brakes, heat is not simulated
			% calculates wheel torque from brake pressure given pad mu and piston sizes
			 
		end
	end
end

