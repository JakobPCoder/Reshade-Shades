# Shaders
## Framework?
    - If other shaders need shared stuff, like image pyramids, AI shared backbone etc.
    - Maybe our own motion estimation 
## TFAA
    - Temporal anti-aliasing
## Motion Blur
    - problematic. not truly solvable in a post raster shader.
    - Could access
        - Color current and last
        - Depth current and last
        - Motion current
## Motion clarity
Either per pixel model to implement "overdrive" to cancel motion blur based on monitor pixel black to white and gray to gray times, or a motion vector based directional sharpener.
## Film Grain
- All existing ones have one or more of the following problems:
    - Not animated
    - Animated but still "stuck to cam" visually.
    - No custom grain size
    - No natural grain distribution/behviour across brightness levels.
    - Not maintaining colors / brightness levels of the original image.
- So our solution should:
    - Be animated
    - NOT be "stuck to cam" visually.
    - Have a custom grain size
    - Have a natural and customizable grain size and "rate" distribution/behviour across brightness levels.
    - Maintain colors / brightness levels of the original image.

- In realife, grains are everwher with a given mean and variance of size, filling hte entire film, so density and size are directly related.
- On real film, Dark areas are grainy in a salty, way, many grains might now get activated at all, 