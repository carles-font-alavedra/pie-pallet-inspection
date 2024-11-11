% Inicializar el pipeline de RealSense
pipe = realsense.pipeline();
config = realsense.config();

% Habilitar los streams de profundidad y color
config.enable_stream(realsense.stream.depth, 640, 480, realsense.format.z16, 30);
config.enable_stream(realsense.stream.color, 640, 480, realsense.format.rgb8, 30);

% Empezar a capturar datos
pipe.start(config);

% Función para capturar un escaneo 3D
function [depth_image, color_image] = capturarEscaneo(pipe)
    % Esperar a recibir un frame
    frames = pipe.wait_for_frames();
    
    % Obtener los frames de profundidad y color
    depth_frame = frames.get_depth_frame();
    color_frame = frames.get_color_frame();
    
    % Convertir el frame de color a formato MATLAB (RGB)
    color_data = color_frame.get_data();
    color_image = permute(reshape(color_data, [3, 640, 480]), [3, 2, 1]);
    
    % Convertir el frame de profundidad a formato MATLAB
    depth_data = depth_frame.get_data();
    depth_image = double(reshape(depth_data, [640, 480])) * 0.001; % Convertir de milímetros a metros
end

% Capturar el primer escaneo
disp('Capturando el primer escaneo 3D...');
[depth1, color1] = capturarEscaneo(pipe);
figure;
imshow(depth1, []);
title('Primer Escaneo de Profundidad');

% Pausa para mover el objeto o cambiar la posición si es necesario
pause(2); % Pausa de 2 segundos

% Capturar el segundo escaneo
disp('Capturando el segundo escaneo 3D...');
[depth2, color2] = capturarEscaneo(pipe);
figure;
imshow(depth2, []);
title('Segundo Escaneo de Profundidad');

% Asegurarse de que las dimensiones sean iguales
if size(depth1) ~= size(depth2)
    error('Las imágenes de profundidad deben tener el mismo tamaño.');
end

% Aplanar las matrices para calcular la correlación manualmente
depth1_vector = depth1(:);
depth2_vector = depth2(:);

% Manejar posibles valores NaN o Inf
validIdx = isfinite(depth1_vector) & isfinite(depth2_vector);
depth1_vector = depth1_vector(validIdx);
depth2_vector = depth2_vector(validIdx);

% Calcular la correlación de Pearson manualmente
mean_depth1 = mean(depth1_vector);
mean_depth2 = mean(depth2_vector);

numerador = sum((depth1_vector - mean_depth1) .* (depth2_vector - mean_depth2));
denominador = sqrt(sum((depth1_vector - mean_depth1).^2) * sum((depth2_vector - mean_depth2).^2));

% Evitar división por cero
if denominador == 0
    R = 0;
else
    R = numerador / denominador;
end

% Convertir la correlación a porcentaje
porcentaje_correlacion = R * 100;

% Mostrar el resultado
fprintf('El porcentaje de correlación entre los dos escaneos 3D es: %.2f%%\n', porcentaje_correlacion);

% Detener el pipeline de RealSense
pipe.stop();
