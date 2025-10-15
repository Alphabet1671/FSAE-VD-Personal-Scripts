%% Louis Ye, Sept 2025
% Find torque distribution that maximizes Ay for skidpad

% sure, TV can be a yaw rate controller, but can it help get more Ay out of
% the vehicle? Can we use load sensitive tire model? -> no because that
% assumes that both the inside and outside wheel reach limit at the same
% time which isn't true.


% first make a variable radius skidpad solver without TV, this is going to
% be a simplified model with LLTD, think a TV go kart with R20
% tires lol, using parallel steer
%% constants
g = 9.81

%% vehicle inputs
vehicle.tir = mfeval.readTIR("Hoosier43075_16x75_10_R20_7_mod2_COMBINED.tir");
vehicle.m = 210 + 80; % weight of 
vehicle.w = 1.24; % width in m
vehicle.l = 1.53; % wheelbase in m
vehicle.h = 0.25; % cg height above ground in m
vehicle.cgx = 0.49;
vehicle.cpx = 0.42; % both as ratio of wheelbase from rear axle
vehicle.CLA = 5;
vehicle.CDA = 1.8;
vehicle.LLTD = 0.43; % lateral load transfer distribution ratio of wheelbase from rear axle




%% skidpad sim function
function result = skidPadSim(vehicle, r) % 
tir = vehicle.tir;

m = vehicle.m;
w = vehicle.w;
l = vehicle.l;
h = vehicle.h;
cgx = vehicle.cgx;
b = cgx*l;
a = l-b;
LLTD = vehicle.LLTD;

frontAeroLoad = @(v) vehicle.CLA/2*1.228*v^2 * (1-vehicle.cpx);
rearAeroLoad = @(v) vehicle.CLA/2*1.228*v^2 * vehicle.cpx;

% hold the car at constant delta, for each speed find beta of the car until
% it's no longer possible.
for v = 0:0.01:30
    deltaAckermann = asin(l/r); % radians
    FzFront = frontAeroLoad(v) + m*g*(1-cgx);
    FzRear = rearAeroLoad(v) + m*g*cgx;

    ay = v^2/r;
    frontLLT = h*ay/w*(1-LLTD);
    rearLLT = h*ay/w*LLTD;
    
    % assumes positive Ay (right turn)
    % 1-4 = FL, FR, RL, RR
    Fz(1) = FzFront/2 + frontLLT;
    Fz(2) = FzFront/2 - frontLLT;
    Fz(3) = FzRear/2 + rearLLT;
    Fz(4) = FzRear/2 - rearLLT;
    Fytot = m*ay;


    for delta = (deltaAckermann - deg2rad(-5)):0.001:(deltaAckermann- deg2rad(5))
        for beta = 0:0.001:deg2rad(10)
            % given beta and delta calculate alpha at each wheel
            alpha(1) = 
            alpha(2) = 
            for i=1:4
                outMF(i) = mfeval(Fz(i), 0, alpha(i))
        end
    end
end

result.delta = 
result.beta = 
result.ay = 
result.time = 

end

