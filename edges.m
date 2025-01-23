W = 320;
H = 320;
port = 8081;
zoomFactor = 2.5;

pkg load sockets;

screenSize = get(0, 'ScreenSize'); % [X Y Width Height]
screenHeight = screenSize(4);

figW = W*zoomFactor;
figH = H*zoomFactor;

% Create a figure and an empty image handle
% Position left, bottom, width, height:
fig = figure('Position', [0, screenHeight-figH, figW, figH]);

% small padding:
set(gca, 'Position', [0.05 0.05 0.9 0.9]);

% prepare a placeholder image:
img_handle = imshow(zeros(figH, figW, 'uint8'));

temp_filename = '/dev/shm/temp_image.jpg';

% Sobel filter for horizontal edges
sobel_x = [-1 0 1; -2 0 2; -1 0 1];

% Sobel filter for vertical edges
sobel_y = [1 2 1; 0 0 0; -1 -2 -1];

udp_socket = socket(AF_INET, SOCK_DGRAM, 0);
bind(udp_socket, port);

fprintf(['Listening for UDP packets on port ', num2str(port), '...\n']);

while ishandle(fig),

    % Receive a UDP packet
    % packet data = JPEG image from UDP Camera
    % https://play.google.com/store/apps/details?id=com.hardcodedjoy.udpcamera

    [data, count] = recv(udp_socket, 65507, MSG_DONTWAIT);
    
    if(count > 0)
        % Write JPEG data to RAM filesystem
        % Open file in binary write mode
        fid = fopen(temp_filename, 'wb'); 
        fwrite(fid, data);
        fclose(fid);

        % Now read the image from the temp file to memory
        data = imread(temp_filename);

        % image processing - detect edges:

        data = mean(data, 3); % grayscale

        % Apply the Sobel filters
        grad_x = conv2(data, sobel_x, 'same');  % Horizontal edges
        grad_y = conv2(data, sobel_y, 'same');  % Vertical edges

        % Calculate the gradient magnitude
        gradient_magnitude = sqrt(grad_x.^2 + grad_y.^2);

        % Normalize the gradient magnitude
        gradient_magnitude_normalized = gradient_magnitude / max(gradient_magnitude(:));

        % Threshold to detect edges
        threshold = 0.15;  % You can adjust this value
        edges = gradient_magnitude_normalized > threshold;

        data = gradient_magnitude_normalized * 255;
        %data = edges * 255;
        
        set(img_handle, 'CData', data); % update image data
        set(img_handle, 'XData', [0, figW]);
        set(img_handle, 'YData', [0, figH]);
        drawnow; % force update figure
    end
    
    pause(0.001); % prevent excessive CPU usage
end