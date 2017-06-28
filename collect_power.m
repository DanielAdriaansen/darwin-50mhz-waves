%
% File: collect_power_2.m
%
% Author: D. Adriaansen
%
% Date: 25 May 2017
%
% Purpose: Aggregate the power from the S-transform from every minute in the current regime into a single 24-hour window
%
% Notes: 
%________________________________________________________________________________________________

%######################## User Config ##################################%

% Path to matfiles
matpath = '/d1/dadriaan/paper/data/matfiles';

% What height are we operating at (meters)?
lev = 3000;

% Frequency bins for integrating S-transform output
fbins = [0.0,0.05,0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5];

%#######################################################################%

% Load data from MAT file
load([matpath,'/profiler.mat'],'Datenum','mask','VertVel','agl','chunkbegin','chunkend','chunklength','totpow');

% A single 24-hr window (1-minute interval) matrix to hold the collected data
meanwindow = zeros(length(fbins)-1,1440);

% A single 24-hr window (1-minute interval) vector to hold the sample size at each time
samplesize = zeros(1,1440);

% Take all of the times and make a date vector
alldvec = datevec(Datenum);

% Loop over two arbitrary datenumbers, as long as they cover a 24-h period.
% **** NOTE: Must start at 02Z, since that's the beginning of a "day" as we're defining it.
dnstart = datenum(2006,1,1,2,0,0);
dnend = dnstart+datenum(0,0,0,0,0,86399);

% Vector to store datenumbers for plotting
dnplot = zeros(1,1440);

% Loop while the current datenumber is <= the end datenumber, incrementing 60 seconds each time (once per minute)
dncurr = dnstart;
count = 1;
while dncurr <= dnend
    
    % Store the current datenumber for plotting
    dnplot(count) = dncurr;
    
    % Convert current datenumber to a date vector
    dvec = datevec(dncurr);
    
    % Store current hours and minutes
    HH = dvec(:,4);
    MM = dvec(:,5);
    
    % Find all the times where the time was exactly HH hours and MM minutes
    times = find(alldvec(:,4)==HH & alldvec(:,5)==MM);
    data = totpow(:,times);
    
    % Figure out how many of the times actually have good data at this HH:MM
    powgood = find(~isnan(totpow(1,times)));
    
    % Store the number of days with good data at this time
    if ~isempty(powgood)
        samplesize(count) = length(powgood);
        % Loop over the number of bins and do stuff
        for nb=1:length(fbins)-1
            % If there is more than 1, do statistics (mean, median) otherwise just store the value
            if length(powgood) > 1
                meanwindow(nb,count) = mean(data(nb,powgood));
            else
                meanwindow(nb,count) = data(nb,powgood);
            end
        end
    else
        samplesize(count) = 0;
    end
    
    % Go to the next time (increment the current datenumber by 60 seconds)
    dncurr = dncurr + datenum(0,0,0,0,0,60);
    
    % Increment the counter
    count = count + 1;
end

% Now plot the collected power
fw = [0,0,1200,700];
figure('visible','on','position',fw);

% Make the plot
imagesc(dnplot,fbins,meanwindow);

% Reverse the Y Axis
set(gca,'YDir','normal');

% Add a colorbar
cbh = colorbar;

% Set the Y-axis Label
ylabel(cbh,'Average power (m/s)')

% Set the X-axis Label
xlabel('Time (UTC)');

% Turn the X-axis to readable times
datetick('x',15);

% Tighten the axes
axis tight;

% Adjust the colormap
caxis([0.0 0.2]);