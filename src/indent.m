% --- CONFIGURACIÓN DE LA CÁMARA INTEL REALSENSE ---
disp('Inicializando la cámara Intel RealSense...');
pipe = realsense.pipeline();
config = realsense.config();
config.enable_stream(realsense.stream.depth, 640, 480, realsense.format.z16, 30);
profile = pipe.start(config);

% --- CAPTURAR IMAGEN DE PROFUNDIDAD ---
disp('Capturando el mapa de profundidad...');
frames = pipe.wait_for_frames();
depth_frame = frames.get_depth_frame();

if isempty(depth_frame)
    error('No se pudo capturar el frame de profundidad.');
end

depth_image = reshape(depth_frame.get_data(), [640, 480])';

% --- SEGMENTACIÓN BASADA EN PROFUNDIDAD ---
disp('Segmentando la pantalla...');
depth_vals = depth_image(depth_image > 0);
min_depth = min(depth_vals) + 50; % Ajustar según entorno
max_depth = min_depth + 500;      % Ajustar rango dinámicamente

% Crear la máscara inicial
depth_mask = (depth_image >= min_depth) & (depth_image <= max_depth);

% Operaciones morfológicas para limpiar ruido
se = strel('disk', 5);
depth_mask_cleaned = imclose(imopen(depth_mask, se), se);

% Mostrar la máscara limpia
figure;
imshow(depth_mask_cleaned);
title('Máscara limpia basada en profundidad');

% --- ELIMINAR REGIONES PEQUEÑAS ---
disp('Eliminando regiones pequeñas...');
connected_components = bwconncomp(depth_mask_cleaned);
stats = regionprops(connected_components, 'Area', 'BoundingBox');
min_area = 2000; % Área mínima para considerar como pantalla (ajustar según resolución)
large_regions = find([stats.Area] > min_area);

% Crear una nueva máscara con solo las regiones grandes
filtered_mask = ismember(labelmatrix(connected_components), large_regions);

% Mostrar la máscara con regiones grandes
figure;
imshow(filtered_mask);
title('Máscara con regiones grandes');

% --- DETECCIÓN DE BORDES ---
disp('Detectando bordes de la pantalla...');
edges = edge(filtered_mask, 'Canny');

% Mostrar bordes detectados
figure;
imshow(filtered_mask);
hold on;
contour(edges, [0.5, 0.5], 'r', 'LineWidth', 1);
title('Bordes detectados sobre la máscara refinada');
hold off;

% --- SELECCIONAR LA REGIÓN MÁS GRANDE ---
disp('Seleccionando la región más grande...');
stats = regionprops(edges, 'BoundingBox', 'Area', 'Centroid');
[~, idx] = max([stats.Area]); % Seleccionar la región de mayor área
bounding_box = stats(idx).BoundingBox;

% Dibujar el rectángulo ajustado
figure;
imshow(filtered_mask);
hold on;
rectangle('Position', bounding_box, 'EdgeColor', 'g', 'LineWidth', 2);
title('Pantalla detectada con rectángulo ajustado');
hold off;

% --- CÁLCULO DE DIMENSIONES ---
disp('Calculando dimensiones de la pantalla...');
pixel_size_mm = 0.845; % Ajustar según la cámara
width_mm = bounding_box(3) * pixel_size_mm;
height_mm = bounding_box(4) * pixel_size_mm;

disp(['Ancho de la pantalla: ', num2str(width_mm), ' mm']);
disp(['Alto de la pantalla: ', num2str(height_mm), ' mm']);

% --- FINALIZACIÓN ---
pipe.stop();
disp('Proceso completado y cámara detenida.');
