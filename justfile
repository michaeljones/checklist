start:
    zellij -l zellij.kdl

watch:
    gleam run -m lustre/dev start

watch-css:
    tailwindcss -i styling/input.css -o assets/static/output.css --watch
