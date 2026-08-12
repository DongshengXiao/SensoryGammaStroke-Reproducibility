function plotMotionVsFMA_LateralityFigure1h_v2( ...
        xlsxFile, ratioCSV, figFile, metricColumns, showPatientLabels, sameXYScale)
% =========================================================================
% Sensory Gamma Entrainment Enhances Motor Recovery After Stroke
%
% Figure: Figure 1h
% Description: Correlation between laterality-reclassified kinematic
%              improvement and Fugl-Meyer motor improvement.
%
% Author: Dongsheng Xiao, MD, PhD
% Queensland Brain Institute, The University of Queensland
%
% Manuscript: Science Advances, aeh9028
% Year: 2026
%
% This code is provided for reproducibility of the analyses reported in the
% manuscript.
% =========================================================================
%
% Generate a Figure 1h scatter/regression plot using the
% laterality-reclassified kinematic data in:
%
%   Kinematic_Laterality_Reanalysis.xlsx
%
% Main updates in v2:
%   1) Patient ID labels are OFF by default.
%   2) X and Y axes can be forced to the same ratio scale across all panels.
%
% Data source:
%   Sheet 1: "Relabeled Kinematics"
%   Sheet 2: "Laterality Mapping"
%
% Example:
%   plotMotionVsFMA_LateralityFigure1h_v2( ...
%       'Kinematic_Laterality_Reanalysis.xlsx', ...
%       'Figure1h_laterality_ratioData.csv', ...
%       'Figure1h_laterality_reanalysis_v2.png');
%
% Example with patient labels turned on:
%   plotMotionVsFMA_LateralityFigure1h_v2( ...
%       'Kinematic_Laterality_Reanalysis.xlsx', ...
%       'Figure1h_laterality_ratioData.csv', ...
%       'Figure1h_laterality_reanalysis_v2.png', [], true, true);

%% Defaults
if nargin < 1 || isempty(xlsxFile)
    xlsxFile = 'Kinematic_Laterality_Reanalysis.xlsx';
end
if nargin < 2 || isempty(ratioCSV)
    ratioCSV = 'Figure1h_laterality_ratioData.csv';
end
if nargin < 3 || isempty(figFile)
    figFile = 'Figure1h_laterality_reanalysis_v2.png';
end
if nargin < 4 || isempty(metricColumns)
    metricColumns = { ...
        'Affected hand ROM3D (m)', ...
        'Less-affected hand ROM3D (m)', ...
        'Affected foot ROM3D (m)', ...
        'Less-affected foot ROM3D (m)'};
end
if nargin < 5 || isempty(showPatientLabels)
    showPatientLabels = false;
end
if nargin < 6 || isempty(sameXYScale)
    sameXYScale = true;
end

pidField = 'Patient ID';

%% 1. Read tables
M = readtable(xlsxFile, ...
    'Sheet','Relabeled Kinematics', ...
    'PreserveVariableNames',true);

S = readtable(xlsxFile, ...
    'Sheet','Laterality Mapping', ...
    'PreserveVariableNames',true);

M.(pidField) = lower(string(M.(pidField)));
S.(pidField) = lower(string(S.(pidField)));
M.Time = string(M.Time);

%% 2. Split Pre/Post motion rows and align patients
M0 = M(strcmpi(strtrim(M.Time), 'Pre'), :);
M1 = M(strcmpi(strtrim(M.Time), 'Post'), :);

[M0_ids, idx0] = sort(M0.(pidField));
[M1_ids, idx1] = sort(M1.(pidField));

if ~isequal(M0_ids, M1_ids)
    error('Pre and Post patient IDs differ in the Relabeled Kinematics sheet.');
end

M0 = M0(idx0,:);
M1 = M1(idx1,:);

[~, idxS] = sort(S.(pidField));
S = S(idxS,:);

commonIDs = intersect(intersect(M0.(pidField), M1.(pidField)), S.(pidField));
M0 = M0(ismember(M0.(pidField), commonIDs), :);
M1 = M1(ismember(M1.(pidField), commonIDs), :);
S  = S(ismember(S.(pidField), commonIDs), :);

[~, idx0] = sort(M0.(pidField));
[~, idx1] = sort(M1.(pidField));
[~, idxS] = sort(S.(pidField));
M0 = M0(idx0,:);
M1 = M1(idx1,:);
S  = S(idxS,:);

if ~isequal(M0.(pidField), M1.(pidField)) || ~isequal(M0.(pidField), S.(pidField))
    error('Patient IDs could not be aligned across motion and FMA sheets.');
end

%% 3. FMA ratio
if all(ismember({'FMA Total Pre','FMA Total Post'}, S.Properties.VariableNames))
    fmaBefore = S.('FMA Total Pre');
    fmaAfter  = S.('FMA Total Post');
    scaleLabel = 'FMA total motor';
elseif all(ismember({'FMA-UE Pre','FMA-UE Post','FMA-LE Pre','FMA-LE Post'}, S.Properties.VariableNames))
    fmaBefore = S.('FMA-UE Pre') + S.('FMA-LE Pre');
    fmaAfter  = S.('FMA-UE Post') + S.('FMA-LE Post');
    scaleLabel = 'FMA limb';
else
    error('Could not find FMA Total Pre/Post or FMA-UE/FMA-LE Pre/Post columns.');
end

ratioFMA = fmaAfter ./ fmaBefore;
ratioFMA(fmaBefore == 0) = NaN;

%% 4. Validate metric columns
metricColumns = metricColumns(:)';
existsMask = ismember(metricColumns, M0.Properties.VariableNames) & ...
             ismember(metricColumns, M1.Properties.VariableNames);

if any(~existsMask)
    warning('Some requested metric columns were not found and will be skipped:');
    disp(metricColumns(~existsMask)');
end

metricColumns = metricColumns(existsMask);
nMotion = numel(metricColumns);

if nMotion == 0
    error('No valid motion metric columns found.');
end

%% 5. Compute ratios and save ratio table
ratioTbl = table;
ratioTbl.(pidField) = M0.(pidField);
ratioTbl.Group = S.Group;
ratioTbl.('Affected side') = S.('Affected side');
ratioTbl.([scaleLabel '_ratio']) = ratioFMA;

ratioMotion = nan(height(M0), nMotion);

for k = 1:nMotion
    mname = metricColumns{k};
    beforeMotion = M0.(mname);
    afterMotion  = M1.(mname);
    r = afterMotion ./ beforeMotion;
    r(beforeMotion == 0) = NaN;
    ratioMotion(:,k) = r;
    safeName = matlab.lang.makeValidName([mname '_ratio']);
    ratioTbl.(safeName) = r;
end

writetable(ratioTbl, ratioCSV);
fprintf('Ratio table saved to %s\n', ratioCSV);

%% 6. Compute common axis limits
allVals = [ratioMotion(:); ratioFMA(:)];
allVals = allVals(~isnan(allVals) & ~isinf(allVals));

if sameXYScale && ~isempty(allVals)
    limLow = min(allVals);
    limHigh = max(allVals);
    pad = 0.08 * (limHigh - limLow);
    if pad == 0
        pad = 0.1;
    end
    commonLim = [max(0, limLow - pad), limHigh + pad];
    commonLim(1) = min(commonLim(1), 0.8);
    commonLim(2) = max(commonLim(2), 1.2);
else
    commonLim = [];
end

%% 7. Scatter/regression matrix
nCols = min(4, nMotion);
nRows = ceil(nMotion / nCols);

figure('Color','w','Position',[80 80 330*nCols 330*nRows]);
tiledlayout(nRows, nCols, 'TileSpacing','compact', 'Padding','compact');

pal = lines(max(nMotion,7));

Metric = strings(nMotion,1);
N = nan(nMotion,1);
Pearson_r = nan(nMotion,1);
Slope = nan(nMotion,1);
CI_low = nan(nMotion,1);
CI_high = nan(nMotion,1);
P_slope = nan(nMotion,1);

for c = 1:nMotion
    mname = metricColumns{c};
    Metric(c) = string(mname);

    nexttile; hold on;

    x = ratioMotion(:,c);
    y = ratioFMA;
    good = ~isnan(x) & ~isnan(y);

    col = pal(c,:);

    scatter(x(good), y(good), 70, 'filled', ...
        'MarkerFaceColor', col, ...
        'MarkerEdgeColor', 'k', ...
        'MarkerFaceAlpha', .85);

    % Optional patient ID labels. OFF by default because labels can overlap.
    if showPatientLabels
        idsGood = M0.(pidField)(good);
        xGood = x(good);
        yGood = y(good);
        xRange = max(xGood) - min(xGood);
        if xRange == 0 || isnan(xRange)
            xOffset = 0.03;
        else
            xOffset = 0.015 * xRange;
        end
        for ii = 1:numel(idsGood)
            text(xGood(ii) + xOffset, yGood(ii), char(upper(idsGood(ii))), ...
                'FontSize',7, 'Color',[0.25 0.25 0.25], ...
                'Interpreter','none', 'Clipping','on');
        end
    end

    if nnz(good) >= 3
        mdl = fitlm(x(good), y(good));
        xGrid = linspace(min(x(good)), max(x(good)), 200)';
        [yFit, yCI] = predict(mdl, xGrid);
        patch([xGrid; flipud(xGrid)], ...
              [yCI(:,1); flipud(yCI(:,2))], ...
              col, 'EdgeColor','none', 'FaceAlpha',0.15);
        plot(xGrid, yFit, 'Color', col, 'LineWidth',1.7);
        slope = mdl.Coefficients.Estimate(2);
        ci = coefCI(mdl, 0.05);
        ciLo = ci(2,1);
        ciHi = ci(2,2);
        pSlope = mdl.Coefficients.pValue(2);
        [R,~] = corr(x(good), y(good), 'type','Pearson');
        N(c) = nnz(good);
        Pearson_r(c) = R;
        Slope(c) = slope;
        CI_low(c) = ciLo;
        CI_high(c) = ciHi;
        P_slope(c) = pSlope;
    else
        R = NaN; slope = NaN; ciLo = NaN; ciHi = NaN; pSlope = NaN;
    end

    xline(1, ':', 'Color',[0.65 0.65 0.65], 'LineWidth',0.8);
    yline(1, ':', 'Color',[0.65 0.65 0.65], 'LineWidth',0.8);

    if sameXYScale
        xlim(commonLim);
        ylim(commonLim);
        axis square;
    end

    title(sprintf('%s\\newline r = %.2f; slope = %.2f [%.2f, %.2f]\\newline p = %.3g', ...
        cleanMetricLabel(mname), R, slope, ciLo, ciHi, pSlope), ...
        'FontSize',9, 'Interpreter','tex');

    xlabel([cleanMetricLabel(mname) ' ratio'], 'Interpreter','tex');
    ylabel([scaleLabel ' ratio'], 'Interpreter','none');
    box off;
    grid off;
end

sgtitle('After/Before ratio: laterality-reclassified motion metrics vs Fugl-Meyer score', ...
    'FontSize',13, 'FontWeight','bold');

%% 8. Caption
capTxt = sprintf([ ...
    'Figure 1h laterality reanalysis. After/Before ratios of laterality-reclassified ', ...
    '3-D motion metrics are plotted against the Fugl-Meyer motor-score ratio. ', ...
    'Affected limbs denote the clinically affected side; less-affected limbs denote ', ...
    'the opposite side. Each point is one patient. Solid lines show ordinary-least-squares ', ...
    'fits and shaded bands show 95%% confidence intervals. Titles report Pearson r, ', ...
    'regression slope with 95%% CI, and the two-tailed p value for slope ~= 0.']);

annotation(gcf,'textbox',[0.02, 0.00, 0.96, 0.075], ...
    'String', capTxt, ...
    'Interpreter','tex', ...
    'EdgeColor','none', ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','top', ...
    'FontSize',8.5);

%% 9. Save figure and stats
if ~isempty(figFile)
    [~,~,ext] = fileparts(figFile);
    if isempty(ext)
        figFile = [figFile '.png'];
    end
    exportgraphics(gcf, figFile, 'Resolution',300);
    fprintf('Figure saved to %s\n', figFile);
end

statsTbl = table(Metric, N, Pearson_r, Slope, CI_low, CI_high, P_slope, ...
    'VariableNames', {'Metric','N','Pearson_r','Slope','CI_low','CI_high','P_slope'});

statsCSV = replace(ratioCSV, '.csv', '_correlation_stats.csv');
writetable(statsTbl, statsCSV);
disp(statsTbl);
fprintf('Correlation stats saved to %s\n', statsCSV);

end

% =====================================================================
function label = cleanMetricLabel(mname)
label = char(mname);
label = strrep(label, 'Less-affected', 'Less affected');
label = strrep(label, 'Mean velocity', 'Velocity');
label = strrep(label, 'Mean acceleration', 'Acceleration');
label = strrep(label, 'ROM3D', 'ROM3D');
label = strrep(label, ' (m/s²)', ' (m/s^2)');
label = strrep(label, '_', '\\_');
end
