function pipeline=connectDepth(varargin)
    switch nargin
        case 0
            %default values
            WIDTH          = 640   ;           %// Defines the number of columns for each frame or zero for auto resolve//
            HEIGHT          =480  ;            %// Defines the number of lines for each frame or zero for auto resolve  //
            FPS            = 30   ;            %// Defines the rate of frames per second
        case 1
            FPS=varargin{1};
        case 3
            FPS=varargin{1};
            WIDTH=varargin{2};
            HEIGHT=varargin{3};
        case others
            error('Arguments(none, fps, fps width height)...');
    end
            
%     // Create a context object. This object owns the handles to all connected realsense devices.
%     // The returned object should be released with rs2_delete_context(...)
    ctx =realsense.context();

%     /* Get a list of all the connected devices. */
%     // The returned object should be released with rs2_delete_device_list(...)
    device_list = query_devices(ctx);
    dev_count = length(device_list);
    fprintf("There are %d connected RealSense devices.\n", dev_count);

%     // Get the first connected device
%     // The returned object should be released with rs2_delete_device(...)
    dev = device_list{1};
    fprintf('%s\n',dev.get_info(realsense.camera_info.name));
%     // Create a pipeline to configure, start and stop camera streaming
%     // The returned object should be released with rs2_delete_pipeline(...)
    pipeline =  realsense.pipeline(ctx);

%     // Create a config instance, used to specify hardware configuration
%     // The retunred object should be released with rs2_delete_config(...)
    config = realsense.config();
% 
%     // Request a specific configuration
%     // If such configuration is not valid, it will display an error
%     saying it wasn't able to resolve...(!)
    config.enable_stream(realsense.stream.depth,0,WIDTH,HEIGHT,realsense.format.z16,FPS);
% 
%     // Start the pipeline streaming
%     // The retunred object should be released with rs2_delete_pipeline_profile(...)
    pipeline.start(config);
end