# -*- coding: utf-8 -*-
"""
Created on Thu Jun 10 14:27:10 2021

@author: Sergio G. Lopez from the Bioimaging Facility of the John Innes Centre.
"""

# Imports the necessary libraries.
from ncempy.io import dm
import numpy as np
import matplotlib.pyplot as plt
from skimage import filters, morphology, segmentation, measure, color
from scipy import ndimage as ndi
import pandas as pd
# import glob
# import tkinter as tk
# from tkinter import filedialog
# import os

def open_DM4(filepath):
    """This function opens the DM4 image and returns the name of the image, the image itself, and the pixel size."""
    fileDM4 = dm.dmReader(filepath) # Imports the dm4 image as a dictionary.
    filename = fileDM4['filename'] # Gets the name of the image.
    filename = filename.split('.')[0] # Removes the '.dm4' extension from the name of the image.
    img = fileDM4['data'] # Gets the image itself as a float32 Numpy array.
    pixel_size = fileDM4['pixelSize'][0] # Gets the pixel size in nm.
    return filename, img, pixel_size

def img_prep(img, block_size=301, erosions=1, dilations=5, small_object_removal=2000, small_holes_removal=500):
    """This function performs an adaptive thresholding, followed by erosions, followed by small objects removal, followed by dilations,
    followed by small holes removal. The output is the processed image"""
    thresh = filters.threshold_local(img, block_size, offset=0) # Computes a threshold mask image based on the local pixel neighborhood. Also known as adaptive or dynamic thresholding.
    binary_local = img > thresh # Uses the threshold to obtain a binary image.
    for i in range(erosions): # Erodes the image a number of times.
        binary_local = morphology.binary_erosion(binary_local)
    binary_local = morphology.remove_small_objects(binary_local,small_object_removal) # Removes small objects.
    for i in range(dilations): # Dilates the image a number of times.
        binary_local = morphology.binary_dilation(binary_local)
    binary_local = morphology.remove_small_holes(binary_local, small_holes_removal) # Removes small holes in the objects.
    return binary_local

def watershedding(binary_img, seed_threshold=0.2):
    """This function watersheds the objects to separate them. It's followed by the removal of small objects."""
    distance = ndi.distance_transform_edt(binary_img) # Applies a distance transform to the image.
    local_maxi = np.copy(distance) # We make a copy of our image so as not to destroy the original.
    local_maxi = local_maxi>(np.max(local_maxi)*seed_threshold) # We take a threshold based on the size of the objects. The middle 20% remains as a seed for each region.
    markers = ndi.label(local_maxi)[0]
    labels = segmentation.watershed(-distance, markers, mask=binary_img) # Now we run the watershed algorithm and connect the objects to each seed point.
    labels = segmentation.clear_border(labels) # Removes the objects that touch the edges of the image.
    return labels

def plotfig(labels, region_properties, img, filename):
    """This function takes the labelled image, the properties of the labels, and the name of the image and then plots (and saves) the figure."""
    fig, ax = plt.subplots(1,2,figsize=(15,8))
    ax[0].imshow(color.label2rgb(labels,bg_label=0,colors=['red','violet','orange','green','blue','magenta','purple','crimson','lime','maroon','mediumvioletred','goldenrod','darkgreen','fuchsia','cornflowerblue','navy','hotpink','grey','chocolate','peru']))
    ax[0].set_title('Selected objects', fontsize=16)
    for i in region_properties:
        ax[0].text(i.centroid[1],i.centroid[0],i.label,color='white')
    ax[1].imshow(img,cmap='Greys_r')
    ax[1].contour(labels,colors='r', linewidths=0.8)
    ax[1].set_title('Original', fontsize=16)
    plt.tight_layout()
    plt.savefig(filename+'.png',dpi=600)
    # plt.show()
    plt.close()

def filter_labels_by_eccentricity(labels,eccentricity):
    """This function filters out labels that have an eccentricity below the value of the "eccentricity" parameter. The output is a labelled image."""
    props = measure.regionprops(labels)
    labels_cleaned = np.zeros_like(labels)
    for i in props:
        if i.eccentricity > eccentricity:
            labels_cleaned[labels == i.label] = i.label
    return labels_cleaned

def filter_labels_by_minor_axis_length(labels,length_in_nm,pixel_size):
    """This function filters out labels that have a minor axis length above the value of the "length in nm" parameter. The output is a labelled image."""
    props = measure.regionprops(labels)
    labels_cleaned = np.zeros_like(labels)
    for i in props:
        if i.minor_axis_length*pixel_size < length_in_nm:
            labels_cleaned[labels == i.label] = i.label
    return labels_cleaned

def filter_labels_by_area(labels,area_in_nm2,pixel_size):
    """This function filters out labels that have an area below the value of the "area" parameter. The output is a labelled image."""
    props = measure.regionprops(labels)
    labels_cleaned = np.zeros_like(labels)
    for i in props:
        if i.area*pixel_size*pixel_size > area_in_nm2:
            labels_cleaned[labels == i.label] = i.label
    return labels_cleaned

def reorder_labels(labels):
    """This function reorders the labels so as to make them start from 1."""
    props = measure.regionprops(labels)
    labels_cleaned = np.zeros_like(labels)
    for i,j in enumerate(props):
        labels_cleaned[labels == j.label] = i+1
    return labels_cleaned

# # Creates the dataframe to which all the local dataframes will be appended.
# great_dataframe = pd.DataFrame(columns=['Image name','Nanorod ID','Coordinate in Y','Coordinate in X','Length in nm'])
#
# # Creates a dialog window to obtain the folder in which the images are.
# # root = tk.Tk()
# # root.withdraw()
# # folder_selected = filedialog.askdirectory(title='Select the folder that contains the images.')
# folder_selected = "/Users/kristiar/Downloads/Nanorods/1-3 dilution"
#
# # It opens each one of the images.
# for filepath in glob.glob(os.path.join(folder_selected, '*.dm4')):
#     # Opens and labels the images.
#     filename, img, pixel_size = open_DM4(filepath) # Opens the image.
#     binary = img_prep(img) # Prepares the image to be labelled.
#     labels = watershedding(binary) # Watersheds and labels the image.
#     labels = filter_labels_by_area(labels,500,pixel_size)
#     labels = filter_labels_by_minor_axis_length(labels,40,pixel_size)
#     labels = reorder_labels(labels)
#     # Obtains the properties of the labels.
#     labels_properties = measure.regionprops(labels)
#     if len(labels_properties) > 0:
#         # Plots and saves the images.
#         plotfig(labels,labels_properties, filename)
#         # Creates a table containing the nanorod properties.
#         table = measure.regionprops_table(labels,properties=('label','centroid','feret_diameter_max'))
#         # Transforms the table into a Pandas dataframe.
#         data = pd.DataFrame(table)
#         # Converts the length of the nanorod in pixels into length in nm.
#         data['feret_diameter_max'] = pixel_size*data['feret_diameter_max'] # Transforms the pixel length into a length in nm.
#         # Creates a list with the name of the image.
#         list_image_name = [filename+'.dm4' for i in range(data.shape[0])]
#         # Inserts this list as a column in the dataframe.
#         data.insert(0,'Image name',list_image_name)
#         # Renames the columns of the dataframe.
#         data.rename(columns={'label':'Nanorod ID','centroid-0':'Coordinate in Y','centroid-1':'Coordinate in X','feret_diameter_max':'Length in nm'},inplace=True)
#         # Appends this local dataframe to the great dataframe that contains nanorods from all of the images.
#         great_dataframe = great_dataframe.append(data, ignore_index = True)
#         # Saves the great dataframe with all the data as an Excel spreadsheet.
#         great_dataframe.to_excel('Nanorods.xlsx')
