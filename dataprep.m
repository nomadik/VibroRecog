close all; clear all; clc;
path = '.\hap_rec_csv\';
filetempl = '.\\hap_rec_csv\\%s';           
files = dir([path '\*.csv']);
 
%%
doplot = true;
mydata = {};
maincounter = 1; 
%outputFID = fopen('result.txt','w');

for fileind = 1:numel(files)
    fname = files(fileind).name;
    label = fname(1:4);
    fid = fopen(sprintf(filetempl, fname),'rt');
    tline = fgetl(fid);
    counter = 0;
    data = [];
    while ischar(tline)
        counter = counter + 1;
        splitted = strsplit(tline, ',');
        tline = fgetl(fid);
        if (counter == 1)
            continue;
        end;

        data = vertcat(data, splitted(5:end));
    end

    fclose(fid);

    dataextracted = cellfun(@str2double,data);
    dataextracted = dataextracted(:,[2,3,6,7,13,14]);
    dataextracted(:,1) = dataextracted(:,1) + dataextracted(:,2);
    dataextracted(:,2) = [];
    dataextracted(:,3) = dataextracted(:,3) + dataextracted(:,4);
    dataextracted(:,3) = [];
    dataextracted(:,4) = [];
    %% 2-3 and pac
    Nfft = size(dataextracted, 1);
    fsamp = 100;
    Tsamp = 1/fsamp;
    [Pxx,f] = pwelch(dataextracted(:,1)-mean(dataextracted(:,1)), gausswin(Nfft),Nfft/2,Nfft,fsamp);

    if (doplot) 
        plot(f,Pxx);
    end;

    if (strcmp(fname, 'Spices150.csv'))
        [shit, loc] = max(Pxx(5:end));
    else
        [shit, loc] = max(Pxx(1:end));
    end;
    FREQ_ESTIMATE = f(loc);
    tmp = Pxx(loc);
    Pxx(:) = 0;
    Pxx(loc) = tmp;

    %%
    if (doplot) 
        close all;
    end;
    N = 10;
    hd = design(fdesign.bandpass('N,Fc1,Fc2', N, FREQ_ESTIMATE - 0.01, FREQ_ESTIMATE + 0.01, 100));
    y = filter(hd,dataextracted(:,1)); 
    %%
    if (doplot) 
        close all;
        hold on;
        plot(dataextracted(:,1), 'r');
        plot(y, 'b');
        hold off;
    end;

    %%
    [pks,locs] = findpeaks(-y, 'MinPeakDistance',50/FREQ_ESTIMATE);

    %%
    locs = locs - N/2;
    if (doplot) 
        close all; 
        hold on;
        plot(y, 'r');
    end;
    npks = [];
    nlocs = [];
    ymean = mean(y);
    counter = 0;
    for i=1:numel(pks)
        if (strcmp(fname, 'Spices150.csv') == 0)
            if (-pks(i) > ymean)
                continue;
            end;
        end;
        counter = counter + 1;
        npks(counter) = pks(i);
        nlocs(counter) = locs(i);
    end
    if (doplot) 
        text(nlocs+.02,-npks,num2str((1:numel(npks))'))
        %t = [0:1:numel(y)];
        %plot(sin(2*pi*t*FREQ_ESTIMATE/100));
        hold off;
    end;

    for i=2:numel(npks) 
        if ((strcmp(fname, 'Pillow25.csv') && i == 2) || (strcmp(fname, 'Spices150.csv') && i < 4))
            disp('ohoho');
            continue;
        end;
        
        if (strcmp(fname, 'Spices100.csv') && i > 31)
            continue;
        end;
        n1 = nlocs(i-1);
        n2 = nlocs(i);
        singledata = struct('angles', dataextracted(n1:n2,1), ...
            'pac0', dataextracted(n1:n2,2), ...
            'pac1', dataextracted(n1:n2,3), ...
            'label', label, ...
            'filename', fname);
        mydata{maincounter} = singledata;
        maincounter = maincounter + 1;
    end;
    %clearvars -except fileind files path filetempl doplot mydata maincounter;
    disp(sprintf('processed %d out of %d', fileind, numel(files)));
end;
%fclose(outputFID);

%%
pause();
loc = 0;
mymax = 0;
sizechecks = [];
datachekcs = {};
for i=1:size(mydata, 2)
    if (mymax < numel(mydata{i}.angles))
        mymax = numel(mydata{i}.angles);
        loc = i;
    end;
    plot(mydata{i}.angles);
    disp(mydata{i}.filename);
    drawnow();
    pause();
end;

%% generate stupid features
fftsize = 300;
features1 = [];
features2 = [];
features12 = [];
close all;
dohighpass = false;
hd = design(fdesign.highpass('Fst,Fp,Ast,Ap', FREQ_ESTIMATE - 0.05, FREQ_ESTIMATE + 0.05,60,1));
for i=1:size(mydata, 2)
    if (dohighpass)         
        pac0Filt = filter(hd, mydata{i}.pac0); 
        pac1Filt = filter(hd, mydata{i}.pac1); 
    else
        pac0Filt = mydata{i}.pac0;
        pac1Filt = mydata{i}.pac1;
    end;
    %close all;
    %hold on;
    %plot(mydata{i}.angles, 'b');
    %plot(filter(hd, mydata{i}.angles), 'r');
    %hold off;
    %drawnow();
    %pause();
    data0 = fft(pac0Filt, fftsize);
    data1 = fft(pac1Filt, fftsize);
    label = labelToNumber(mydata{i}.label);
    datapiece12 = horzcat(data0', data1');
    datapiece12 = horzcat(datapiece12, label);
    features12 = vertcat(features12, datapiece12);
    
    datapiece1 = data0';
    datapiece1 = horzcat(datapiece1, label);
    features1 = vertcat(features1, datapiece1);
    
    datapiece2 = data1';
    datapiece2 = horzcat(datapiece2, label);
    features2 = vertcat(features2, datapiece2);
    
end;

% make real valued features
absfeat12 = abs(features12);
absfeat1 = abs(features1);
absfeat2 = abs(features2);

%% make equall data size by classes
dothis = false;
if (dothis)
    feat12_1 = absfeat12(absfeat12(:,end) == 1,:);
    rand_ind = randperm(size(feat12_1, 1));
    feat12_1 = feat12_1(rand_ind, :);

    feat12_2 = absfeat12(absfeat12(:,end) == 2,:);
    rand_ind = randperm(size(feat12_2, 1));
    feat12_2 = feat12_2(rand_ind, :);

    feat12_3 = absfeat12(absfeat12(:,end) == 3,:);
    rand_ind = randperm(size(feat12_3, 1));
    feat12_3 = feat12_3(rand_ind, :);

    feat12_4 = absfeat12(absfeat12(:,end) == 4,:);
    rand_ind = randperm(size(feat12_4, 1));
    feat12_4 = feat12_4(rand_ind, :);

    feat12_5 = absfeat12(absfeat12(:,end) == 5,:);
    rand_ind = randperm(size(feat12_5, 1));
    feat12_5 = feat12_5(rand_ind, :);

    feat12_6 = absfeat12(absfeat12(:,end) == 6,:);
    rand_ind = randperm(size(feat12_6, 1));
    feat12_6 = feat12_6(rand_ind, :);

    feat12_7 = absfeat12(absfeat12(:,end) == 7,:);
    rand_ind = randperm(size(feat12_7, 1));
    feat12_7 = feat12_7(rand_ind, :);

    minsize = min([size(feat12_1, 1), size(feat12_2, 1), ...
        size(feat12_3, 1), size(feat12_4, 1), ...
        size(feat12_5, 1), size(feat12_6, 1), ...
        size(feat12_7, 1)]);

    feat12_1 = feat12_1(1:minsize, :);
    feat12_2 = feat12_2(1:minsize, :);
    feat12_3 = feat12_3(1:minsize, :);
    feat12_4 = feat12_4(1:minsize, :);
    feat12_5 = feat12_5(1:minsize, :);
    feat12_6 = feat12_6(1:minsize, :);
    feat12_7 = feat12_7(1:minsize, :);
    absfeat12 = [feat12_1;feat12_2;feat12_3;feat12_4;feat12_5;feat12_6;feat12_7];
end;
%% normalize

[absfeat12, maxs12, mins12] = normalizeColumns(absfeat12);
[absfeat1, maxs1, mins1] = normalizeColumns(absfeat1);
[absfeat2, maxs2, mins2] = normalizeColumns(absfeat2);

% shuffle
rand_ind = randperm(size(absfeat12, 1));
absfeat12 = absfeat12(rand_ind, :);

rand_ind = randperm(size(absfeat1, 1));
absfeat1 = absfeat1(rand_ind, :);

rand_ind = randperm(size(absfeat2, 1));
absfeat2 = absfeat2(rand_ind, :);

% train / test separation
thresh1 = round(size(absfeat1, 1) * 0.8);
train_absfeat1 = absfeat1(1:thresh1, :);
test_absfeat1 = absfeat1(thresh1 + 1:end, :);

thresh2 = round(size(absfeat2, 1) * 0.8);
train_absfeat2 = absfeat2(1:thresh2, :);
test_absfeat2 = absfeat2(thresh2 + 1:end, :);
 
thresh3 = round(size(absfeat12, 1) * 0.8);
train_absfeat12 = absfeat12(1:thresh3, :);
test_absfeat12 = absfeat12(thresh3 + 1:end, :);

%% test
yfit = svm12.predictFcn(test_absfeat12(:,1:end-1));
sum(yfit == test_absfeat12(:,end))/numel(test_absfeat12(:,end))

y = confusionMatrix(yfit, test_absfeat12(:,end)); 