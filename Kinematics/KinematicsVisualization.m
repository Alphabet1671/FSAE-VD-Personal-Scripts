table = GenerateInputTable();

function file = GenerateInputTable()
    % generates input coordinates table
    % for double wishbone suspension

    names = [
        % Wheel Centers
        "Front Wheel Center"
        "Rear Wheel Center"
        "Front Wheel Diameter"
        "Rear Wheel Diameter"

        % A-Arms
        "Front Upper Fore"
        "Front Upper Aft"
        "Front Upper Outboard"

        "Front Lower Fore"
        "Front Lower Aft"
        "Front Lower Outboard"

        "Rear Upper Fore"
        "Rear Upper Aft"
        "Rear Upper Outboard"

        "Rear Lower Fore"
        "Rear Lower Aft"
        "Rear Lower Outboard"
        
        % Steering/toe
        "Front Toe Inboard Min"
        "Front Toe Inboard Max"
        "Front Toe Inboard Neutral"
        "Front Toe Outboard"

        "Rear Toe Inboard Min"
        "Rear Toe Inboard Max"
        "Rear Toe Inboard Neutral"
        "Rear Toe Outboard"
    ];

    n = numel(names);

    % Preallocate empty numeric columns (NaN = placeholder to be filled)
    x = NaN(n,1);
    y = NaN(n,1);
    z = NaN(n,1);

    % First column is the point name, next three are x, y, z
    file = table(names, x, y, z, ...
                 'VariableNames', {'Point','x','y','z'});
end


function suspension = ReadInputTable(tbl)
    % Read the coordinates from the table created by GenerateInputTable

    % Helper to grab [x y z] for a given point name
    coord = @(name) [ ...
        tbl.x(tbl.Point == name), ...
        tbl.y(tbl.Point == name), ...
        tbl.z(tbl.Point == name)  ...
    ];

    % Wheel centers
    suspension.front.wheel.center = coord("Front Wheel Center");
    suspension.rear.wheel.center  = coord("Rear Wheel Center");
    suspension.front.wheel.diameter = coord("Front Wheel Diameter");
    suspension.rear.wheel.diameter = coord("Rear Wheel Diameter");
    suspension.front.wheel.dir = [1,0,0];
    suspension.rear.wheel.dir = [1,0,0];

    % Front A-arms
    suspension.front.upper.fore     = coord("Front Upper Fore");
    suspension.front.upper.aft      = coord("Front Upper Aft");
    suspension.front.upper.outboard = coord("Front Upper Outboard");

    suspension.front.lower.fore     = coord("Front Lower Fore");
    suspension.front.lower.aft      = coord("Front Lower Aft");
    suspension.front.lower.outboard = coord("Front Lower Outboard");

    % Rear A-arms
    suspension.rear.upper.fore      = coord("Rear Upper Fore");
    suspension.rear.upper.aft       = coord("Rear Upper Aft");
    suspension.rear.upper.outboard  = coord("Rear Upper Outboard");

    suspension.rear.lower.fore      = coord("Rear Lower Fore");
    suspension.rear.lower.aft       = coord("Rear Lower Aft");
    suspension.rear.lower.outboard  = coord("Rear Lower Outboard");

    % Front toe
    suspension.front.toe.inboard.min     = coord("Front Toe Inboard Min");
    suspension.front.toe.inboard.max     = coord("Front Toe Inboard Max");
    suspension.front.toe.inboard = coord("Front Toe Inboard Neutral");
    suspension.front.toe.outboard        = coord("Front Toe Outboard");

    % Rear toe
    suspension.rear.toe.inboard.min      = coord("Rear Toe Inboard Min");
    suspension.rear.toe.inboard.max      = coord("Rear Toe Inboard Max");
    suspension.rear.toe.inboard  = coord("Rear Toe Inboard Neutral");
    suspension.rear.toe.outboard         = coord("Rear Toe Outboard");
end

function suspension = SetSuspension(suspension, front_jounce, rear_jounce, front_steer, rear_steer)
    % jounce is in unit of length, 
    % steer is in a decimal number as fraction of maximum steering rack movement
    
    % solve for outboard balljoints
    
    % upper ball joint and lower ball joint are contrainted by:
    % both the a arm and the upright.
    % 2 vector eqn, and 2 vector variables
    % Statically, upright = ubj - lbj
    % so at any given time, 
    
    % solve for steering movement
    % based on the ball joint location after jounce, change the inboard
    % steering point based on the steering percentage provided.
end