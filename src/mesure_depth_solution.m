% --- INICIALIZACIÓN ---
% Crear un objeto de vídeo para la cámara RealSense
vid = videoinput('realsense', 1, 'Depth_640x480');

% Configuración adicional (opcional)
vid.FramesPerTrigger = 1;
triggerconfig(vid, 'manual');

% Iniciar la captura
start(vid);

% --- CAPTURAR IMAGEN DE PROFUNDIDAD ---
% Capturar un frame de profundidad
disp('Capturando imagen de profundidad...');
trigger(vid);
depthImage = getdata(vid);

% Mostrar el mapa de profundidad
figure;
imshow(depthImage, [min(depthImage(:)), max(depthImage(:))]);
title('Mapa de profundidad');
colormap jet; colorbar;

% --- DEFINIR EL ÁREA DE INTERÉS (ROI) ---
disp('Selecciona el objeto de interés en la imagen.');
roi = imcrop(depthImage, []); % Selección manual de ROI
figure;
imshow(roi, [min(roi(:)), max(roi(:))]);
title('ROI seleccionado');
colormap jet; colorbar;

% --- CALCULAR DIMENSIONES ---
% Parámetros de la cámara (puedes ajustar según tu configuración)
pixelSize = 0.1; % Tamaño de píxel en mm (depende del campo de visión y resolución)

% Calcular dimensiones
[heightPx, widthPx] = size(roi); % Dimensiones en píxeles
width = widthPx * pixelSize; % Ancho en mm
height = heightPx * pixelSize; % Alto en mm
depth = mean(roi(:), 'omitnan'); % Profundidad promedio en mm

% Mostrar dimensiones
disp(['Dimensiones del objeto:']);
disp(['Ancho: ', num2str(width), ' mm']);
disp(['Alto: ', num2str(height), ' mm']);
disp(['Profundidad: ', num2str(depth), ' mm']);

% --- VISUALIZAR 3D ---
[X, Y] = meshgrid(1:size(roi, 2), 1:size(roi, 1));
figure;
surf(X, Y, double(roi), 'EdgeColor', 'none');
title('Representación 3D del objeto');
xlabel('Ancho (píxeles)');
ylabel('Alto (píxeles)');
zlabel('Profundidad (mm)');
colormap jet; colorbar;

% --- LIBERAR RECURSOS ---
stop(vid);
delete(vid);
clear vid;
disp('Proceso finalizado.');
