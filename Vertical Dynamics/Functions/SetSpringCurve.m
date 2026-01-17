function springCurve = SetSpringCurve(table, motionRatio)
    array = table2array(table);
    springCurve(1,:) = array(1,:)./1000; % N/mm to N/m
    springCurve(2,:) = array(2,:).*motionRatio^2;
end