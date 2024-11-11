%Connect with default configuration
pipeline=connectDepth(60);
% Discard first frames...
fs = pipeline.wait_for_frames();
% Use colorizer to color the depth data
colorizer=realsense.colorizer();

    while (1)
%         // This call waits until a new composite_frame is available
%         // composite_frame holds a set of frames. It is used to prevent frame drops
%         // The returned object should be released with rs2_release_frame(...)
        fs = pipeline.wait_for_frames();
        depth_frame = fs.get_depth_frame();    
 
% % %     // Get the depth frame's dimensions
        height = depth_frame.get_height();
        width=depth_frame.get_width();
% % %     // Query the distance from the camera to the object in the center of the image
        depth_frame=permute(reshape(colorizer.colorize(depth_frame).get_data()',[3,width,height]),[3 2 1]);
        imshow(depth_frame,[])
    end
