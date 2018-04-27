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

%currmfile = '/d1/dadriaan/paper/data/matfiles/era_2.mat';

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

% Buffer for before and after a precipitation period (minutes)
precipbuffmin = 0;

% Gross filtering thresholds for filtering
uthresh = 6.0;
vthresh = 3.0;
wthresh = 3.0;

% Fixed wind component standard deviations used for filtering (m/s)
usdev = 0;
vsdev = 0;
wsdev = 0;

% Hampel filter number of neighbors. This is number of points before/after
% sample to use (i.e. N-S-N where N is number before/after, and S is
% sample)
Uhampelneighbor = 5;
Vhampelneighbor = 5;
Whampelneighbor = 7;

% Hampel filter standard deviations. The sample point must be within this
% many multiples of the median of the neighbors to be retained.
Uhampeldev = 6;
Vhampeldev = 6;
Whampeldev = 4;

% Filtering key. Numbers increase because higher numbers can overwrite lower numbers
% 3 = Bad data from 50 MHz profiler (-99)
% 5 = Precipitation
% 8 = Gross outlier

%#######################################################################%

% Load data from MAT file
%load([matpath,'/profiler.mat'],'Datenum','Dbz','mask','VertVel','Dopvel','agl');
%load([matpath,'/profiler.mat'],'Datenum','Dbz','VertVel','Uwind','Dopvel','agl');
load([matpath,'/',currmfile],'DatenumEra','MonvecEra','DbzEra','VertVelEra','DopvelEra','UwindEra','VwindEra','agl');

% Rename some variables for the rest of the processing
Datenum = DatenumEra;
Dbz = DbzEra;
VertVel = VertVelEra;
Dopvel = DopvelEra;
Uwind = UwindEra;
Vwind = VwindEra;
Monvec = MonvecEra;
clear DatenumEra DopvelEra VertVelEra VwindEra DbzEra UwindEra MonvecEra;

% Create a new 1D time/height matrix to hold the mask
mask = zeros(size(VertVel));

% Mask out bad data where the 50 MHz data are flagged as bad
% 3 = bad 50 MHz data
mask(VertVel==-99) = 3;
mask(Uwind==-99) = 3;
mask(Vwind==-99) = 3;

% Apply the bad data mask to the data before going further
Unomask = Uwind;
Vnomask = Vwind;
Wnomask = VertVel;
VertVel(mask>1) = nan;
Vwind(mask>1) = nan;
Uwind(mask>1) = nan;

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

% Save off where we identified precip for use later
precip = find(mask==5);

% Save off time series without precip filtering for use later
Unopcp = Uwind;
Vnopcp = Vwind;
Wnopcp = VertVel;

% Apply the precip mask to the data before going further
VertVel(mask>1) = nan;
Uwind(mask>1) = nan;
Vwind(mask>1) = nan;

% Save off time series with just precip filtering applied for use later
Upcp = Uwind;
Vpcp = Vwind;
Wpcp = VertVel;

% Apply the Hampel filter, a local median filter, to the precip filtered data.
Uhamp1 = hampel(Uwind,Uhampelneighbor,Uhampeldev);
Vhamp1 = hampel(Vwind,Vhampelneighbor,Vhampeldev);
Whamp1 = hampel(VertVel,Whampelneighbor,Whampeldev);

% Set the wind components to the hampel filtered data
Uwind = Uhamp1;
Vwind = Vhamp1;
VertVel = Whamp1;

% Do the hampel filter again -------------> ONLY USEFUL FOR MULTIPLE
% HAMPELS
%Uhamp2 = hampel(Uwind,5,10);
%Vhamp2 = hampel(Vwind,5,10);
%Whamp2 = hampel(VertVel,5,10);
%Uwind = Uhamp2;
%Vwind = Vhamp2;
%VertVel = Whamp2;

% Calculate the standard deviation of all the remaining good U,V,W data
%sigmaW = std(VertVel(~isnan(VertVel)));
%sigmaU = std(Uwind(~isnan(Uwind)));
%sigmaV = std(Vwind(~isnan(Vwind)));
%fprintf(['\n']);
%fprintf(['STDEV W-wind = ',num2str(sigmaW),' m/s\n']);
%fprintf(['STDEV U-wind = ',num2str(sigmaU),' m/s\n']);
%fprintf(['STDEV V-wind = ',num2str(sigmaV),' m/s\n']);

% Compute the mean of the U/V/W time series
%um = mean(Uwind(~isnan(Uwind)));
%vm = mean(Vwind(~isnan(Vwind)));
%wm = mean(VertVel(~isnan(VertVel)));
%fprintf(['\n']);
%fprintf(['MEAN W-wind = ',num2str(wm),' m/s\n']);
%fprintf(['MEAN U-wind = ',num2str(um),' m/s\n']);
%fprintf(['MEAN V-wind = ',num2str(vm),' m/s\n']);

% Do the gross outlier filtering
%wout = find((abs(VertVel-wm))>(wthresh*sigmaW));
%uout = find((abs(Uwind-um))>(uthresh*sigmaU));
%vout = find((abs(Vwind-vm))>(vthresh*sigmaV));
%mask(wout) = 8;
%mask(vout) = 8;
%mask(uout) = 8;

% Mask out the U-wind vector used for monsoon/break determination
Monbad = find(Monvec==-99); % Only missing U-wind
Monvec(Monbad) = nan; % Mask out missing U-wind
Monvec(precip) = nan; % Mask out precipitation
%Monvec(uout) = nan; % Mask out from gross outlier filtering

% Apply the outlier mask to the data before going further.
%Upcp = Uwind;
%Vpcp = Vwind;
%Wpcp = VertVel;
%VertVel(mask>1) = nan;
%Uwind(mask>1) = nan;
%Vwind(mask>1) = nan;

% This section was used to test doing gross outlier then hampel, as opposed
% to hampel then gross outlier.
%Uhamp1 = hampel(Uwind,5,6);
%Vhamp1 = hampel(Vwind,5,6);
%Whamp1 = hampel(VertVel,5,6);
%Uwind = Uhamp1;
%Vwind = Vhamp1;
%VertVel = Whamp1;

% A second hampel filter, if needed.
%Uhamp2 = hampel(Uwind,5,10);
%Vhamp2 = hampel(Vwind,5,10);
%Whamp2 = hampel(VertVel,5,10);
%Uwind = Uhamp2;
%Vwind = Vhamp2;
%VertVel = Whamp2;

% Plot the three panel plot
plot_era_timeseries;

% Save out the data to a MAT file (APPEND)
save([matpath,'/profiler.mat'],'Datenum','Uwind','VertVel','Vwind','Dopvel','Dbz','mask','Monvec','regime','-append');
%save([matpath,'/profiler.mat'],'VertVel','Dopvel','Dbz','mask','-append');
%save([matpath,'/profiler.mat'],'VertVel','Uwind','Dopvel','Dbz','mask','-append');

% Clear out variables we don't need
%clear('VertVel','Datenum','mask','Dbz','Dopvel','agl','Uwind');
%clear('VertVel','Datenum','mask','Dbz','Dopvel','agl','tmpmask','pmask');
%clear('currmfile','Datenum','Uwind','VertVel','Vwind','Dopvel','Dbz','mask','Monvec');
clear('currmfile','Datenum','Uwind','VertVel','Vwind','Dopvel','Dbz','mask','Monvec');