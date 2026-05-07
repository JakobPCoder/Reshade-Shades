# Shades
Shades is a collection of my updated Reshade shaders.
## Installation
### A. ReShade installer
### B. Manual 

## Shaders `.fx`
### Framework.fx
---
### OpticalFlow.fx
---
### TFAA.fx
---
**TFAA** is a purely temporal anti-aliasing component, used to get the closest thing to real temporal anti-aliasing possible in a [Reshade](https://reshade.me/) shader.

#### How it works
#### History Resampling
#### History Rectification

#### Color Rectification Visualization


<table width="100%">
<tr valign="top">
<td align="center"><img src="./misc/output/clip_vis/key_neighborhood_dark.png" alt="Neighborhood 3×3" height="131" /></td>
<td align="center"><img src="./misc/output/clip_vis/key_history_dark.png" alt="History sample" height="131" /></td>
<td align="center"><img src="./misc/output/clip_vis/key_clipped_dark.png" alt="Clipped results by mode and color space" height="131" /></td>
</tr>
</table>

---

##### No clipping

<table width="100%">
<tr><th>RGB</th><th>YCoCg</th><th>YCbCr</th></tr>
<tr>
<td><img src="./misc/output/clip_vis/rgb_off_dark.png" alt="RGB off" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycocg_off_dark.png" alt="YCoCg off" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycbcr_off_dark.png" alt="YCbCr off" width="280" /></td>
</tr>
</table>

No rectification is applied; history remains identical to the raw sample.

---

##### Clamp

<table width="100%">
<tr><th>RGB</th><th>YCoCg</th><th>YCbCr</th></tr>
<tr>
<td><img src="./misc/output/clip_vis/rgb_clamp_dark.png" alt="RGB clamp" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycocg_clamp_dark.png" alt="YCoCg clamp" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycbcr_clamp_dark.png" alt="YCbCr clamp" width="280" /></td>
</tr>
</table>

Clamp mode independently clamps each rectify-space coordinate of history to the per-axis minima and maxima observed across the 3×3 neighborhood.

---

##### Center

<table width="100%">
<tr><th>RGB</th><th>YCoCg</th><th>YCbCr</th></tr>
<tr>
<td><img src="./misc/output/clip_vis/rgb_center_dark.png" alt="RGB center" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycocg_center_dark.png" alt="YCoCg center" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycbcr_center_dark.png" alt="YCbCr center" width="280" /></td>
</tr>
</table>

Center clipping pulls history toward the center of the neighborhood AABB when it lies outside that box, preserving hue-like structure via uniform scaling.

---

##### Anchor

<table width="100%">
<tr><th>RGB</th><th>YCoCg</th><th>YCbCr</th></tr>
<tr>
<td><img src="./misc/output/clip_vis/rgb_anchor_dark.png" alt="RGB anchor" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycocg_anchor_dark.png" alt="YCoCg anchor" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycbcr_anchor_dark.png" alt="YCbCr anchor" width="280" /></td>
</tr>
</table>

Anchor clipping scales the vector from the neighborhood anchor (center tap) toward history until it intersects the axis-aligned neighborhood bounding box.

---

##### 14-DOP

<table width="100%">
<tr><th>RGB</th><th>YCoCg</th><th>YCbCr</th></tr>
<tr>
<td><img src="./misc/output/clip_vis/rgb_14dop_dark.png" alt="RGB 14-DOP" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycocg_14dop_dark.png" alt="YCoCg 14-DOP" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycbcr_14dop_dark.png" alt="YCbCr 14-DOP" width="280" /></td>
</tr>
</table>

The 14-DOP hull uses seven directions (axes plus four space diagonals); this is the tightest k-DOP variant shown here before falling back to box modes.

---

##### 18-DOP

<table width="100%">
<tr><th>RGB</th><th>YCoCg</th><th>YCbCr</th></tr>
<tr>
<td><img src="./misc/output/clip_vis/rgb_18dop_dark.png" alt="RGB 18-DOP" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycocg_18dop_dark.png" alt="YCoCg 18-DOP" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycbcr_18dop_dark.png" alt="YCbCr 18-DOP" width="280" /></td>
</tr>
</table>

The 18-DOP hull retains nine directions (axes plus selected face diagonals); ray clipping against these slabs bounds temporal history.

---

##### 26-DOP

<table width="100%">
<tr><th>RGB</th><th>YCoCg</th><th>YCbCr</th></tr>
<tr>
<td><img src="./misc/output/clip_vis/rgb_26dop_dark.png" alt="RGB 26-DOP" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycocg_26dop_dark.png" alt="YCoCg 26-DOP" width="280" /></td>
<td><img src="./misc/output/clip_vis/ycbcr_26dop_dark.png" alt="YCbCr 26-DOP" width="280" /></td>
</tr>
</table>

The 26-DOP feasible set uses thirteen symmetric directions in rectify space; history is clipped by marching from the neighborhood center toward the history sample until the first supporting half-space is hit.


# LICENSE
- License File: [LICENSE.md](./LICENSE.md)
- Human-readable summary of the License: https://creativecommons.org/licenses/by-nc-nd/4.0/
- Full legal code: https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode