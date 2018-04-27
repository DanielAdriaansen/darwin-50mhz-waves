%
%
% File: createStartEndLUT.m
%
% Author: D. Adriaansen
%
% Date: 29 Mar 2017
%
% Purpose: Take a vector of start/end dates, create MATLAB serial date numbers and write it to a MAT file which will be used
%          as a Look Up Table (LUT) for processing the 50 MHz wind profiler data to reference start and end of monsoon/break periods.
%
% Notes: These times are determined manually using the 50 MHz 700 hPa wind direction.
%
%_________________________________________________________________________________________________________________________________

%######################## User Config ##################################%

% Path to matfiles
matpath = '/d1/dadriaan/paper/data/matfiles';

% What are the list of days where the monsoon periods begin? These variables are arrays of date strings.
monsoonbeg = ({'01/14/2006 02:00:00'});
monsoonend = ({'02/03/2006 01:59:00'});
breakbeg = ({'02/06/2006 02:00:00'});
breakend = ({'02/28/2006 23:59:00'});

%######################################################################%

% Read in the unix_time from the mat file created in the first step
%load([matpath,'/profiler.mat'],'time');

% Convert the datestrings to MATLAB serial date numbers for use later
mbsdn = datenum(monsoonbeg,'mm/dd/yyyy HH:MM:SS');
mesdn = datenum(monsoonend,'mm/dd/yyyy HH:MM:SS');
bbsdn = datenum(breakbeg,'mm/dd/yyyy HH:MM:SS');
besdn = datenum(breakend,'mm/dd/yyyy HH:MM:SS');

% Save all of the data to a new matfile
save([matpath,'/StartEndLUT.mat'],'monsoonbeg','monsoonend','breakbeg','breakend','mbsdn','mesdn','bbsdn','besdn');