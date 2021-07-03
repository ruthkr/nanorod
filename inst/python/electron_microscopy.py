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


def open_DM4(filepath):
    """This function opens the DM4 image and returns the name of the image, the image itself, and the pixel size."""
    fileDM4 = dm.dmReader(filepath)  # Imports the dm4 image as a dictionary.
    filename = fileDM4['filename']  # Gets the name of the image.
    filename = filename.split('.')[0]  # Removes the '.dm4' extension from the name of the image.
    img = fileDM4['data']  # Gets the image itself as a float32 Numpy array.
    pixel_size = fileDM4['pixelSize'][0]  # Gets the pixel size in nm.
    return filename, img, pixel_size


def img_prep(img, block_size=301, erosions=1, dilations=5, small_object_removal=2000, small_holes_removal=500):
    """This function performs an adaptive thresholding, followed by erosions, followed by small objects removal, followed by dilations,
    followed by small holes removal. The output is the processed image"""
    thresh = filters.threshold_local(
        img, block_size, offset=0
    )  # Computes a threshold mask image based on the local pixel neighborhood. Also known as adaptive or dynamic thresholding.
    binary_local = img > thresh  # Uses the threshold to obtain a binary image.
    for i in range(erosions):  # Erodes the image a number of times.
        binary_local = morphology.binary_erosion(binary_local)
    binary_local = morphology.remove_small_objects(
        binary_local, small_object_removal)  # Removes small objects.
    for i in range(dilations):  # Dilates the image a number of times.
        binary_local = morphology.binary_dilation(binary_local)
    binary_local = morphology.remove_small_holes(
        binary_local,
        small_holes_removal)  # Removes small holes in the objects.
    return binary_local


def watershedding(binary_img, seed_threshold=0.2):
    """This function watersheds the objects to separate them. It's followed by the removal of small objects."""
    distance = ndi.distance_transform_edt(
        binary_img)  # Applies a distance transform to the image.
    local_maxi = np.copy(
        distance
    )  # We make a copy of our image so as not to destroy the original.
    local_maxi = local_maxi > (
        np.max(local_maxi) * seed_threshold
    )  # We take a threshold based on the size of the objects. The middle 20% remains as a seed for each region.
    markers = ndi.label(local_maxi)[0]
    labels = segmentation.watershed(
        -distance, markers, mask=binary_img
    )  # Now we run the watershed algorithm and connect the objects to each seed point.
    labels = segmentation.clear_border(
        labels)  # Removes the objects that touch the edges of the image.
    return labels


def plotfig(labels, region_properties, img, filename, out_dpi = 600):
    """This function takes the labelled image, the properties of the labels, and the name of the image and then plots (and saves) the figure."""
    fig, ax = plt.subplots(1, 2, figsize=(15, 8))
    ax[0].imshow(
        color.label2rgb(
            labels,
            bg_label=0,
            colors=[
                'red', 'violet', 'orange', 'green', 'blue',
                'magenta', 'purple', 'crimson', 'lime', 'maroon',
                'mediumvioletred', 'goldenrod', 'darkgreen',
                'fuchsia', 'cornflowerblue', 'navy', 'hotpink',
                'grey', 'chocolate', 'peru'
            ]
        )
    )
    ax[0].set_title('Selected objects', fontsize=16)
    for i in region_properties:
        ax[0].text(i.centroid[1], i.centroid[0], i.label, color='white')
    ax[1].imshow(img, cmap='Greys_r')
    ax[1].contour(labels, colors='r', linewidths=0.8)
    ax[1].set_title('Original', fontsize=16)

    plt.tight_layout()
    plt.savefig(filename + '.png', dpi=out_dpi)
    plt.close()


def plotfig_separate(labels, region_properties, img, filename, out_dpi = 600):
    """This function takes the labelled image, the properties of the labels, and the name of the image and then plots (and saves) the figure."""

    fig, ax = plt.subplots()
    ax.imshow(
        color.label2rgb(
            labels,
            bg_label=0,
            colors=[
                'red', 'violet', 'orange', 'green', 'blue',
                'magenta', 'purple', 'crimson', 'lime', 'maroon',
                'mediumvioletred', 'goldenrod', 'darkgreen',
                'fuchsia', 'cornflowerblue', 'navy', 'hotpink',
                'grey', 'chocolate', 'peru'
            ]
        )
    )
    for i in region_properties:
        ax.text(i.centroid[1], i.centroid[0], i.label, color='white')

    plt.gca().set_axis_off()
    plt.subplots_adjust(top=1, bottom=0, right=1, left=0, hspace=0, wspace=0)
    plt.margins(0, 0)
    plt.gca().xaxis.set_major_locator(plt.NullLocator())
    plt.gca().yaxis.set_major_locator(plt.NullLocator())
    plt.savefig(filename + '_processed.png', dpi=out_dpi, bbox_inches='tight', pad_inches=0)
    plt.close()

    fig, ax = plt.subplots()
    ax.imshow(img, cmap='Greys_r')
    ax.contour(labels, colors='r', linewidths=0.8)

    plt.gca().set_axis_off()
    plt.subplots_adjust(top=1, bottom=0, right=1, left=0, hspace=0, wspace=0)
    plt.margins(0, 0)
    plt.gca().xaxis.set_major_locator(plt.NullLocator())
    plt.gca().yaxis.set_major_locator(plt.NullLocator())
    plt.savefig(filename + '_raw.png', dpi=out_dpi, bbox_inches='tight', pad_inches=0)
    plt.close()


def filter_labels_by_eccentricity(labels, eccentricity):
    """This function filters out labels that have an eccentricity below the value of the "eccentricity" parameter. The output is a labelled image."""
    props = measure.regionprops(labels)
    labels_cleaned = np.zeros_like(labels)
    for i in props:
        if i.eccentricity > eccentricity:
            labels_cleaned[labels == i.label] = i.label
    return labels_cleaned


def filter_labels_by_minor_axis_length(labels, length_in_nm, pixel_size):
    """This function filters out labels that have a minor axis length above the value of the "length in nm" parameter. The output is a labelled image."""
    props = measure.regionprops(labels)
    labels_cleaned = np.zeros_like(labels)
    for i in props:
        if i.minor_axis_length * pixel_size < length_in_nm:
            labels_cleaned[labels == i.label] = i.label
    return labels_cleaned


def filter_labels_by_area(labels, area_in_nm2, pixel_size):
    """This function filters out labels that have an area below the value of the "area" parameter. The output is a labelled image."""
    props = measure.regionprops(labels)
    labels_cleaned = np.zeros_like(labels)
    for i in props:
        if i.area * pixel_size * pixel_size > area_in_nm2:
            labels_cleaned[labels == i.label] = i.label
    return labels_cleaned


def reorder_labels(labels):
    """This function reorders the labels so as to make them start from 1."""
    props = measure.regionprops(labels)
    labels_cleaned = np.zeros_like(labels)
    for i, j in enumerate(props):
        labels_cleaned[labels == j.label] = i + 1
    return labels_cleaned
