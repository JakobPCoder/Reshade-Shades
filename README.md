# Shades
Shades is a collection of my updated Reshade shaders.

<!-- README_TOC_START -->
## Table of contents

- [Shades](#shades)
  - [Installation](#installation)
    - [A. ReShade installer (SOON)](#a-reshade-installer-soon)
    - [B. Manual](#b-manual)
- [Shaders .fx](#shaders-fx)
- [TFAA.fx](#tfaafx)
  - [What it is](#what-it-is)
  - [Compatible Spatial Anti-Aliasing Methods](#compatible-spatial-anti-aliasing-methods)
  - [How it works](#how-it-works)
  - [Dependencies](#dependencies)
  - [Runtime Settings](#runtime-settings)
  - [Preprocessor Controls.](#preprocessor-controls)
  - [History Resampling](#history-resampling)
  - [History Validation](#history-validation)
  - [History Rectification](#history-rectification)
- [LICENSE](#license)
<!-- README_TOC_END -->

## **Installation**
### *A. ReShade installer* (SOON)
1. *Run the [Reshade](https://reshade.me/) installer.*
2. *Select your target game.*
3. *Select the correct rendering API (DirectX 9, 10, 11, 12, OpenGL or Vulkan).*
4. *If you already have Reshade installed for that game select: `Update ReShade and Effects`.*
5. *Toggle the checkmark on `Shades`.*
6. *Click on next or continue to install.*
### B. Manual 
If reshade is alredy installed for that game you can install the shaders manually by:
1. Locating the games executable `.exe` file. Next to it you will find folder named `./reshade-shaders` with subfolders `/Shaders` and `/Textures`.
2. Download the whole repo and drop the `/Shaders` and `/Textures` folders into the `./reshade-shaders` folder.
3. In the reshade seettings add the `/Shaders/Shades` and `/Textures/Shades` folders to the "Texture Search Paths" and "Effect Search Paths" respectively.

# Shaders .fx

# **TFAA**.*fx*
## **What it is**
**TFAA** is a purely temporal anti-aliasing component, used to get the closest thing to real temporal anti-aliasing possible in a [Reshade](https://reshade.me/) shader.

<!-- TFAA_EXMAPLE_VIDEO_START -->
<p style="margin:0 0 8px 0;"><img src="./misc/videos/1_smaa.webp" alt="1 — SMAA" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></p>
<p style="margin:0 0 8px 0;"><img src="./misc/videos/1_smaa+tfaa.webp" alt="1 — SMAA + TFAA" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></p>
<div align="center">

*Top: SMAA · Bottom: SMAA + TFAA*

</div>
<!-- TFAA_EXMAPLE_VIDEO_END -->

**TFAA**, or any temporal filter for that matter, does not smooth edges that are static on screen by itself. It only accumulates data over mulitple frames to produce a higher quality image.
This means that static edges need a seperate, spatial anti-aliasing method to be applied to them. The great thing is, also moving edges profit from first being spatialy and than temporally anti-aliased.

Any ingame anti-aliasing method that does not destroy the access to the depth buffer and any Reshade anti-aliasing shader can be used in conjunction with TFAA.

## Compatible Spatial Anti-Aliasing Methods

- [FXAA](https://developer.download.nvidia.com/assets/gamedev/files/sdk/11/FXAA_WhitePaper.pdf) Fast Approximate Anti-Aliasing
- [MLAA](https://www.cs.cmu.edu/afs/cs/academic/class/15869-f11/www/readings/reshetov09_mlaa.pdf) Morphological Anti-Aliasing
- [SMAA](https://www.iryoku.com/smaa/downloads/SMAA-Enhanced-Subpixel-Morphological-Antialiasing.pdf) Subpixel Morphological Anti-Aliasing. Only ones that do not already include a temporal component
    - These ones make sense to use with TFAA:
        - [$\color{green}{\textsf{SMAA}}$](https://www.iryoku.com/smaa/downloads/SMAA-Enhanced-Subpixel-Morphological-Antialiasing.pdf) - *Orignal*
        - [$\color{green}{\textsf{SMAA}}$ **1x**](https://www.iryoku.com/smaa/downloads/SMAA-Enhanced-Subpixel-Morphological-Antialiasing.pdf) - *Same as "SMAA"*
    - These ones not:
        - [$\color{red}{\textsf{SMAA}}$ **s2x**](https://www.iryoku.com/smaa/downloads/SMAA-Enhanced-Subpixel-Morphological-Antialiasing.pdf) - *2x Spatial supersampling*
        - [$\color{red}{\textsf{SMAA}}$ **t2x**]((https://www.iryoku.com/smaa/downloads/SMAA-Enhanced-Subpixel-Morphological-Antialiasing.pdf)) - *2x Temporal supersampling*
        - [$\color{red}{\textsf{SMAA}}$ **4x**](https://www.iryoku.com/smaa/downloads/SMAA-Enhanced-Subpixel-Morphological-Antialiasing.pdf) - *2x Spatial + 2x Temporal supersampling*
        - [$\color{red}{\textsf{Filmic SMAA}}$ **1x**](https://www.activision.com/cdn/research/Dynamic_Temporal_Antialiasing_and_Upsampling_in_Call_of_Duty_v4.pdf) - *1x Temporal Filtering*
        - [$\color{red}{\textsf{Filmic SMAA}}$ **t2x**](https://www.activision.com/cdn/research/Dynamic_Temporal_Antialiasing_and_Upsampling_in_Call_of_Duty_v4.pdf) - *2x Temporal supersampling + temporal filtering*
        - [$\color{red}{\textsf{Filmic SMAA}}$ **TU2x**](https://www.activision.com/cdn/research/Dynamic_Temporal_Antialiasing_and_Upsampling_in_Call_of_Duty_v4.pdf) - *2x Temporal Upsampling + temporal filtering*
        - [$\color{red}{\textsf{Filmic SMAA}}$ **TU4x**](https://www.activision.com/cdn/research/Dynamic_Temporal_Antialiasing_and_Upsampling_in_Call_of_Duty_v4.pdf) - *4x Temporal Upsampling + temporal filtering*
- [**CMAA**](https://www.intel.com/content/www/us/en/developer/articles/technical/conservative-morphological-anti-aliasing-20.html) |  Conservative Morphological Anti-Aliasing
- [**"Post Anti-Aliasing"**]() Whatever is listed as *"Post Anti-Aliasing"* in the game's settings should work, as long as it does not have a temporal component.


Below you can see how TFAA and SMAA can work together on edges in motion.

<!-- TFAA_EXMAPLE_Images_START -->
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="18%" style="width:18%;"></th>
<th width="41%" style="width:41%;">Without SMAA</th>
<th width="41%" style="width:41%;">With SMAA</th>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;">Without TFAA</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/images/1_none.png" alt="1 — NONE" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/images/1_smaa.png" alt="1 — SMAA" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;">With TFAA</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/images/1_tfaa.png" alt="1 — TFAA" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/images/1_smaa+tfaa.png" alt="1 — SMAA + TFAA" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>
<!-- TFAA_EXMAPLE_Images_END -->


## **How it works**
The most basic verion of a temporal filter as in TFAA or in well known industry solutions like Filmic SMAA T1x consists of the following steps:
1. [**History data**](#history-resampling) is [sampled](#history-resampling) for each pixel using the **velocity buffer** and an accumulated **history buffer**.
2. **Validatate** that history data is plausible and reject if not.
3. [**Rectificy**](#history-rectification) history data to the neighborhood of the current frame.
4. **Blend** new frame data with the rectified history data.
5. **Write Data** blended data to the history buffer.

## **Dependencies**
 - The **depth buffer** being available and configured correctly. (Check via DisplayDepth.fx)
 - [LAUNCHPAD](https://github.com/martymcmodding/iMMERSE/blob/main/Shaders/MartysMods_LAUNCHPAD.fx) being 
 installed with all its dependencies. (Just installl the IMMERSE shader pack when installing Reshade.)
 - Some **spatial anti-aliasing** method being run either ingame or via Reshade **before TFAA**.

## **Runtime Settings**
| [**`TFAA_SAMPLING_METHOD`**] | |

## **Preprocessor Controls**. 
These Settings are implemented as preprocessor defines instead of runtime branching for performance reasons.

|  |  |  |  |
|:-|:-|:-|:-|
| [**`TFAA_SAMPLING_METHOD`**](#history-resampling) | [**Value**]() | [**Samples**]() | [**Description**]() |
| *BILINEAR* | *`0`* | 1-tap | Hardware [bilinear](https://en.wikipedia.org/wiki/Bilinear_interpolation) tap |
| **CATMULLROM** | **`1`** | 5-tap | [Catmull-Rom](https://en.wikipedia.org/wiki/Catmull%E2%80%93Rom_spline) |
| *LANCZOS2* | *`2`* | 16-tap | [Lanczos-2](https://en.wikipedia.org/wiki/Lanczos_resampling) |
| *LANCZOS3* | *`3`* | 36-tap | [Lanczos-3](https://en.wikipedia.org/wiki/Lanczos_resampling) |
| *LANCZOS4* | *`4`* | 64-tap | [Lanczos-4](https://en.wikipedia.org/wiki/Lanczos_resampling) |
| *FSR EASU* ($\color{red}{\textsf{BROKEN}}$) | *`5`* | 12-tap | [AMD FidelityFX EASU](https://github.com/GPUOpen-Effects/FidelityFX-FSR)  |
|  |  |  |
| [**`TFAA_RECTIFY_COLOR_SPACE`**](#color-rectification-visualization) | [**Value**]() | [**Channels**]() | [**Description**]() |
| *RGB* | *`0`* | **R**: $\color{red}{\textsf{Red}}$<br>**G**: $\color{green}{\textsf{Green}}$<br>**B**: $\color{blue}{\textsf{Blue}}$ | No color transform (identity); loosest rectification bounds. Most blurring and most color deviation artifacts.|
| *YCbCr* | *`1`* | **Y**: BT.601 **luma**<br>**Cb**: $\color{blue}{\textsf{blue}}$-$\color{yellow}{\textsf{yellow}}$<br>**Cr**: $\color{red}{\textsf{red}}$-$\color{cyan}{\textsf{cyan}}$ | ITU-R BT.601 / JPEG-style full-range chroma scales (not broadcast limited-range packing). Chrominance more correlated across axes than YCoCg. Rectify path stores Cb/Cr with **+0.5** offset so all axes are in [0,1]. |
| **YCoCg** | **`2`** | **Y**: (R+2G+B)/4 **luma**<br>**Co**: $\color{orange}{\textsf{orange}}$-$\color{cyan}{\textsf{cyan}}$<br>**Cg**: $\color{green}{\textsf{green}}$-$\color{magenta}{\textsf{magenta}}$ | Malvar & Sullivan (2003 YCoCg); orthogonal chroma, more decorrelated than YCbCr. Rectify path stores Co/Cg with **+0.5** offset so all axes are in [0,1]. |
|  |  |  |
| [**`TFAA_RECTIFY_OP`**](#history-rectification) | [**Value**]() |  | [**Description**]() |
| *CLAMP*         | *`0`* |   | Clamp history to the AABB. (**`TFAA_RECTIFY_SHAPE`** is ignored). |  |
| *CLIP_NEAREST*  | *`1`* |  | Ray clip towards neighborhood sample **closest** to history in rectification space. |  |
| *CLIP_MEAN*     | *`2`* |  | Ray clip towards the nine-tap arithmetic **average**. |  |
| *CLIP_CENTROID* | *`3`* |  | Ray clip towards the per-channel **midpoint** `(min+max)/2`. |  |
| **CLIP_CURRENT**  | **`4`** |  | Ray clip towards the **current** pixel. |  |
|  |  |  |
| [**`TFAA_RECTIFY_SHAPE`**](#history-rectification) | [**Value**]() |  | [**Description**]() |
| *AABB* | *`0`* |  | **3**-axis \| **6**-faces<br>Box - classic axis-aligned box used for clipping/clamping in common industry TAA solutions. |  |
| **14-DOP** | **`1`** |  | **7**-axis \| **14** - faces \| Box with cut corners.<br> |  |
| *18-DOP* | *`2`* |  | **9**-axis \| **18** - faces \| Box with cut edges.<br> |  |
| *26-DOP* | *`3`* |  | **13**-axis \| **26** - faces\| Box with cut corners and edges.<br> |
|_________________________________|______|_______________________|____________________________________________________________________|
|  |  |  |




 


## History Resampling

When TFAA reads **history data**, the sample position will most likely sit at a **subpixel positon**. Depending on what method is used to interpolate between real data points, the results can vary greatly. Cheaper methods generally blur more, expensive methods tend to preserve more detail but might also introduce more artifacts.

Below you can see some examples of how the differnt sampling methods behave when sampling at subpixel positions **0.125**, **0.25**, and **0.5**.



<!-- RESAMPLE_TABLE_START -->
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="14%" style="width:14%;"></th>
<th width="21.5%">0.0 offset</th>
<th width="21.5%">0.125</th>
<th width="21.5%">0.25</th>
<th width="21.5%">0.5</th>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Bilinear<br />1 tap</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_bilinear_dx0p000_dy0p000.png" alt="Bilinear - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_bilinear_dx0p125_dy0p125.png" alt="Bilinear dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_bilinear_dx0p250_dy0p250.png" alt="Bilinear dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_bilinear_dx0p500_dy0p500.png" alt="Bilinear dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Catmull–Rom<br />5 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_catmullrom_dx0p000_dy0p000.png" alt="Catmull–Rom - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_catmullrom_dx0p125_dy0p125.png" alt="Catmull–Rom dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_catmullrom_dx0p250_dy0p250.png" alt="Catmull–Rom dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_catmullrom_dx0p500_dy0p500.png" alt="Catmull–Rom dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Lanczos 2<br />16 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_lanczos2_dx0p000_dy0p000.png" alt="Lanczos 2 - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_lanczos2_dx0p125_dy0p125.png" alt="Lanczos 2 dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_lanczos2_dx0p250_dy0p250.png" alt="Lanczos 2 dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_lanczos2_dx0p500_dy0p500.png" alt="Lanczos 2 dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Lanczos 3<br />36 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_lanczos3_dx0p000_dy0p000.png" alt="Lanczos 3 - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_lanczos3_dx0p125_dy0p125.png" alt="Lanczos 3 dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_lanczos3_dx0p250_dy0p250.png" alt="Lanczos 3 dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_lanczos3_dx0p500_dy0p500.png" alt="Lanczos 3 dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Lanczos 4<br />64 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_lanczos4_dx0p000_dy0p000.png" alt="Lanczos 4 - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_lanczos4_dx0p125_dy0p125.png" alt="Lanczos 4 dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_lanczos4_dx0p250_dy0p250.png" alt="Lanczos 4 dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_lanczos4_dx0p500_dy0p500.png" alt="Lanczos 4 dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">FSR EASU<br />12 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_easu_dx0p000_dy0p000.png" alt="FSR EASU - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_easu_dx0p125_dy0p125.png" alt="FSR EASU dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_easu_dx0p250_dy0p250.png" alt="FSR EASU dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/1/1_easu_dx0p500_dy0p500.png" alt="FSR EASU dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>

<details style="margin-top:8px;">

<summary><strong>Show more examples</strong> — click to expand</summary>



<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="14%" style="width:14%;"></th>
<th width="21.5%">0.0 offset</th>
<th width="21.5%">0.125</th>
<th width="21.5%">0.25</th>
<th width="21.5%">0.5</th>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Bilinear<br />1 tap</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_bilinear_dx0p000_dy0p000.png" alt="Bilinear - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_bilinear_dx0p125_dy0p125.png" alt="Bilinear dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_bilinear_dx0p250_dy0p250.png" alt="Bilinear dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_bilinear_dx0p500_dy0p500.png" alt="Bilinear dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Catmull–Rom<br />5 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_catmullrom_dx0p000_dy0p000.png" alt="Catmull–Rom - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_catmullrom_dx0p125_dy0p125.png" alt="Catmull–Rom dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_catmullrom_dx0p250_dy0p250.png" alt="Catmull–Rom dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_catmullrom_dx0p500_dy0p500.png" alt="Catmull–Rom dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Lanczos 2<br />16 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_lanczos2_dx0p000_dy0p000.png" alt="Lanczos 2 - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_lanczos2_dx0p125_dy0p125.png" alt="Lanczos 2 dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_lanczos2_dx0p250_dy0p250.png" alt="Lanczos 2 dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_lanczos2_dx0p500_dy0p500.png" alt="Lanczos 2 dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Lanczos 3<br />36 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_lanczos3_dx0p000_dy0p000.png" alt="Lanczos 3 - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_lanczos3_dx0p125_dy0p125.png" alt="Lanczos 3 dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_lanczos3_dx0p250_dy0p250.png" alt="Lanczos 3 dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_lanczos3_dx0p500_dy0p500.png" alt="Lanczos 3 dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Lanczos 4<br />64 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_lanczos4_dx0p000_dy0p000.png" alt="Lanczos 4 - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_lanczos4_dx0p125_dy0p125.png" alt="Lanczos 4 dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_lanczos4_dx0p250_dy0p250.png" alt="Lanczos 4 dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_lanczos4_dx0p500_dy0p500.png" alt="Lanczos 4 dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">FSR EASU<br />12 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_easu_dx0p000_dy0p000.png" alt="FSR EASU - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_easu_dx0p125_dy0p125.png" alt="FSR EASU dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_easu_dx0p250_dy0p250.png" alt="FSR EASU dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/2/2_easu_dx0p500_dy0p500.png" alt="FSR EASU dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>

<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="14%" style="width:14%;"></th>
<th width="21.5%">0.0 offset</th>
<th width="21.5%">0.125</th>
<th width="21.5%">0.25</th>
<th width="21.5%">0.5</th>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Bilinear<br />1 tap</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_bilinear_dx0p000_dy0p000.png" alt="Bilinear - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_bilinear_dx0p125_dy0p125.png" alt="Bilinear dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_bilinear_dx0p250_dy0p250.png" alt="Bilinear dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_bilinear_dx0p500_dy0p500.png" alt="Bilinear dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Catmull–Rom<br />5 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_catmullrom_dx0p000_dy0p000.png" alt="Catmull–Rom - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_catmullrom_dx0p125_dy0p125.png" alt="Catmull–Rom dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_catmullrom_dx0p250_dy0p250.png" alt="Catmull–Rom dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_catmullrom_dx0p500_dy0p500.png" alt="Catmull–Rom dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Lanczos 2<br />16 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_lanczos2_dx0p000_dy0p000.png" alt="Lanczos 2 - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_lanczos2_dx0p125_dy0p125.png" alt="Lanczos 2 dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_lanczos2_dx0p250_dy0p250.png" alt="Lanczos 2 dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_lanczos2_dx0p500_dy0p500.png" alt="Lanczos 2 dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Lanczos 3<br />36 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_lanczos3_dx0p000_dy0p000.png" alt="Lanczos 3 - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_lanczos3_dx0p125_dy0p125.png" alt="Lanczos 3 dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_lanczos3_dx0p250_dy0p250.png" alt="Lanczos 3 dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_lanczos3_dx0p500_dy0p500.png" alt="Lanczos 3 dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">Lanczos 4<br />64 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_lanczos4_dx0p000_dy0p000.png" alt="Lanczos 4 - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_lanczos4_dx0p125_dy0p125.png" alt="Lanczos 4 dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_lanczos4_dx0p250_dy0p250.png" alt="Lanczos 4 dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_lanczos4_dx0p500_dy0p500.png" alt="Lanczos 4 dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
<tr>
<th align="left" valign="middle" style="text-align:left;vertical-align:middle;white-space:normal;">FSR EASU<br />12 taps</th>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_easu_dx0p000_dy0p000.png" alt="FSR EASU - 0.0 offset" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_easu_dx0p125_dy0p125.png" alt="FSR EASU dx dy 0.125" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_easu_dx0p250_dy0p250.png" alt="FSR EASU dx dy 0.25" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
<td valign="top" style="vertical-align:top;padding:4px;"><img src="./misc/output/resample_vis/3/3_easu_dx0p500_dy0p500.png" alt="FSR EASU dx dy 0.5" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>



</details>
<!-- RESAMPLE_TABLE_END -->

---
</br>

## History Validation
After a sample from the history buffer is taken, we need to find out if it is plausible that this sample belongs to our pixel in the current frame.
We do this primarily by checking for depth discontinuities and specifically disocclusion. This is important to avoid artifacts like ghosting.
If a sample is considered to be invalid, it is discared completly and only the data from teh new frame is considered.


## History Rectification
After a potentialy valid history sample has been found, we alreedy know that we gonna blend it into the current frame data by some amount.
Before we do this, we need to make sure

<!-- RECTIFICATION_BASICS_START -->
<div style="display:flex;flex-wrap:wrap;align-items:flex-start;gap:12px;margin:12px 0;">
<img src="./misc/output/clip_vis/key_neighborhood_dark.svg" alt="Neighborhood 3×3 sample grid" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
<img src="./misc/output/clip_vis/key_history_dark.svg" alt="History sample swatch" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
<img src="./misc/output/clip_vis/key_clipped_clamp_dark.svg" alt="Rectified RGB swatches - CLAMP" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
</div>

<div style="display:flex;flex-wrap:wrap;align-items:flex-start;gap:12px;margin:12px 0;">
<img src="./misc/output/clip_vis/key_clipped_clip_nearest_dark.svg" alt="Rectified RGB swatches - CLIP_NEAREST" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
<img src="./misc/output/clip_vis/key_clipped_clip_mean_dark.svg" alt="Rectified RGB swatches - CLIP_MEAN" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
<img src="./misc/output/clip_vis/key_clipped_clip_centroid_dark.svg" alt="Rectified RGB swatches - CLIP_CENTROID" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
<img src="./misc/output/clip_vis/key_clipped_clip_current_dark.svg" alt="Rectified RGB swatches - CLIP_CURRENT" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
</div>
<!-- RECTIFICATION_BASICS_END -->

<!-- RECTIFICATION_CLAMP_START -->
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">None</th><th width="25%">RGB</th><th width="25%">YCbCr</th><th width="25%">YCoCg</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_norectify_dark.svg" alt="No rectification (baseline)" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_aabb_clamp_dark.svg" alt="RGB rectify space clamp" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_aabb_clamp_dark.svg" alt="YCbCr rectify space clamp" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_aabb_clamp_dark.svg" alt="YCoCg rectify space clamp" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>
<!-- RECTIFICATION_CLAMP_END -->

<!-- RECTIFICATION_ALL_START -->
<details style="margin-top:8px;">
<summary><strong>Show all rectification diagrams</strong> — click to expand</summary>

<p style="margin:16px 0 8px;"><strong>CLIP_NEAREST</strong> (<code>TFAA_RECTIFY_OP</code> 1)</p>
<p style="margin:8px 0 4px;"><strong>YCoCg</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_aabb_clip_nearest_dark.svg" alt="YCoCg AABB CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_14dop_clip_nearest_dark.svg" alt="YCoCg 14-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_18dop_clip_nearest_dark.svg" alt="YCoCg 18-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_26dop_clip_nearest_dark.svg" alt="YCoCg 26-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>
<details style="margin-top:8px;">
<summary><strong>YCbCr &amp; RGB</strong> — click to expand</summary>

<p style="margin:12px 0 4px;"><strong>YCbCr</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_aabb_clip_nearest_dark.svg" alt="YCbCr AABB CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_14dop_clip_nearest_dark.svg" alt="YCbCr 14-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_18dop_clip_nearest_dark.svg" alt="YCbCr 18-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_26dop_clip_nearest_dark.svg" alt="YCbCr 26-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>

<p style="margin:12px 0 4px;"><strong>RGB</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_aabb_clip_nearest_dark.svg" alt="RGB AABB CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_14dop_clip_nearest_dark.svg" alt="RGB 14-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_18dop_clip_nearest_dark.svg" alt="RGB 18-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_26dop_clip_nearest_dark.svg" alt="RGB 26-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>

</details>

<p style="margin:16px 0 8px;"><strong>CLIP_MEAN</strong> (<code>TFAA_RECTIFY_OP</code> 2)</p>
<p style="margin:8px 0 4px;"><strong>YCoCg</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_aabb_clip_mean_dark.svg" alt="YCoCg AABB CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_14dop_clip_mean_dark.svg" alt="YCoCg 14-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_18dop_clip_mean_dark.svg" alt="YCoCg 18-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_26dop_clip_mean_dark.svg" alt="YCoCg 26-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>
<details style="margin-top:8px;">
<summary><strong>YCbCr &amp; RGB</strong> — click to expand</summary>

<p style="margin:12px 0 4px;"><strong>YCbCr</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_aabb_clip_mean_dark.svg" alt="YCbCr AABB CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_14dop_clip_mean_dark.svg" alt="YCbCr 14-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_18dop_clip_mean_dark.svg" alt="YCbCr 18-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_26dop_clip_mean_dark.svg" alt="YCbCr 26-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>

<p style="margin:12px 0 4px;"><strong>RGB</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_aabb_clip_mean_dark.svg" alt="RGB AABB CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_14dop_clip_mean_dark.svg" alt="RGB 14-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_18dop_clip_mean_dark.svg" alt="RGB 18-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_26dop_clip_mean_dark.svg" alt="RGB 26-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>

</details>

<p style="margin:16px 0 8px;"><strong>CLIP_CENTROID</strong> (<code>TFAA_RECTIFY_OP</code> 3)</p>
<p style="margin:8px 0 4px;"><strong>YCoCg</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_aabb_clip_centroid_dark.svg" alt="YCoCg AABB CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_14dop_clip_centroid_dark.svg" alt="YCoCg 14-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_18dop_clip_centroid_dark.svg" alt="YCoCg 18-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_26dop_clip_centroid_dark.svg" alt="YCoCg 26-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>
<details style="margin-top:8px;">
<summary><strong>YCbCr &amp; RGB</strong> — click to expand</summary>

<p style="margin:12px 0 4px;"><strong>YCbCr</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_aabb_clip_centroid_dark.svg" alt="YCbCr AABB CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_14dop_clip_centroid_dark.svg" alt="YCbCr 14-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_18dop_clip_centroid_dark.svg" alt="YCbCr 18-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_26dop_clip_centroid_dark.svg" alt="YCbCr 26-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>

<p style="margin:12px 0 4px;"><strong>RGB</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_aabb_clip_centroid_dark.svg" alt="RGB AABB CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_14dop_clip_centroid_dark.svg" alt="RGB 14-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_18dop_clip_centroid_dark.svg" alt="RGB 18-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_26dop_clip_centroid_dark.svg" alt="RGB 26-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>

</details>

<p style="margin:16px 0 8px;"><strong>CLIP_CURRENT</strong> (<code>TFAA_RECTIFY_OP</code> 4)</p>
<p style="margin:8px 0 4px;"><strong>YCoCg</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_aabb_clip_current_dark.svg" alt="YCoCg AABB CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_14dop_clip_current_dark.svg" alt="YCoCg 14-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_18dop_clip_current_dark.svg" alt="YCoCg 18-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_26dop_clip_current_dark.svg" alt="YCoCg 26-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>
<details style="margin-top:8px;">
<summary><strong>YCbCr &amp; RGB</strong> — click to expand</summary>

<p style="margin:12px 0 4px;"><strong>YCbCr</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_aabb_clip_current_dark.svg" alt="YCbCr AABB CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_14dop_clip_current_dark.svg" alt="YCbCr 14-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_18dop_clip_current_dark.svg" alt="YCbCr 18-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_26dop_clip_current_dark.svg" alt="YCbCr 26-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>

<p style="margin:12px 0 4px;"><strong>RGB</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_aabb_clip_current_dark.svg" alt="RGB AABB CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_14dop_clip_current_dark.svg" alt="RGB 14-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_18dop_clip_current_dark.svg" alt="RGB 18-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_26dop_clip_current_dark.svg" alt="RGB 26-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>

</details>

</details>
<!-- RECTIFICATION_ALL_END -->






<!-- README_REFERENCES_START -->
## References

1. https://creativecommons.org/licenses/by-nc-nd/4.0/
2. https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode
3. FXAA https://developer.download.nvidia.com/assets/gamedev/files/sdk/11/FXAA_WhitePaper.pdf
4. bilinear https://en.wikipedia.org/wiki/Bilinear_interpolation
5. Catmull-Rom https://en.wikipedia.org/wiki/Catmull%E2%80%93Rom_spline
6. Lanczos-2 https://en.wikipedia.org/wiki/Lanczos_resampling
7. AMD FidelityFX EASU https://github.com/GPUOpen-Effects/FidelityFX-FSR
8. LAUNCHPAD https://github.com/martymcmodding/iMMERSE/blob/main/Shaders/MartysMods_LAUNCHPAD.fx
9. Reshade https://reshade.me/
10. Filmic SMAA 1x https://www.activision.com/cdn/research/Dynamic_Temporal_Antialiasing_and_Upsampling_in_Call_of_Duty_v4.pdf
11. MLAA https://www.cs.cmu.edu/afs/cs/academic/class/15869-f11/www/readings/reshetov09_mlaa.pdf
12. CMAA https://www.intel.com/content/www/us/en/developer/articles/technical/conservative-morphological-anti-aliasing-20.html
13. SMAA https://www.iryoku.com/smaa/downloads/SMAA-Enhanced-Subpixel-Morphological-Antialiasing.pdf
<!-- README_REFERENCES_END -->

<!-- README_ASSETS_START -->
## Figures and assets

| Asset | Type |
| ----- | ---- |
| [`./LICENSE.md`](./LICENSE.md) | document |
| [`./misc/images/1_none.png`](./misc/images/1_none.png) | image |
| [`./misc/images/1_smaa+tfaa.png`](./misc/images/1_smaa+tfaa.png) | image |
| [`./misc/images/1_smaa.png`](./misc/images/1_smaa.png) | image |
| [`./misc/images/1_tfaa.png`](./misc/images/1_tfaa.png) | image |
| [`./misc/output/clip_vis/key_clipped_clamp_dark.svg`](./misc/output/clip_vis/key_clipped_clamp_dark.svg) | diagram |
| [`./misc/output/clip_vis/key_clipped_clip_centroid_dark.svg`](./misc/output/clip_vis/key_clipped_clip_centroid_dark.svg) | diagram |
| [`./misc/output/clip_vis/key_clipped_clip_current_dark.svg`](./misc/output/clip_vis/key_clipped_clip_current_dark.svg) | diagram |
| [`./misc/output/clip_vis/key_clipped_clip_mean_dark.svg`](./misc/output/clip_vis/key_clipped_clip_mean_dark.svg) | diagram |
| [`./misc/output/clip_vis/key_clipped_clip_nearest_dark.svg`](./misc/output/clip_vis/key_clipped_clip_nearest_dark.svg) | diagram |
| [`./misc/output/clip_vis/key_history_dark.svg`](./misc/output/clip_vis/key_history_dark.svg) | diagram |
| [`./misc/output/clip_vis/key_neighborhood_dark.svg`](./misc/output/clip_vis/key_neighborhood_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_14dop_clip_centroid_dark.svg`](./misc/output/clip_vis/rgb_14dop_clip_centroid_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_14dop_clip_current_dark.svg`](./misc/output/clip_vis/rgb_14dop_clip_current_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_14dop_clip_mean_dark.svg`](./misc/output/clip_vis/rgb_14dop_clip_mean_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_14dop_clip_nearest_dark.svg`](./misc/output/clip_vis/rgb_14dop_clip_nearest_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_18dop_clip_centroid_dark.svg`](./misc/output/clip_vis/rgb_18dop_clip_centroid_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_18dop_clip_current_dark.svg`](./misc/output/clip_vis/rgb_18dop_clip_current_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_18dop_clip_mean_dark.svg`](./misc/output/clip_vis/rgb_18dop_clip_mean_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_18dop_clip_nearest_dark.svg`](./misc/output/clip_vis/rgb_18dop_clip_nearest_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_26dop_clip_centroid_dark.svg`](./misc/output/clip_vis/rgb_26dop_clip_centroid_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_26dop_clip_current_dark.svg`](./misc/output/clip_vis/rgb_26dop_clip_current_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_26dop_clip_mean_dark.svg`](./misc/output/clip_vis/rgb_26dop_clip_mean_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_26dop_clip_nearest_dark.svg`](./misc/output/clip_vis/rgb_26dop_clip_nearest_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_aabb_clamp_dark.svg`](./misc/output/clip_vis/rgb_aabb_clamp_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_aabb_clip_centroid_dark.svg`](./misc/output/clip_vis/rgb_aabb_clip_centroid_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_aabb_clip_current_dark.svg`](./misc/output/clip_vis/rgb_aabb_clip_current_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_aabb_clip_mean_dark.svg`](./misc/output/clip_vis/rgb_aabb_clip_mean_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_aabb_clip_nearest_dark.svg`](./misc/output/clip_vis/rgb_aabb_clip_nearest_dark.svg) | diagram |
| [`./misc/output/clip_vis/rgb_norectify_dark.svg`](./misc/output/clip_vis/rgb_norectify_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_14dop_clip_centroid_dark.svg`](./misc/output/clip_vis/ycbcr_14dop_clip_centroid_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_14dop_clip_current_dark.svg`](./misc/output/clip_vis/ycbcr_14dop_clip_current_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_14dop_clip_mean_dark.svg`](./misc/output/clip_vis/ycbcr_14dop_clip_mean_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_14dop_clip_nearest_dark.svg`](./misc/output/clip_vis/ycbcr_14dop_clip_nearest_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_18dop_clip_centroid_dark.svg`](./misc/output/clip_vis/ycbcr_18dop_clip_centroid_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_18dop_clip_current_dark.svg`](./misc/output/clip_vis/ycbcr_18dop_clip_current_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_18dop_clip_mean_dark.svg`](./misc/output/clip_vis/ycbcr_18dop_clip_mean_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_18dop_clip_nearest_dark.svg`](./misc/output/clip_vis/ycbcr_18dop_clip_nearest_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_26dop_clip_centroid_dark.svg`](./misc/output/clip_vis/ycbcr_26dop_clip_centroid_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_26dop_clip_current_dark.svg`](./misc/output/clip_vis/ycbcr_26dop_clip_current_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_26dop_clip_mean_dark.svg`](./misc/output/clip_vis/ycbcr_26dop_clip_mean_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_26dop_clip_nearest_dark.svg`](./misc/output/clip_vis/ycbcr_26dop_clip_nearest_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_aabb_clamp_dark.svg`](./misc/output/clip_vis/ycbcr_aabb_clamp_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_aabb_clip_centroid_dark.svg`](./misc/output/clip_vis/ycbcr_aabb_clip_centroid_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_aabb_clip_current_dark.svg`](./misc/output/clip_vis/ycbcr_aabb_clip_current_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_aabb_clip_mean_dark.svg`](./misc/output/clip_vis/ycbcr_aabb_clip_mean_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycbcr_aabb_clip_nearest_dark.svg`](./misc/output/clip_vis/ycbcr_aabb_clip_nearest_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_14dop_clip_centroid_dark.svg`](./misc/output/clip_vis/ycocg_14dop_clip_centroid_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_14dop_clip_current_dark.svg`](./misc/output/clip_vis/ycocg_14dop_clip_current_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_14dop_clip_mean_dark.svg`](./misc/output/clip_vis/ycocg_14dop_clip_mean_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_14dop_clip_nearest_dark.svg`](./misc/output/clip_vis/ycocg_14dop_clip_nearest_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_18dop_clip_centroid_dark.svg`](./misc/output/clip_vis/ycocg_18dop_clip_centroid_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_18dop_clip_current_dark.svg`](./misc/output/clip_vis/ycocg_18dop_clip_current_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_18dop_clip_mean_dark.svg`](./misc/output/clip_vis/ycocg_18dop_clip_mean_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_18dop_clip_nearest_dark.svg`](./misc/output/clip_vis/ycocg_18dop_clip_nearest_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_26dop_clip_centroid_dark.svg`](./misc/output/clip_vis/ycocg_26dop_clip_centroid_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_26dop_clip_current_dark.svg`](./misc/output/clip_vis/ycocg_26dop_clip_current_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_26dop_clip_mean_dark.svg`](./misc/output/clip_vis/ycocg_26dop_clip_mean_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_26dop_clip_nearest_dark.svg`](./misc/output/clip_vis/ycocg_26dop_clip_nearest_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_aabb_clamp_dark.svg`](./misc/output/clip_vis/ycocg_aabb_clamp_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_aabb_clip_centroid_dark.svg`](./misc/output/clip_vis/ycocg_aabb_clip_centroid_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_aabb_clip_current_dark.svg`](./misc/output/clip_vis/ycocg_aabb_clip_current_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_aabb_clip_mean_dark.svg`](./misc/output/clip_vis/ycocg_aabb_clip_mean_dark.svg) | diagram |
| [`./misc/output/clip_vis/ycocg_aabb_clip_nearest_dark.svg`](./misc/output/clip_vis/ycocg_aabb_clip_nearest_dark.svg) | diagram |
| [`./misc/output/resample_vis/1/1_bilinear_dx0p000_dy0p000.png`](./misc/output/resample_vis/1/1_bilinear_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/1/1_bilinear_dx0p125_dy0p125.png`](./misc/output/resample_vis/1/1_bilinear_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/1/1_bilinear_dx0p250_dy0p250.png`](./misc/output/resample_vis/1/1_bilinear_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/1/1_bilinear_dx0p500_dy0p500.png`](./misc/output/resample_vis/1/1_bilinear_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/1/1_catmullrom_dx0p000_dy0p000.png`](./misc/output/resample_vis/1/1_catmullrom_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/1/1_catmullrom_dx0p125_dy0p125.png`](./misc/output/resample_vis/1/1_catmullrom_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/1/1_catmullrom_dx0p250_dy0p250.png`](./misc/output/resample_vis/1/1_catmullrom_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/1/1_catmullrom_dx0p500_dy0p500.png`](./misc/output/resample_vis/1/1_catmullrom_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/1/1_easu_dx0p000_dy0p000.png`](./misc/output/resample_vis/1/1_easu_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/1/1_easu_dx0p125_dy0p125.png`](./misc/output/resample_vis/1/1_easu_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/1/1_easu_dx0p250_dy0p250.png`](./misc/output/resample_vis/1/1_easu_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/1/1_easu_dx0p500_dy0p500.png`](./misc/output/resample_vis/1/1_easu_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/1/1_lanczos2_dx0p000_dy0p000.png`](./misc/output/resample_vis/1/1_lanczos2_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/1/1_lanczos2_dx0p125_dy0p125.png`](./misc/output/resample_vis/1/1_lanczos2_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/1/1_lanczos2_dx0p250_dy0p250.png`](./misc/output/resample_vis/1/1_lanczos2_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/1/1_lanczos2_dx0p500_dy0p500.png`](./misc/output/resample_vis/1/1_lanczos2_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/1/1_lanczos3_dx0p000_dy0p000.png`](./misc/output/resample_vis/1/1_lanczos3_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/1/1_lanczos3_dx0p125_dy0p125.png`](./misc/output/resample_vis/1/1_lanczos3_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/1/1_lanczos3_dx0p250_dy0p250.png`](./misc/output/resample_vis/1/1_lanczos3_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/1/1_lanczos3_dx0p500_dy0p500.png`](./misc/output/resample_vis/1/1_lanczos3_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/1/1_lanczos4_dx0p000_dy0p000.png`](./misc/output/resample_vis/1/1_lanczos4_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/1/1_lanczos4_dx0p125_dy0p125.png`](./misc/output/resample_vis/1/1_lanczos4_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/1/1_lanczos4_dx0p250_dy0p250.png`](./misc/output/resample_vis/1/1_lanczos4_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/1/1_lanczos4_dx0p500_dy0p500.png`](./misc/output/resample_vis/1/1_lanczos4_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/2/2_bilinear_dx0p000_dy0p000.png`](./misc/output/resample_vis/2/2_bilinear_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/2/2_bilinear_dx0p125_dy0p125.png`](./misc/output/resample_vis/2/2_bilinear_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/2/2_bilinear_dx0p250_dy0p250.png`](./misc/output/resample_vis/2/2_bilinear_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/2/2_bilinear_dx0p500_dy0p500.png`](./misc/output/resample_vis/2/2_bilinear_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/2/2_catmullrom_dx0p000_dy0p000.png`](./misc/output/resample_vis/2/2_catmullrom_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/2/2_catmullrom_dx0p125_dy0p125.png`](./misc/output/resample_vis/2/2_catmullrom_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/2/2_catmullrom_dx0p250_dy0p250.png`](./misc/output/resample_vis/2/2_catmullrom_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/2/2_catmullrom_dx0p500_dy0p500.png`](./misc/output/resample_vis/2/2_catmullrom_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/2/2_easu_dx0p000_dy0p000.png`](./misc/output/resample_vis/2/2_easu_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/2/2_easu_dx0p125_dy0p125.png`](./misc/output/resample_vis/2/2_easu_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/2/2_easu_dx0p250_dy0p250.png`](./misc/output/resample_vis/2/2_easu_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/2/2_easu_dx0p500_dy0p500.png`](./misc/output/resample_vis/2/2_easu_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/2/2_lanczos2_dx0p000_dy0p000.png`](./misc/output/resample_vis/2/2_lanczos2_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/2/2_lanczos2_dx0p125_dy0p125.png`](./misc/output/resample_vis/2/2_lanczos2_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/2/2_lanczos2_dx0p250_dy0p250.png`](./misc/output/resample_vis/2/2_lanczos2_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/2/2_lanczos2_dx0p500_dy0p500.png`](./misc/output/resample_vis/2/2_lanczos2_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/2/2_lanczos3_dx0p000_dy0p000.png`](./misc/output/resample_vis/2/2_lanczos3_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/2/2_lanczos3_dx0p125_dy0p125.png`](./misc/output/resample_vis/2/2_lanczos3_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/2/2_lanczos3_dx0p250_dy0p250.png`](./misc/output/resample_vis/2/2_lanczos3_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/2/2_lanczos3_dx0p500_dy0p500.png`](./misc/output/resample_vis/2/2_lanczos3_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/2/2_lanczos4_dx0p000_dy0p000.png`](./misc/output/resample_vis/2/2_lanczos4_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/2/2_lanczos4_dx0p125_dy0p125.png`](./misc/output/resample_vis/2/2_lanczos4_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/2/2_lanczos4_dx0p250_dy0p250.png`](./misc/output/resample_vis/2/2_lanczos4_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/2/2_lanczos4_dx0p500_dy0p500.png`](./misc/output/resample_vis/2/2_lanczos4_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/3/3_bilinear_dx0p000_dy0p000.png`](./misc/output/resample_vis/3/3_bilinear_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/3/3_bilinear_dx0p125_dy0p125.png`](./misc/output/resample_vis/3/3_bilinear_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/3/3_bilinear_dx0p250_dy0p250.png`](./misc/output/resample_vis/3/3_bilinear_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/3/3_bilinear_dx0p500_dy0p500.png`](./misc/output/resample_vis/3/3_bilinear_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/3/3_catmullrom_dx0p000_dy0p000.png`](./misc/output/resample_vis/3/3_catmullrom_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/3/3_catmullrom_dx0p125_dy0p125.png`](./misc/output/resample_vis/3/3_catmullrom_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/3/3_catmullrom_dx0p250_dy0p250.png`](./misc/output/resample_vis/3/3_catmullrom_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/3/3_catmullrom_dx0p500_dy0p500.png`](./misc/output/resample_vis/3/3_catmullrom_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/3/3_easu_dx0p000_dy0p000.png`](./misc/output/resample_vis/3/3_easu_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/3/3_easu_dx0p125_dy0p125.png`](./misc/output/resample_vis/3/3_easu_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/3/3_easu_dx0p250_dy0p250.png`](./misc/output/resample_vis/3/3_easu_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/3/3_easu_dx0p500_dy0p500.png`](./misc/output/resample_vis/3/3_easu_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/3/3_lanczos2_dx0p000_dy0p000.png`](./misc/output/resample_vis/3/3_lanczos2_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/3/3_lanczos2_dx0p125_dy0p125.png`](./misc/output/resample_vis/3/3_lanczos2_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/3/3_lanczos2_dx0p250_dy0p250.png`](./misc/output/resample_vis/3/3_lanczos2_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/3/3_lanczos2_dx0p500_dy0p500.png`](./misc/output/resample_vis/3/3_lanczos2_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/3/3_lanczos3_dx0p000_dy0p000.png`](./misc/output/resample_vis/3/3_lanczos3_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/3/3_lanczos3_dx0p125_dy0p125.png`](./misc/output/resample_vis/3/3_lanczos3_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/3/3_lanczos3_dx0p250_dy0p250.png`](./misc/output/resample_vis/3/3_lanczos3_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/3/3_lanczos3_dx0p500_dy0p500.png`](./misc/output/resample_vis/3/3_lanczos3_dx0p500_dy0p500.png) | image |
| [`./misc/output/resample_vis/3/3_lanczos4_dx0p000_dy0p000.png`](./misc/output/resample_vis/3/3_lanczos4_dx0p000_dy0p000.png) | image |
| [`./misc/output/resample_vis/3/3_lanczos4_dx0p125_dy0p125.png`](./misc/output/resample_vis/3/3_lanczos4_dx0p125_dy0p125.png) | image |
| [`./misc/output/resample_vis/3/3_lanczos4_dx0p250_dy0p250.png`](./misc/output/resample_vis/3/3_lanczos4_dx0p250_dy0p250.png) | image |
| [`./misc/output/resample_vis/3/3_lanczos4_dx0p500_dy0p500.png`](./misc/output/resample_vis/3/3_lanczos4_dx0p500_dy0p500.png) | image |
| [`./misc/videos/1_smaa+tfaa.webp`](./misc/videos/1_smaa+tfaa.webp) | image |
| [`./misc/videos/1_smaa.webp`](./misc/videos/1_smaa.webp) | image |
<!-- README_ASSETS_END -->

# LICENSE
- License File: [LICENSE.md](./LICENSE.md)
- Human-readable summary of the License: https://creativecommons.org/licenses/by-nc-nd/4.0/
- Full legal code: https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode


