%
% File: profiler_driver.m
%
% Author: D. Adriaansen
%
% Date: 15 Mar 2017
%
% Purpose: Control the processing of 50 MHz wind profiler data that has been filtered for precipitation
%
% Notes: 
%________________________________________________________________________________________________

% Clear everything
clear;

%######################## Usr Config ##################################%

% Is this break or monsoon processing?
regime = 'break';

% Path to matfiles
matpath = '/d1/dadriaan/paper/data/matfiles';

% What vertical level do we want to examine from the 50 MHz for waves? (S-transform)
Slev = 5000;

% What vertical level do we want to use from the 50 MHz u-wind for monsoon determination?
% 3000m AGL ~ 700 hPa
Mlev = 3000;

% What era?
erastring = 'era_34.mat';

% ***************************************************************************************** Pre-Processing
% Pre-process the data? (concatenate and make eras)
% Subflags: concat, eras
preproc = 0;

% Concatenate data?
% 1. Read in all netCDF daily files
% 2. Create MATLAB serial datenums
% 3. Concatenate the data and write to MAT file
concat = 1;

% Create the ERAs from the master record?
eras = 1;

%
%
% Update regime times?
%regimeinfo = 0;
%
%

% **************************************************************************************** S-transform Processing
% Perform the S-stransform processing? (masking, chunks, S-transform)
% Subflags: maskregime, maskbadprecip, findchunks, maskoutliers, findchunks2, stranspower
stproc = 1;

% Figure out what regime it is?
findregime = 1;

% Mask regime?
% 1. Read in concatendated data
% 2. Mask out times outside the regime we have requested
% 3. Write masked data and mask key to MAT file
maskregime = 1;

% Mask bad & precip?
% 1. Read in concatenated & regime masked data
% 2. Use 920 MHz profiler to mask out precipitation
% 3. Use bad data flag to mask out those times also
% 4. Write masked data and mask key to MAT file
maskbadprecip = 1;

% Find chunks of good data that meet a minimum time requirement
findchunks = 1;

% Find outliers and mask these out using a new flag
maskoutliers = 0;

% Find good chunks again after masking outliers
findchunks2 = 0;

% Perform the S-transform
stranspower = 1;

% Collect all the power from each minute into a single 24-hour window representing the current regime
collectpower = 0;

%#######################################################################

% Proposed order of operation:
% 0. Manually configure the createStartEndLUT.m script to include regime begin/end times based on manually examining 700 hPa wind direction plot
% 1. Read in and concatenate the relevant data from the daily files into matfiles, and convert time to MATLAB serial datenums
% 2. Load in the regime start/end times
% 3. Read in the data and mask out the data outside the regime that has been requested.
% 4. Read in the 920 MHz data and the 50 MHz data and mask out the 50 MHz data for precipitation, and bad data

% 1. Convert netcdf data to mat files for easy reading by later steps.
% 2. Read in mat files and determine monsoon begin and end and break begin and end using 50 MHz data, write to mat file.
%    a. This is actually done manually, by examining the 700 hPa wind direction plot and identifying the start and end days. Then, use the
%       script createStartEndLUT to convert the start and end dates to MATLAB date numbers for use later on.
% 3. Read in monsoon and break begin/end mat files and identify "chunks" of good data using chunk criteria. Write out some mat files here, but what?
%    a. Chunk begin/end time
%    b. Chunk data
%    c. Indices of the begin and end of each of the chunks for quick indexing?
% 4. Read in the info from the first pass of the chunks, and then run the outlier code and filtering to determine even more chunks. Save info to mat files.
%    a. Indices of the begin and end of each chunk for quick indexing for S-Transform later
% 5. Read in the filtered chunks and then perform the S-Transform on each, collecting the output each time. Write out the collected power to a mat file.

% ****************** Pre-Processing
if preproc

    %
    % ******** STEP 1: Concatenate, convert to matfiles, and convert time to serial datenums
    %
    if concat
        fprintf(['\nCONCATENATING PROFILER DATA\n'])
        concat_profiler_data;
    end

    %
    % ********* STEP 2: Break up the entire data record into distinct "eras" where there is continuous data
    %
    if eras
        fprintf(['\nCREATING ERAS FROM MASTER RECORD\n'])
        createEras;
    end
end


% ***************** S-transform Processing
if stproc
    
    % Get a list of the matfiles that contain the data for each era. We want to do everything below for each era, so loop.
    %mfiles = dir([matpath,'/era*.mat']);
    mfiles = dir([matpath,'/',erastring]);
    nf = length(mfiles);
    fprintf(['\nFOUND: ',num2str(nf),' ERA FILES.']);
    for g=1:nf
    
        % Set the current filename
        currmfile = mfiles(g).name;
        fprintf(['\n']);
        fprintf(['PROCESSING MATFILE: ',currmfile,'\n']);
        fprintf(['\n']);
                %
        % ******** STEP 5: Mask out data that was obtained during precipitation, or that has a bad data flag with it
        %
        if maskbadprecip
            fprintf(['MASKING BAD DATA AND PRECIPITATION\n'])
            mask_bad_precip;
        end
        
        %
        % ******** STEP 7: Determine outlier points inside the chunks. Mask these out, then find chunks again.
        %
        if maskoutliers
            fprintf(['GROSS OUTLIER REMOVAL\n'])
            mask_outliers;
        end
        
        %
        % ******** STEP 3: Identify the regime at each time in the era
        %
        if findregime
            fprintf(['DETERMINING REGIME\n']);
            identifyRegime;
        end
        
        %
        % ******** STEP 4: Mask out data outside the current regime that has been requested
        %
        if maskregime
            fprintf(['MASKING DATA OUTSIDE REGIME\n'])
            mask_regime;
        end
        
        %
        % ******** STEP 6: Find chunks of data that meet a time minimum defined in this script
        %
        if findchunks
            fprintf(['FINDING CHUNKS\n'])
            find_chunks;
        end
        
        %
        % ******** STEP 8: Call the code to find chunks again, now that we've done another filtering
        %
        %if findchunks2
        %    fprintf(['FINDING CHUNKS AGAIN AFTER GROSS OUTLIER REMOVAL\n'])
        %    find_chunks;
        %end
        
        %
        % ******** STEP 9: Run the S-Transform on the time series from each chunk
        %
        if stranspower
            fprintf(['CALCULATING THE S-TRANSFORM\n'])
            strans_power;
        end
        
        % Create summary plots
        summary_plots;
    end
end

% ************ Final Step: Collect power
%
% ******** STEP 10: Collect the power from all minutes of a 24 hour period into a single 24 hour window
%
if collectpower
    fprintf(['COLLECTING THE POWER INTO A SINGLE 24-H WINDOW\n'])
    collect_power;
end
