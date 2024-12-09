% --- CONFIGURACIÓN DE LA CÁMARA INTEL REALSENSE D435i ---
% Crear un objeto para la cámara RealSense
disp('Inicializando la cámara Intel RealSense D435i...');
depthVid = videoinput('realsense', 2, 'Depth_640x480'); % "2" suele ser el índice del sensor de profundidad

% Configuración de parámetros de vídeo
depthVid.FramesPerTrigger = 1;
depthVid.TriggerRepeat = 1;
triggerconfig(depthVid, 'manual');

% Iniciar la conexión con la cámara
start(depthVid);

% --- CAPTURAR IMAGEN DE PROFUNDIDAD ---
disp('Capturando el mapa de profundidad...');
trigger(depthVid); % Activar captura manual
depthFrame = getdata(depthVid);

% Mostrar el mapa de profundidad
figure;
imshow(depthFrame, [min(depthFrame(:)), max(depthFrame(:))]);
title('Mapa de profundidad capturado');
colormap jet; colorbar;

% --- SELECCIONAR ÁREA DE INTERÉS (ROI) ---
disp('Selecciona el objeto de interés manualmente en la imagen.');
roi = imcrop(depthFrame, []); % Selección manual del ROI
figure;
imshow(roi, [min(roi(:)), max(roi(:))]);
title('ROI del objeto seleccionado');
colormap jet; colorbar;

% --- CALCULAR DIMENSIONES ---
disp('Calculando dimensiones del objeto...');
% Parámetros específicos de la D435i (ajustar si es necesario)
resolution = [640, 480]; % Resolución de la captura
fov = [87, 58]; % Campo de visión en grados (horizontal y vertical)
depth_scale = 0.001; % Escala de profundidad en metros (RealSense)

% Tamaño de píxel en mm
pixelSizeX = (2 * tan(deg2rad(fov(1)/2)) / resolution(1)) * 1000; % mm/píxel
pixelSizeY = (2 * tan(deg2rad(fov(2)/2)) / resolution(2)) * 1000; % mm/píxel

% Dimensiones en mm
[heightPx, widthPx] = size(roi); % Dimensiones en píxeles
width = widthPx * pixelSizeX; % Ancho en mm
height = heightPx * pixelSizeY; % Alto en mm
depth = mean(roi(:)) * depth_scale * 1000; % Profundidad promedio en mm

% Mostrar las dimensiones calculadas
disp('Dimensiones del objeto:');
disp(['Ancho: ', num2str(width), ' mm']);
disp(['Alto: ', num2str(height), ' mm']);
disp(['Profundidad: ', num2str(depth), ' mm']);

% --- VISUALIZACIÓN 3D ---
disp('Generando visualización 3D del objeto...');
[X, Y] = meshgrid(1:size(roi, 2), 1:size(roi, 1));
figure;
surf(X, Y, double(roi), 'EdgeColor', 'none');
title('Representación 3D del objeto');
xlabel('Ancho (píxeles)');
ylabel('Alto (píxeles)');
zlabel('Profundidad (mm)');
colormap jet; colorbar;

% --- FINALIZACIÓN ---
stop(depthVid);
delete(depthVid);
clear depthVid;
disp('Cámara liberada. Proceso finalizado.');
