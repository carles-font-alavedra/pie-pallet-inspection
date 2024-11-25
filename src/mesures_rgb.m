% Conectar la cámara Intel RealSense
pipe = realsense.pipeline();
config = realsense.config();
config.enable_stream(realsense.stream.color, 640, 480, realsense.format.rgb8, 30);
pipe.start(config);

% Capturar dos frames consecutivos para detectar movimiento
disp('Capturando frames iniciales. Por favor, mueve ligeramente la cámara o el palet.');
pause(1); % Estabilización inicial
frameset1 = pipe.wait_for_frames();
frameset2 = pipe.wait_for_frames();

color_frame1 = frameset1.get_color_frame();
color_frame2 = frameset2.get_color_frame();

% Verificar que las imágenes fueron capturadas
if isempty(color_frame1) || isempty(color_frame2)
    error('No se pudieron capturar los frames.');
end

% Convertir las imágenes a matrices de MATLAB
image1 = permute(reshape(color_frame1.get_data()', [3, color_frame1.get_width(), color_frame1.get_height()]), [3, 2, 1]);
image2 = permute(reshape(color_frame2.get_data()', [3, color_frame2.get_width(), color_frame2.get_height()]), [3, 2, 1]);

% Convertir imágenes a escala de grises
gray1 = rgb2gray(image1);
gray2 = rgb2gray(image2);

% Calcular la diferencia entre frames
disp('Procesando diferencia entre frames...');
diff_image = abs(double(gray1) - double(gray2));

% Umbral para detectar movimiento
threshold = 30; % Ajustar este valor según sensibilidad deseada
motion_mask = diff_image > threshold;

% Operaciones morfológicas para limpiar la máscara
disp('Aplicando operaciones morfológicas...');
se = strel('disk', 5); % Elemento estructurante circular
motion_mask_cleaned = imopen(imclose(motion_mask, se), se); % Apertura y cierre para eliminar ruido

% Aplicar la máscara de movimiento a la imagen original
segmented_image = image2;
segmented_image(repmat(~motion_mask_cleaned, [1, 1, 3])) = 0;

% Mostrar resultados intermedios
figure;
subplot(1, 3, 1);
imshow(image1);
title('Frame Inicial');

subplot(1, 3, 2);
imshow(image2);
title('Frame Final');

subplot(1, 3, 3);
imshow(segmented_image);
title('Objeto Detectado por Movimiento');

% Detección de bordes
disp('Detectando bordes en la máscara...');
edges = edge(rgb2gray(segmented_image), 'Canny');

% Encontrar regiones conectadas
stats = regionprops(edges, 'BoundingBox', 'Area');
min_area = 10000; % Filtrar regiones pequeñas
stats = stats([stats.Area] > min_area);

% Seleccionar la región más grande
if isempty(stats)
    error('No se detectó el palet.');
end
[~, max_idx] = max([stats.Area]);
selected_box = stats(max_idx).BoundingBox;

% Mostrar rectángulo delimitador
figure;
imshow(image2);
hold on;
rectangle('Position', selected_box, 'EdgeColor', 'r', 'LineWidth', 2);
title('Palet Detectado');
hold off;

% Calcular dimensiones del palet
pixels_per_meter = 100; % Relación de píxeles por metro ajustada previamente
width_pixels = selected_box(3);
height_pixels = selected_box(4);

width_meters = width_pixels / pixels_per_meter;
height_meters = height_pixels / pixels_per_meter;

% Mostrar resultados
fprintf('Dimensiones del palet detectadas:\n');
fprintf('Ancho: %.2f m\n', width_meters);
fprintf('Alto: %.2f m\n', height_meters);

% Detener la cámara
pipe.stop();
