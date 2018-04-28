function varargout = show_mask_preview(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mask_preview_OpeningFcn, ...
                   'gui_OutputFcn',  @mask_preview_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})    gui_State.gui_Callback = str2func(varargin{1});    end
if nargout    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else    gui_mainfcn(gui_State, varargin{:});    end

function mask_preview_OpeningFcn(hObject, eventdata, handles, varargin)
run('Aro_parameters.m');
handles.output = hObject;
handles.files = dir([SegmentationMaskDir filesep 'thumbnails*']);
sorted_names = {handles.files.name};
sorted_names = natsortfiles(sorted_names);
for i = 1 : length(handles.files)
    handles.X{i} = imread(fullfile([SegmentationMaskDir filesep sorted_names{i}]));   
end

current_files = dir([SegmentationMaskDir filesep '*.tif']);
tif_files = {current_files.name};
tif_files = natsortfiles(tif_files);

bad_mask_file = fopen(BadMaskList);
handles.bad_files = textscan(bad_mask_file, '%s');
handles.bad_files = handles.bad_files{1};
fclose(bad_mask_file);
disp(handles.bad_files);


num_thumbs = floor(numel(tif_files)/20);
if numel(tif_files)/20 > num_thumbs
    num_thumbs = num_thumbs + 1;
end
if num_thumbs < 1
    num_thumbs = 1;
end

handles.image_handle = imshow(handles.X{1},[]);
handles.index = 1;
Cek(hObject, eventdata, handles);

rectangle_files = {};
rectangles = {};

for j = 0:3
    for k = 0:4
        if ((k + 1) +  5 * (j)) <= numel(tif_files)
            start_x = j * 100 + 1;
            end_x = start_x + 99;
            start_y = k * 100 + 1;
            end_y = start_y + 99;
            name = tif_files{(k + 1) + 5*j};
            rectangle_files{end+1} = name;
            show_rectangle = 'off';
            if any(strcmp(handles.bad_files, name))
                show_rectangle = 'on';
            end
            name = strsplit(name, '_');
            name = name(2);
            text(handles.axes1, start_y+35, start_x+50, name, 'Color', 'magenta', 'FontWeight', 'Bold');
            current_rect = rectangle(handles.axes1, 'Position', [start_y + 4 start_x + 4 92 92], 'EdgeColor', 'r', 'LineWidth', 4, 'Visible', show_rectangle);
            rectangles{end+1} = current_rect;
        end
    end
end

handles.rectangles = rectangles;
handles.rectangle_files = rectangle_files;

set(handles.image_handle, 'ButtonDownFcn', {@toggle_status, handles});

guidata(hObject, handles);

% when an image of a mask is clicked, its status of being
% bad or good is toggled (i.e. flipped)
function toggle_status(objectHandle, eventData, handles)
run('Aro_parameters.m');
current_files = dir([SegmentationMaskDir filesep '*.tif']);
tif_files = {current_files.name};
tif_files = natsortfiles(tif_files);

handles = guidata(objectHandle);
axesHandle  = get(objectHandle,'Parent');
coordinates = get(axesHandle,'CurrentPoint'); 
coordinates = coordinates(1,1:2);
x = round(coordinates(1), 0);
y = round(coordinates(2), 0);
k = (x - mod(x, 100)) / 100;
j = (y - mod(y, 100)) / 100;

if ((k + 1) +  5*j + 20*(handles.index - 1)) <= numel(tif_files) && strcmp(handles.rectangles{(k+1) + 5*j + 20*(handles.index - 1)}.Visible,'on')
    handles.rectangles{(k + 1) + 5*j + 20*(handles.index - 1)}.Visible = 'off';
    index = find(strcmp(handles.bad_files, handles.rectangle_files{(k + 1) + 5*j + 20*(handles.index - 1)}));
    handles.bad_files(index) = [];
elseif ((k + 1) +  5*j + 20*(handles.index - 1)) <= numel(tif_files)
    handles.rectangles{(k + 1) + 5*j + 20*(handles.index - 1)}.Visible = 'on';
    handles.bad_files{end+1} = handles.rectangle_files{(k + 1) + 5*j + 20*(handles.index - 1)};
end
disp(handles.bad_files);
guidata(objectHandle, handles);


function varargout = mask_preview_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function pushbutton1_Callback(hObject, eventdata, handles)
run('Aro_parameters.m');
handles.output = hObject;
handles.index = handles.index - 1;
Cek(hObject, eventdata, handles);
handles.image_handle = imshow(handles.X{handles.index},[]);

current_files = dir([SegmentationMaskDir filesep '*.tif']);
tif_files = {current_files.name};
tif_files = natsortfiles(tif_files);

for j = 0:3
    for k = 0:4
        if ((k + 1) +  5*j + 20*(handles.index-1)) <= numel(tif_files);
            start_x = j * 100 + 1;
            end_x = start_x + 99;
            start_y = k * 100 + 1;
            end_y = start_y + 99;
            name = tif_files{(k + 1) + 5*j + 20*(handles.index-1)};
            handles.rectangle_files{end+1} = name;
            show_rectangle = 'off';
            if any(strcmp(handles.bad_files, name))
                show_rectangle = 'on';
            end
            name = strsplit(name, '_');
            name = name(2);
            text(handles.axes1, start_y+35, start_x+50, name, 'Color', 'magenta', 'FontWeight', 'Bold');
            current_rect = rectangle(handles.axes1, 'Position', [start_y + 4 start_x + 4 92 92], 'EdgeColor', 'r', 'LineWidth', 4, 'Visible', show_rectangle);
            handles.rectangles{end+1} = current_rect;
        end
    end
end

set(handles.image_handle, 'ButtonDownFcn', {@toggle_status, handles});

guidata(hObject, handles);

function pushbutton2_Callback(hObject, eventdata, handles)
run('Aro_parameters.m');
handles.output = hObject;
handles.index = handles.index + 1;
Cek(hObject, eventdata, handles);
handles.image_handle = imshow(handles.X{handles.index},[]);

current_files = dir([SegmentationMaskDir filesep '*.tif']);
tif_files = {current_files.name};
tif_files = natsortfiles(tif_files);

for j = 0:3
    for k = 0:4
        if ((k + 1) +  5*j + 20*(handles.index-1)) <= numel(tif_files);
            start_x = j * 100 + 1;
            end_x = start_x + 99;
            start_y = k * 100 + 1;
            end_y = start_y + 99;
            name = tif_files{(k + 1) + 5*j + 20*(handles.index-1)};
            handles.rectangle_files{end+1} = name;
            show_rectangle = 'off';
            if any(strcmp(handles.bad_files, name))
                show_rectangle = 'on';
            end
            name = strsplit(name, '_');
            name = name(2);
            text(handles.axes1, start_y+35, start_x+50, name, 'Color', 'magenta', 'FontWeight', 'Bold');
            current_rect = rectangle(handles.axes1, 'Position', [start_y + 4 start_x + 4 92 92], 'EdgeColor', 'r', 'LineWidth', 4, 'Visible', show_rectangle);
            handles.rectangles{end+1} = current_rect;
        end
    end
end

set(handles.image_handle, 'ButtonDownFcn', {@toggle_status, handles});

guidata(hObject, handles);

function Cek(hObject, eventdata, handles)
handles.output = hObject;
n = length(handles.files);
if handles.index > 1,  set(handles.pushbutton1,'enable','on');
else                           set(handles.pushbutton1,'enable','off'); end
if handles.index < n, set(handles.pushbutton2,'enable','on');
else                           set(handles.pushbutton2,'enable','off'); end
guidata(hObject, handles);


% --- Executes on button press in pushbutton3.
% saves current bad mask list to .csv file
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
run('Aro_parameters.m');
bad_file_id = fopen(BadMaskList, 'wt');
for i = 1:numel(handles.bad_files)
    fprintf(bad_file_id, [handles.bad_files{i} '\n']);
end
fclose(bad_file_id);
guidata(hObject, handles);
