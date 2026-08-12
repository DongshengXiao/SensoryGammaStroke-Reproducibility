# SensoryGammaStroke-Reproducibility

Reproducibility code for the human kinematic analyses reported in the manuscript:

**Sensory Gamma Entrainment Enhances Motor Recovery After Stroke**  
Science Advances manuscript: **aeh9028**

## Author

**Dongsheng Xiao, MD, PhD**  
Queensland Brain Institute, The University of Queensland

## Contents

This repository currently contains MATLAB code used for the kinematic analyses associated with:

- **Figure 1f** — pre/post kinematic comparisons after laterality reclassification into clinically more-affected and less-affected limbs.
- **Figure 1h** — correlations between post/pre kinematic ratios and post/pre Fugl-Meyer motor-score ratios.

No Figure 2 EEG functional-connectivity code is included in this repository.

## Repository structure

```text
Figure1_Kinematics/
├── compareStrokeMotionLateralityFigure1f.m
├── plotMotionVsFMA_LateralityFigure1h_v2.m
└── README.md
```

## Software

The analysis scripts are written for MATLAB and use functions from MATLAB Statistics and Machine Learning Toolbox, including `ttest`, `ttest2`, `fitlm`, `predict`, `corr`, and `ksdensity`.

## Input data

The scripts expect an Excel workbook named `Kinematic_Laterality_Reanalysis.xlsx` containing the laterality-reclassified kinematic measurements and Fugl-Meyer scores. Patient-level study data are not included in this public code repository.

See `Figure1_Kinematics/README.md` for the expected sheet names, variables, and example commands.

## Citation

If you use this code, please cite the associated Science Advances article once the final bibliographic information is available.

## Contact

Dongsheng Xiao, MD, PhD
