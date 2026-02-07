function [Fx, Fy, My, Mz, sigmax, sigmay]= RunMFEval(Fz, alpha, kappa, gamma, vx)

tire = mfeval.readTIR('Hoosier43075_16x75_10_R20.tir');
inputs = [Fz, kappa, alpha, gamma, 0, vx];

outputs = mfeval(tire, inputs, 121);

Fx = outputs(1);
Fy = outputs(2);
Mz = outputs(6);
My = outputs(5);
sigmax = outputs(27);
sigmay = outputs(28);

end