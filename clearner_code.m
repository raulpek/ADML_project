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
compared to	the	healthy	turbine?

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
sheetNames = ["No.2WT","No.3","No.14WT","No.39WT"];
data = readtable('data.xlsx','Sheet',sheetNames(1)); % obs in rows, vars in cols

% check for missing values
missingValues = sum(ismissing(data));
missing_summ = table(data.Properties.VariableNames',...
    missingValues',...,
    'VariableNames',{'Variable','Missing values'});
disp(missing_summ); % no missing values
% store the data
data_arr = table2array(data);
data_stand = zscore(data_arr); % normalize the data
% plot the normalized variables
figure('Color','w');
title('Overlay of 28 variables');
for i = 1:28
    subplot(7,4,i);
    plot(data_stand(:,i),'LineWidth',0.8);
    title(sprintf('Var %d',i),'FontSize',8);
    grid on;
    axis tight;
end
grid on;
axis tight;
% check correlation between variables
R = corr(data_stand, 'Rows','pairwise');
num_cols = size(data_stand,2);
to_keep = true(1,num_cols);
for i = 1:num_cols
    if ~to_keep(i)
        % already marked for removal
        continue;
    end
    for j = (i+1):num_cols
        if to_keep(j) && abs(abs(R(i,j)) - 1) < 1e-6
            % drop the variable
            to_keep(j) = false; 
        end
    end
end
    % cleaned data
data_clean = data_stand(:,to_keep);
num_vars_kept = find(to_keep);
new_no_cols = length(num_vars_kept);
% show correlation heatmap
figure;
heatmap(R,'Colormap',jet,'ColorLimits',[-1,1]);
title('Variable correlation');
xlabel('Variable index');
ylabel('Variable index');

% we can try to identify if there are significant shifts
% lets check volatility over time
window_sz = 50;
volati = movstd(data_clean, window_sz,1);
figure('Name','Volatility over time','Color','w');
t = tiledlayout(5,6, 'TileSpacing','compact','Padding','compact');
ax = zeros(1, new_no_cols);

for i = 1:new_no_cols
    ax(i) = nexttile;
    plot(volati(:, i), 'LineWidth', 0.8, 'Color', [0.8500 0.3250 0.0980]);
    title(sprintf('Var %d', i), 'FontSize', 8);
    grid on;
    axis tight;
end

% link all x-axis to zoom
linkaxes(ax, 'x');
xlabel(t, 'Time Index (10s intervals)');
% PCA
[coeff, score, latent, ~, explained] = pca(data_clean,'Centered',false);
explained_pc1 = explained(1); % PC1
explained_pc2 = explained(2); % PC2

varNames = data.Properties.VariableNames(to_keep);
% and loading
figure('Name','PCA Loading (PC1,PC2)','Color','w');
quiver(zeros(length(varNames),1), zeros(length(varNames),...
    1),coeff(:,1), coeff(:,2),0, 'LineWidth',1.3,...
    'Color','r');
hold on;
    % labels per arrow
for i = 1:length(varNames)
    text(coeff(i,1)*1.2, coeff(i,2)*1,2,...
       varNames{i}, 'Fontsize',6,...
       'Interpreter','none');
end
xlabel(sprintf('PC1 Loading _ %.1f%% Variance', explained_pc1));
ylabel(sprintf('PC2 Loading _ %.1f%% Variance', explained_pc2));
grid on;
axis equal;
xlim([-1,1]);
ylim([-1,1]);
hold off;
% PCA biplot
figure('Name','PCA Biplot','Color','w');
biplot(coeff(:,1:2),...
    'Scores',score(:,1:2),...
    'VarLabels',varNames);
title('PCA Biplot (PC1,PC2)');
xlabel(sprintf('PC1 Loading _ %.1f%% Variance', explained_pc1));
ylabel(sprintf('PC2 Loading _ %.1f%% Variance', explained_pc2));
grid on;
fprintf("Total explained variance by PC1 and PC2 %.1f%% \n\n",(explained_pc1 + explained_pc2));
% 70.4% so let's do cumulative energy plot
cumsum_expl = cumsum(explained);
figure('Name','Cumulative energy plot','Color','w');
plot(cumsum_expl, '-*','LineWidth',1.2, 'Color','g',...
    'MarkerFaceColor','g','MarkerSize',3);
xlabel('Number of PCs(k)');
ylabel('Cumulative Energy (%)');
title('Cumulative energy plot');
ylim([0,105]);
grid on;

% residual vector, check it also
x_mov_avg = movmean(data_clean, window_sz,1);
residuals = abs(data_clean - x_mov_avg);
mean_residuals = mean(residuals,1);
% lets check how often we exceed 4*std
thresh = 4*std(residuals, 0,1);
faults = residuals > thresh;
count_faults = sum(faults,1); % total faulty 
% sort from "cleanest" to least clean
[sort_faults, rank_j] = sort(count_faults,'ascend');
match_residuals = mean_residuals(rank_j)';
turb_health = table(varNames(rank_j)',...
    sort_faults',...
    match_residuals,...
    'VariableNames',...
    {'Variable','No. of faults (4*sigma)', 'Avg_Residuals'});
disp("Data 'cleanliness'");
disp(turb_health);

% Subplot for the PDF
figure
subplot(1, 2, 1)
biplot(coeff(:,1:2),...
    'Scores',score(:,1:2),...
    'VarLabels',varNames);
title('PCA Biplot (PC1,PC2)');
xlabel(sprintf('PC1 Loading _ %.1f%% Variance', explained_pc1));
ylabel(sprintf('PC2 Loading _ %.1f%% Variance', explained_pc2));
grid on;

subplot(1, 2, 2)
heatmap(R,'Colormap',jet,'ColorLimits',[-1,1]);
title('Variable correlation');
xlabel('Variable index');
ylabel('Variable index');