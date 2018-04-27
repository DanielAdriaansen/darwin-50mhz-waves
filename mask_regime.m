%
% File: mask_regime.m
%
% Author: D. Adriaansen
%
% Date: 29 Mar 2017
%
% Purpose: Using the StartEndLUT mask out the data outside the requested regime
%
% Notes: variables in the StartEndLUT are: mbegind, mendind, bbegind,
% bendind, signifying the beginning and the end of the monsoon and break
% periods. The length of these variables signifies the respective number of
% monsoon and break periods.
%________________________________________________________________________________________________

%######################## User Config ##################################%

% Path to matfiles
matpath = '/d1/dadriaan/paper/data/matfiles';

%#######################################################################%

% Load the profiler data
load([matpath,'/profiler.mat'],'Datenum','VertVel','Dbz','Dopvel','Uwind','Vwind','mask');

% Load the information in the lookup table
load([matpath,'/StartEndLUT.mat']);

% Create a new vector to hold the mask for regime. Here the wind component
% should be 1D only, at the height that was requested in profiler_driver.m
rmask = zeros(size(VertVel));

% Mask out the data that we don't need
if strcmp(regime,'break')
    begins = bbegind;
    ends = bendind;
else
    begins = mbegind;
    ends = mendind;
end

% Loop over the number of begins (one for each regime chunk we have) and
% note where we want to save data.
% save = 1
% mask = 0
nstarts = length(begins);
for s=1:nstarts
   %mask(:,find(Datenum==begins(s)):find(Datenum==ends(s))) = 1;
   rmask(begins(s):ends(s)) = 1;
end

% Now turn data to the enumeration that means "outside regime"
% 2 = outside regime
mask(rmask==0) = 2;

% Apply the mask to all the data
VertVel(mask>1) = nan;
Uwind(mask>1) = nan;
Vwind(mask>1) = nan;
Dbz(mask>1) = nan;
Dopvel(mask>1) = nan;

% Save out the data to a MAT file (APPEND)
save([matpath,'/profiler.mat'],'VertVel','Uwind','Vwind','Dopvel','Dbz','mask','-append');

% Clear out variables we don't need
%clear('VertVel','Datenum','mask','Dopvel','Dbz','mbegind','mendind','bbegind','bendind');