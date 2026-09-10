% General requirements

%{
0.25p – an established communication channel and appropriate strategy for code sharing.
0.25p – data correctly imported into appropriate matrices completely:
        observations as rows, variables (predictors) as columns.
0.5p – identification of challenges of the data: for example:
    time series not synchronized, missing values in data,
    extra variables, variables with unknown physical meanings, etc.
0.5p – a visualization and comment on the dataset:
    variable distribution, number of observations,
    type of measurements (time series or not time series)
3p  - exploratory data analysis with PCA: explain variable
    correlations and visualize the PCs using biplots,
    loading plots;
    (! only on the X matrix - we are not looking
    at the response variable now)
0.5p  – identification of pretreatment steps,
    and a plan on how to do data pretreatment
%}

% Level A2 requirements (30p)

%{
Sensor	importance	and	multivariate	
models	for	filling	
missing	data.

Calibrate	a	PCA	model	of	the	healthy	turbine,
and	separate	PCA	models	for	the	first 20 
observations of	 the two chosen	 faulty	 turbines.
> Which	are	the sensors	 that give most different loadings when
compared	to	the	healthy	turbine?

For	the	healthy	turbine, create	 PLS models	to estimate	the values
of two important sensors. 
> How well does	your model predict?	Use, as	a test data,
one	of	the	 faulty	turbines.
> Are you still	able to	maintain your regression performance
in the case	where the turbine has a	fault?

_Note_ :Since this is an A-level task, you need	to consider	one
healthy	turbine	and	two	faulty turbines	for	your analysis
%}

% Data description

%{
The	wind turbine failure	dataset	(SCADA	– Supervisory	Control	and	Data	Acquisition)
has	 measurements recorded every 10th second, from	wind 
turbine	 sensors.The variable names	are	unknown, but they
represent sensor measurements that correspond to various	
physical process	properties.	The	dataset	contains four wind	turbines:
	WT2,	WT3,	WT14	and	WT39.
The	WT2	is	the	healthy-functioning	turbine, whereas the other three present
faults (they are developing	faults). What we know about	the	faulty	wind
turbines is	that there	is	an	initial	fault,	and	then they switch at	some
point to normal	operation after	the	fault has been resolved.
%}

%% Healthy
clc
clearvars
close all

% open the data (1571 x 28)
data = readtable('data.xlsx','Sheet',"No.2WT"); % obs in rows, vars in cols

% check for missing values
missingValues = sum(ismissing(data)); % 28 missing values

% plot the variables
data_arr = table2array(data);
data_stand = zscore(data_arr);
figure('Color','w');
for i = 1:28
    subplot(7,4,i);
    plot(data_stand(:,i),'LineWidth',0.8);
    title(sprintf('Var %d',i),'FontSize',8);
    grid on;
    axis tight;
end

title('Overlay of 28 variables');
grid on;
axis tight;
% check correlation
R = corr(data_stand, 'Rows','pairwise');
[r,c] = find(triu(true(size(R)),1));
values = R(sub2ind(size(R),r,c));
    % sort the correlation
[~,sort_idx] = sort(abs(values),'descend');
r_sorted = r(sort_idx);
c_sorted = c(sort_idx);
values_sorted = values(sort_idx);
to_keep = true(1,28);
for i = 1:28
    if ~to_keep(i)
        % already marked for removal
        continue;
    end
    for j = (i+1):28
        if to_keep(j)
            if abs(abs(R(i,j)) - 1) < 1e-6
                to_keep(j) = false;
            end
        end
    end
end
    % cleaned data
data_clean = data_stand(:,to_keep);
num_vars = find(to_keep);

% we can try to identify if there are significant shifts
% lets check volatility over time
window_sz = 50;
[nrows, ncols] = size(data_clean);

volati = movstd(data_clean, window_sz,1);
figure('Name','Volatility over time','Color','w');
t = tiledlayout(5,6, 'TileSpacing','compact','Padding','compact');
ax = zeros(1, ncols);

for i = 1:ncols
    ax(i) = nexttile;
    plot(volati(:, i), 'LineWidth', 0.8, 'Color', [0.8500 0.3250 0.0980]);
    title(sprintf('Var %d', i), 'FontSize', 8);
    grid on;
    axis tight;
end

% link all x-axis to zoom
linkaxes(ax, 'x');
xlabel(t, 'Time Index (10s intervals)');

% most "stable" seems to be variable 5
% let see how it correlates with other variables
corr2 = corr(data_clean);
target_corr = corr2(5,:);
other_cols = [1:4, 6:size(data_clean,2)];
corr_vs_5 = target_corr(other_cols);
% check which correlate highly with var5
high_corr = abs(corr_vs_5) >= 0.8;
filt_cols = other_cols(high_corr);
filt_corrs = corr_vs_5(high_corr);
% sort my correlation
[~, sort_i] = sort(abs(filt_corrs));
ranked_cols = filt_cols(sort_i);
ranked_corrs = filt_corrs(sort_i);
% show a table
resu = table(ranked_cols, ranked_corrs,...
    abs(ranked_corrs),'VariableNames',...
    {'Var.i','Correlation','Abs corr.'});
disp(resu); 
% v10:0.998, v11:0.98676, v6:0.847
% v7:0.8451, v3:0.8337,v15:0.8138, v18:0.80474

% residual vector
x_mov_avg = movmean(data_clean, window_sz,1);
residuals = abs(data_clean - x_mov_avg);
mean_residuals = mean(residuals,1);
[~,worst_mean] = max(mean_residuals);
% lets check how often we exceed 4*std
thresh = 4*std(data_clean, 0,1);
faults = residuals > thresh;
count_faults = sum(faults,1); % total flagged meas.
% sort from "cleanest" to least clean
[sort_cnt, rank_i] = sort(count_faults, 'ascend');

turb_health = table(rank_i', sort_cnt',...
    'VariableNames',...
    {'Var.i','No. of faults'});
disp(turb_health); 
% v5, v10, v15,v23 have 0 fault
% the rest have 1

% lets try clustering (hierarchical)
corr_dist = 1 - abs(corr2);
tree = linkage(squareform(corr_dist,'tovector'),'average');
turb_clust = cluster(tree,'maxclust',4);
    % mapping table
clus_map = table((1:26)', turb_clust,...
    'VariableNames',{'Var.i', 'Ass.cluster'});
disp(clus_map);
% the tree plot
figure;
[~,~,leaf_ord] = dendrogram(tree, 0,'Orientation','left');
title('Hierarchical tree of the variables');
xlabel('Corr.dist (1-|r|)');
ylabel('Var.i');
grid on;

%% Faulty 1
clc
clearvars
close all

% open the data (1571 x 28)
data = readtable('data.xlsx','Sheet',"No.3"); % obs in rows, vars in cols

% check for missing values
missingValues = sum(ismissing(data)); % 28 missing values

% plot the variables
data_arr = table2array(data);
data_stand = zscore(data_arr);
figure('Color','w');
for i = 1:28
    subplot(7,4,i);
    plot(data_stand(:,i),'LineWidth',0.8);
    title(sprintf('Var %d',i),'FontSize',8);
    grid on;
    axis tight;
end

title('Overlay of 28 variables');
grid on;
axis tight;
% check correlation
R = corr(data_stand, 'Rows','pairwise');
[r,c] = find(triu(true(size(R)),1));
values = R(sub2ind(size(R),r,c));
    % sort the correlation
[~,sort_idx] = sort(abs(values),'descend');
r_sorted = r(sort_idx);
c_sorted = c(sort_idx);
values_sorted = values(sort_idx);
to_keep = true(1,28);
for i = 1:28
    if ~to_keep(i)
        % already marked for removal
        continue;
    end
    for j = (i+1):28
        if to_keep(j)
            if abs(abs(R(i,j)) - 1) < 1e-6
                to_keep(j) = false;
            end
        end
    end
end
    % cleaned data
data_clean = data_stand(:,to_keep);
num_vars = find(to_keep);

% we can try to identify if there are significant shifts
% lets check volatility over time
window_sz = 50;
[nrows, ncols] = size(data_clean);

volati = movstd(data_clean, window_sz,1);
figure('Name','Volatility over time','Color','w');
t = tiledlayout(5,6, 'TileSpacing','compact','Padding','compact');
ax = zeros(1, ncols);

for i = 1:ncols
    ax(i) = nexttile;
    plot(volati(:, i), 'LineWidth', 0.8, 'Color', [0.8500 0.3250 0.0980]);
    title(sprintf('Var %d', i), 'FontSize', 8);
    grid on;
    axis tight;
end

% link all x-axis to zoom
linkaxes(ax, 'x');
xlabel(t, 'Time Index (10s intervals)');

% most "stable" seems to be variable 5
% let see how it correlates with other variables
corr2 = corr(data_clean);
target_corr = corr2(5,:);
other_cols = [1:4, 6:size(data_clean,2)];
corr_vs_5 = target_corr(other_cols);
% check which correlate highly with var5
high_corr = abs(corr_vs_5) >= 0.8;
filt_cols = other_cols(high_corr);
filt_corrs = corr_vs_5(high_corr);
% sort my correlation
[~, sort_i] = sort(abs(filt_corrs));
ranked_cols = filt_cols(sort_i);
ranked_corrs = filt_corrs(sort_i);
% show a table
resu = table(ranked_cols, ranked_corrs,...
    abs(ranked_corrs),'VariableNames',...
    {'Var.i','Correlation','Abs corr.'});
disp(resu); 
% v10:0.998, v11:0.98676, v6:0.847
% v7:0.8451, v3:0.8337,v15:0.8138, v18:0.80474

% residual vector
x_mov_avg = movmean(data_clean, window_sz,1);
residuals = abs(data_clean - x_mov_avg);
mean_residuals = mean(residuals,1);
[~,worst_mean] = max(mean_residuals);
% lets check how often we exceed 4*std
thresh = 4*std(data_clean, 0,1);
faults = residuals > thresh;
count_faults = sum(faults,1); % total flagged meas.
% sort from "cleanest" to least clean
[sort_cnt, rank_i] = sort(count_faults, 'ascend');

turb_health = table(rank_i', sort_cnt',...
    'VariableNames',...
    {'Var.i','No. of faults'});
disp(turb_health); 
% v5, v10, v15,v23 have 0 fault
% the rest have 1

% lets try clustering (hierarchical)
corr_dist = 1 - abs(corr2);
tree = linkage(squareform(corr_dist,'tovector'),'average');
turb_clust = cluster(tree,'maxclust',4);
    % mapping table
clus_map = table((1:26)', turb_clust,...
    'VariableNames',{'Var.i', 'Ass.cluster'});
disp(clus_map);
% the tree plot
figure;
[~,~,lead_ord] = dendrogram(tree, 0,'Orientation','left');
title('Hierarchical tree of the variables');
xlabel('Corr.dist (1-|r|)');
ylabel('Var.i');
grid on;

%% Faulty 2
clc
clearvars
close all

% open the data (1571 x 28)
data = readtable('data.xlsx','Sheet',"No.14WT"); % obs in rows, vars in cols

% check for missing values
missingValues = sum(ismissing(data)); % 28 missing values

% plot the variables
data_arr = table2array(data);
data_stand = zscore(data_arr);
figure('Color','w');
for i = 1:28
    subplot(7,4,i);
    plot(data_stand(:,i),'LineWidth',0.8);
    title(sprintf('Var %d',i),'FontSize',8);
    grid on;
    axis tight;
end

title('Overlay of 28 variables');
grid on;
axis tight;
% check correlation
R = corr(data_stand, 'Rows','pairwise');
[r,c] = find(triu(true(size(R)),1));
values = R(sub2ind(size(R),r,c));
    % sort the correlation
[~,sort_idx] = sort(abs(values),'descend');
r_sorted = r(sort_idx);
c_sorted = c(sort_idx);
values_sorted = values(sort_idx);
to_keep = true(1,28);
for i = 1:28
    if ~to_keep(i)
        % already marked for removal
        continue;
    end
    for j = (i+1):28
        if to_keep(j)
            if abs(abs(R(i,j)) - 1) < 1e-6
                to_keep(j) = false;
            end
        end
    end
end
    % cleaned data
data_clean = data_stand(:,to_keep);
num_vars = find(to_keep);

% we can try to identify if there are significant shifts
% lets check volatility over time
window_sz = 50;
[nrows, ncols] = size(data_clean);

volati = movstd(data_clean, window_sz,1);
figure('Name','Volatility over time','Color','w');
t = tiledlayout(5,6, 'TileSpacing','compact','Padding','compact');
ax = zeros(1, ncols);

for i = 1:ncols
    ax(i) = nexttile;
    plot(volati(:, i), 'LineWidth', 0.8, 'Color', [0.8500 0.3250 0.0980]);
    title(sprintf('Var %d', i), 'FontSize', 8);
    grid on;
    axis tight;
end

% link all x-axis to zoom
linkaxes(ax, 'x');
xlabel(t, 'Time Index (10s intervals)');

% most "stable" seems to be variable 5
% let see how it correlates with other variables
corr2 = corr(data_clean);
target_corr = corr2(5,:);
other_cols = [1:4, 6:size(data_clean,2)];
corr_vs_5 = target_corr(other_cols);
% check which correlate highly with var5
high_corr = abs(corr_vs_5) >= 0.8;
filt_cols = other_cols(high_corr);
filt_corrs = corr_vs_5(high_corr);
% sort my correlation
[~, sort_i] = sort(abs(filt_corrs));
ranked_cols = filt_cols(sort_i);
ranked_corrs = filt_corrs(sort_i);
% show a table
resu = table(ranked_cols, ranked_corrs,...
    abs(ranked_corrs),'VariableNames',...
    {'Var.i','Correlation','Abs corr.'});
disp(resu); 
% v10:0.998, v11:0.98676, v6:0.847
% v7:0.8451, v3:0.8337,v15:0.8138, v18:0.80474

% residual vector
x_mov_avg = movmean(data_clean, window_sz,1);
residuals = abs(data_clean - x_mov_avg);
mean_residuals = mean(residuals,1);
[~,worst_mean] = max(mean_residuals);
% lets check how often we exceed 4*std
thresh = 4*std(data_clean, 0,1);
faults = residuals > thresh;
count_faults = sum(faults,1); % total flagged meas.
% sort from "cleanest" to least clean
[sort_cnt, rank_i] = sort(count_faults, 'ascend');

turb_health = table(rank_i', sort_cnt',...
    'VariableNames',...
    {'Var.i','No. of faults'});
disp(turb_health); 
% v5, v10, v15,v23 have 0 fault
% the rest have 1

% lets try clustering (hierarchical)
corr_dist = 1 - abs(corr2);
tree = linkage(squareform(corr_dist,'tovector'),'average');
turb_clust = cluster(tree,'maxclust',4);
    % mapping table
clus_map = table((1:26)', turb_clust,...
    'VariableNames',{'Var.i', 'Ass.cluster'});
disp(clus_map);
% the tree plot
figure;
[~,~,lead_ord] = dendrogram(tree, 0,'Orientation','left');
title('Hierarchical tree of the variables');
xlabel('Corr.dist (1-|r|)');
ylabel('Var.i');
grid on;

%% Faulty 3
clc
clearvars
close all

% open the data (1571 x 28)
data = readtable('data.xlsx','Sheet',"No.39WT"); % obs in rows, vars in cols

% check for missing values
missingValues = sum(ismissing(data)); % 28 missing values

% plot the variables
data_arr = table2array(data);
data_stand = zscore(data_arr);
figure('Color','w');
for i = 1:28
    subplot(7,4,i);
    plot(data_stand(:,i),'LineWidth',0.8);
    title(sprintf('Var %d',i),'FontSize',8);
    grid on;
    axis tight;
end

title('Overlay of 28 variables');
grid on;
axis tight;
% check correlation
R = corr(data_stand, 'Rows','pairwise');
[r,c] = find(triu(true(size(R)),1));
values = R(sub2ind(size(R),r,c));
    % sort the correlation
[~,sort_idx] = sort(abs(values),'descend');
r_sorted = r(sort_idx);
c_sorted = c(sort_idx);
values_sorted = values(sort_idx);
to_keep = true(1,28);
for i = 1:28
    if ~to_keep(i)
        % already marked for removal
        continue;
    end
    for j = (i+1):28
        if to_keep(j)
            if abs(abs(R(i,j)) - 1) < 1e-6
                to_keep(j) = false;
            end
        end
    end
end
    % cleaned data
data_clean = data_stand(:,to_keep);
num_vars = find(to_keep);

% we can try to identify if there are significant shifts
% lets check volatility over time
window_sz = 50;
[nrows, ncols] = size(data_clean);

volati = movstd(data_clean, window_sz,1);
figure('Name','Volatility over time','Color','w');
t = tiledlayout(5,6, 'TileSpacing','compact','Padding','compact');
ax = zeros(1, ncols);

for i = 1:ncols
    ax(i) = nexttile;
    plot(volati(:, i), 'LineWidth', 0.8, 'Color', [0.8500 0.3250 0.0980]);
    title(sprintf('Var %d', i), 'FontSize', 8);
    grid on;
    axis tight;
end

% link all x-axis to zoom
linkaxes(ax, 'x');
xlabel(t, 'Time Index (10s intervals)');

% most "stable" seems to be variable 5
% let see how it correlates with other variables
corr2 = corr(data_clean);
target_corr = corr2(5,:);
other_cols = [1:4, 6:size(data_clean,2)];
corr_vs_5 = target_corr(other_cols);
% check which correlate highly with var5
high_corr = abs(corr_vs_5) >= 0.8;
filt_cols = other_cols(high_corr);
filt_corrs = corr_vs_5(high_corr);
% sort my correlation
[~, sort_i] = sort(abs(filt_corrs));
ranked_cols = filt_cols(sort_i);
ranked_corrs = filt_corrs(sort_i);
% show a table
resu = table(ranked_cols, ranked_corrs,...
    abs(ranked_corrs),'VariableNames',...
    {'Var.i','Correlation','Abs corr.'});
disp(resu); 
% v10:0.998, v11:0.98676, v6:0.847
% v7:0.8451, v3:0.8337,v15:0.8138, v18:0.80474

% residual vector
x_mov_avg = movmean(data_clean, window_sz,1);
residuals = abs(data_clean - x_mov_avg);
mean_residuals = mean(residuals,1);
[~,worst_mean] = max(mean_residuals);
% lets check how often we exceed 4*std
thresh = 4*std(data_clean, 0,1);
faults = residuals > thresh;
count_faults = sum(faults,1); % total flagged meas.
% sort from "cleanest" to least clean
[sort_cnt, rank_i] = sort(count_faults, 'ascend');

turb_health = table(rank_i', sort_cnt',...
    'VariableNames',...
    {'Var.i','No. of faults'});
disp(turb_health); 
% v5, v10, v15,v23 have 0 fault
% the rest have 1

% lets try clustering (hierarchical)
corr_dist = 1 - abs(corr2);
tree = linkage(squareform(corr_dist,'tovector'),'average');
turb_clust = cluster(tree,'maxclust',4);
    % mapping table
clus_map = table((1:26)', turb_clust,...
    'VariableNames',{'Var.i', 'Ass.cluster'});
disp(clus_map);
% the tree plot
figure;
[~,~,lead_ord] = dendrogram(tree, 0,'Orientation','left');
title('Hierarchical tree of the variables');
xlabel('Corr.dist (1-|r|)');
ylabel('Var.i');
grid on;
