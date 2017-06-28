%
% File: strans_power.m
%
% Author: D. Adriaansen
%
% Date: 25 May 2017
%
% Purpose: Call the S-transform
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

% Make plots?
pmake = 0;

% Debug flag
debug = 0;

%#######################################################################%

% Load data from MAT file
load([matpath,'/profiler.mat'],'Datenum','mask','VertVel','agl','chunkbegin','chunkend','chunklength','regime');

% Create a new variable with size equal to the number of frequency bins and the number of total times in the current period
totpow = nan(length(fbins)-1,length(Datenum));

% Loop over each chunk and do the S-transform and power integrating
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

    % Find the beginning and end of the current chunk
    tbeg = chunkbegin(goodchunks(i));
    tend = chunkend(goodchunks(i));
    
    %### DEBUG
    if debug
        min(mask(agl==lev,tbeg:tend))
        max(mask(agl==lev,tbeg:tend))
    end
    %### DEBUG
    
    % Vector of data for the S-transform for this chunk
    stvec = VertVel(agl==lev,tbeg:tend);
    
    % S-transform
    [str,stt,stf] = st(stvec);
    
    if pmake==1
        % Before moving on, create a save a plot for this period
        fw = [0,0,900,700];
        figure('visible','off','position',fw);
        
        %clevs = [0.0,1.0,0.05];
        clims = [0.0 1.0];
        
        %imagesc(stt,stf,(abs(str).*abs(str)),clims);
        imagesc(Datenum(tbeg:tend),stf,(abs(str)),clims);
        %imagesc(totpow,clims);
        
        set(gca,'YDir','normal');
        cbh = colorbar;
        ylabel('Frequency 1/s');
        xlabel('TIme (UTC)');
        title({[regime,' chunk ',num2str(i)],['Begin = ',datestr(Datenum(tbeg))],['End = ',datestr(Datenum(tend))],['Length =',num2str(length(stvec)),' MIN']})
        datetick('x',15);
        axis tight;
        
        %ylabel(cbh,'abs(str)^2 (m^2/s^2)');
        ylabel(cbh,'abs(str) (m/s)');
        %ylabel(cbh,'Average power (m/s)')
        
        %set(gca,'YTick',[0.5,1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5,10.5])
        %set(gca,'YTickLabel',[0.0,0.05,0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5])
        
        %saveas(gcf,['st_',bm,'_chunk_',num2str(periodcount),'_square.png']);
        saveas(gcf,['st_',regime,'_chunk_',num2str(i),'_abs.png']);
        %saveas(gcf,['st_',bm,'_chunk_',num2str(periodcount),'_totpow.png']);
        
        % Time series of the input velocity
        figure('visible','off','position',fw);
        plot(Datenum(tbeg:tend),runmean(abs(stvec),10));
        xlabel('Time (UTC)');
        ylabel('Velocity (m/s)');
        title({[regime,' chunk ',num2str(i)],['Begin = ',datestr(Datenum(tbeg))],['End = ',datestr(Datenum(tend))],['Length =',num2str(length(stvec)),' MIN']})
        datetick('x',15);
        set(gca,'YLim',[-2.0 2.0]);
        %axis tight;
        saveas(gcf,['ts_',regime,'_chunk_',num2str(i),'.png']);

    end
    
    % Store stuff to make a boxplot if we want
    if i == 1
        stboxplot = [stvec'];
    else
        stboxplot = [stboxplot; stvec'];
    end
               
    % Store the period number
    if i == 1
        pnums = [(i)*ones(size(stvec'))];
    else
        pnums = [pnums; ((i)*ones(size(stvec')))];
    end
    
    % Create a new vector to hold the number of voices per band
    nvoice = zeros(1,length(fbins)-1);
    
    % Instead of looping over every time, just loop over frequencies and apply the averaging at each time using indexing
    for b=1:length(fbins)-1
        
        % Figure out which frequencies we want to collect
        if b==1  
            group = find(stf>fbins(b) & stf<fbins(b+1));
        elseif b==length(fbins)-1
            group = find(stf>=fbins(b) & stf<=fbins(b+1));                  
        else
            group = find(stf>=fbins(b) & stf<fbins(b+1));
        end
                     
        % This is the denominator- divide by the number of voices in the frequency band
        nvoice = length(group);
                
        % Instead of summing/integrating, try using the average
        % English description of this line: for the current frequency band, and for all the times in the current chunk, take the
        % sum of all the S-transform output in the range of frequencies we want and normalize/divide/average whatever you want to say
        % by the number of voices in the band of frequencies we're looking at.
        totpow(b,tbeg:tend) = sum(abs(str(group,:)))/nvoice;
    end
end

% By the time we reach here, the totpow array should contain all the averaged power per band for each time where we computed the S-transform
% which is every time in every chunk during the regime requested.

% Save out the data to a MAT file (APPEND)
save([matpath,'/profiler.mat'],'Datenum','mask','agl','VertVel','chunkbegin','chunkend','chunklength','totpow','regime','-append');

% Clear out variables we don't need
clear('Datenum','mask','agl','VertVel','group','tbeg','tend','stvec','chunkbegin','chunkend','chunklength','nvoice','totpow','str','stt','stf','regime');


    