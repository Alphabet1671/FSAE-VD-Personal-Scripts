function FRF = CalcFRF(run)
	t = run.logsout.get("Front CPL").Values.Time;
	
	frontCPL = run.logsout.get("Front CPL").Values.Data;
	rearCPL = run.logsout.get("Rear CPL").Values.Data;
	
	frontBodyDisplacement = run.logsout.get("Front Body Displacement").Values.Data;
	rearBodyDisplacement = run.logsout.get("Rear Body Displacement").Values.Data;
	
	frontHubDisplacement = run.logsout.get("Front Hub Displacement").Values.Data;
	rearHubDisplacement = run.logsout.get("Rear Hub Displacement").Values.Data;
	
	Fs = 80; % change based on t of simulation
	
	
	frontCPL = resample(frontCPL,t,Fs);
	rearCPL = resample(rearCPL,t,Fs);
	frontBodyDisplacement = resample(frontBodyDisplacement, t, Fs);
	rearBodyDisplacement = resample(rearBodyDisplacement, t, Fs);
	frontHubDisplacement = resample(frontHubDisplacement, t, Fs);
	rearHubDisplacement = resample(rearHubDisplacement, t, Fs);
	
	frontCPL = fft(frontCPL);
	rearCPL = fft(rearCPL);
	frontBodyDisplacement = fft(frontBodyDisplacement);
	rearBodyDisplacement = fft(rearBodyDisplacement);
	frontHubDisplacement = fft(frontHubDisplacement);
	rearHubDisplacement = fft(rearHubDisplacement);
		
	FRF.frontCPL.mag = smooth(abs(frontCPL),10);
	FRF.rearCPL.mag = smooth(abs(rearCPL),10);

	FRF.frontBodyDisplacement.mag = abs(frontBodyDisplacement);
	FRF.rearBodyDisplacement.mag = abs(rearBodyDisplacement);

	FRF.frontHubDisplacement.mag = abs(frontHubDisplacement);
	FRF.rearHubDisplacement.mag = abs(rearHubDisplacement);


	FRF.frontCPL.phase = rad2deg(angle(frontCPL));
	FRF.rearCPL.phase = rad2deg(angle(rearCPL));

	FRF.frontBodyDisplacement.phase = rad2deg(angle(frontBodyDisplacement));
	FRF.rearBodyDisplacement.phase = rad2deg(angle(rearBodyDisplacement));

	FRF.frontHubDisplacement.phase = rad2deg(angle(frontHubDisplacement));
	FRF.rearHubDisplacement.phase = rad2deg(angle(rearHubDisplacement));

	names = fieldnames(FRF);

	for i = 1:numel(names)
    	FRF.(names{i}).f = Fs/length(frontCPL)*(0:length(frontCPL)-1);
	end
end