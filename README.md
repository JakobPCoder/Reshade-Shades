# Shades
Shades is a collection of my updated Reshade shaders.
## **Installation**
### A. ReShade installer
### B. Manual 

## **Shaders** *`.fx`*
### Framework.*fx*
---
### OpticalFlow.*fx*
---
### TFAA.*fx*
---
**TFAA** is a purely temporal anti-aliasing component, used to get the closest thing to real temporal anti-aliasing possible in a [Reshade](https://reshade.me/) shader.

#### Preprocessor controls in **`TFAA.fx`**. 
These Settings are implemented as preprocessor defines instead of runtime branching for performance reasons.

- **`TFAA_RECTIFY_COLOR_SPACE`**  
    - `0` = **RGB** (identity; loosest bounds),
    - `1` = **YCbCr** normalized axes to [0,1]
    - `2` = **YCoCg** normalized axis to [0,1] (default).
- **`TFAA_RECTIFY_OP`**  
    - `0` = **CLAMP** per-channel min/max **AABB**. (**`TFAA_RECTIFY_SHAPE`** is ignored). 
    - `1` = **CLIP_NEAREST** ray clip to the neiborhood
    
    - `2` = **CLIP_MEAN** (ray from the **nine-tap arithmetic mean**). 
    - `3` = **CLIP_CENTROID** (ray from the per-channel **AABB midpoint** `(min+max)/2`, not the nine-tap mean). 
    - `4` = **CLIP_CURRENT** (ray from the **center tap** / current UV).
- **`TFAA_RECTIFY_SHAPE`** — applies only to CLIP ops `1–4`: 
    - `0` = **AABB** (3-axis bounding box) This is the classic Axis-Aligned Bounding Box used for clipping/clamping in all popular industry taa solutions.
    - `1` = **14-DOP** (7-axis bounding box + corners)
    - `2` = **18-DOP** (9-axis bounding box + edges)
    - `3` = **26-DOP** (13-axis bounding box + edges + corners)

#### How it works
#### History Resampling
#### History Rectification

#### Color Rectification Visualization


<div style="display:flex;flex-wrap:wrap;align-items:flex-start;gap:12px;margin:12px 0;">
<img src="./misc/output/clip_vis/key_neighborhood_dark.png" alt="Neighborhood 3×3 sample grid" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
<img src="./misc/output/clip_vis/key_history_dark.png" alt="History sample swatch" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
<img src="./misc/output/clip_vis/key_clipped_clamp_dark.png" alt="Rectified RGB swatches — CLAMP" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
</div>


<div style="display:flex;flex-wrap:wrap;align-items:flex-start;gap:12px;margin:12px 0;">
<img src="./misc/output/clip_vis/key_clipped_clip_nearest_dark.png" alt="Rectified RGB swatches — CLIP_NEAREST" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
<img src="./misc/output/clip_vis/key_clipped_clip_mean_dark.png" alt="Rectified RGB swatches — CLIP_MEAN" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
<img src="./misc/output/clip_vis/key_clipped_clip_centroid_dark.png" alt="Rectified RGB swatches — CLIP_CENTROID" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
<img src="./misc/output/clip_vis/key_clipped_clip_current_dark.png" alt="Rectified RGB swatches — CLIP_CURRENT" style="max-width:min(200px,100%);width:auto;height:auto;display:block;" />
</div>

<p><small>Legend: each image is a separate asset (reorder or restyle in CSS). Neighborhood · history · then one matrix per <code>TFAA_RECTIFY_OP</code> (rows = rectify color space, columns = none / shape-specific bounds). A stacked all-in-one graphic is still emitted as <code>key_clipped_&lt;theme&gt;.png</code> for convenience.</small></p>

---

**CLAMP (`TFAA_RECTIFY_OP` 0)** — per-channel clamp to the neighborhood AABB. All **shape** columns use the **same** feasible set here (matches the preprocessor ignoring shape for clamp).

<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr>
<th></th><th>No rectification</th><th>AABB</th><th>14-DOP</th><th>18-DOP</th><th>26-DOP</th>
</tr>
<tr>
<th scope="row">RGB</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_norectify_dark.png" alt="RGB no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_aabb_clamp_dark.png" alt="RGB AABB clamp" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_14dop_clamp_dark.png" alt="RGB 14-DOP clamp" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_18dop_clamp_dark.png" alt="RGB 18-DOP clamp" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_26dop_clamp_dark.png" alt="RGB 26-DOP clamp" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
<tr>
<th scope="row">YCoCg</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_norectify_dark.png" alt="YCoCg no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_aabb_clamp_dark.png" alt="YCoCg AABB clamp" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_14dop_clamp_dark.png" alt="YCoCg 14-DOP clamp" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_18dop_clamp_dark.png" alt="YCoCg 18-DOP clamp" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_26dop_clamp_dark.png" alt="YCoCg 26-DOP clamp" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
<tr>
<th scope="row">YCbCr</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_norectify_dark.png" alt="YCbCr no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_aabb_clamp_dark.png" alt="YCbCr AABB clamp" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_14dop_clamp_dark.png" alt="YCbCr 14-DOP clamp" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_18dop_clamp_dark.png" alt="YCbCr 18-DOP clamp" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_26dop_clamp_dark.png" alt="YCbCr 26-DOP clamp" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
</table>

---

**CLIP_NEAREST (`TFAA_RECTIFY_OP` 1)** — ray-clip from the **neighbor tap closest to history** in rectify space (Euclidean), after the 3×3 neighborhood is accumulated.

<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr><th></th><th>No rectification</th><th>AABB</th><th>14-DOP</th><th>18-DOP</th><th>26-DOP</th></tr>
<tr>
<th scope="row">RGB</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_norectify_dark.png" alt="RGB no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_aabb_clip_nearest_dark.png" alt="RGB AABB CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_14dop_clip_nearest_dark.png" alt="RGB 14-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_18dop_clip_nearest_dark.png" alt="RGB 18-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_26dop_clip_nearest_dark.png" alt="RGB 26-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
<tr>
<th scope="row">YCoCg</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_norectify_dark.png" alt="YCoCg no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_aabb_clip_nearest_dark.png" alt="YCoCg AABB CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_14dop_clip_nearest_dark.png" alt="YCoCg 14-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_18dop_clip_nearest_dark.png" alt="YCoCg 18-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_26dop_clip_nearest_dark.png" alt="YCoCg 26-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
<tr>
<th scope="row">YCbCr</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_norectify_dark.png" alt="YCbCr no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_aabb_clip_nearest_dark.png" alt="YCbCr AABB CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_14dop_clip_nearest_dark.png" alt="YCbCr 14-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_18dop_clip_nearest_dark.png" alt="YCbCr 18-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_26dop_clip_nearest_dark.png" alt="YCbCr 26-DOP CLIP_NEAREST" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
</table>

---

**CLIP_MEAN (`TFAA_RECTIFY_OP` 2)** — ray-clip from the **nine-tap arithmetic mean** of the neighborhood in rectify space.

<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr><th></th><th>No rectification</th><th>AABB</th><th>14-DOP</th><th>18-DOP</th><th>26-DOP</th></tr>
<tr>
<th scope="row">RGB</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_norectify_dark.png" alt="RGB no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_aabb_clip_mean_dark.png" alt="RGB AABB CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_14dop_clip_mean_dark.png" alt="RGB 14-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_18dop_clip_mean_dark.png" alt="RGB 18-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_26dop_clip_mean_dark.png" alt="RGB 26-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
<tr>
<th scope="row">YCoCg</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_norectify_dark.png" alt="YCoCg no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_aabb_clip_mean_dark.png" alt="YCoCg AABB CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_14dop_clip_mean_dark.png" alt="YCoCg 14-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_18dop_clip_mean_dark.png" alt="YCoCg 18-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_26dop_clip_mean_dark.png" alt="YCoCg 26-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
<tr>
<th scope="row">YCbCr</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_norectify_dark.png" alt="YCbCr no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_aabb_clip_mean_dark.png" alt="YCbCr AABB CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_14dop_clip_mean_dark.png" alt="YCbCr 14-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_18dop_clip_mean_dark.png" alt="YCbCr 18-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_26dop_clip_mean_dark.png" alt="YCbCr 26-DOP CLIP_MEAN" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
</table>

---

**CLIP_CENTROID (`TFAA_RECTIFY_OP` 3)** — ray-clip from the per-channel **AABB midpoint** `(min+max)/2` in rectify space (not the nine-tap mean).

<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr><th></th><th>No rectification</th><th>AABB</th><th>14-DOP</th><th>18-DOP</th><th>26-DOP</th></tr>
<tr>
<th scope="row">RGB</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_norectify_dark.png" alt="RGB no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_aabb_clip_centroid_dark.png" alt="RGB AABB CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_14dop_clip_centroid_dark.png" alt="RGB 14-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_18dop_clip_centroid_dark.png" alt="RGB 18-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_26dop_clip_centroid_dark.png" alt="RGB 26-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
<tr>
<th scope="row">YCoCg</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_norectify_dark.png" alt="YCoCg no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_aabb_clip_centroid_dark.png" alt="YCoCg AABB CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_14dop_clip_centroid_dark.png" alt="YCoCg 14-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_18dop_clip_centroid_dark.png" alt="YCoCg 18-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_26dop_clip_centroid_dark.png" alt="YCoCg 26-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
<tr>
<th scope="row">YCbCr</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_norectify_dark.png" alt="YCbCr no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_aabb_clip_centroid_dark.png" alt="YCbCr AABB CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_14dop_clip_centroid_dark.png" alt="YCbCr 14-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_18dop_clip_centroid_dark.png" alt="YCbCr 18-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_26dop_clip_centroid_dark.png" alt="YCbCr 26-DOP CLIP_CENTROID" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
</table>

---

**CLIP_CURRENT (`TFAA_RECTIFY_OP` 4)** — ray-clip from the **center tap** (current UV) toward history; this is the in-repo **default** (`TFAA_RECTIFY_OP` 4).

<table width="100%" style="width:100%;table-layout:fixed;border-collapse:collapse;">
<tr><th></th><th>No rectification</th><th>AABB</th><th>14-DOP</th><th>18-DOP</th><th>26-DOP</th></tr>
<tr>
<th scope="row">RGB</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_norectify_dark.png" alt="RGB no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_aabb_clip_current_dark.png" alt="RGB AABB CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_14dop_clip_current_dark.png" alt="RGB 14-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_18dop_clip_current_dark.png" alt="RGB 18-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/rgb_26dop_clip_current_dark.png" alt="RGB 26-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
<tr>
<th scope="row">YCoCg</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_norectify_dark.png" alt="YCoCg no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_aabb_clip_current_dark.png" alt="YCoCg AABB CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_14dop_clip_current_dark.png" alt="YCoCg 14-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_18dop_clip_current_dark.png" alt="YCoCg 18-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycocg_26dop_clip_current_dark.png" alt="YCoCg 26-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
<tr>
<th scope="row">YCbCr</th>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_norectify_dark.png" alt="YCbCr no rectification" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_aabb_clip_current_dark.png" alt="YCbCr AABB CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_14dop_clip_current_dark.png" alt="YCbCr 14-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_18dop_clip_current_dark.png" alt="YCbCr 18-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
<td style="vertical-align:top;padding:4px;"><img src="./misc/output/clip_vis/ycbcr_26dop_clip_current_dark.png" alt="YCbCr 26-DOP CLIP_CURRENT" width="100%" style="max-width:100%;height:auto;display:block;" /></td>
</tr>
</table>
# LICENSE
- License File: [LICENSE.md](./LICENSE.md)
- Human-readable summary of the License: https://creativecommons.org/licenses/by-nc-nd/4.0/
- Full legal code: https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode