%
%
% File: identifyRegime.m
%
% Author: D. Adriaansen
%
% Date: 05 Jul 2017
%
% Purpose: Take a vector of 50 MHz U-wind data at 700 hPa and apply a definition of the monsoon/break to identify regime
%
% Notes: 
%   From May et al. (2008):
%   There are various definitions of monsoon conditions (e.g., Drosdowsky 1996), but the principal feature of the monsoon in
%   Darwin is the presence of westerly winds between 850 and 700 hPa. The use of more complex definitions usually only change
%   the monsoon periods by a few days. We will largely use a simple definition here of westerlies at 700 hPa in a 4-day smoothed
%   wind time series, except where explicitly discussed.
%_________________________________________________________________________________________________________________________________

%######################## User Config ##################################%

% Path to matfiles
matpath = '/d1/dadriaan/paper/data/matfiles';

%######################################################################%

% Load the profiler data
load([matpath,'/profiler.mat'],'Datenum','Monvec');

% Prepare the wind time series for running mean by masking out bad data (-99)
bad = find(Monvec==-99);
Monvec(bad) = nan;

% Calculate the running mean for the monsoon/break. This is a 4 day running mean
meanvec = runmean(Monvec,1440*4);

% Find all velocities that are > 0.0. If there aren't any > 0.0, then the
% entire era is the other regime, when the velocities are all < 0.0.
posvel = find(meanvec>0.0);
if isempty(posvel)
    fprintf(['\nNO POSITIVE VELOCITIES FOUND. ENTIRE ERA IS NEGATIVE (WESTWARD) VELOCITIES (BREAK)\n']);
    goodval = find(~isnan(Monvec));
    break_beg = Datenum(goodval(1));
    break_end = Datenum(goodval(end));
    bbegind = 1;
    bendind = length(Datenum);
    mbegind = -9;
    mendind = -9;
    % Save out the information in some meaningful format
    save([matpath,'/StartEndLUT.mat'],'mbegind','mendind','bbegind','bendind','-append');
    regime
    if strcmp(regime,'monsoon')
        error('NO WIND DATA FOR REQUESTED REGIME');
    else
        return;
    end
end

% Find all velocities that are < 0.0. If there aren't any < 0.0, then the
% entire era is the other regime, when the velocities are all > 0.0.
negvel = find(meanvec<0.0);
if isempty(negvel)
    fprintf(['\nNO NEGATIVE VELOCITIES FOUND. ENTIRE ERA IS POSITIVE (EASTWARD) VELOCITIES (MONSOON)\n']);
    goodval = find(~isnan(Monvec));
    mon_beg = Datenum(goodval(1));
    mon_end = Datenum(goodval(end));
    mbegind = 1;
    mendind = length(Datenum);
    bbegind = -9;
    bendind = -9;
    % Save out the information in some meaningful format
    save([matpath,'/StartEndLUT.mat'],'mbegind','mendind','bbegind','bendind','-append');
    if strcmp(regime,'break')
        error('NO WIND DATA FOR REQUESTED REGIME');
    else
        return;
    end
end

% If we've made it down here, then we need to figure out where it's
% negative and where it's positive to denote monsoon/break.
fprintf(['\nMONSOON AND BREAK BOTH FOUND\n']);
maskmon = zeros(1,length(Monvec));
maskmon(posvel) = 1;
mbegind = find(diff(maskmon)>0);
mendind = find(diff(maskmon)<0);
mbegind = mbegind+1;
maskbrk = zeros(1,length(Monvec));
maskbrk(negvel) = 1;
bbegind = find(diff(maskbrk)>0);
bendind = find(diff(maskbrk)<0);
bbegind = bbegind+1;
fprintf(['\nFOUND ',num2str(length(mbegind)),' MONSOON CHUNKS\n']);
fprintf(['\nFOUND ',num2str(length(bbegind)),' BREAK CHUNKS\n']);

% Save out the information in some meaningful format
save([matpath,'/StartEndLUT.mat'],'mbegind','mendind','bbegind','bendind','-append');
