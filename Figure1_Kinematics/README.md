# Figure 1 Kinematic Analysis

This folder contains the MATLAB code used for the kinematic analyses associated with Figure 1f and Figure 1h of the manuscript **Sensory Gamma Entrainment Enhances Motor Recovery After Stroke** (Science Advances manuscript aeh9028).

## Author

**Dongsheng Xiao, MD, PhD**  
Queensland Brain Institute, The University of Queensland

## Figure 1f

`compareStrokeMotionLateralityFigure1f.m`

This script compares pre- and post-intervention kinematic measurements after each participant's left/right measurements have been reclassified according to the clinically documented affected side. The clinically affected limb is treated as the more-affected limb and the opposite limb as the less-affected limb.

Default metrics include ROM3D, mean velocity, and mean acceleration for the more-affected and less-affected hands and feet. The script performs paired within-group tests, compares change scores between the 40 Hz and standard-treatment groups, reports the corresponding Group × Time-equivalent statistic for a complete 2 × 2 design, and outputs violin plots and a statistics table.

Example:

```matlab
compareStrokeMotionLateralityFigure1f( ...
    'Kinematic_Laterality_Reanalysis.xlsx', ...
    'Figure1f_laterality_stats.csv', ...
    'Figure1f_laterality_reanalysis.png');
```

## Figure 1h

`plotMotionVsFMA_LateralityFigure1h_v2.m`

This script calculates post/pre kinematic ratios and post/pre Fugl-Meyer motor-score ratios and evaluates their relationships using ordinary least-squares regression and Pearson correlation. It reports Pearson's r, regression slope, 95% confidence interval, and the two-tailed p value for the regression slope.

By default, the four plotted motion measures are ROM3D ratios for the more-affected hand, less-affected hand, more-affected foot, and less-affected foot.

Example:

```matlab
plotMotionVsFMA_LateralityFigure1h_v2( ...
    'Kinematic_Laterality_Reanalysis.xlsx', ...
    'Figure1h_laterality_ratioData.csv', ...
    'Figure1h_laterality_reanalysis_v2.png');
```

## Required workbook structure

The scripts expect `Kinematic_Laterality_Reanalysis.xlsx` with the following sheets.

### `Relabeled Kinematics`

Expected fields include:

- `Patient ID`
- `Group` (`40 Hz` or `Standard`)
- `Time` (`Pre` or `Post`)
- `Affected side`
- `Affected hand ROM3D (m)`
- `Affected hand Mean velocity (m/s)`
- `Affected hand Mean acceleration (m/s²)`
- `Less-affected hand ROM3D (m)`
- `Less-affected hand Mean velocity (m/s)`
- `Less-affected hand Mean acceleration (m/s²)`
- analogous foot variables

### `Laterality Mapping`

Expected fields include:

- `Patient ID`
- `Group`
- `Affected side`
- `FMA Total Pre`
- `FMA Total Post`

If total FMA fields are not present, the Figure 1h script can instead use:

- `FMA-UE Pre`, `FMA-UE Post`
- `FMA-LE Pre`, `FMA-LE Post`

## Data availability

Patient-level study data are not included in this public repository. The code is provided to document and reproduce the analysis workflow when the corresponding authorized dataset is available.
