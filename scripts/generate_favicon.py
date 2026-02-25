from PIL import Image, ImageDraw
import numpy as np

# Create a 64x64 image for favicon
size = 64
img = Image.new('RGBA', (size, size), (10, 14, 39, 255))
draw = ImageDraw.Draw(img)

# Draw galaxy center with gradient effect
for r in range(20, 0, -1):
    alpha = int(255 * (20 - r) / 20)
    color = (167, 139, 250, alpha)
    draw.ellipse([size//2 - r, size//2 - r, size//2 + r, size//2 + r], fill=color)

# Draw outer glow
for r in range(30, 20, -2):
    alpha = int(100 * (30 - r) / 10)
    color = (99, 102, 241, alpha)
    draw.ellipse([size//2 - r, size//2 - r, size//2 + r, size//2 + r], fill=color)

# Add stars
stars = [
    (10, 10, 2), (50, 8, 2), (8, 40, 1),
    (55, 50, 2), (15, 52, 1), (45, 15, 1),
    (52, 35, 1), (18, 28, 1)
]

for x, y, size_star in stars:
    draw.ellipse([x-size_star, y-size_star, x+size_star, y+size_star], fill=(255, 255, 255, 200))

# Add bright center
draw.ellipse([size//2 - 5, size//2 - 5, size//2 + 5, size//2 + 5], fill=(255, 255, 255, 220))
draw.ellipse([size//2 - 3, size//2 - 3, size//2 + 3, size//2 + 3], fill=(236, 72, 153, 255))

# Save as PNG
img.save('static/favicon.png')
print("Favicon PNG created successfully!")

# Also create ICO format for older browsers
img.save('static/favicon.ico', format='ICO', sizes=[(32, 32), (64, 64)])
print("Favicon ICO created successfully!")
