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
WT2_missing_values = sum(sum(ismissing(WT2)))
WT3_missing_values = sum(sum(ismissing(WT3)))
WT14_missing_values = sum(sum(ismissing(WT14))) % Var9 has 1 missing
WT39_missing_values = sum(sum(ismissing(WT39)))

% Check measurement and variable sizes
[WT2_rows, WT2_cols] = size(WT2) % 1572×28 - One extra variable compared to WT14 and WT39
[WT3_rows, WT3_cols] = size(WT3) % 699×31 - 4 Extra variables, so needs to be dropped
[WT14_rows, WT14_cols] = size(WT14) % 687×27 - Same amount of variables as in WT39
[WT39_rows, WT39_cols] = size(WT39) % 1406×27 - Same amount of variables as in WT14

%%
% WT2 has  one extra variable (last one) which needs to be dropped, so that
% the data can be compared to WT14 and WT39. WT14 has one missing value,
% which has to be handled. WT3 has 4 extra rows, and since the variables
% are not ordered, we cannot properly identify the variables that are
% connected to the WT2 turbine, so it needs to be dropped. Also, WT2 and
% WT39 have much more samples than WT14, which might be a problem. Some of
% the values in the tables are integers, but most of the data is
% float/double. 
%%
X_WT2 = table2array(WT2);
X_WT14 = table2array(WT14);
X_WT39 = table2array(WT39);

% Replace NaN value with the mean of the previous and next measurements
nan_index = find(isnan(X_WT14(:,9)), 1);
X_WT14(nan_index,9) = (X_WT14(nan_index-1,9) + X_WT14(nan_index+1,9)) / 2;

% Drop last variable of WT2
X_WT2 = X_WT2(:,1:end-1);


% Standardize datasets
X_WT2_scaled = (X_WT2 - mean(X_WT2, 1)) ./ std(X_WT2, 1);
X_WT14_scaled = (X_WT14 - mean(X_WT14, 1)) ./ std(X_WT14, 1);
X_WT39_scaled = (X_WT39 - mean(X_WT39, 1)) ./ std(X_WT39, 1);


variable_names = {
    'Var1','Var2','Var3','Var4','Var5','Var6','Var7','Var8','Var9','Var10',...
    'Var11','Var12','Var13','Var14','Var15','Var16','Var17','Var18','Var19',...
    'Var20','Var21','Var22','Var23','Var24','Var25','Var26','Var27'};


% Computing principal components, 
[loadings_WT2, scores_WT2, eigen_values_WT2, tsquared_WT2, explained_WT2, mu_WT2] = pca(X_WT2_scaled);
[loadings_WT14, scores_WT14, eigen_values_WT14, tsquared_WT14, explained_WT14, mu_WT14] = pca(X_WT14_scaled);
[loadings_WT39, scores_WT39, eigen_values_WT39, tsquared_WT39, explained_WT39, mu_WT39] = pca(X_WT39_scaled);


% Computing biplot of the variables for each WT
figure
subplot(1,3,1)
biplot(loadings_WT2(:,1:2), scores= scores_WT2(:,1:2), VarLabels=variable_names)
title('WT2 PC1 & PC2 biplot')

subplot(1,3,2)
biplot(loadings_WT2(:,2:3), scores= scores_WT2(:,2:3), VarLabels=variable_names)
title('WT2 PC2 & PC3 biplot')

subplot(1,3,3)
biplot(loadings_WT2(:,3:4), scores= scores_WT2(:,3:4), VarLabels=variable_names)
title('WT2 PC3 & PC4 biplot')

figure
subplot(1,3,1)
biplot(loadings_WT14(:,1:2), scores= scores_WT14(:,1:2), VarLabels=variable_names)
title('WT14 PC1 & PC2 biplot')
subplot(1,3,2)
biplot(loadings_WT14(:,2:3), scores= scores_WT14(:,2:3), VarLabels=variable_names)
title('WT14 PC2 & PC3 biplot')
subplot(1,3,3)
biplot(loadings_WT14(:,3:4), scores= scores_WT14(:,3:4), VarLabels=variable_names)
title('WT14 PC3 & PC4 biplot')

figure
subplot(1,3,1)
biplot(loadings_WT39(:,1:2), scores= scores_WT39(:,1:2), VarLabels=variable_names)
title('WT39 PC1 & PC2 biplot')
subplot(1,3,2)
biplot(loadings_WT39(:,2:3), scores= scores_WT39(:,2:3), VarLabels=variable_names)
title('WT39 PC2 & PC3 biplot')
subplot(1,3,3)
biplot(loadings_WT39(:,3:4), scores= scores_WT39(:,3:4), VarLabels=variable_names)
title('WT39 PC3 & PC4 biplot')


% 
% Plotting T^2 values.
figure
subplot(1,3,1)
plot(tsquared_WT2)
xlabel('Measurements')
ylabel('T^2 Scores')
title('WT2 T^2 Chart')
subplot(1,3,2)
plot(tsquared_WT14)
xlabel('Measurements')
ylabel('T^2 Scores')
title('WT14 T^2 Chart')
subplot(1,3,3)
plot(tsquared_WT39)
xlabel('Measurements')
ylabel('T^2 Scores')
title('WT39 T^2 Chart')


% Plotting the explained variance
figure
subplot(1,3,1)
plot(cumsum(explained_WT2) / sum(explained_WT2))
title('WT2 Explained Variance Plot')
xlabel('Components')
ylabel('Explained Variance Fraction')

subplot(1,3,2)
plot(cumsum(explained_WT14) / sum(explained_WT14))
title('WT14 Explained Variance Plot')
xlabel('Components')
ylabel('Explained Variance Fraction')

subplot(1,3,3)
plot(cumsum(explained_WT39) / sum(explained_WT39))
title('WT39 Explained Variance Plot')
xlabel('Components')
ylabel('Explained Variance Fraction')

% Loadings histograms to see the importance of the variables
figure
for i = 1 : 9
    subplot(3, 3, i)
    bar(loadings_WT2(:,i))
    xticks(1:28)
    xticklabels(variable_names)
    title(['WT2 PC',num2str(i),' loadings'])
end

figure
for i = 1 : 9
    subplot(3, 3, i)
    bar(loadings_WT14(:,i))
    xticks(1:28)
    xticklabels(variable_names)
    title(['WT14 PC',num2str(i),' loadings'])
end

figure
for i = 1 : 9
    subplot(3, 3, i)
    bar(loadings_WT39(:,i))
    xticks(1:28)
    xticklabels(variable_names)
    title(['WT39 PC',num2str(i),' loadings'])
end
% 
% % Correlation matrix to see which variables are correlated with each other
% figure
% heatmap(corr(X_standardized))
% xlabel('Var_i')
% ylabel('Var_i')
% title('Correlation matrix')
% colormap('hot') % Change the color map to your liking. All are awful in my opinion

% 
% figure
% [rows, cols] = size(X_standardized);
% 
% for i = 1 : cols
%     subplot(7, 4, i)
%     plot(1:rows, X_standardized(:,i))
%     xlabel('Time')
%     ylabel('Signal')
%     title(['Var',num2str(i)])
% end