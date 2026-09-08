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
data = readtable('data.xlsx'); % obs in rows, vars in cols
% DATA variables are not ordered, i.e. probably have to infer the variables
% that are correlated with each other using biplot.



% check for missing values
missingValues = sum(ismissing(data)); % 28 missing values

% Table to matrix and standardizing the data for the PCA
X = table2array(data);
X_mean = mean(X, 1);
X_std  = std(X, 1);
X_standardized = (X - X_mean) ./ X_std;
% X_normalized = normalize(X); % Can also use this

% Computing principal components, 
[loadings, scores, eigen_values, tsquared, explained, mu] = pca(X_standardized, NumComponents=10);

% Computing biplot of the variables
variable_names = {
    'Var1','Var2','Var3','Var4','Var5','Var6','Var7','Var8','Var9','Var10',...
    'Var11','Var12','Var13','Var14','Var15','Var16','Var17','Var18','Var19',...
    'Var20','Var21','Var22','Var23','Var24','Var25','Var26','Var27','Var28'};
biplot(loadings(1:28,2:3), scores= scores(1:28,3:4), VarLabels=variable_names)
% biplot(loadings(:,1:3), scores= scores(:,1:3), VarLabels=variable_names)

% With pc1 and pc2 correlated sets:
% var3, var6, var7, var8, (var4)
% var9, var12, var15, var18
% var5, var10

% With pc2 and pc3 correlated sets:
% var3, var6, var7, var8
% var26, var27, var 28
% var5, var10
% var12, var15, var18, var19

% With pc3 and pc4 correlated sets:
% var26, var27, var 28



% Plotting T^2 values.
figure
plot(tsquared)
title('T^2 Chart')
xlabel('Measurements')
ylabel('T^2 Scores')

% Plotting the explained variance
figure
plot(cumsum(explained) / sum(explained))
title('Explained Variance Plot')
xlabel('Components')
ylabel('Explained Variance Fraction')