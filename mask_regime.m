%
% File: mask_regime.m
%
% Author: D. Adriaansen
%
% Date: 29 Mar 2017
%
% Purpose: Using the StartEndLUT mask out the data outside the requested regime
%
% Notes: 
%________________________________________________________________________________________________

%######################## User Config ##################################%

% Path to matfiles
matpath = '/d1/dadriaan/paper/data/matfiles';

%#######################################################################%

% Load the profiler data
load([matpath,'/profiler.mat'],'Datenum','VertVel','regime','Dbz','Dopvel','agl');

% Load the information in the lookup table
load([matpath,'/StartEndLUT.mat']);

% Create a new 2D time/height matrix to hold the mask
mask = zeros(size(VertVel));

% Mask out the data that we don't need
if strcmp(regime,'break')
    begins = bbsdn;
    ends = besdn;
else
    begins = mbsdn;
    ends = mesdn;
end

% Loop over the number of begins (one for each regime chunk we have) and turn the data to good
% Good = 1
nstarts = length(begins);
for s=1:nstarts
   mask(:,find(Datenum==begins(s)):find(Datenum==ends(s))) = 1;
end

% Now turn data to the enumeration that means "outside regime"
% 2 = outside regime
mask(mask==0) = 2;

% Apply the mask to all the data
VertVel(mask==2) = nan;
Dbz(mask==2) = nan;
Dopvel(mask==2) = nan;

% Save out the data to a MAT file (APPEND)
save([matpath,'/profiler.mat'],'VertVel','Dopvel','Dbz','mask','-append');

% Clear out variables we don't need
clear('VertVel','Datenum','regime','mask','Dopvel','Dbz');