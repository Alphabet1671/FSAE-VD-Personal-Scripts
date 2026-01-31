function KPI = CalculateKPI(result)
    % Time is given for car to settle after initial drop, the drop is
    % used to fit a first order spring-mass-damper system in order to find
    % the heave zeta of the car.

    % Settle time setup, change if the shaker input is changed.
    simStartTime = 9.9;
    simEndTime = 30;
    timeTol = 0.005;

    rawTime = result.logsout.get("Front CPL").Values.Time;

    for i = 1:length(rawTime)
        if rawTime(i) - simStartTime < timeTol
            simStartIndex = i;
        end
        if rawTime(i) - simEndTime < timeTol
            simEndIndex = i;
        end
    end

    simInterval = simStartIndex:simEndIndex;

    mu = result.logsout.get("Unsprung Mass").Values.Data;
    ms = result.logsout.get("Sprung Mass").Values.Data;

    frontCPL = result.logsout.get("Front CPL").Values.Data;
    rearCPL = result.logsout.get("Rear CPL").Values.Data;

    frontBodyDisplacement = result.logsout.get("Front Body Displacement").Values.Data;
    rearBodyDisplacement = result.logsout.get("Rear Body Displacement").Values.Data;

    frontHubDisplacement = result.logsout.get("Front Hub Displacement").Values.Data;
    rearHubDisplacement = result.logsout.get("Rear Hub Displacement").Values.Data;

    % Zeta math
    displacement = (frontBodyDisplacement(1:simStartIndex)+rearBodyDisplacement(1:simStartIndex))/2;

    % m = mu(1)*2 + ms(1); % total mass, used only for sim plots
    % t = rawTime(1:simStartIndex); % used only for sim plots

    % Find all peaks in the response
    [peaks, peak_locs] = findpeaks(-displacement);
    if length(peaks) > 2
        peaks = peaks+displacement(end);
        delta =  log(peaks(1)/peaks(2));  % average logarithmic decrement
        % k = -m*9.81/displacement(end); % used only for sim plots
        zeta = real(delta / sqrt(4*pi^2 + delta^2));
    else
        zeta = 0;
    end
    
    % % Verification plot
    % figure;
    % plot(t, displacement, 'b-', 'LineWidth', 1.5);
    % hold on;
    % 
    % % Simulate with estimated parameters
    % c = zeta * 2 * sqrt(k*m);
    % ode_fun = @(t, x) [x(2); -9.81 - (c/m)*x(2) - (k/m)*x(1)];
    % [~, x_sim] = ode45(ode_fun, t - t(1), [0; 0]);
    % plot(t, x_sim(:, 1), 'r--', 'LineWidth', 1.5);
    % 
    % xlabel('Time (s)');
    % ylabel('Displacement (m)');
    % title(sprintf('Heave Mode: k=%.0f N/m, ζ=%.3f', k, zeta));
    % legend('Simulink', 'Linear Fit', 'Location', 'best');
    % grid on;

    % KPI math
    frontNominalCPL = frontCPL(simStartIndex);
    rearNominalCPL = rearCPL(simStartIndex);

    % contact patch load variation
    frontCPLV = (frontCPL - frontNominalCPL)./frontNominalCPL; % variation as percent of nominal wheel load
    rearCPLV = (rearCPL - rearNominalCPL)./rearNominalCPL;
    
    % re-zero car after drop
    frontNominalBodyDisplacement = frontBodyDisplacement(simStartIndex);
    rearNominalBodyDisplacement = rearBodyDisplacement(simStartIndex);

    frontNominalHubDisplacement = frontHubDisplacement(simStartIndex);
    rearNominalHubDisplacement = rearHubDisplacement(simStartIndex);

    frontBodyDisplacement = frontBodyDisplacement - frontNominalBodyDisplacement; 
    rearBodyDisplacement = rearBodyDisplacement - rearNominalBodyDisplacement;

    frontHubDisplacement = frontHubDisplacement - frontNominalHubDisplacement;
    rearHubDisplacement = rearHubDisplacement - rearNominalHubDisplacement;

    % body & hub pitch
    bodyPitch = frontBodyDisplacement - rearBodyDisplacement; % head up is positive
    hubPitch = frontHubDisplacement - rearHubDisplacement;
    
    KPI.frontMinCPL = 1 + min(frontCPLV(simInterval));
    KPI.rearMinCPL = 1 + min(rearCPLV(simInterval));
    KPI.frontCPLVRMS = rms(frontCPLV(simInterval));
    KPI.rearCPLVRMS = rms(rearCPLV(simInterval));
    KPI.bodyPitchRMS = max(bodyPitch(simInterval));
    KPI.hubPitchRMS = max(hubPitch(simInterval));
    KPI.heaveZeta = zeta;
end