%
% File: find_chunks.m
%
% Author: D. Adriaansen
%
% Date: 30 Mar 2017
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

% Debug
debug = 1;

%#######################################################################%

% Load data from MAT file
%load([matpath,'/profiler.mat'],'Datenum','mask','agl','VertVel');
load([matpath,'/profiler.mat'],'Datenum','mask','VertVel','regime');
%load([matpath,'/profiler.mat'],'Datenum','mask','agl','regime','VertVel');
%load([matpath,'/',currmfile],'Datenum','mask','agl','regime','VertVel');

% Create a mask of zeros and ones, where 1 is good, and zero is bad
mask_boolean = ones(1,length(Datenum));

% Turn off the points where there's data we don't want
%mask_boolean(mask(agl==lev,:)>1) = 0;
mask_boolean(mask>1) = 0;

% Figure out the difference of the mask
mask_diff = diff(mask_boolean);

% Figure out the beginning of all the chunks (mask_diff == 1)
chunkbegin = find(mask_diff==1);

% Figure out the end of all the chunks (mask_diff == -1)
chunkend = find(mask_diff==-1);

% If the number of chunk ends is 1 less than the chunk begins, then the data
% are good all the way to the end of the record. Add the length of the record.
if length(chunkend)==(length(chunkbegin)-1)
    chunkend = [chunkend length(mask_boolean)];
end

% Shift the chunk beginnings up one, because of the way the "diff" function works
chunkbegin = chunkbegin + 1;

% Take a difference between the beginnings and the ends to figure out the length
chunklength = chunkend - chunkbegin;

% Print the number of chunks that exceed the minimum
fprintf(['\n Number of good chunks for ',regime,' is: ',num2str(length(find(chunklength>mingood))),'\n']);
if length(find(chunklength>mingood))==0
  error('NO CHUNKS TO PROCESS');
end

% Debugging
if debug
    % Find indices of chunks with lengths > mingood
    goodchunks = find(chunklength>mingood);
    for n=1:length(goodchunks)
        fprintf(['\n************ CHUNK NUMBER = ',num2str(n),'\n'])
        fprintf(['CHUNK BEGIN = ',datestr(Datenum(chunkbegin(goodchunks(n)))),'\n'])
        fprintf(['CHUNK END = ',datestr(Datenum(chunkend(goodchunks(n)))),'\n'])
        fprintf(['BEGIN = ',num2str(chunkbegin(goodchunks(n))),'\n'])
        fprintf(['END = ',num2str(chunkend(goodchunks(n))),'\n'])
        fprintf(['CHUNK LENGTH = ',num2str(chunklength(goodchunks(n))),'\n'])
        
        % Find the beginning and end of the current chunk
        tbeg = chunkbegin(goodchunks(n));
        tend = chunkend(goodchunks(n));
                
        fw = [0,0,900,700];
        %op = [0,0,1,1];
        %pp = [0.2500 2.5000 8 6];
        figure('visible','off','Position',fw);
        
        % Time series of the input velocity
        %figure('visible','off','Position',fw,'OuterPosition',op,'PaperPosition',pp);
        subplot(2,1,1)
        %plot(Datenum(tbeg:tend),mask(agl==lev,tbeg:tend));
        plot(Datenum(tbeg:tend),mask(tbeg:tend));
        xlabel('Time (UTC)');
        ylabel('Mask');
        title({[regime,' chunk ',num2str(n)],['Begin = ',datestr(Datenum(tbeg))],['End = ',datestr(Datenum(tend))],['Length =',num2str(length(tbeg:tend)),' MIN']})
        datetick('x',15);
        set(gca,'YLim',[-2.0 2.0]);
        %axis tight;
        subplot(2,1,2)
        %plot(Datenum(tbeg:tend),VertVel(agl==lev,tbeg:tend))
        plot(Datenum(tbeg:tend),VertVel(tbeg:tend));
        xlabel('Time (UTC)')
        ylabel('Velocity m/s')
        datetick('x',15)
        saveas(gcf,['mask_',regime,'_chunk_',sprintf('%02d',n),'.png']);
        
    end
end

% Save out the data to a MAT file (APPEND)
save([matpath,'/profiler.mat'],'Datenum','mask','agl','chunkbegin','chunkend','chunklength','regime','VertVel','-append');
%save([matpath,currmfile],'Datenum','mask','agl','chunkbegin','chunkend','chunklength','regime','VertVel','-append');

% Clear out variables we don't need
clear('Datenum','mask','mask_boolean','mask_diff','chunkbegin','chunkend','chunklength','VertVel');
