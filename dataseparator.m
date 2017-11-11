len = numel(mydata);
maindir = 'data_by_trials';
classdir = './data_by_trials/%s/';
speeddir = './data_by_trials/%s/%s/';
template = './data_by_trials/%s/%s/%s';
dirtemplate = './data_by_trials/%s/%s/*.mat';
mkdir(maindir);
for i=1:len
    str = mydata{i}.filename;
    str = strrep(str, '_again', '');
    str = strrep(str, '.csv', '');
    classname = regexp(str, '[A-Za-z]+', 'match');
    speed = regexp(str, '\d+', 'match');
    
    classname = cell2mat(classname);
    speed = cell2mat(speed);
    
    mkdir(sprintf(classdir, classname));
    mkdir(sprintf(speeddir, classname, speed));
    numbers = numel(dir(sprintf(dirtemplate, classname, speed))) + 1;
    trialname = sprintf('trial%d.mat', numbers);
    tosave = mydata{i};
    save(sprintf(template, classname, speed, trialname), 'tosave');
end;