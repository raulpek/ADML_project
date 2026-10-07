% Level A2 requirements (30p)

%{
Sensor	importance	and	multivariate	models	for	filling	
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
faults (they	are	developing	faults). What we know about	the	faulty	wind
turbines is	that there	is	an	initial	fault,	and	then they switch at	some
point to normal	operation after	the	fault has been resolved.
%}

%% Initialization and data importing
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

%% Data pretreatment

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
X_WT14_scaled = (X_WT14 - mean(X_WT2, 1)) ./ std(X_WT2, 1);
X_WT39_scaled = (X_WT39 - mean(X_WT2, 1)) ./ std(X_WT2, 1);


% Variable identifiers for the plots
n_vars = size(X_WT2, 2);
var_labels = arrayfun(@(x) sprintf('Var%d', x), 1:n_vars, 'UniformOutput', false);

%% Visualisation of the pretreated variables and their correlations

% Time-series plot of the normalized variables (Healthy WT2)
figure('Name', 'Pretreated variabes (WT2)', 'Color','w');
title('Overlay of 28 variables');
for i = 1:n_vars
    subplot(5,6,i);
    plot(X_WT2_scaled(:,i),'LineWidth',0.8);
    title(var_labels{i},'FontSize',8);
    grid on;
    axis tight;
end
grid on;
axis tight;

% Correlation matrix
figure('Name', 'Correlation Matrix (WT2)', 'Color', 'w');
corr_matrix = corr(X_WT2);

% Blue-white-red color scale
custom_map = [linspace(0,1,100)', linspace(0,1,100)', ones(100,1); ...
              ones(100,1), linspace(1,0,100)', linspace(1,0,100)'];

heatmap(var_labels, var_labels, corr_matrix, ...
    'Colormap', custom_map, ...
    'ColorLimits', [-1, 1], ...
    'CellLabelColor', 'none');

title('Correlation Matrix - Healthy WT2');

% Select 1 and 2 as interesting variables to observe fault behavior
selected_vars = [1, 2]; 

for v = selected_vars
    figure('Name', sprintf('Variable %d Comparison Across Turbines', v), 'Color', 'w');
    
    plot(X_WT2_scaled(:, v), 'g', 'LineWidth', 1, 'DisplayName', 'WT2 (Healthy)'); hold on;
    plot(X_WT14_scaled(:, v), 'r', 'LineWidth', 1, 'DisplayName', 'WT14 (Faulty)');
    plot(X_WT39_scaled(:, v), 'm', 'LineWidth', 1, 'DisplayName', 'WT39 (Faulty)');
    
    title(sprintf('Behavior of Variable %d Across All Turbines', v));
    xlabel('Observation Index (Time)');
    ylabel('Scaled Value');
    legend('Location', 'best');
    grid on;
end

%% Explorative PCA for the healthy turbine

% PCA COMPUTING
[loadings_WT2, scores_WT2, eigen_values_WT2, tsquared_WT2, explained_WT2, mu_WT2] = pca(X_WT2_scaled);
[loadings_WT14, scores_WT14, eigen_values_WT14, tsquared_WT14, explained_WT14, mu_WT14] = pca(X_WT14_scaled);
[loadings_WT39, scores_WT39, eigen_values_WT39, tsquared_WT39, explained_WT39, mu_WT39] = pca(X_WT39_scaled);

% Scree plot - Explained variance
figure('Name', 'PCA Scree Plot', 'Color', 'w');
pareto(explained_WT2);
xlabel('Principal Component');
ylabel('Variance Explained (%)');
title('Scree Plot - WT2 Healthy Turbine');

% Biplot for PC1 and PC2
figure('Name', 'PCA Biplot', 'Color', 'w');
biplot(loadings_WT2(:,1:2), ...
    'Scores', scores_WT2(:,1:2), ...
    'VarLabels', var_labels);
title('PCA Biplot (PC1 vs PC2) - WT2');

% Loading plot for PC1 and PC2
figure('Name', 'PCA Loadings', 'Color', 'w');
plot(loadings_WT2(:,1), loadings_WT2(:,2), 'bo', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
xlabel('PC1 Loadings'); 
ylabel('PC2 Loadings');
title('PCA Loading Plot (PC1 vs PC2) - WT2');
grid on;

% Normalized PCA biplot with time trajectory
% Normalize scores to unit variance for equal scaling with loadings
scores_WT2_norm = scores_WT2(:, 1:2) ./ std(scores_WT2(:, 1:2));

figure('Name', 'Normalized PCA Biplot', 'Color', 'w');

% Plot observations with a color gradient representing time progression
num_obs = size(scores_WT2_norm, 1);
scatter(scores_WT2_norm(:,1), scores_WT2_norm(:,2), 15, 1:num_obs, 'filled'); 
colormap(jet);
c = colorbar;
c.Label.String = 'Observation Index (Time)';
hold on;

% Plot loading vectors overlaid on the same normalized scale
scaling_factor = 2; % Adjust visually if needed to match point spread
quiver(zeros(n_vars, 1), zeros(n_vars, 1), ...
    loadings_WT2(:,1)*scaling_factor, loadings_WT2(:,2)*scaling_factor, ...
    0, 'r', 'LineWidth', 1.2, 'MaxHeadSize', 0.5);

% Add labels for variables
text(loadings_WT2(:,1)*scaling_factor*1.1, loadings_WT2(:,2)*scaling_factor*1.1, ...
    var_labels, 'Color', 'r', 'FontSize', 8, 'FontWeight', 'bold');

xlabel('Normalized PC1 Scores');
ylabel('Normalized PC2 Scores');
title('Normalized PCA Biplot with Time Trajectory (WT2)');
grid on;


% Project faulty turbines onto healthy WT2 PC axes
scores_WT14_projected = X_WT14_scaled * loadings_WT2(:, 1:2);
scores_WT39_projected = X_WT39_scaled * loadings_WT2(:, 1:2);

figure('Name', 'Faulty Turbines Projected on Healthy PC Axes', 'Color', 'w');

% Plot Healthy Baseline
plot(scores_WT2(:,1), scores_WT2(:,2), 'g.', 'MarkerSize', 8, 'DisplayName', 'WT2 (Healthy Baseline)'); hold on;

% Plot Projected Faulty Turbines
plot(scores_WT14_projected(:,1), scores_WT14_projected(:,2), 'r-', 'LineWidth', 1, 'DisplayName', 'WT14 Trajectory');
plot(scores_WT39_projected(:,1), scores_WT39_projected(:,2), 'm-', 'LineWidth', 1, 'DisplayName', 'WT39 Trajectory');

% Highlight start points (Observation 1)
plot(scores_WT14_projected(1,1), scores_WT14_projected(1,2), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'WT14 Start');
plot(scores_WT39_projected(1,1), scores_WT39_projected(1,2), 'mo', 'MarkerFaceColor', 'm', 'MarkerSize', 8, 'DisplayName', 'WT39 Start');

xlabel('PC1 (Healthy Space)');
ylabel('PC2 (Healthy Space)');
title('Projection of Faulty Turbines onto Healthy PCA Space');
legend('Location', 'best');
grid on;

%% PCA calibration and sensor selection

% 20 FIRST OBSERVATIONS on faulty & PCA
fault_WT14_20 = X_WT14_scaled(1:20,:);
fault_WT39_20 = X_WT39_scaled(1:20,:);

% Calibrate PCA-models for the faulty turbines
[loadings_F_WT14, scoresFault14, ~, ~, explainedFault14, muFault14] = pca(fault_WT14_20);
[loadings_F_WT39, scoresFault39, ~, ~, explainedFault39, muFault39] = pca(fault_WT39_20);

% Keep 6 PCs across the turbines
k = 6;
P_WT2 = loadings_WT2(:,1:k);
P_WT14_20 = loadings_F_WT14(:,1:k);
P_WT39_20 = loadings_F_WT39(:,1:k);

% Checking most different sensors across all 6 components
diff1_matrix = min(abs(P_WT2(:,1) - P_WT14_20(:,1)), abs(P_WT2(:,1) + P_WT14_20(:,1)));
diff2_matrix = min(abs(P_WT2(:,1) - P_WT39_20(:,1)), abs(P_WT2(:,1) + P_WT39_20(:,1)));

loading_diff1 = sum(diff1_matrix, 2);
loading_diff2 = sum(diff2_matrix, 2);

% Take two most different sensors as the target variables Y
[~, sorted_sensors] = sort(loading_diff1 + loading_diff2,...
    'descend');
tgt_cols = sorted_sensors(1:2); % Most different sensors: 1 & 3

%% PLS modeling and  cross-validation

% PLS modeling
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
q2_crossv = zeros(max_lv, 1); % CV Q^2

for lv = 1:max_lv
    vali_err = [];
    ss_res_vec = []; % residual sum of squares
    ss_tot_vec = []; % total sum of squares

    % rolling window
    for start_i = 1:step_size:(N-train_size...
            -vali_size+1)
        train_i = start_i : (start_i + train_size - 1);
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

        % calculate errors and square sums
        res = Y_va - Y_va_pred;
        fold_rmse = sqrt(mean((Y_va - Y_va_pred).^2, 'all'));
        vali_err = [vali_err; fold_rmse];

        % For Q2 calculation (comparing to training window's average)
        ss_res_vec = [ss_res_vec; sum(res.^2, 'all')];
        ss_tot_vec = [ss_tot_vec; sum((Y_va - mean(Y_tr, 1)).^2, 'all')];
    end
    % Mean RMSE_CV and Q^2 for the amount of LVs
    rmse_crossv(lv) = mean(vali_err);
    q2_crossv(lv)   = 1 - (sum(ss_res_vec) / sum(ss_tot_vec));
end
% choose the best number of latent variables
[~, best_nLV] = min(rmse_crossv);

%% PLS model diagnostics plots (RMSECV and Q^2)
% Determining the components to x-axle
lvs = 1:max_lv;

figure('Name', 'PLS Model Diagnostics', 'Color', [1 1 1], 'Position', [100, 100, 1000, 400]);

% Left plot: RMSECV
subplot(1, 2, 1);
plot(lvs, rmse_crossv, '-o', 'LineWidth', 2, 'MarkerSize', 6, 'Color', [0 0.4470 0.7410]);
hold on;
% Highlighting the chosen point
plot(best_nLV, rmse_crossv(best_nLV), 'rs', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'r');
xline(best_nLV, '--k', 'LineWidth', 1);

xlabel('Number of latent variables (LV)', 'FontSize', 11);
ylabel('RMSECV', 'FontSize', 11);
title('CV error (RMSECV)', 'FontSize', 12);
xticks(lvs);
grid on;
legend('RMSECV', sprintf('Chosen nLV = %d', best_nLV), 'Location', 'northeast');

% Right plot: Q^2
subplot(1, 2, 2);
plot(lvs, q2_crossv, '-s', 'LineWidth', 2, 'MarkerSize', 6, 'Color', [0.8500 0.3250 0.0980]);
hold on;
% Highlighting the chosen point
plot(best_nLV, q2_crossv(best_nLV), 'rs', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'r');
xline(best_nLV, '--k', 'LineWidth', 1);

xlabel('Number of latent variables (LV)', 'FontSize', 11);
ylabel('Q^2', 'FontSize', 11);
title('Predictive ability (Q^2)', 'FontSize', 12);
xticks(lvs);
grid on;
legend('Q^2', sprintf('Chosen nLV = %d', best_nLV), 'Location', 'southeast');

%% Final model fit and testing with faulty turbine data

% fit with the best num of lv
[XL, YL, XS, YS, BETA2] =....
    plsregress(X_train,Y_train, best_nLV);

% predict healthy turbine values
Y_train_pred = [ones(N,1), X_train]*BETA2;
train_RMSE = sqrt(mean((Y_train- Y_train_pred).^2,1));

% so we got 0.88 rmse on first, 0.46 on 2nd
% now test on a faulty turbine
Y_test_WT14 = X_WT14_scaled(:,tgt_cols);
Y_test_WT39 = X_WT39_scaled(:,tgt_cols);
X_test_WT14 = X_WT14_scaled;
X_test_WT14(:,tgt_cols) = []; % remove Y
X_test_WT39 = X_WT39_scaled;
X_test_WT39(:,tgt_cols) = [];

% predict with healthy model faulty turbine values
Y_test_WT14_pred = [ones(size(X_test_WT14,1),1), X_test_WT14]*BETA2;
Y_test_WT39_pred = [ones(size(X_test_WT39,1),1), X_test_WT39]*BETA2;

% compute the residuals
res_WT14 = Y_test_WT14  - Y_test_WT14_pred;
res_WT39 = Y_test_WT39 - Y_test_WT39_pred;

% rmses
test_RMSE_WT14 = sqrt(mean((res_WT14).^2,1));
test_RMSE_WT39 = sqrt(mean((res_WT39).^2,1));

% for Wt14: 76.8 and 1600.1
% for WT39 94.1 and 1897.4

%% Prediction and control chart visualizations
% Plot of predictions vs actual values
% Graph for sensor 1
figure('Name', 'Sensor 1 predictions across turbines');

% Healthy turbine (WT2)
subplot(3,1,1);
plot(Y_train(:,1), 'k', 'LineWidth', 1); hold on;
plot(Y_train_pred(:,1), 'r--', 'LineWidth', 1);
title('Healthy turbine (WT2) - Sensor 1');
ylabel('Scaled value'); legend('Truth', 'Prediction'); grid on;

% Faulty turbine (WT14)
subplot(3,1,2);
plot(Y_test_WT14(:,1), 'k', 'LineWidth', 1); hold on;
plot(Y_test_WT14_pred(:,1), 'r--', 'LineWidth', 1);
title('Faulty turbine (WT14) - Sensor 1');
ylabel('Scaled value'); grid on;

% Faulty turbine 2 (WT39)
subplot(3,1,3);
plot(Y_test_WT39(:,1), 'k', 'LineWidth', 1); hold on;
plot(Y_test_WT39_pred(:,1), 'r--', 'LineWidth', 1);
title('Faulty turbine (WT39) - Sensor 1');
xlabel('Time / Observation-index'); ylabel('Scaled value'); grid on;

% Residual plot / Control chart
figure('Name', 'Residual Analysis');

% Calculating the residuals also for the training data
res_train = Y_train - Y_train_pred;

% Statistical threshold limit (3*std here for the healthy data)
times_std = 3;
threshold_s1 = times_std * std(res_train(:,1));

plot(res_train(:,1), 'g', 'DisplayName', 'WT2 (Healthy)'); hold on;
plot(res_WT14(:,1), 'r', 'DisplayName', 'WT14 (Faulty)');
plot(res_WT39(:,1), 'm', 'DisplayName', 'WT39 (Faulty)');

% Plotting the alarm limits (dashed lines)
yline(threshold_s1, 'k--', '3\sigma limits', 'LineWidth', 1.5, 'HandleVisibility', 'off');
yline(-threshold_s1, 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');

title('Residuals (Sensor 1) and fault detection threshold');
xlabel('Observation-index'); ylabel('Residual');
legend('Location', 'best'); grid on;

disp('Healthy WT2 Train RMSE (Sensor 1 & Sensor 2):');
disp(train_RMSE);

disp('Faulty WT14 Test RMSE (Sensor 1 & Sensor 2):');
disp(test_RMSE_WT14);

disp('Faulty WT39 Test RMSE (Sensor 1 & Sensor 2):');
disp(test_RMSE_WT39);

%{
We get good regression performance for the healthy turbine (WT2),
especially for Sensor 2 (RMSE = 0.4607).

On the faulty turbines, the regression performance degrades
significantly. For Sensor 2, the RMSE increases from 0.4607 to 76.8389 on WT14
and to 1897.4158 on WT39.

Conclusion: The PLS model trained on healthy baseline data is unable to
maintain its regression performance on faulty turbines, demonstrating
that the learned physical relationship between sensors breaks down during a fault.
%}