%
% File: mask_bad_precip.m
%
% Author: D. Adriaansen
%
% Date: 30 Mar 2017
%
% Purpose: Using the 920 MHz data, mask out the 50 MHz data where there was precipitation and 
%          also mask out data flagged as bad.
%
% Notes: 
%________________________________________________________________________________________________

%######################## User Config ##################################%

% Path to matfiles
matpath = '/d1/dadriaan/paper/data/matfiles';

% Which tests to use for identifying precipitation using the 920 MHz data?
% TEST 1: Z > 4 km && valid dBZ
t1 = 1;
t1z = 4000.0;
t1dbz = 0.0;

% TEST 2: abs(Dopvel) > 1.0 m/s
t2 = 0;
t2v = 10.0;

% TEST 3: dBZ > 20.0 dBZ
t3 = 0;
t3r = 20.0;

% TEST 4: abs(VertVel50) > 1.0 m/s && Z < 8 km
t4 = 0;
t4v = 5.0;
t4z = 8000.0;

%#######################################################################%

% Load data from MAT file
load([matpath,'/profiler.mat'],'Datenum','Dbz','mask','VertVel','Dopvel','agl');
%load([matpath,'/profiler.mat'],'Datenum','Dbz','VertVel','Uwind','Dopvel','agl');

% Mask out bad data where the 50 MHz data are flagged as bad
% 3 = bad 50 MHz data
mask(VertVel==-99) = 3;

% Mask out bad data where the 920 MHz data are flagged as bad
% 4 = bad 920 MHz data
%mask(Dbz==-99) = 4;

% Apply the bad data mask to the data before going further
%Dbz(mask>1) = nan;
%Dopvel(mask>1) = nan;
VertVel(mask>1) = nan;

% Now employ the tests on the 920 MHz data for precipitation
% TEST 1
if t1
    % Find all the heights greater than the minimum
    zind1 = find(agl>t1z);
    
    % Find all the times where there was Dbz > the threshold
    precip1 = find(Dbz(zind1,:)>t1dbz);
    
    % Note that the above line has subset our data to a size of nheights>t1z x ntimes so it's not the same size
    % Create a new mask to apply the precip mask to the original matrix
    tmpmask = zeros(size(Dbz(zind1,:)));
    tmpmask(precip1) = 5;
    
    % Squish the values down to a single vector since the entire column is bad if there's precip
    pmask = find(max(tmpmask)==5);
    mask(:,pmask) = 5;
    
    % Assign value of 5 where there was precip
    %mask(precip1) = 5;
end

% TEST 2
if t2
    % Find all the times where there was 920 MHz VV > the threshold
    precip2 = find(Dopvel>t2v);
    
    % Assign value of 5 where there was precip
    mask(precip2) = 5;
end

% TEST 3
if t3
    % Find all the times where there was 920 MHZ dBZ > the threshold
    precip3 = find(Dbz>t3r);
    
    % Assign value of 5 where there was precip
    mask(precip3) = 5;
end

% TEST 4
if t4
    % Find all the heights greater than the threshold
    zind4 = find(agl>t4z);
    
    % Find all the times when there was 50 MHz VV > the threshold
    precip4 = find(abs(VertVel(zind4,:))>t4v);
    
    % Assign value of 5 where there was precip
    mask(precip4) = 5;
end

% Since some of the precipitation filtering only looks at heights above a certain level,
% find all the columns (times) that have 5 in the mask anywhere in the column and mask out the whole column
%precipmask = find(max(mask)==5);
%mask(:,precipmask) = 5;

% Apply the precip mask to the data before going further
%Dbz(mask>1) = nan;
%Dopvel(mask>1) = nan;
VertVel(mask>1) = nan;
%Uwind(mask>1) = nan;
%Uwind(Uwind==-99) = nan;

% Save out the data to a MAT file (APPEND)
save([matpath,'/profiler.mat'],'VertVel','Dopvel','Dbz','mask','-append');
%save([matpath,'/profiler.mat'],'VertVel','Uwind','Dopvel','Dbz','mask','-append');

% Clear out variables we don't need
%clear('VertVel','Datenum','mask','Dbz','Dopvel','agl','Uwind');
clear('VertVel','Datenum','mask','Dbz','Dopvel','agl');