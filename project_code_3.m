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
Sensor	importance	and	multivariate	models	for	filling	
missing	data.
Calibrate	a	PCA	model	of	the	healthy	turbine,
and	separate	PCA	models	for	the	first 20 
observations of	 the two chosen	 faulty	 turbines.
> Which	are	the sensors	 that give mostdifferent loadings when
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
faults (they	are	developing	faults). What we know about	the	faulty	wind
turbines is	that there	is	an	initial	fault,	and	then they switch at	some
point to normal	operation after	the	fault has been resolved.
%}

%% Code
clc
clearvars
close all

% open the data (1571 x 28)
WT2 = readtable('data.xlsx', Sheet=1); % obs in rows, vars in cols
WT3 = readtable("data.xlsx", Sheet=2);
WT14 = readtable("data.xlsx", Sheet=3);
WT39 = readtable("data.xlsx", Sheet=4);
% DATA variables are not ordered, i.e. probably have to infer the variables
% that are correlated with each other using biplot.


% Check for missing values
WT2_missing_values = sum(sum(ismissing(WT2)));
WT3_missing_values = sum(sum(ismissing(WT3)));
WT14_missing_values = sum(sum(ismissing(WT14))); % Var9 has 1 missing
WT39_missing_values = sum(sum(ismissing(WT39)));

% Check measurement and variable sizes
[WT2_rows, WT2_cols] = size(WT2); % 1572×28 - One extra variable compared to WT14 and WT39
[WT3_rows, WT3_cols] = size(WT3); % 699×31 - 4 Extra variables, so needs to be dropped
[WT14_rows, WT14_cols] = size(WT14); % 687×27 - Same amount of variables as in WT39
[WT39_rows, WT39_cols] = size(WT39); % 1406×27 - Same amount of variables as in WT14


% WT2 has  one extra variable (last one) which needs to be dropped, so that
% the data can be compared to WT14 and WT39. WT14 has one missing value,
% which has to be handled. WT3 has 4 extra rows, and since the variables
% are not ordered, we cannot properly identify the variables that are
% connected to the WT2 turbine, so it needs to be dropped. Also, WT2 and
% WT39 have much more samples than WT14, which might be a problem. Some of
% the values in the tables are integers, but most of the data is
% float/double. 

% Casting tables to arrays and removing index rows
X_WT2 = table2array(WT2);
X_WT2(1,:) = [];
X_WT14 = table2array(WT14);
X_WT14(1,:) = []; 
X_WT39 = table2array(WT39);
X_WT39(1,:) = [];

% Replace NaN value with the mean of the previous and next measurements
nan_index = find(isnan(X_WT14(:,9)), 1);
X_WT14(nan_index,9) = (X_WT14(nan_index-1,9) + X_WT14(nan_index+1,9)) / 2;

% Drop last variable of WT2
X_WT2 = X_WT2(:,1:end-1);

% Checking zero variance variables
WT2_zerovar = var(X_WT2) < 1e-3;
WT14_zerovar = var(X_WT14) < 1e-3;
WT39_zerovar = var(X_WT39) < 1e-3;

% Dropping zero variance variables
X_WT2(:,WT2_zerovar) = [];
X_WT14(:,WT2_zerovar) = [];
X_WT39(:,WT2_zerovar) = [];


% Standardize datasets
X_WT2_scaled = (X_WT2 - mean(X_WT2, 1)) ./ std(X_WT2, 1);
X_WT14_scaled = (X_WT14 - mean(X_WT14, 1)) ./ std(X_WT14, 1);
X_WT39_scaled = (X_WT39 - mean(X_WT39, 1)) ./ std(X_WT39, 1);

variable_names = {
    'Var1','Var2','Var3','Var4','Var5','Var6','Var7','Var8','Var9','Var10',...
    'Var11','Var12','Var13','Var14','Var15','Var16','Var17','Var18','Var19',...
    'Var20','Var21','Var22','Var23','Var24','Var25','Var26','Var27'};

% plot the normalized variables
figure('Color','w');
title('Overlay of 28 variables');
for i = 1:size(X_WT2_scaled,2)
    subplot(7,4,i);
    plot(X_WT2_scaled(:,i),'LineWidth',0.8);
    title(sprintf('Var %d',i),'FontSize',8);
    grid on;
    axis tight;
end
grid on;
axis tight;

% % Correlation matrix to see which variables are correlated with each other
figure
heatmap(corr(X_WT2))
xlabel('Var_i')
ylabel('Var_i')
title('Correlation matrix')
colormap('parula') % Change the color map to your liking. All are awful in my opinion


% PCA COMPUTING
[loadings_WT2, scores_WT2, eigen_values_WT2, tsquared_WT2, explained_WT2, mu_WT2] = pca(X_WT2_scaled);
[loadings_WT14, scores_WT14, eigen_values_WT14, tsquared_WT14, explained_WT14, mu_WT14] = pca(X_WT14_scaled);
[loadings_WT39, scores_WT39, eigen_values_WT39, tsquared_WT39, explained_WT39, mu_WT39] = pca(X_WT39_scaled);


% 20 FIRST OBSERVATIONS on faulty & PCA
fault_WT14_20 = X_WT14_scaled(1:20,:);
fault_WT39_20 = X_WT39_scaled(1:20,:);
% calibrate
[loadings_F_WT14, scoresFault14, ~, ~, explainedFault14, muFault14] = pca(fault_WT14_20);
[loadings_F_WT39, scoresFault39, ~, ~, explainedFault39, muFault39] = pca(fault_WT39_20);
% keep 6 PCs across the turbines
k = 6;
P_WT2 = loadings_WT2(:,1:k);
P_WT14_20 = loadings_F_WT14(:,1:k);
P_WT39_20 = loadings_F_WT39(:,1:k);
% checks the most different sensors
loading_diff1 = abs(P_WT2(:,1) -P_WT14_20(:,1));
loading_diff2 = abs(P_WT2(:,1) -P_WT39_20(:,1));
% take two most different sensors
[~, sorted_sensors] = sort(loading_diff1 + loading_diff2,...
    'descend');
% PLS modelling
tgt_cols = sorted_sensors(1:2); % 1 & 21
X_train = X_WT2_scaled;
X_train(:,tgt_cols) = []; % take out Y
Y_train = X_WT2_scaled(:,tgt_cols);
%{
For	the	healthy	turbine, create	 PLS models	to estimate	the values
of two important sensors.   
%}
N = size(X_train,1); %number of samples
max_lv = 6; % upper limit from PCA
train_size = round(0.5*N);
vali_size = round(0.1*N);
step_size = vali_size;
rmse_crossv = zeros(max_lv,1); % CV RMSE

for lv = 1:max_lv
    vali_err = [];
    % rollign window
    for start_i = 1:step_size:(N-train_size...
            -vali_size+1)
        train_i = start_i : (start_i + train_size+1);
        vali_i = (start_i + train_size) : ...
            (start_i + train_size + vali_size - 1);
        X_tr = X_train(train_i,:);
        Y_tr = Y_train(train_i,:);
        X_va = X_train(vali_i,:);
        Y_va = Y_train(vali_i,:);
        % pls fit
        [~,~,~, ~, BETA] = plsregress(X_tr, Y_tr, lv);
        % prediction on validation portion
        Y_va_pred = [ones(length(vali_i),1), X_va]*BETA;
        % calculate errors
        fold_rmse = sqrt(mean((Y_va - Y_va_pred).^2, 'all'));
        vali_err = [vali_err; fold_rmse];
    end
    rmse_crossv(k) = mean(vali_err);
end
% choose the best number of latent variables
[~, best_nLV] = min(rmse_crossv);
% fit with the best num of lv
[XL, YL, XS, YS, BETA2] =....
    plsregress(X_train,Y_train, best_nLV);
% predict healthy turbine values
Y_train_pred = [ones(N,1), X_train]*BETA;
train_RMSE = sqrt(mean((Y_train- Y_train_pred).^2,1));
% so we got 0.88 rmse on first, 0.42 on 2nd
% now test on a faulty turbine
Y_test_WT14 = X_WT14_scaled(:,tgt_cols);
Y_test_WT39 = X_WT39_scaled(:,tgt_cols);
X_test_WT14 = X_WT14_scaled;
X_test_WT14(:,tgt_cols) = []; % remove Y
X_test_WT39 = X_WT39_scaled;
X_test_WT39(:,tgt_cols) = [];
% predict with healthy model faulty turbine values
Y_test_WT14_pred = [ones(size(X_test_WT14,1),1), X_test_WT14]*BETA;
Y_test_WT39_pred = [ones(size(X_test_WT39,1),1), X_test_WT39]*BETA;
% compute the residuals
res_WT14 = Y_test_WT14  - Y_test_WT14_pred;
res_WT39 = Y_test_WT39 - Y_test_WT39_pred;
% rmses
test_RMSE_WT14 = sqrt(mean((res_WT14).^2,1));
test_RMSE_WT39 = sqrt(mean((res_WT39).^2,1));
% for Wt14: 1.05 and 1.14
% for WT39 1.02 and 1.08
