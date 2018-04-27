%
%
% File: createEras.m
%
% Author: D. Adriaansen
%
% Date: 05 Jul 2017
%
% Purpose: Take discontinuous profiler data and break it up into "eras" (continuous periods in time) equal to or greater than a user specified length
%
% Notes: 
%
%
%_________________________________________________________________________________________________________________________________

%######################## User Config ##################################%

% Path to matfiles
matpath = '/d1/dadriaan/paper/data/matfiles';

% What's the minimum length of time to define an era (days, 1439 minutes data items in a day, 1440 minutes total)
mineralength = 7*1439;

%######################################################################%

% Load the profiler data
load([matpath,'/profiler.mat'],'VertVel','Uwind','Vwind','Monvec','Datenum','Dbz','Dopvel','regime','agl');

% Datenumbers are in number and fractions of days. If we use the MATLAB "diff" function we can easily
% locate discontinuous jumps in time.
dnd = diff(Datenum);

% Convert from days/fractions of days to seconds and round to nearest second
dndsecs = round(dnd.*86400);

% We know that our data is spaced every 60 seconds. This means wherever the difference is > 60 seconds, we have a jump.
% The indices returned here are the last time BEFORE the jump. To get the first time AFTER the jump, add 1 to these indices.
era_end = find(dndsecs > 60.0);

% Now, add 1 to the era_end to get the beginning of each era (first time AFTER jump)
era_beg = era_end + 1;

% Add the indes of the last datenum in the record to the era_end (i.e. length of Datenum)
era_end(end+1) = length(Datenum);

% Add the index of the first datenum (always should be 0) in the record to the era_beg
era_tmp = zeros(size(era_end));
era_tmp(1) = 1;
era_tmp(2:end) = era_beg;
era_beg = era_tmp;

% Calculate the era length (minutes)
era_length = era_end-era_beg;

% Find the eras greater than the minimum
good_era = find(era_length>mineralength);

fprintf(['\n']);
fprintf(['FOUND ',num2str(length(good_era)),' ERAS > ',num2str(mineralength),' MINUTES\n']);
fprintf(['\n']);

% Now we need to loop over each era, and save things to a matfile, 1 per era
for e=1:length(good_era)
    fprintf(['\n']);
    fprintf(['Era length = ',num2str(round(era_length(good_era(e))/1439)),' days\n']);
    fprintf(['\n']);
    
    % Create the m-file name
    mfilename = ['era_',num2str(e),'.mat'];
    
    % Save the current era beginning and end index
    eb = era_beg(good_era(e));
    ee = era_end(good_era(e));
    
    fprintf(['ERA BEG = ',num2str(eb),'\n']);
    fprintf(['ERA END = ',num2str(ee),'\n']);
    
    % Do we need temp variables to hold the subsetted data before saving? I think so. Actually, we may need
    % to think of new variable names to save in each of the era matfiles because they can't be the same as
    % the full variable names for the entire data record which are in memory at this point.
    VertVelEra = VertVel(:,eb:ee);
    UwindEra = Uwind(:,eb:ee);
    VwindEra = Vwind(:,eb:ee);
    MonvecEra = Monvec(eb:ee);
    DatenumEra = Datenum(eb:ee);
    DbzEra = Dbz(:,eb:ee);
    DopvelEra = Dopvel(:,eb:ee);
    
    % What variables do we want to save? Pretty much all the same as the input but just for the indices of the era
    save([matpath,'/',mfilename],'VertVelEra','UwindEra','VwindEra','MonvecEra','DatenumEra','DbzEra','DopvelEra','regime','agl');
    
    % Clear out data from this era
    clear VertVelEra UwindEra VwindEra MonvecEra DatenumEra DbzEra DopvelEra;
    
end

% Clear out data we don't need from the entire record
clear VertVel Uwind Vwind Monvec Datenum Dbz Dopvel agl;
