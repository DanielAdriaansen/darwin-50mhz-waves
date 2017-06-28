%
% File: mask_outliers.m
%
% Author: D. Adriaansen
%
% Date: 11 May 2017
%
% Purpose: Using the masked data, find good chunks of data that meet a minimum time requirement
%
% Notes: 
%________________________________________________________________________________________________

%######################## User Config ##################################%

% Path to matfiles
matpath = '/d1/dadriaan/paper/data/matfiles';

% What is the minimum chunk length we want in minutes?
mingood = 240;

% What height are we operating at (meters)?
lev = 3000;

% Debug flag
debug = 0;

%#######################################################################%

% Load data from MAT file
load([matpath,'/profiler.mat'],'Datenum','mask','VertVel','agl','chunkbegin','chunkend','chunklength','regime');

% Loop over each chunk with a length greater than the minimum and perform the following:
% 1. Running mean
% 2. Examine data
% 3. Insert 6 in the mask array
goodchunks = find(chunklength>mingood);

nchunk = length(goodchunks);
for i=1:nchunk
    
    % Debugging
    if debug
        fprintf(['\n************ CHUNK NUMBER = ',num2str(i),'\n'])
        fprintf(['CHUNK BEGIN = ',datestr(Datenum(chunkbegin(goodchunks(i)))),'\n'])
        fprintf(['CHUNK END = ',datestr(Datenum(chunkend(goodchunks(i)))),'\n'])
        fprintf(['BEGIN = ',num2str(chunkbegin(goodchunks(i))),'\n'])
        fprintf(['END = ',num2str(chunkend(goodchunks(i))),'\n'])
        fprintf(['CHUNK LENGTH = ',num2str(chunklength(goodchunks(i))),'\n'])
    end
    
    % Find the beginning and the end of the current chunk
    tbeg = chunkbegin(goodchunks(i));
    tend = chunkend(goodchunks(i));
    
    % Calculate a 10-minute running mean of the data
    tmean = runmean(abs(VertVel(agl==lev,tbeg:tend)),10);
    
    % Threshold on 0.5 m/s
    thresh = find(tmean>0.5);
    tmean(thresh) = nan;
    
    % Mask out data where appropriate in the chunk
    if ~isempty(find(isnan(tmean(end-60:end))))
        fprintf(['DISCARDING END OF CHUNK\n'])
        %tmean(end-60:end) = nan;
        %mask_boolean(tend-60:tend) = 0;
        mask(agl==lev,tend-60:tend) = 6;
    end
    if ~isempty(find(isnan(tmean(1:61))))
        fprintf(['DISCARDING BEG OF CHUNK\n'])
        %tmean(1:61) = nan;
        %mask_boolean(tbeg:tbeg+60) = 0;
        mask(agl==lev,tbeg:tbeg+60) = 6;
    end
    if ~isempty(find(isnan(tmean(62:end-61))))
        fprintf(['BAD DATA FOUND IN MIDDLE\n'])
        badlocs = find(isnan(tmean(62:end-61)));
        badlocs
        badinds = tbeg+61+badlocs;
        %tmean(badlocs) = nan;
        %mask_boolean(badinds) = 0;
        mask(agl==lev,badinds) = 6;
    end
     
    if debug
        
        fw = [0,0,900,700];
        figure('visible','off','position',fw);
        % Time series of the input velocity
        figure('visible','off','position',fw);
        subplot(2,1,1)
        plot(Datenum(tbeg:tend),mask(agl==lev,tbeg:tend));
        xlabel('Time (UTC)');
        ylabel('Mask');
        title({[regime,' chunk ',num2str(i)],['Begin = ',datestr(Datenum(tbeg))],['End = ',datestr(Datenum(tend))],['Length =',num2str(length(tbeg:tend)),' MIN']})
        datetick('x',15);
        set(gca,'YLim',[0 7]);
        %axis tight;
        subplot(2,1,2)
        plot(Datenum(tbeg:tend),runmean(abs(VertVel(agl==lev,tbeg:tend)),10))
        xlabel('Time (UTC)')
        ylabel('Velocity m/s')
        datetick('x',15)
        saveas(gcf,['outlier_',regime,'_chunk_',num2str(i),'.png']);
    end
    
end

% Save out the data to a MAT file (APPEND)
save([matpath,'/profiler.mat'],'Datenum','mask','agl','VertVel','chunkbegin','chunkend','chunklength','regime','-append');

% Clear out variables we don't need
clear('Datenum','mask','agl','VertVel','tmean','tbeg','tend','badinds','chunkbegin','chunkend','chunklength','regime');
