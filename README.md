# Conv-Div-Nozzle_OpenSCAD
A 2D Convergent-Divergent Nozzle design using OpenSCAD with a Python front-end for ease of use.

Within the OpenSCAD file, almost any aspect of the nozzle can be adjusted. This includes the mounting locations and sizes, the nozzle size and shape, the pipe connection size, shape and thread, and the thickness of the assembly parts. For general use, the Python GUI (wip) will provide easy usage and visualization of the nozzle. The nozzle is defined as distances from the center line in OpenSCAD however, the Python will simplify the geometry to a series of points which define a bezier cubic curve. This curve is then converted into geometry for the OpenSCAD. 
