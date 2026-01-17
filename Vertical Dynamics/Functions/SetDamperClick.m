function dampercurve = SetDamperClick(table, motionRatio, compression, rebound)
    array = table2array(table);
    dampercurve(1,:) = array(1,2:end)./1000; % Ns/mm to Ns/m
    zero = find(~dampercurve(1,:));
    dampercurve(2,:) = array(rebound+1,2:end);
    dampercurve(2,1:zero-1) = array(compression+1,2:zero);
    dampercurve(2,:) = dampercurve(2,:).*motionRatio^2;
end