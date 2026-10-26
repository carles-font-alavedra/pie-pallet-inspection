# PIE — 3D Pallet Measurement Module with Intel RealSense D435i

MATLAB pipeline for capturing and measuring pallets with a depth camera,
developed as part of the INT course (ETSETB–UPC, 2024/25).

The project's goal was to detect pallet defects (incorrect dimensions, missing
boards) inside an automated Product Inspection Entry, using 3D cameras instead
of manual inspection.

## The prototype

Beyond the software module, I was responsible for the **design and construction
of the physical prototype**: the CAD model, the assembly, camera positioning and
calibration, and the conveyor masks.

![PIE CAD model](img/prototipo_cad.png)

A full-scale PIE wasn't possible in the lab, so the prototype inverts the
geometry: the pallet slides **underneath** the masks and the cameras are mounted
**above**, simulating the view from below the conveyors of a real PIE. An
earlier version with the pallet sliding on top of the masks was discarded
because it wouldn't run smoothly.

Two cameras, one perpendicular to the conveyor and one at 45°, on an adjustable
support so angle and height could be varied between tests:

![Camera support](img/soporte_camaras.png)

The masks reproduce the two conveyor types found in a PIE — rollers and chains —
to check that the method holds in both cases. The roller mask, mounted over the
test pallet:

![Roller mask](img/mascara_rodillos.jpg)

The design criteria were that it could be disassembled easily, that it was rigid
enough for measurements not to drift, and that it allowed adjustments as the
software side asked for changes. The stepper motor firmware that drives the
platform was written by another team member.

## Approach

The team evaluated **four approaches** in parallel, so as not to commit to a
single solution before investing in an expensive camera: side measurement, from
below, with perspective, and via 3D point cloud.

This repository covers the **fourth approach: pallet integrity checking using a
3D point map**, with an Intel RealSense D435i — a low-end 3D camera chosen under
budget constraints — to detect cracks and missing boards.

## My contribution

This repository contains **only the part I developed**: depth capture and the
point-cloud measurement pipeline. The full project was team work and lives at
[mahelbdlm/INT](https://github.com/mahelbdlm/INT).

## Captures

The physical pallet used in the prototype, with worn boards and irregular gaps:

![Real pallet](img/palet_real.jpg)

Point cloud reconstruction from the D435i depth map. The board structure and the
gaps between boards are distinguishable:

![Point cloud](img/nube_puntos.png)

Perspective view of the same capture, colored by height:

![Point cloud, perspective view](img/nube_puntos_perspectiva.png)

Top-down view of the point cloud during an inspection:

![Top-down view of the point cloud](img/deteccion_defectos.png)

## How defects are detected

The module doesn't classify defects directly: it measures the pallet and
compares it against a reference. Three chained mechanisms.

### 1. Depth threshold segmentation

The depth map arrives in millimeters and is converted to meters. The pallet is
isolated from the background and the floor by keeping only the pixels within a
known distance band:

```matlab
min_dist = 0.1;   % meters
max_dist = 0.75;
palet_mask = (depth >= min_dist) & (depth <= max_dist);
```

The band depends on the height at which the camera is mounted on the prototype.
Everything outside it (floor, structure, conveyor) is discarded before measuring.

### 2. Pearson correlation comparison

Two scans are captured and compared pixel by pixel over the segmented depth,
computing the Pearson correlation coefficient between both vectors and
expressing it as a percentage.

The idea: an intact pallet compared against the reference yields a high
correlation. A broken board, a gap or a crack changes the local geometry and
drives that percentage down. It works as a deviation indicator, not as a
locator of the specific defect.

### 3. Dimension measurement

Two independent paths, to cross-check results:

**Via depth** (`mesure_depth_solution.m`) — over a selected ROI, pixel size is
derived from the D435i field of view (87° × 58°) and the capture resolution:

```matlab
pixelSizeX = (2 * tan(deg2rad(87/2)) / 640) * 1000;   % mm/pixel
```

That yields width and height in millimeters, plus the mean depth of the ROI.
Measurements are checked against the standard ones: 80 cm wide for the European
pallet, 100 cm for the American one.

**Via RGB** (`mesures_rgb.m`) — two consecutive grayscale frames are subtracted
and the difference is thresholded to isolate what moved:

```matlab
diff_image  = abs(double(gray1) - double(gray2));
motion_mask = diff_image > 30;
```

The mask is cleaned with morphological opening and closing (disk-shaped
structuring element, radius 5), edges are detected with Canny, and the largest
connected region is kept. Its bounding box gives the pallet dimensions.

## Results

**What worked:**

- **Detection of large cracks.** Breaks and missing boards of appreciable size
  show up as clear discontinuities in the point cloud and are detected
  consistently.
- **Dimension measurement.** Pallet width and height are obtained with enough
  precision for the use case.
- **Pallet type identification.** Those measurements distinguish the European
  pallet (80 cm wide) from the American one (100 cm), which was one of the
  project requirements.

**What didn't work:**

- **Small fissures are missed.** This is the method's real limit as it stands.
  Below a certain size, the defect doesn't separate from the sensor's own noise
  and goes undetected. For a real PIE this matters, since a small crack can
  propagate under load.

This was precisely the question the project set out to answer before spending on
hardware: whether a low-end 3D camera like the D435i offered enough resolution.
The answer was yes for large structural defects and for dimensioning the pallet,
and no for fine fissures — which sets the bar a better camera would have to
clear.

The results weren't judged in isolation: measurements from this path were
cross-checked against the team's other three approaches — side, from below and
with perspective — on the same pallets. That comparison between methods is what
made it possible to decide what was reliable. Data from the other approaches is
in the [group repository](https://github.com/mahelbdlm/INT).

**What's still open:**

- Detection of fine fissures, which would require a higher-resolution camera or
  a different sensor.
- Automatic localization and classification of the defect. The correlation
  returns a single scalar for the whole image: it indicates how far the pallet
  deviates from the reference, but gives no coordinates. Locating the damage is
  done by inspecting the point cloud or the segmented depth map, where cracks
  and missing boards are clearly visible. Automating that step fell outside the
  project's scope.
- Calibration independent of mounting height. The pixel-to-meter conversion on
  the RGB path uses a fixed factor calibrated for one specific distance, and the
  FOV-based pixel size calculation assumes a plane at constant depth.
- Reading directly from the camera instead of pre-recorded `.mat` files.
- Automatic ROI selection in `mesure_depth_solution.m`, currently manual.

## Structure

| File | What it does |
|---|---|
| `connectDepth.m` | Configures the D435i pipeline (resolution and fps parameterizable) |
| `depthCapture.m` | Depth frame capture |
| `scan2images.m` | Converts a scan into an image sequence |
| `scan2mascara.m` | Isolates the pallet by distance threshold and builds the mask |
| `mesures_rgb.m` | RGB-channel measurement, with motion detection between frames |
| `mesure_depth_solution.m` | Depth-map measurement via Image Acquisition Toolbox |
| `video_mesura.m` | Measurement over video sequences |
| `janvideo.m` | Capture playback utility |
| `prueba1.m` | Pipeline test script |
| `indent.m` | Helper utility |

Source comments are in Spanish, as originally written.

## Requirements

- MATLAB (tested on R2024a)
- Image Processing Toolbox / Computer Vision Toolbox
- Intel RealSense D435i + SDK

## Context

Developed between October and December 2024. The original commit history for
this work is in the group repository linked above.
