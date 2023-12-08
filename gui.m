function varargout = gui(varargin)
% GUI MATLAB code for gui.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI.M with the given input arguments.
%
%      GUI('Property','Value',...) creates a new GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui_OpeningFcn via varargin.

% Edit the above text to modify the response to help gui

% Last Modified by Chengrui Yuan  1-Nov.-2023 13:35:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui (see VARARGIN)

% Choose default command line output for gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global x  fs
 [file1,path1] = uigetfile('.wav');
 [x,fs]=audioread([path1,file1]);
 axes(handles.axes1)
 plot(x)
title('Voice File Waveform','Color','b','FontSize',14);
sound(x,fs)
% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global x  X

%Parameter settings
FrameLen =512;     %Frame length
inc =285;           %Unoverlapping parts
amp3 = 1.2;          %Short time energy threshold
amp4 = 0.8;      
zcr1 = 10;          %Zero Rate Crossing Threshold
zcr2 = 2;
minsilence = 40;  %Using silent length to determine if the speech ends
minlen  = 20;    %Determine the minimum length of speech
status  = 0;     %Record the status of the voice segments
count   = 0;     %Length of the speech sequence
silence = 0;     %silent length
%Calculate the zero crossing rate
tmp1  = enframe(x(1:end-1), FrameLen,inc);
tmp2  = enframe(x(2:end)  , FrameLen,inc);
signs = (tmp1.*tmp2)<0;
diffs = (tmp1 -tmp2)>0.02;
zcr   = sum(signs.*diffs,2);
avgzcr = sum(zcr(1:10,1))./10;%Average zero crossing rate of the first ten frames.

%Calculate the short-time energy
amp = sum((abs(enframe(x, FrameLen, inc))).^2, 2);
avgamp = sum(amp(1:10,1))./10;%Average zero crossing rate of the first ten frames.
%Adjusting the energy threshold
amp11 = min(amp3, max(amp)/4);%Upperbound
amp12 = min(amp4, max(amp)/8);%Lowerbound of the energy

voicecount = 1;%Record the number of the segments of the voice
%Start the endpoint detection
for n=1:length(zcr)
   goto = 0;
   switch status
   case {0,1}                   % 0 = silence, 1 = probably begin
      if amp(n) > amp11 || zcr(n)>zcr1         % Make sure to enter the voice segment
         x11(voicecount) = max((n-count(voicecount)-1),1);  % Record the starting point of the voice segment
         status  = 2;
         silence(voicecount) = 0;
         count(voicecount)   = count(voicecount) + 1;
      else                       % silent status
         status  = 0;
         count(voicecount)  = 0;
      end
   case 2                      % 2 = voice segment
      if amp(n) > amp11 ||zcr(n) > zcr1     % keep in voice segment
         count(voicecount) = count(voicecount) + 1;
         status = 2;
         silence(voicecount) = 0;
      else                                  % voice will end
         silence(voicecount) = silence(voicecount)+1;
         if silence(voicecount) < minsilence % silent piece isn't long enough and the voice doesn't end
            count(voicecount)  = count(voicecount) + 1;
            %status = 2;
         elseif count(voicecount) < minlen   % The speech is too short and is considered noise.
               status  = 0; 
               silence(voicecount) = 0;
               count(voicecount) = 0;
        else                 % voice end
              voicecount = voicecount + 1;
              status  = 3;
         end
      end
   case 3
       status = 0;
       continue;
   end 
end

for i=1:length(count)
count(i) = count(i)-silence(i)/2;
x22(i) = x11(i) + count(i) -1;              %Record the ending point of the voice segment
end    
 axes(handles.axes2)
    plot(x)
    axis([1 length(x) -1 1])
   title('Endpoint_Detection','Color','b','FontSize',14);
   for i=1:length(count)
    line([x11(i)*inc x11(i)*inc], [-1 1], 'Color', 'red');
    line([x22(i)*inc x22(i)*inc], [-1 1], 'Color', 'red');
   end
%Extracting speech information within the endpoints

X=[];         %Record valid voice segment information
for j=1:length(count)
  m(j) = (x22(j) - x11(j))*inc;
  for n=1:m(j)
    XY1(n) = x(x11(j)*inc + n);%Retrieve voice information within each endpoint
  end
  X = [X,XY1];
end
% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global feature  X fs
f = waitbar(0,'Please wait...');
waitbar(0.5,f);
feature= mfcc(X,fs );
waitbar(1,f,'Extraction Completed');
pause(0.8)
delete(f)

% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global feature model 
[predicted_label,~,~] = svmpredict(1,feature ,model);
if predicted_label==1
    t='Anger';
elseif predicted_label==2
      t='Sadness';
else
    t='Happiness';
end
set(handles.edit1, 'string', t);
% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
ha=axes('units','normalized','pos',[0 0 1 1]);
uistack(ha,'down');
ii=imread('Background.jpg');
image(ii);
colormap gray
set(ha,'handlevisibility','off','visible','on');



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1)
cla
axes(handles.axes2)
cla
set(handles.edit1,'string',[])


% --------------------------------------------------------------------
function Untitled_2_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)\
close
main


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global  model
%%%%%%%%%%%%%%%%%%% Endpoint Detection  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[FileName] = uigetdir('.','Select Training Set Folder');%
f = waitbar(0,'Please wait...');
class_label = containers.Map({'anger','sadness','happiness'},{1,2,3});
%% Read the original audio sequence and extract feature parameters using MFCC.
for i=1:10
    [y ,fs]=audioread(strcat(FileName,'\',[num2str(i),'.wav']));
    y=vad(y);%Endpoint detection
    feature_anger(i,:) = mfcc( y,fs );
end
waitbar(.25,f);
pause(0.01)
for i =1:10
     [y ,fs]=audioread(strcat(FileName,'\',[num2str(10+i),'.wav']));
    y=vad(y);%Endpoint detection
    feature_sadness(i,:) = mfcc( y,fs );
end
waitbar(.50,f);
pause(0.01)
for i =1:10
      [y ,fs]=audioread(strcat(FileName,'\',[num2str(20+i),'.wav']));
    y=vad(y);%Endpoint detection
    feature_happiness(i,:) = mfcc( y,fs );
end
waitbar(.75,f);
pause(0.01)
%% (Training Set)training_matrix
training_matrix_anger = feature_anger;
training_matrix_happiness = feature_happiness;
training_matrix_sadness = feature_sadness;
training_matrix = [training_matrix_anger;training_matrix_sadness;training_matrix_happiness];
%% (Label)training_label
training_label_anger = class_label('anger')*ones(size(training_matrix_anger,1),1);
training_label_happiness = class_label('happiness')*ones(size(training_matrix_happiness,1),1);
training_label_sadness = class_label('sadness')*ones(size(training_matrix_sadness,1),1);
training_label = [training_label_anger; training_label_sadness;training_label_happiness;];
%% svm training
model = svmtrain(training_label, training_matrix);%Training Model
waitbar(1,f,'Finishing');
pause(0.8)
delete(f)
