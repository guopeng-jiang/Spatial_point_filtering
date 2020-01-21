# A simple program for filtering spatial point data

This is a part of my PhD research to develop methods to process sensor-derived data for crop management in New Zealand.

This simple program removes common errors in the historical yield monitor data recorded from combine harvesters. 

Data required:

  (1) Yield monitor data collected over the years.
  (2) Field boundary in which the data is collected. 

Data format: shapefiles

Before running:

  (1) Historical yield monitor data put in one folder 
  (2) Field boundary data put in the other folder 
  (3) Start a new folder for the output data 

Potential error: 
  Different names for the yield attribute caused by different yield monitors ... 
  Here it should be called "Yld_Mass_D", not anything else.
  Simply change the name into "Yld_Mass_D" will bypass the error.

Major references:

  Sudduth, K. A., Drummond, S. T., & Myers, D. B. (2012). Yield Editor 2.0: Software for automated removal of yield map errors. In 2012 Dallas, Texas, July 29-August 1, 2012 (p. 1). American Society of Agricultural and Biological Engineers.

  Spekken, M. A. R. K., Anselmi, A. A., & Molin, J. P. (2013). A simple method for filtering spatial data. In Precision agriculture’13 (pp. 259-266). Wageningen Academic Publishers, Wageningen.

  Jiang, G., Grafton, M., Pearson, D., Bretherton, M., & Holmes, A. (2019). Integration of Precision Farming Data and Spatial Statistical Modelling to Interpret Field-Scale Maize Productivity. Agriculture, 9(11), 237.
