# Shades
Shades is a collection of my updated Reshade shaders.
## **Installation**
### A. ReShade installer
1. Run the [Reshade](https://reshade.me/) installer.
2. Select your target game.
3. Select the correct rendering API (DirectX 9, 10, 11, 12, OpenGL or Vulkan).
4. If you already have Reshade installed for that game select: `Update ReShade and Effects`.
5. Toggle the checkmark on `Shades`.
6. Click on next or continue to install.
### B. Manual 
If reshade is alredy installed for that game you can install the shaders manually by:
1. Locating the games executable `.exe` file. Next to it you will find folder named `./reshade-shaders` with subfolders `/Shaders` and `/Textures`.
2. Download the whole repo and drop the `/Shaders` and `/Textures` folders into the `./reshade-shaders` folder.
3. In the reshade seettings add the `/Shaders/Shades` and `/Textures/Shades` folders to the "Texture Search Paths" and "Effect Search Paths" respectively.

# Shaders *`.fx`*

## **TFAA**.*fx*
### **What it is**
**TFAA** is a purely temporal anti-aliasing component, used to get the closest thing to real temporal anti-aliasing possible in a [Reshade](https://reshade.me/) shader.

<!-- TFAA_EXMAPLE_VIDEO_START -->
<p style="margin:0 0 8px 0;"><img src="./misc/videos/1_smaa.webp" alt="1 — SMAA" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></p>
<p style="margin:0 0 8px 0;"><img src="./misc/videos/1_smaa+tfaa.webp" alt="1 — SMAA + TFAA" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></p>
<div align="center">

*Top: SMAA · Bottom: SMAA + TFAA*

</div>
<!-- TFAA_EXMAPLE_VIDEO_END -->


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


### **How it works**
The most basic verion of temporal filters as in TFAA or in well known industry solutions like Filmic SMAA T1x consists of the following steps:
1. **History data** is [sampled](#history-resampling) for each pixel using the velocity buffer and accumulated history buffer.
2. **Validate** that history data is plausible and **reject** if not.
3. **Rectification** of the history data. 
    - a.) If the history data is valid, we rectify it to the neighborhood of the current frame.
    - b.) If the history data is not valid, we skip this and go straight to 5.
4. **Blending** of the new data with the rectified history data.
5. **Writing Data** of either the blendend data or the new data only into the history buffer.


### **Dependencies**
 - The **depth buffer** being available and configured correctly. (Check via DisplayDepth.fx)
 - [LAUNCHPAD](https://github.com/martymcmodding/iMMERSE/blob/main/Shaders/MartysMods_LAUNCHPAD.fx) being 
 installed with all its dependencies. (Just installl the IMMERSE shader pack when installing Reshade.)
 - Some **spatial anti-aliasing** method being run either ingame or via Reshade **before TFAA**.

### **Preprocessor controls in `TFAA.fx`**. 
These Settings are implemented as preprocessor defines instead of runtime branching for performance reasons.

|  |  |  |  |  |  |  |
|---|---|---|---|---|---|---|
| [**`TFAA_SAMPLING_METHOD`**](#history-resampling) | [**Value**]() | [**Setting**]() | [**Samples**]() | [**Quality**]() | [**Performance**]() | [**Description**]() |
|           | `0` | **BILINEAR** | 1-tap | *Ass* (1/5) | *Great* (5/5) | Hardware bilinear tap |
| *default* | `1` | **CATMULLROM** | 5-tap | *Ok* (3/5) | *Good* (4/5) | [Catmull-Rom](https://en.wikipedia.org/wiki/Catmull%E2%80%93Rom_spline) |
|           | `2` | **LANCZOS2** | 16-tap | *Ok* (3/5) | *Ok* (3/5) | [Lanczos-2](https://en.wikipedia.org/wiki/Lanczos_resampling) |
|           | `3` | **LANCZOS3** | 36-tap | *Good* (4/5) | *Bad* (2/5) | [Lanczos-3](https://en.wikipedia.org/wiki/Lanczos_resampling) |
|           | `4` | **LANCZOS4** | 64-tap | *Great* (5/5) | *Ass* (1/5) | [Lanczos-4](https://en.wikipedia.org/wiki/Lanczos_resampling) |
|           | `5` | **FSR EASU** | 12-tap | *Broken* (1/5) | *Ass* (1/5) | [AMD FidelityFX EASU](https://github.com/GPUOpen-Effects/FidelityFX-FSR)  |
|  |  |  |  |  |
| [**`TFAA_RECTIFY_COLOR_SPACE`**](#color-rectification-visualization) | [**Value**]() | [**Setting**]() | [**Channel**]() | [**Quality**]() | [**Performance**]() | [**Description**]() |
|           | `0` | RGB | **R**: Red.<br>**G**: Green.<br>**B**: Blue. | *Bad* (2/5) | *Great* (5/5) | No color transform (identity); loosest rectification bounds. Most blurring and most color deviation artifacts.|
|           | `1` | YCbCr | **Y**: BT.601 luma.<br>**Cb**: blue-yellow axis.<br>**Cr**: red-cyan axi. | *Good* (4/5) | *Good* (4/5) | ITU-R BT.601 / JPEG-style full-range chroma scales (not broadcast limited-range packing). Chrominance more correlated across axes than YCoCg; rectify path stores Cb/Cr with **+0.5** offset so all axes are in [0,1].
| *default* | `2` | YCoCg | **Y**: (R+2G+B)/4 luma.<br>**Co**: orange-cyan axis.<br>**Cg**: green-magenta axis. | *Great* (5/5) | *Good* (4/5) | Malvar & Sullivan (2003 YCoCg); orthogonal chroma, more decorrelated than YCbCr. Shader uses the linear-float form here (papers show integer-shift variants); rectify path stores Co/Cg with **+0.5** offset so all axes are in [0,1]. | 
|  |  |  |  |  |
| [**`TFAA_RECTIFY_OP`**](#history-rectification) | [**Value**]() | [**Setting**]() | [**Stability**]() | [**Ghosting**]() | [**Performance**]() | [**Description**]() |
|           | `0` | **CLAMP**         | *Ok* (3/5)    | *Bad* (2/5)   | *Great* (5/5)  | Clamp history to the AABB. (**`TFAA_RECTIFY_SHAPE`** is ignored). |  |
|           | `1` | **CLIP_NEAREST**  | *Great* (5/5) | *Ok* (3/5)   | *Ok* (3/5)     | Ray clip towards neighborhood sample **closest** to history in rectification space. |  |
|           | `2` | **CLIP_MEAN**     | *Good* (4/5)    | *Good* (4/5)   |  *Ok* (3/5)  | Ray clip towards the nine-tap arithmetic **average**. |  |
|           | `3` | **CLIP_CENTROID** | *Good* (4/5)    | *Good* (4/5)   |  *Ok* (3/5)  | Ray clip towards the per-channel **midpoint** `(min+max)/2`. |  |
| *default* | `4` | **CLIP_CURRENT**  | *Good* (4/5)    | *Great* (5/5) |  *Good* (4/5) | Ray clip towards the **current** pixel. |  |
|  |  |  |  |  |
| [**`TFAA_RECTIFY_SHAPE`**](#history-rectification) | [**Value**]() | [**Setting**]() | [**Shape**]() | [**Quality**]() | [**Performance**]() | [**Description**]() |
|           | `0` | **AABB** | **3**-axis<br>**6**-faces<br>Box |  |  | 3-axis bounding box - classic axis-aligned box used for clipping/clamping in common industry TAA solutions. |  |
| *default* | `1` | **14-DOP** | **7**-axis<br>**14**-faces<br>Box with cut corners |  |  | 7-axis - bounding box + corners |  |
|           | `2` | **18-DOP** | **9**-axis<br>**18**-faces<br>Box with cut edges |  |  | 9-axis - bounding box + edges |  |
|           | `3` | **26-DOP** | **13**-axis<br>**26**-faces<br>Box with cut corners and edges |  |  | 13-axis - bounding box + edges + corners |  |
|  |  |  |  |  |




 


### History Resampling

When TFAA reads **history data**, the sample position will most likely sit at a **subpixel positon**. Depending on what method is used to sample, the results can vary greatly. Cheaper methods generally blur more, expensive methods tend to preserve more detail but might also introduce more artifacts.

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

### History Rectification

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

<p style="margin:16px 0 8px;"><strong>CLAMP</strong> (<code>TFAA_RECTIFY_OP</code> 0)</p>
<p style="margin:8px 0 4px;"><strong>YCoCg</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_aabb_clamp_dark.svg" alt="YCoCg AABB CLAMP" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_14dop_clamp_dark.svg" alt="YCoCg 14-DOP CLAMP" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_18dop_clamp_dark.svg" alt="YCoCg 18-DOP CLAMP" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_26dop_clamp_dark.svg" alt="YCoCg 26-DOP CLAMP" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
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
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_aabb_clamp_dark.svg" alt="YCbCr AABB CLAMP" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_14dop_clamp_dark.svg" alt="YCbCr 14-DOP CLAMP" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_18dop_clamp_dark.svg" alt="YCbCr 18-DOP CLAMP" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_26dop_clamp_dark.svg" alt="YCbCr 26-DOP CLAMP" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>

<p style="margin:12px 0 4px;"><strong>RGB</strong></p>
<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th width="25%">AABB</th><th width="25%">14-DOP</th><th width="25%">18-DOP</th><th width="25%">26-DOP</th>
</tr>
<tr>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_aabb_clamp_dark.svg" alt="RGB AABB CLAMP" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_14dop_clamp_dark.svg" alt="RGB 14-DOP CLAMP" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_18dop_clamp_dark.svg" alt="RGB 18-DOP CLAMP" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td><td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_26dop_clamp_dark.svg" alt="RGB 26-DOP CLAMP" width="100%" style="max-width:100%;height:auto;display:block;image-rendering:pixelated;" /></td>
</tr>
</table>

</details>

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






# LICENSE
- License File: [LICENSE.md](./LICENSE.md)
- Human-readable summary of the License: https://creativecommons.org/licenses/by-nc-nd/4.0/
- Full legal code: https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode


