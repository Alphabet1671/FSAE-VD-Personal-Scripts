function KPI = CalculateKPI(result)
    % Time is given for car to settle after initial drop, the drop can be
    % used to fit a first order spring-mass-damper system in order to find
    % the heave zeta of the car.

    % Settle time setup, change if the shaker input is changed.
    simStartTime = 9;
    simEndTime = 40;
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

    frontCPL = result.logsout.get("Front CPL").Values.Data;
    rearCPL = result.logsout.get("Rear CPL").Values.Data;

    frontBodyDisplacement = result.logsout.get("Front Body Displacement").Values.Data;
    rearBodyDisplacement = result.logsout.get("Rear Body Displacement").Values.Data;

    frontHubDisplacement = result.logsout.get("Front Hub Displacement").Values.Data;
    rearHubDisplacement = result.logsout.get("Rear Hub Displacement").Values.Data;
    
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
    bodyPitch = (1.53/(frontBodyDisplacement - rearBodyDisplacement)); % head up is positive
    hubPitch = (1.53/(frontHubDisplacement - rearHubDisplacement));
    
    KPI.frontMinCPL = 1 + min(frontCPLV(simInterval));
    KPI.rearMinCPL = 1 + min(rearCPLV(simInterval));
    KPI.frontCPLVRMS = rms(frontCPLV(simInterval));
    KPI.rearCPLVRMS = rms(rearCPLV(simInterval));
    KPI.bodyPitchRMS = max(bodyPitch(simInterval));
    KPI.hubPitchRMS = max(hubPitch(simInterval));
end