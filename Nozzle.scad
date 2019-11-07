/* Convergent-Divergent 2D Nozzle
 * Designed for Dr. Kayuza Tajiri
 * Adjust the List to adjust the Curve
 * Written by Jacob Loss
 */

/* ====== Includes ====== */
include <Libs/tsmthread4.scad>

/* ====== User Defined Values ====== */

/* Geometry of Nozzle centered around the center-line of the nozzle.
 * Geometry is defined from Convergent (input) to Divergent (output) side
 *      GasIn -> x -> GasOut
 *  Ex. [10, 10, 5, 3, 1.5, 1.5, 4, 6, 8, 9, 10, 11, 12]
 * Size of frame is defined by the end value like so:
 *      width = 2 * (end + t)
 *  Where <t> is the minimum wall thickness value.
 */
nozzle_geo = [15, 15, 10, 1.5, 7, 12.5, 16, 20, 23, 26, 28, 30, 31, 32, 32.5];

/* Length of the nozzle piece */
nozzle_length = 180;

/* Minimum Thickness of the walls along the nozzle geometry */
wall_thickness = 5;

/* Thickness in the z direction of the nozzle piece */
noz_vert_thickness = 5;

/* Thickness in the z direction of the inlet piece */
inlet_vert_thickness = 5;

/* ==== Inlet Values ==== */
/* Currently threads only support NPT for inlet. */
/* NPT Thread parameters are in inches */

/* Inlet Thickness */
inlet_thickness = 2.5;

/* Inlet Diameter */
/* Note: this is NOT the same as the pipe diameter */
inlet_dia = 0.54;   // Default for 1/4" pipe threads

/* Inlet Length in Inches */
inlet_len = 1/2;

/* Inlet Thread Pitch */
inlet_pitch = 0.05556; // Defualt pitch for 1/4" pipe threads

/* Inlet Gender */
inlet_male = false; // Male = true, Female = false.

/* Inner Diameter of inlet */
/* Note: this value is only used on male connectors */
inlet_inner_dia = inlet_dia * 0.66; // Just an example

/* Number of mounting points on the inlet */
/* Automajically aligns mounting points to the nozzle */
inlet_mounting_points = 4;

/* ==== Mounting Values ==== */

/* Mouting Hole centers
 * All values relative to the center back of the nozzle.
 * Start with values closest to the inlet
 */
mount_points = [
        [30, 40, 0],
        [0, -40, 0],
        [90, 40, 0],
        [90, -40, 0],
        [30, -40, 0],
        [0, 40, 0],
        [60, 40, 0],
        [60, -40, 0],
        [173.9, 40, 0],
        [173.9, -40, 0],
        [120, 40, 0],
        [120, -40, 0],
        [150, 40, 0],
        [150, -40, 0]
    ];

/* Mouting hole diameter */
mount_dia = 7; 

/* Thickness of walls around mount points */
mount_wall_thickness = 5;

/* Mounting Tolerance */
mount_tolerance = 0.2;

/* ==== Extra Features ==== */

/* Minimize Plastic use
 * Will use less plastic by cutting out square structure that is unnecessary.
 * Still follows minimum wall thickness for the nozzle
 * Will extend arms to defined mounting points as necessary
 */
min_plas = true;

/* Adds a sealing groove along the edge of the nozzle. 
 * This can be filled with rubber to help maintain a seal.
 */
sealing_groove = false;

/* Sealing Details
 * Not used if sealing_groove=false
 */
seal_dia = 2;       // Diameter of seal groove
seal_dist = 0.5;    // Distance seal groove is from wall edge

/* ====== Calculated Values ====== */

/* Length of outside frame */
frame_length = nozzle_length + wall_thickness;

/* Width of outside frame */
frame_width = 2*max(nozzle_geo) + 2 * wall_thickness;

/* Full frame dims */
frame = [frame_length, frame_width, noz_vert_thickness];

/* Expanded Nozzle Profile */
big_nozzle_geo = [ for(i = [0:len(nozzle_geo)-1]) nozzle_geo[i] + wall_thickness];



/* Inlet Block Dimensions */
inlet_frame = [min(extract_x(mount_points)) 
                +(mount_dia+mount_tolerance+mount_wall_thickness)/2 
                + wall_thickness,
                frame_width, 
                inlet_thickness];

/* ====== Functions ====== */

/* Extracts the X value for list of 3D coords */
function extract_x(list) = [
    for(i = [0:len(list)-1])
    list[i][0]  // Extract X
    ];
    
// input : list of numbers
// output : sorted list of numbers
function quicksort_x(arr) = !(len(arr)>0) ? [] : let(
    pivot   = arr[floor(len(arr)/2)],
    lesser  = [ for (y = arr) if (y  < pivot) y ],
    equal   = [ for (y = arr) if (y == pivot) y ],
    greater = [ for (y = arr) if (y  > pivot) y ]
) concat(
    quicksort_x(lesser), equal, quicksort_x(greater)
);

/* ====== Modules ====== */

/* Make Nozzle Difference Geometry 
 * 
 *  Makes the Positive Nozzle geometry for use as a difference value.
 *  Is used in minimize plastic mode to define the shape of the frame.
 */
module make_nozzle_diff_geo(
    nozzle_geo, 
    nozzle_length, 
    noz_vert_thickness){
    // Make Nozzle Geometry
    inc = nozzle_length / (len(nozzle_geo)-1);
    geo1 =  [ for(i = [0 : len(nozzle_geo)-1]) 
                [i * inc, nozzle_geo[i]]
            ];

    geo2 = [ for(i = [0 : len(nozzle_geo)-1])
                let(i = len(nozzle_geo)-1 - i)
                [i * inc, -nozzle_geo[i]]
            ];
    big_nozzle_geo = [ for(i = [0:len(nozzle_geo)-1]) nozzle_geo[i] + wall_thickness];
    geo = concat(geo1, geo2);
    //echo(geo);
    linear_extrude(height = noz_vert_thickness)
    polygon(geo);
}

module make_mounting_points(mounting_points, mount_dia, mount_wall_thickness, mount_tolerance, mount_thickness){
    for(i = [0:len(mounting_points)-1]){
        translate(mounting_points[i])
        union(){
            cylinder(h = mount_thickness, d = mount_dia+mount_tolerance+mount_wall_thickness);
            translate([0, -mounting_points[i][1]/2, mount_thickness/2])
            cube([
                    mount_dia+mount_tolerance+mount_wall_thickness, 
                    abs(mounting_points[i][1]), 
                    mount_thickness
                ], center = true);
        }
    }
}

module make_mounting_drills(mounting_points, mount_dia, mount_thickness, mount_tolerance){
    for(i = [0:len(mounting_points)-1]){
        translate(mounting_points[i])
        cylinder(h = mount_thickness, d = mount_dia+mount_tolerance);
    }
}

module build_nozzle_frame(
    frame,
    nozzle_length, 
    big_nozzle_geo,
    wall_thickness,
    noz_vert_thickness,
    min_plas,
    mount_points, 
    mount_dia, 
    mount_wall_thickness, 
    mount_tolerance){
    if(min_plas){
        butt_dims = [wall_thickness, 2 * big_nozzle_geo[0], noz_vert_thickness];
            union(){
                translate([-wall_thickness/2, 0, noz_vert_thickness/2])
                cube(butt_dims, center = true);
                make_nozzle_diff_geo(big_nozzle_geo, nozzle_length, noz_vert_thickness);
                make_mounting_points(mount_points, mount_dia, mount_wall_thickness, mount_tolerance, noz_vert_thickness);
            }

    } else {
            union(){
                translate([-wall_thickness, -frame[1]/2, 0])
                cube(frame);
                make_mounting_points(mount_points, mount_dia, mount_wall_thickness, mount_tolerance, noz_vert_thickness);
            }
    }   
    
}

module build_nozzle(
    frame, 
    wall_thickness, 
    min_plas = false, 
    sealing_groove = false, 
    nozzle_geo, 
    nozzle_length, 
    noz_vert_thickness,
    big_nozzle_geo,
    mount_points, 
    mount_dia, 
    mount_wall_thickness, 
    mount_tolerance
    ){
    difference(){
        build_nozzle_frame(
            frame,
            nozzle_length, 
            big_nozzle_geo,
            wall_thickness,
            noz_vert_thickness,
            min_plas,
            mount_points, 
            mount_dia, 
            mount_wall_thickness, 
            mount_tolerance);
     make_nozzle_diff_geo(nozzle_geo, nozzle_length, noz_vert_thickness);
     make_mounting_drills(mount_points, mount_dia, noz_vert_thickness, mount_tolerance);
    }
}

module build_inlet_frame(
    frame,
    wall_thickness,
    min_plas, 
    big_nozzle_geo, 
    nozzle_length, 
    noz_vert_thickness,
    big_nozzle_geo,
    mount_points, 
    mount_dia, 
    mount_wall_thickness, 
    mount_tolerance,
    inlet_thickness,
    inlet_mounting_points){
    sorted_x = quicksort_x(extract_x(mount_points));
    /* Max X value that needs to be included */
    max_x = sorted_x[inlet_mounting_points-1] 
        + wall_thickness 
        + (mount_dia + mount_tolerance + mount_wall_thickness)/2;
    
    intersection(){
        translate([max_x/2-wall_thickness, 0, inlet_thickness/2])
        cube([max_x, 1000, inlet_thickness], center=true);
        difference(){
        build_nozzle_frame(
            frame=frame, 
            wall_thickness=wall_thickness, 
            min_plas=min_plas, 
            big_nozzle_geo=nozzle_geo, 
            nozzle_length = nozzle_length, 
            noz_vert_thickness = inlet_thickness,
            big_nozzle_geo = big_nozzle_geo,
            mount_points = mount_points, 
            mount_dia = mount_dia, 
            mount_wall_thickness = mount_wall_thickness, 
            mount_tolerance = mount_tolerance);
            
            make_mounting_drills(mount_points, mount_dia, noz_vert_thickness, mount_tolerance);
        }
    }
}

module build_inlet_block(
    big_nozzle_geo,
    inlet_thickness,
    wall_thickness,
    mount_points, 
    mount_dia, 
    mount_wall_thickness, 
    mount_tolerance, 
    noz_vert_thickness,
    min_plas=false,
    inlet_mounting_points,
    inlet_dia,
    inlet_pitch,
    inlet_male,
    inlet_inner_dia,
    inlet_len){
        
    // Z-lift noz_vert_thickness+inlet_thickness/2
    
    frame = [frame_length, frame_width, inlet_thickness];
    if(inlet_male){
        difference(){
        union(){
            build_inlet_frame(
                    frame=frame, 
                    wall_thickness=wall_thickness, 
                    min_plas=min_plas, 
                    big_nozzle_geo=nozzle_geo, 
                    nozzle_length = nozzle_length, 
                    noz_vert_thickness = inlet_thickness,
                    big_nozzle_geo = big_nozzle_geo,
                    mount_points = mount_points, 
                    mount_dia = mount_dia, 
                    mount_wall_thickness = mount_wall_thickness, 
                    mount_tolerance = mount_tolerance,
                    inlet_thickness = inlet_thickness,
                    inlet_mounting_points = inlet_mounting_points);
            
                translate([wall_thickness + (inlet_dia + $OD_COMP)/(2*0.0393701), 0, inlet_thickness]){
                imperial(){
                    thread_npt(DMAJ=inlet_dia + $OD_COMP,L = inlet_len,PITCH = inlet_pitch);
                }
            }
        }
            /* Male Connector */
            translate([wall_thickness + (inlet_dia + $OD_COMP)/(2*0.0393701), 0, 0])
            cylinder(h = inlet_len / 0.0393701 + inlet_thickness, r = inlet_inner_dia / (2 * 0.0393701)); 
        }
    } else {
        difference(){
        union(){
            build_inlet_frame(
                        frame=frame, 
                        wall_thickness=wall_thickness, 
                        min_plas=min_plas, 
                        big_nozzle_geo=nozzle_geo, 
                        nozzle_length = nozzle_length, 
                        noz_vert_thickness = inlet_thickness,
                        big_nozzle_geo = big_nozzle_geo,
                        mount_points = mount_points, 
                        mount_dia = mount_dia, 
                        mount_wall_thickness = mount_wall_thickness, 
                        mount_tolerance = mount_tolerance,
                        inlet_thickness = inlet_thickness,
                        inlet_mounting_points = inlet_mounting_points);
            translate([wall_thickness + (inlet_dia + $OD_COMP)/(2*0.0393701), 0, inlet_thickness])
            cylinder(h = inlet_len / 0.0393701, r = (inlet_dia + $OD_COMP)/ (1 * 0.0393701)+ mount_wall_thickness, $fn = 6);
        }
        translate([wall_thickness + (inlet_dia + $OD_COMP)/(2*0.0393701), 0, inlet_thickness]){
                imperial(){
                    thread_npt(DMAJ=inlet_dia - $OD_COMP,L = inlet_len+1,PITCH = inlet_pitch);
                }
                
            }
            translate([wall_thickness + (inlet_dia + $OD_COMP)/(2*0.0393701), 0, 0])
            cylinder(h = inlet_thickness, r = inlet_inner_dia / (2 * 0.0393701));
        }
    }
}

module test(){
    
    
    build_nozzle(
        frame=frame, 
        wall_thickness=wall_thickness, 
        min_plas=false, 
        nozzle_geo=nozzle_geo, 
        nozzle_length = nozzle_length, 
        noz_vert_thickness = noz_vert_thickness,
        big_nozzle_geo = big_nozzle_geo,
        mount_points = mount_points, 
        mount_dia = mount_dia, 
        mount_wall_thickness = mount_wall_thickness, 
        mount_tolerance = mount_tolerance);
    
    
    //translate([0, 0, noz_vert_thickness])
    //rotate([0, 0, 0])
    
    /*
    build_inlet_block(
    wall_thickness=wall_thickness,
    inlet_thickness = 2.5,
    big_nozzle_geo = big_nozzle_geo,
    mount_points = mount_points, 
    mount_dia = mount_dia, 
    mount_wall_thickness = mount_wall_thickness, 
    mount_tolerance = mount_tolerance, 
    noz_vert_thickness = noz_vert_thickness,
    min_plas=true,
    inlet_mounting_points=inlet_mounting_points,
    inlet_dia = inlet_dia,
    inlet_pitch = inlet_pitch,
    inlet_male = true,
    inlet_inner_dia = inlet_inner_dia,
    inlet_len = inlet_len);
    */
    
}
/*
echo(mount_points);
echo(quicksort_x(extract_x(mount_points)));
*/
/* Test all values */
test();
