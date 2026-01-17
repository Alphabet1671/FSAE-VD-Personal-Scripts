function result = SingleRun(frontDamperCurve, rearDamperCurve, frontSpringCurve, rearSpringCurve)
    simInput = Simulink.SimulationInput("HalfCarModel");

    simInput = simInput.setVariable("ax", 0);
    
    simInput = simInput.setVariable("f_damper_curve_x",frontDamperCurve(1,:));
    simInput = simInput.setVariable("f_damper_curve_y",frontDamperCurve(2,:));
    
    simInput = simInput.setVariable("r_damper_curve_x",rearDamperCurve(1,:));
    simInput = simInput.setVariable("r_damper_curve_y",rearDamperCurve(2,:));
    
    simInput = simInput.setVariable("f_spring_curve_x",frontSpringCurve(1,:));
    simInput = simInput.setVariable("f_spring_curve_y",frontSpringCurve(2,:));
    
    simInput = simInput.setVariable("r_spring_curve_x",rearSpringCurve(1,:));
    simInput = simInput.setVariable("r_spring_curve_y",rearSpringCurve(2,:));
%% run sim
    result = sim(simInput);
end
