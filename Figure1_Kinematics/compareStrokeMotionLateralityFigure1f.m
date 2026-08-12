function compareStrokeMotionLateralityFigure1f( ...
    xlsxFile, outStats, figFile, metricColumns)
% =========================================================================
% Sensory Gamma Entrainment Enhances Motor Recovery After Stroke
%
% Figure: Figure 1f
% Description: Laterality-reclassified human kinematic analysis and
%              visualization for clinically more-affected and less-affected
%              limbs.
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
% Generate a Figure 1f-style violin plot using the laterality-reclassified
% kinematic data in Kinematic_Laterality_Reanalysis.xlsx.
%
% Data source:
%   Sheet: "Relabeled Kinematics"
%
% Expected columns:
%   Patient ID
%   Group                  -> "40 Hz" or "Standard"
%   Time                   -> "Pre" or "Post"
%   Affected side
%   Affected hand ROM3D (m)
%   Less-affected hand ROM3D (m)
%   ...
%
% The figure compares:
%   Control Pre/Post on the left
%   40 Hz Pre/Post on the right
%
% The between-group p value is calculated on change scores:
%   delta = Post - Pre
% which is equivalent to the Group x Time interaction for a 2 x 2 design
% with complete paired observations.
%
% Example:
%   compareStrokeMotionLateralityFigure1f( ...
%       'Kinematic_Laterality_Reanalysis.xlsx', ...
%       'Figure1f_laterality_stats.csv', ...
%       'Figure1f_laterality_reanalysis.png');

if nargin < 1 || isempty(xlsxFile)
    xlsxFile = 'Kinematic_Laterality_Reanalysis.xlsx';
end
if nargin < 2 || isempty(outStats)
    outStats = 'Figure1f_laterality_stats.csv';
end
if nargin < 3 || isempty(figFile)
    figFile = 'Figure1f_laterality_reanalysis.png';
end

%% 1. Load laterality-reclassified table
T = readtable(xlsxFile, ...
    'Sheet','Relabeled Kinematics', ...
    'PreserveVariableNames',true);

% Standardize key columns as strings
patientCol = 'Patient ID';
T.(patientCol) = string(T.(patientCol));
T.Group = string(T.Group);
T.Time = string(T.Time);

%% 2. Default metric list
% This default focuses on the Figure 1f-style kinematic metrics:
% ROM3D, velocity and acceleration for affected/less-affected hands/feet.
if nargin < 4 || isempty(metricColumns)
    metricColumns = { ...
        'Affected hand ROM3D (m)', ...
        'Affected hand Mean velocity (m/s)', ...
        'Affected hand Mean acceleration (m/s²)', ...
        'Less-affected hand ROM3D (m)', ...
        'Less-affected hand Mean velocity (m/s)', ...
        'Less-affected hand Mean acceleration (m/s²)', ...
        'Affected foot ROM3D (m)', ...
        'Affected foot Mean velocity (m/s)', ...
        'Affected foot Mean acceleration (m/s²)', ...
        'Less-affected foot ROM3D (m)', ...
        'Less-affected foot Mean velocity (m/s)', ...
        'Less-affected foot Mean acceleration (m/s²)'};
end

% Keep only columns that exist in the workbook
metricColumns = metricColumns(:)';
existsMask = ismember(metricColumns, T.Properties.VariableNames);
if any(~existsMask)
    warning('Some requested metric columns were not found and will be skipped:');
    disp(metricColumns(~existsMask)');
end
metricColumns = metricColumns(existsMask);

N = numel(metricColumns);
if N == 0
    error('No valid metric columns found.');
end

%% 3. Prepare statistics table
Metric            = strings(N,1);
nStim             = nan(N,1);
nControl          = nan(N,1);
meanDeltaStim     = nan(N,1);
meanDeltaControl  = nan(N,1);
pWithinStim       = nan(N,1);
pWithinControl    = nan(N,1);
F_GroupTime       = nan(N,1);
df_GroupTime      = nan(N,1);
pGroupTime        = nan(N,1);
pExactPermutation = nan(N,1);
hedgesG_between   = nan(N,1);

%% 4. Colours
cStimBefore = [0.30 0.60 0.80];   % blue
cStimAfter  = [0.90 0.45 0.15];   % orange
cCtrlBefore = [0.50 0.50 0.50];   % grey
cCtrlAfter  = [0.60 0.20 0.20];   % dark red

%% 5. Figure layout
nCols = 3;
nRows = ceil(N / nCols);

figure('Color','w','Position',[80 80 320*nCols 260*nRows]);
tiledlayout(nRows, nCols, 'TileSpacing','compact', 'Padding','compact');

hLegend = gobjects(1,4);

for k = 1:N
    mname = metricColumns{k};
    Metric(k) = string(mname);

    % Extract paired vectors for each group
    [idsS, xsPre, xsPost] = getPairedGroupValues(T, "40 Hz", mname, patientCol);
    [idsC, xcPre, xcPost] = getPairedGroupValues(T, "Standard", mname, patientCol);

    % Drop NaN pairs
    maskS = ~isnan(xsPre) & ~isnan(xsPost);
    maskC = ~isnan(xcPre) & ~isnan(xcPost);

    xsPre = xsPre(maskS); xsPost = xsPost(maskS);
    xcPre = xcPre(maskC); xcPost = xcPost(maskC);
    idsS = idsS(maskS);
    idsC = idsC(maskC);

    dS = xsPost - xsPre;
    dC = xcPost - xcPre;

    nStim(k) = numel(dS);
    nControl(k) = numel(dC);
    meanDeltaStim(k) = mean(dS,'omitnan');
    meanDeltaControl(k) = mean(dC,'omitnan');

    % Within-group paired tests
    if numel(dS) >= 2
        [~, pWithinStim(k)] = ttest(xsPost, xsPre);
    end
    if numel(dC) >= 2
        [~, pWithinControl(k)] = ttest(xcPost, xcPre);
    end

    % Between-group comparison of change scores: Group x Time interaction
    if numel(dS) >= 2 && numel(dC) >= 2
        [~, pGroupTime(k), ~, statsDelta] = ttest2(dS, dC);
        F_GroupTime(k) = statsDelta.tstat^2;
        df_GroupTime(k) = statsDelta.df;

        nS = numel(dS);
        nC = numel(dC);
        pooledSD = sqrt(((nS-1)*var(dS,'omitnan') + ...
                         (nC-1)*var(dC,'omitnan')) / (nS+nC-2));
        cohenD = (mean(dS,'omitnan') - mean(dC,'omitnan')) / pooledSD;
        hedgesG_between(k) = cohenD * (1 - 3/(4*(nS+nC-2)-1));

        pExactPermutation(k) = exactPermutationP(dS, dC);
    end

    %% Plot
    nexttile; hold on;

    % Control on left, 40 Hz stimulation on right
    xCB = -0.45;  xCA = -0.15;
    xSB =  0.15;  xSA =  0.45;

    if k == 1
        hLegend(1) = quickViolin(xcPre,  xCB, cCtrlBefore);
        hLegend(2) = quickViolin(xcPost, xCA, cCtrlAfter);
        hLegend(3) = quickViolin(xsPre,  xSB, cStimBefore);
        hLegend(4) = quickViolin(xsPost, xSA, cStimAfter);
    else
        quickViolin(xcPre,  xCB, cCtrlBefore);
        quickViolin(xcPost, xCA, cCtrlAfter);
        quickViolin(xsPre,  xSB, cStimBefore);
        quickViolin(xsPost, xSA, cStimAfter);
    end

    % Paired connectors
    for i = 1:numel(xcPre)
        plot([xCB xCA], [xcPre(i) xcPost(i)], '-', ...
            'Color',[0.65 0.65 0.65], 'LineWidth',0.7);
    end
    for i = 1:numel(xsPre)
        plot([xSB xSA], [xsPre(i) xsPost(i)], '-', ...
            'Color',[0.65 0.65 0.65], 'LineWidth',0.7);
    end

    % Raw points
    scatter(repmat(xCB,numel(xcPre),1),  xcPre,  18, 'k', 'filled', ...
        'MarkerFaceAlpha',0.45, 'MarkerEdgeAlpha',0.45);
    scatter(repmat(xCA,numel(xcPost),1), xcPost, 18, 'k', 'filled', ...
        'MarkerFaceAlpha',0.45, 'MarkerEdgeAlpha',0.45);
    scatter(repmat(xSB,numel(xsPre),1),  xsPre,  18, 'k', 'filled', ...
        'MarkerFaceAlpha',0.45, 'MarkerEdgeAlpha',0.45);
    scatter(repmat(xSA,numel(xsPost),1), xsPost, 18, 'k', 'filled', ...
        'MarkerFaceAlpha',0.45, 'MarkerEdgeAlpha',0.45);

    xline(0, ':', 'Color',[0.7 0.7 0.7]);

    title(sprintf('%s\np_{40Hz}=%.3g  p_{Ctrl}=%.3g  p_{GxT}=%.3g', ...
        cleanMetricLabel(mname), ...
        pWithinStim(k), pWithinControl(k), pGroupTime(k)), ...
        'FontSize',8.5, 'Interpreter','tex');

    xlim([-0.65 0.65]);
    xticks([xCB xCA xSB xSA]);
    xticklabels({'C-Pre','C-Post','40Hz-Pre','40Hz-Post'});
    xtickangle(30);
    box off;
    grid off;
end

sgtitle('Figure 1f laterality reanalysis: affected vs less-affected limbs', ...
    'FontSize',13, 'FontWeight','bold');

lgd = legend(hLegend, {'Control Pre','Control Post','40 Hz Pre','40 Hz Post'}, ...
    'Location','bestoutside');
lgd.Box = 'off';

%% 6. Save figure
if ~isempty(figFile)
    [~,~,ext] = fileparts(figFile);
    if isempty(ext)
        figFile = [figFile '.png'];
    end
    exportgraphics(gcf, figFile, 'Resolution',300);
    fprintf('\nFigure saved to %s\n', figFile);
end

%% 7. Save statistics
statsTbl = table(Metric, nStim, nControl, ...
    meanDeltaStim, meanDeltaControl, ...
    pWithinStim, pWithinControl, ...
    F_GroupTime, df_GroupTime, pGroupTime, ...
    pExactPermutation, hedgesG_between, ...
    'VariableNames', {'Metric','nStim','nControl', ...
    'meanDeltaStim','meanDeltaControl', ...
    'pWithinStim','pWithinControl', ...
    'F_GroupTime','df_GroupTime','pGroupTime', ...
    'pExactPermutation','hedgesG_between'});

writetable(statsTbl, outStats);
disp(statsTbl);
fprintf('\nStats saved to %s\n', outStats);

end

% =====================================================================
function [ids, preVals, postVals] = getPairedGroupValues(T, groupName, metricName, patientCol)

groupMask = strcmpi(strtrim(T.Group), strtrim(groupName));
Tg = T(groupMask,:);

preMask  = strcmpi(strtrim(Tg.Time), "Pre");
postMask = strcmpi(strtrim(Tg.Time), "Post");

Tpre = Tg(preMask,:);
Tpost = Tg(postMask,:);

[idsPre, idxPre] = sort(Tpre.(patientCol));
[idsPost, idxPost] = sort(Tpost.(patientCol));

if ~isequal(idsPre, idsPost)
    error('Patient IDs differ between Pre and Post for group %s.', groupName);
end

Tpre = Tpre(idxPre,:);
Tpost = Tpost(idxPost,:);

ids = idsPre;
preVals = Tpre.(metricName);
postVals = Tpost.(metricName);

end

% =====================================================================
function p = exactPermutationP(dS, dC)
% Exact two-sided permutation test for the difference in mean change.
% Suitable for the current small sample size. If the number of possible
% label assignments is very large, the function falls back to random
% permutations.

dS = dS(:);
dC = dC(:);
allD = [dS; dC];

nS = numel(dS);
nTotal = numel(allD);

obs = mean(dS,'omitnan') - mean(dC,'omitnan');

nComb = nchoosek(nTotal, nS);
maxExact = 50000;

if nComb <= maxExact
    combs = nchoosek(1:nTotal, nS);
    diffs = nan(size(combs,1),1);

    for ii = 1:size(combs,1)
        idxS = false(nTotal,1);
        idxS(combs(ii,:)) = true;
        diffs(ii) = mean(allD(idxS),'omitnan') - mean(allD(~idxS),'omitnan');
    end
else
    nPerm = 10000;
    diffs = nan(nPerm,1);
    for ii = 1:nPerm
        permIdx = randperm(nTotal);
        idxS = false(nTotal,1);
        idxS(permIdx(1:nS)) = true;
        diffs(ii) = mean(allD(idxS),'omitnan') - mean(allD(~idxS),'omitnan');
    end
end

p = mean(abs(diffs) >= abs(obs));

end

% =====================================================================
function h = quickViolin(data, xShift, rgb)
% quickViolin: compact violin plot for small samples.

data = data(:);
data = data(~isnan(data));

if isempty(data)
    h = gobjects(1);
    return
end

if numel(unique(data)) < 2
    y = linspace(data(1)-0.01, data(1)+0.01, 40);
    f = ones(size(y)) * 0.05;
else
    [f,y] = ksdensity(data, 'NumPoints',160);
    if max(f) > 0
        f = f ./ max(f) * 0.12;
    else
        f = f * 0 + 0.05;
    end
end

X = [xShift - f, fliplr(xShift + f)];
Y = [y,          fliplr(y)];

h = patch('XData',X, 'YData',Y, ...
          'FaceColor',rgb, 'EdgeColor','none', 'FaceAlpha',0.35);

med = median(data);
p25 = prctile(data,25);
p75 = prctile(data,75);

plot([xShift-0.08 xShift+0.08], [med med], 'k-', 'LineWidth',1.3);
plot([xShift xShift], [p25 p75], 'k-', 'LineWidth',1.3);

end

% =====================================================================
function label = cleanMetricLabel(mname)
label = char(mname);
label = strrep(label, 'Less-affected', 'Less affected');
label = strrep(label, 'Mean velocity', 'Velocity');
label = strrep(label, 'Mean acceleration', 'Acceleration');
label = strrep(label, 'ROM3D', 'ROM3D');
label = strrep(label, '_', '\_');
label = strrep(label, '²', '^2');
end
