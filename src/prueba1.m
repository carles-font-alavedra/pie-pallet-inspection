% ---------------- Código Principal --------------------

% Inicializar el pipeline de RealSense
pipe = realsense.pipeline();
config = realsense.config();

% Habilitar los streams de profundidad y color con la misma resolución
config.enable_stream(realsense.stream.depth, 640, 480, realsense.format.z16, 30);
config.enable_stream(realsense.stream.color, 640, 480, realsense.format.rgb8, 30);

% Empezar a capturar datos
pipe.start(config);

% Definir los límites de distancia (en metros) para aislar el palet
min_dist = 1.5;  % Distancia mínima en metros
max_dist = 2.0;  % Distancia máxima en metros

% Capturar el primer escaneo
disp('Capturando el primer escaneo 3D...');
[depth1, color1] = capturarEscaneo(pipe);

% Segmentar el palet en la imagen de profundidad
palet_mask1 = (depth1 >= min_dist) & (depth1 <= max_dist);

% Aplicar la máscara a la imagen de color y profundidad
palet_color1 = bsxfun(@times, color1, cast(palet_mask1, 'like', color1));
palet_depth1 = depth1 .* palet_mask1;

% Mostrar el palet segmentado en el primer escaneo
figure;
imshow(palet_color1, []);
title('Imagen de color del palet (primer escaneo)');

figure;
imshow(palet_depth1, []);
title('Imagen de profundidad del palet (primer escaneo)');

% Pausa para mover el objeto o cambiar la posición si es necesario
pause(2); % Pausa de 2 segundos

% Capturar el segundo escaneo
disp('Capturando el segundo escaneo 3D...');
[depth2, color2] = capturarEscaneo(pipe);

% Segmentar el palet en el segundo escaneo
palet_mask2 = (depth2 >= min_dist) & (depth2 <= max_dist);

% Aplicar la máscara a la imagen de color y profundidad
palet_color2 = bsxfun(@times, color2, cast(palet_mask2, 'like', color2));
palet_depth2 = depth2 .* palet_mask2;

% Mostrar el palet segmentado en el segundo escaneo
figure;
imshow(palet_color2, []);
title('Imagen de color del palet (segundo escaneo)');

figure;
imshow(palet_depth2, []);
title('Imagen de profundidad del palet (segundo escaneo)');

% Comparar las imágenes de profundidad del palet entre los dos escaneos
palet_depth_vector1 = palet_depth1(:);
palet_depth_vector2 = palet_depth2(:);

% Eliminar NaNs o Infs
validIdx = isfinite(palet_depth_vector1) & isfinite(palet_depth_vector2);
palet_depth_vector1 = palet_depth_vector1(validIdx);
palet_depth_vector2 = palet_depth_vector2(validIdx);

% Calcular la correlación de Pearson
mean_depth1 = mean(palet_depth_vector1);
mean_depth2 = mean(palet_depth_vector2);

numerador = sum((palet_depth_vector1 - mean_depth1) .* (palet_depth_vector2 - mean_depth2));
denominador = sqrt(sum((palet_depth_vector1 - mean_depth1).^2) * sum((palet_depth_vector2 - mean_depth2).^2));

% Evitar división por cero
if denominador == 0
    R = 0;
else
    R = numerador / denominador;
end

% Convertir la correlación a porcentaje
porcentaje_correlacion = R * 100;

% Mostrar el resultado
fprintf('El porcentaje de correlación entre las imágenes del palet es: %.2f%%\n', porcentaje_correlacion);

% Detener el pipeline de RealSense
pipe.stop();

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
    depth_image = reshape(depth_data, [height, width]);
    depth_image = double(depth_image) * 0.001;  % Convertir de milímetros a metros

    % Obtener los datos de color y convertirlos a imagen RGB
    color_data = color_frame.get_data();
    color_image = reshape(color_data, [height, width, 3]);

    % Asegurarse de que los valores de color estén en formato double
    color_image = double(color_image);
end
