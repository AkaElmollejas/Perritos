FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
# Comodines: así cualquier .html, .css o .js nuevo de esta carpeta entra a la imagen
COPY *.html *.css *.js /usr/share/nginx/html/
