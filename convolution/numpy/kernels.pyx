# cython: boundscheck = False
# cython: wraparound = False
# cython: cdivision = False

import numpy as np
cimport numpy as cnp

cimport cython
from libc cimport math as cmath
"""
Definit une convolution faisant une moyenne des voisins d'un pixel donne
( stencil de 3x3 )
"""

def convolve_mean2(double[:, :] image):
    cdef:
        int i, j
        int height = image.shape[0]
        int width = image.shape[1]
        double[:, :] vout

    out_image = np.empty((height - 2, width - 2))
    vout = out_image
    for i in range(1, height - 1):
        for j in range(1, width - 1):
            vout[i - 1, j - 1] = 0.25 * (image[i - 1, j] + image[i + 1, j] +
                                         image[i, j - 1] + image[i, j + 1])
    return out_image

def convolve_mean3(double[:, :, :] image):
    cdef:
        int i, j, k
        int height = image.shape[0]
        int width = image.shape[1]
        int dim = image.shape[2]
        double[:, :, :] vout

    out_image = np.empty((height - 2, width - 2, dim))
    vout = out_image
    for i in range(1, height - 1):
        for j in range(1, width - 1):
            for k in range(0, dim):
                vout[i - 1, j - 1, k] = 0.25 * (image[i - 1, j, k] +
                                                image[i + 1, j, k] +
                                                image[i, j - 1, k] +
                                                image[i, j + 1, k])
    return out_image

"""
Definie l'operateur laplacien comme convolution : permet de detecter les bords dans une image
"""
def convolve_laplacien2(double[:, :] image):
    cdef:
        int i, j
        int height = image.shape[0]
        int width = image.shape[1]
        double[:, :] vout

    out_image = np.empty((height - 2, width - 2))
    vout = out_image
    for i in range(1, height - 1):
        for j in range(1, width - 1):
            vout[i - 1, j - 1] = cmath.fabs(4 * image[i, j] - image[i - 1, j] -
                                            image[i + 1, j] - image[i, j - 1] -
                                            image[i, j + 1])
    # On renormalise l'image :
    valmax = cmath.max(out_image)
    valmax = cmath.max(1., valmax) + 1.E-9
    out_image *= 1. / valmax
    return out_image

def convolve_laplacien3(double[:, :, :] image):
    cdef:
        int i, j, k
        int height = image.shape[0]
        int width = image.shape[1]
        int dim = image.shape[2]
        double[:, :, :] vout

    out_image = np.empty((height - 2, width - 2, dim))
    vout = out_image
    for i in range(1, height - 1):
        for j in range(1, width - 1):
            for k in range(0, dim):
                vout[i - 1, j - 1, k] = cmath.fabs(4 * image[i, j, k] -
                                                   image[i - 1, j, k] -
                                                   image[i + 1, j, k] -
                                                   image[i, j - 1, k] -
                                                   image[i, j + 1, k])
    # On renormalise l'image :
    valmax = np.max(out_image)
    valmax = max(1., valmax) + 1.E-9
    out_image *= 1. / valmax
    return out_image

"""
Convolution generale avec une taille de stencil quelconque. Permet de definir tous les stencils que l'on souhaite !
"""
def convolve_matrix2(double[:, ::1] image, double[:, ::1] convolution_array):
    cdef:
        int i, j, iw, jw
        int height = image.shape[0]
        int width = image.shape[1]
        int nx = convolution_array.shape[1]
        int ny = convolution_array.shape[0]
        int half_x = nx//2
        int half_y = ny//2

    out_image = np.empty((height-nx+1,width-ny+1))
    cdef double[:, ::1] vout = out_image

    for j in range(half_y, height - half_y):
        for i in range(half_x, width - half_x):
            vout[j-half_y,i-half_x] = 0.
            for jw in range(-half_y,ny-half_y):
                for iw in range(-half_x,nx-half_x):
                    vout[j-half_y,i-half_x] += convolution_array[jw+half_y,iw+half_x]*image[j+jw,i+iw]
            vout[j-half_y,i-half_x] = cmath.fabs(vout[j-half_y,i-half_x])

    # On renormalise l'image en ramenant les valeurs des couleurs entre 0 et 1
    valmax = np.max(out_image)
    valmax = max(1.,valmax)+1.E-9
    out_image *= 1./valmax
    return out_image


def convolve_matrix3(double[:, :, ::1] image, double[:, ::1] convolution_array):
    cdef:
        int i, j, k, iw, jw
        int height = image.shape[0]
        int width = image.shape[1]
        int dim = image.shape[2]
        int nx = convolution_array.shape[1]
        int ny = convolution_array.shape[0]
        int half_x = nx//2
        int half_y = ny//2

    out_image = np.empty((height-nx+1,width-ny+1, dim))
    cdef double[:, :, ::1] vout = out_image

    for j in range(half_y, height - half_y):
        for i in range(half_x, width - half_x):
            vout[j-half_y,i-half_x,0] = 0.
            vout[j-half_y,i-half_x,1] = 0.
            vout[j-half_y,i-half_x,2] = 0.
            for jw in range(-half_y,ny-half_y):
                for iw in range(-half_x,nx-half_x):
                    vout[j-half_y,i-half_x,0] += convolution_array[jw+half_y,iw+half_x]*image[j+jw,i+iw,0]
                    vout[j-half_y,i-half_x,1] += convolution_array[jw+half_y,iw+half_x]*image[j+jw,i+iw,1]
                    vout[j-half_y,i-half_x,2] += convolution_array[jw+half_y,iw+half_x]*image[j+jw,i+iw,2]
            vout[j-half_y,i-half_x,0] = cmath.fabs(vout[j-half_y,i-half_x,0])
            vout[j-half_y,i-half_x,1] = cmath.fabs(vout[j-half_y,i-half_x,1])
            vout[j-half_y,i-half_x,2] = cmath.fabs(vout[j-half_y,i-half_x,2])

    # On renormalise l'image en ramenant les valeurs des couleurs entre 0 et 1
    valmax = np.max(out_image)
    valmax = max(1.,valmax)+1.E-9
    out_image *= 1./valmax
    return out_image
