Functional COnnectivity Preprocessing and Analysis:

These matlab and shell scripts can be run in order. The dependencies are below, but please email me if anything seems to be missing (z.karas@vanderbilt.edu):
ANTs installation - https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS
FSL installation - https://fsl.fmrib.ox.ac.uk/fsl/docs/#/install/index 
parallel - GNU parallel 20231022
R - 3.30
MATLAB - 2023a

Sample files can be found [here](https://drive.google.com/drive/folders/1cLQb45ozPdKxg0cbibWzD2cuI9EO3bts?usp=sharing). Once the 'data' folder is downloaded, you can directly put it into the 'better_replication_package' folder to run the scripts. As the scripts are run, the preprocessing steps will be applied to the fMRI nifti files as they are saved into `data/midprocess` and `data/clean`. Since there is data from only four participants, these scripts do not replicate the results of the full study. The steps are listed as follows:

1. Preprocess the raw fMRI files using established methodologies
2. Run ica - only runs on data from studies 001 and 003, for reasons listed in the paper
3. Applied to all nifti files. Removes further motion artifacts using nuisance regression
4. Loading the atlases used for standardizing the data and performing Region of Interest (ROI)-to-ROI functional connectivity analysis
5. Actual steps for performing functional connectivity analysis
6. Calculating stats. Again since this is sample data, the results from the paper will not be replicated, but we include spreadsheets of the results, calculated in the same manner
7. Scripts for saving data and making brain plots

