shader_type canvas_item;

uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;
uniform float threshold : hint_range(0.0, 1.0);
uniform float intensity : hint_range(0.0, 1.0);
uniform float opacity : hint_range(0.0, 1.0);
uniform vec4 glow_color : source_color;

void fragment() {
    // Get the pixel color from the texture
    vec4 pixel_color = texture(TEXTURE, UV);

    // Calculate the distance between the pixel color and the first source color
    float distance = length(pixel_color.rgb - color1.rgb);

    // Calculate the distance between the pixel color and the second source color
    float distance_second = length(pixel_color.rgb - color2.rgb);

    // Create a new variable to store the modified glow color
    vec4 modified_glow_color = glow_color;

    // Set the alpha value of the modified glow color to the specified opacity
    modified_glow_color.a = opacity;

    // Calculate the sine wave modulation for twinkling effect
    float sine_wave = sin(TIME * 2.0) * 0.5 + 0.5; // Generates a value between 0 and 1

    // If the distance to either source color is below the threshold, set the output color to a blend of the pixel color and the modified glow color
    if (distance < threshold || distance_second < threshold) {
        // Blend the pixel color with the glow color based on intensity, opacity, and sine wave modulation
        float blend_factor = (1.0 - min(distance, distance_second) / threshold) * intensity * sine_wave;
        COLOR = mix(pixel_color, modified_glow_color, blend_factor);
    } else {
        COLOR = pixel_color;
    }
}
