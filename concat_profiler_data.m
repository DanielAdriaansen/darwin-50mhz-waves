%
% File: concat_profiler_data.m
%
% Author: D. Adriaansen
%
% Date: 29 Mar 2017
%
% Purpose: Convert the 50MHz and 920 MHz profiler data from netCDF to matfiles for easy reading.
%          This also takes data from daily netCDF files (00:00 - 23:59) and concatenates the data into
%          a single vector equal to the length of the number of days of data available (aggregated data).
%
% Notes: 
%________________________________________________________________________________________________

%######################## User Config ##################################%

% Path to raw netCDF data
%ncpath = '/d1/dadriaan/paper/data/c1/raw';
ncpath = '/d1/dadriaan/paper/data/10yrs/all';

% Path to matfiles
matpath = '/d1/dadriaan/paper/data/matfiles';

%#######################################################################%

% Get the list of files we want to process
flist = dir([ncpath,'/*.nc']);

% Number of files
nfiles = length(flist);
fprintf(['\nFOUND: ',num2str(nfiles),' NETCDF FILES.']);

% Read in the first file and get the dimensions we need, then define a new matrix to hold the data
nz = length(ncread([ncpath,'/',flist(1).name],'prof_height_100m_AGL'));
nt = length(ncread([ncpath,'/',flist(1).name],'prof_time_year'));

% Based on the number of files, times, and heights create the correctly sized matrix for the data. Note
% that we only want a single height so instead of nz, just use 1. The exception is 920 MHz data, which still needs
% to be 2D (z,t).
VertVel = zeros(1,nt*nfiles);    % 50 MHz Vertical Velocity
UWind = zeros(1,nt*nfiles);      % 50 MHz Zonal wind
%VWind = zeros(1,nt*nfiles);      % 50 MHz Meridional wind
Monvec = zeros(1,nt*nfiles);     % 50 MHz U-wind for monsoon/break determination
yr = zeros(1,nt*nfiles);         % Year
mon = zeros(1,nt*nfiles);        % Month
day = zeros(1,nt*nfiles);        % Day
hour = zeros(1,nt*nfiles);       % Hour
mins = zeros(1,nt*nfiles);       % Minute
Dbz = zeros(nz,nt*nfiles);       % 920 MHz reflectivity
Dopvel = zeros(nz,nt*nfiles);    % 920 MHz doppler velocity

% Print out the size of the concatenated time,height data for the user
fprintf(['\nSIZE OF 50 MHz data MATRIX:'])
size(VertVel)

% Store the height data
agl = ncread([ncpath,'/',flist(1).name],'prof_height_100m_AGL');

% Loop over each file, open the data and store it
for f=1:nfiles

  % What file are we reading?
  fprintf(['\n',ncpath,'/',flist(f).name,'\n'])
  
  % Determine the begin and end of the indexes we're storing in the concatenated data
  end_ind = 1440*f;
  beg_ind = end_ind-1439;

  % Read in the data. Since we're slicing out the 50 MHz data, read it to a temp var and store the slice
  % 50 MHz w
  tmpW = ncread([ncpath,'/',flist(f).name],'prof_dar50_Omega_mean');
  VertVel(:,beg_ind:end_ind) = tmpW(agl==Slev,:);
  %VertVel(:,beg_ind:end_ind) = ncread([ncpath,'/',flist(f).name],'prof_dar50_Omega_mean');
  
  % 50 MHz u
  tmpU = ncread([ncpath,'/',flist(f).name],'prof_dar50_Zonal_mean');
  Uwind(:,beg_ind:end_ind) = tmpU(agl==Slev,:);
  %Uwind(:,beg_ind:end_ind) = ncread([ncpath,'/',flist(f).name],'prof_dar50_Zonal_mean');
    
  % 50 MHz U-wind for monsoon/break
  Monvec(:,beg_ind:end_ind) = tmpU(agl==Mlev,:);
  
  % 50 MHz v
  tmpV = ncread([ncpath,'/',flist(f).name],'prof_dar50_Merid_mean');
  Vwind(:,beg_ind:end_ind) = tmpV(agl==Slev,:);
  %Vwind(:,beg_ind:end_ind) = ncread([ncpath,'/',flist(f).name],'prof_dar50_Merid_mean');

  % Date/time info
  yr(:,beg_ind:end_ind) = ncread([ncpath,'/',flist(f).name],'prof_time_year');
  mon(:,beg_ind:end_ind) = ncread([ncpath,'/',flist(f).name],'prof_time_month');
  day(:,beg_ind:end_ind) = ncread([ncpath,'/',flist(f).name],'prof_time_dayofmonth');
  hour(:,beg_ind:end_ind) = ncread([ncpath,'/',flist(f).name],'prof_time_hour');
  mins(:,beg_ind:end_ind) = ncread([ncpath,'/',flist(f).name],'prof_time_minute');
  
  % 920 MHz fields
  Dbz(:,beg_ind:end_ind) = ncread([ncpath,'/',flist(f).name],'prof_dar920_vert_zdb');
  Dopvel(:,beg_ind:end_ind) = ncread([ncpath,'/',flist(f).name],'prof_dar920_vert_vel');

end

% Before storing data for later processing, convert the time information to a MATLAB serial date number
Datenum = datenum(yr,mon,day,hour,mins,0);

% Save data to matfiles for later use
save([matpath,'/profiler.mat'],'VertVel','Uwind','Vwind','Monvec','Datenum','Dbz','Dopvel','regime','agl');

% Clear out variables we don't need
%clear('VertVel','Monvec','Uwind','Datenum','Dbz','Dopvel','regime','agl');