%lev
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
pmake = 1;

% Debug flag
debug = 1;

%#######################################################################%

% Load data from MAT file
%load([matpath,'/profiler.mat'],'Datenum','mask','VertVel','agl','chunkbegin','chunkend','chunklength','regime');
%load([matpath,currmfile],'Datenum','mask','VertVel','agl','chunkbegin','chunkend','chunklength','regime');
load([matpath,'/profiler.mat'],'Datenum','mask','VertVel','Uwind','chunkbegin','chunkend','chunklength','regime');

% Create a new variable with size equal to the number of frequency bins and the number of total times in the current period
totpow = nan(length(fbins)-1,length(Datenum));

% Reset VertVel to another component if we want that
%VertVel = Uwind;

% Keep track of the total amount of time in all chunks analyzed
totchunklen = 0;

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
    
    % Increment the totchunklen variable
    totchunklen = totchunklen + chunklength(goodchunks(i));

    % Find the beginning and end of the current chunk
    tbeg = chunkbegin(goodchunks(i));
    tend = chunkend(goodchunks(i));
    
    %### DEBUG
    if debug
        %min(mask(agl==lev,tbeg:tend))
        %max(mask(agl==lev,tbeg:tend))
        min(mask(tbeg:tend))
        max(mask(tbeg:tend))
    end
    %### DEBUG
    
    % Vector of data for the S-transform for this chunk
    %stvec = VertVel(agl==lev,tbeg:tend);
    stvec = VertVel(tbeg:tend);
    
    % S-transform
    [str,stt,stf] = st(stvec);
    
    if pmake==1
        % Before moving on, create a save a plot for this period
        fw = [0,0,900,700];
        figure('visible','off','position',fw);
        
        %clevs = [0.0,1.0,0.05];
        clims = [0.0 1.0];
        
        % Manually set the limits to 00:00 and 23:59 this day, and create times for day begin and night begin
        ldn = datevec(datestr(Datenum(tbeg),1));
        rdn = datevec(datestr(Datenum(tend),1));
        ddd = ldn;
        ddn = ldn;
        ddd(4) = 2;
        ddn(4) = 14;
        rdn(4) = 23;
        rdn(5) = 59;
        llim = find(Datenum==datenum(ldn));
        rlim = find(Datenum==datenum(rdn));
        %set(gca,'XLim',[Datenum(llim) Datenum(rlim)]);
        
        %imagesc(stt,stf,(abs(str).*abs(str)),clims);
        imagesc(Datenum(tbeg:tend),stf(2:end),(abs(str(2:end,:))),clims);
        %imagesc(totpow,clims);
        
        % YLim values here are in frequency.
        % 0.2 = 5 minutes
        % 0.12 = 8.33 minutes
        % 0.005 = 200 minutes
        set(gca,'YLim',[0.005 0.12]);
        axval = get(gca,'YTick');
        axper = 1.0./axval;
        set(gca,'YTickLabel',num2cell(axper));
        set(gca,'YDir','normal');
        cbh = colorbar;
        %ylabel('Frequency 1/s');
        ylabel('Period (minutes)');
        xlabel('TIme (UTC)');
        title({[regime,' chunk ',num2str(i)],['Begin = ',datestr(Datenum(tbeg))],['End = ',datestr(Datenum(tend))],['Length =',num2str(length(stvec)),' MIN']})
        %datetick('x',15);
        
        % Add lines for B-V frequency, darwin begin of day (02Z) and darwin begin of night (02Z + 12 = 14Z). 
        % Note: 0.108 s^-1 = 9.25 minutes, B-V frequency
        % Note: 0.114 s^-1 = 8.77 minutes, B-V frequency
        %line([Datenum(tbeg) Datenum(tend)],[0.108,0.108],'Color','white','LineStyle','--','LineWidth',1.5);
        line([Datenum(tbeg) Datenum(tend)],[0.114,0.114],'Color','white','LineStyle','--','LineWidth',1.5);
        line([Datenum(find(Datenum==datenum(datestr(ddd)))) Datenum(find(Datenum==datenum(datestr(ddd))))],[get(gca,'YLim')],'Color','Yellow','LineStyle','-','LineWidth',1.5);
        line([Datenum(find(Datenum==datenum(datestr(ddn)))) Datenum(find(Datenum==datenum(datestr(ddn))))],[get(gca,'YLim')],'Color','red','LineStyle','-','LineWidth',1.5);
        
        set(gca,'XLim',[Datenum(llim) Datenum(rlim)]);
        datetick('x',15,'keeplimits');
        %set(gca,'XLim',[Datenum(tbeg) Datenum(tend)]);
        %axis tight;                
        
        %ylabel(cbh,'abs(str)^2 (m^2/s^2)');
        ylabel(cbh,'abs(str) (m/s)');
        %ylabel(cbh,'Average power (m/s)')
        
        %set(gca,'YTick',[0.5,1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5,10.5])
        %set(gca,'YTickLabel',[0.0,0.05,0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5])
        
        %saveas(gcf,['st_',bm,'_chunk_',num2str(periodcount),'_square.png']);
        saveas(gcf,['st_',regime,'_chunk_',sprintf('%02d',i),'_abs.png']);
        %saveas(gcf,['st_',bm,'_chunk_',num2str(periodcount),'_totpow.png']);
        
        % Time series of the input velocity
        figure('visible','off','position',fw);
        %plot(Datenum(tbeg:tend),runmean(abs(stvec),10));
        plot(Datenum(tbeg:tend),stvec);
        xlabel('Time (UTC)');
        ylabel('Velocity (m/s)');
        title({[regime,' chunk ',num2str(i)],['Begin = ',datestr(Datenum(tbeg))],['End = ',datestr(Datenum(tend))],['Length =',num2str(length(stvec)),' MIN']})
        datetick('x',15);
        %set(gca,'YLim',[-2.0 2.0]);
        %axis tight;
        saveas(gcf,['ts_',regime,'_chunk_',sprintf('%02d',i),'.png']);

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
save([matpath,'/profiler.mat'],'Datenum','mask','VertVel','chunkbegin','chunkend','chunklength','totpow','regime','-append');
%save([matpath,currmfile],'Datenum','mask','agl','VertVel','chunkbegin','chunkend','chunklength','totpow','regime','-append');

% Clear out variables we don't need
clear('Datenum','mask','agl','VertVel','group','tbeg','tend','stvec','chunkbegin','chunkend','chunklength','nvoice','totpow','str','stt','stf','regime');


    