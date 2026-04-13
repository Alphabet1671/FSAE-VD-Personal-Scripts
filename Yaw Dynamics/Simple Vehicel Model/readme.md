# Simplified Vehicle Model & Lap Time Simulation
This is a full car model built with a simplified UniTire model, single rigid body vehicle and no camber sensitivities. Useful for concept studies and control algorithm development. 

## Track Model
The track is a 1D continuous curve along with labeled path radius. Track can be extracted by on-car driving data or just having someone drive around in a driving simulator like AC or RF2.

## Vehicle Model
### Tire Model
Simplified UniTire model, detailed model fitting and such are under /Yaw Dynamics/Tire Model/
### Drivetrain Model
The drivetrain models have types:
- RWD: with simulated LSD
- AWD: with an approximated torque vectoring algorithm

## Simulation Process
### Instantaneous Vx-max Calculations
1. Taking the path file, calculate based on the path curvature what the maximum possible vehicle speed is at each point
2. After getting the array of maximum speeds, check at each point ay = v^2/r, and then calculate the remaining ax capability, take into account alphaz and tire Mz contributions
3. flag all segments where the car is not capable of delivering the required ax


## Work in Progress...

<!-- 
Basically within the segment where car can't deliver the required ax, find the lowest v and use max ax to go both forward and backward until the velocity is matching again

-->