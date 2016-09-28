function calibratedProbs=calibrateProbabilities(probs)
%% ========================================================================
%   Name:       calibrateProbabilities.m
%   Version:    2.5.1 30 July 2014
%   Author:     Scott Rifkin
%   Command:    calibrateProbabilities(probs)
%   Description:
%       - calibrates probabilities
%
%   Files required:     parametersForSigmoidProbabilityCalibrationCurve.mat file.  This has the probability calibration curve
%                                           
%   Files generated:    none
%   Output:             calibrated probabilities in same form as input
%                       
%% ========================================================================

load parametersForSigmoidProbabilityCalibrationCurve
sigfunc=@(A,x)(1./(1+exp(-x*A(1)+A(2))));

calibratedProbs=sigfunc(parametersForSigmoidProbabilityCalibrationCurve,probs);

end