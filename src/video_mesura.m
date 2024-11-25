% ---------------- Código Principal --------------------
close all;

% Inicializar el pipeline de RealSense
pipe = realsense.pipeline();
config = realsense.config();

% Habilitar los streams de profundidad y color con la misma resolución
config.enable_stream(realsense.stream.depth, 640, 480, realsense.format.z16, 30);
config.enable_stream(realsense.stream.color, 640, 480, realsense.format.rgb8, 30);

% Empezar a capturar datos
pipe.start(config);

% Definir los límites de distancia (en metros) para aislar el palet
min_dist = 0.1;  % Distancia mínima en metros
max_dist = 0.5;  % Distancia máxima en metros

% Parámetros de captura de video
num_frames = 50;  % Número de frames a capturar
max_width_m = 0;  % Ancho máximo del palet encontrado en el video
max_height_m = 0; % Altura máxima del palet encontrada en el video
distancias = [];  % Array para almacenar distancias promedio en cada frame

disp('Capturando video del palet...');

% Procesar cada frame del video
for i = 1:num_frames
    % Capturar escaneo 3D para el frame actual
    [depth_frame, color_frame] = capturarEscaneo(pipe);

    % Segmentar el palet en el frame actual
    palet_mask = (depth_frame >= min_dist) & (depth_frame <= max_dist);
    
    % Calcular las dimensiones de la parte visible del palet
    [width_m, height_m] = calcularDimensiones(palet_mask, depth_frame);
    
    % Actualizar el ancho y la altura máximos encontrados
    max_width_m = max(max_width_m, width_m);
    max_height_m = max(max_height_m, height_m);
    
    % Calcular y almacenar la distancia promedio al palet en este frame
    distancia_media = mean(depth_frame(palet_mask));
    distancias = [distancias; distancia_media];

    % Visualizar la máscara segmentada en el frame actual
    palet_color = bsxfun(@times, color_frame, cast(palet_mask', 'like', color_frame));
    figure(1);
    imshow(palet_color, []);
    title(sprintf('Frame %d - Parte Visible del Palet', i));
    
    pause(0.1); % Pausa para simular captura de video (ajusta según la velocidad de la cámara)
end

% Calcular la distancia promedio al palet en el video
distancia_promedio = mean(distancias, 'omitnan');

% Mostrar las dimensiones estimadas y la distancia promedio
fprintf('Dimensiones aproximadas del palet (basado en video):\n');
fprintf('Ancho máximo: %.2f metros\n', max_width_m);
fprintf('Altura máxima: %.2f metros\n', max_height_m);
fprintf('Distancia promedio al palet: %.2f metros\n', distancia_promedio);

% Detener el pipeline de RealSense
pipe.stop();
delete(pipe);

% ---------------- Función capturarEscaneo --------------------
function [depth_image, color_image] = capturarEscaneo(pipe)
    % Captura un escaneo 3D de la cámara Intel RealSense D435i
    % pipe: objeto de la tubería de la cámara

    % Esperar a que lleguen los frames
    frames = pipe.wait_for_frames();
    
    % Obtener los frames de profundidad y color
    depth_frame = frames.get_depth_frame();
    color_frame = frames.get_color_frame();

    % Obtener los datos de profundidad y convertirlos a formato MATLAB
    depth_data = depth_frame.get_data();
    [height, width] = deal(depth_frame.get_height(), depth_frame.get_width());
    depth_image = reshape(depth_data, [width, height]);
    depth_image = double(depth_image) * 0.001;  % Convertir de milímetros a metros

    % Obtener los datos de color y convertirlos a imagen RGB
    color_data = color_frame.get_data();
    color_image = permute(reshape(color_data', [3, color_frame.get_width(), color_frame.get_height()]), [3, 2, 1]);
end

% ---------------- Función calcularDimensiones --------------------
function [width_meters, height_meters] = calcularDimensiones(mask, depth_image)
    % Calcula las dimensiones aproximadas de un objeto segmentado en metros.
    % mask: máscara binaria del objeto segmentado
    % depth_image: imagen de profundidad con la región segmentada

    % Encuentra los píxeles de interés en la imagen de profundidad
    [rows, cols] = find(mask);
    depth_values = depth_image(mask);

    % Calcular el ancho y la altura en píxeles
    width_pixels = max(cols) - min(cols);
    height_pixels = max(rows) - min(rows);

    % Estima la escala en metros/píxel usando la profundidad media del objeto
    scale = mean(depth_values) / 640;  % Ajustar según sea necesario

    % Calcular tamaño en metros
    width_meters = width_pixels * scale;
    height_meters = height_pixels * scale;
end
