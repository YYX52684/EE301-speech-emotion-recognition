%% Voice endpoint detection
function X=vad(x)
%Parameter Settings
FrameLen =512;     %frame length
inc =285;           %Unoverlapping part
amp3 = 1.2;          %Short time energy threshold
amp4 = 0.8;      
zcr1 = 10;          %Zero crossing rate threshold
zcr2 = 2;

minsilence = 40;  %Use the length of the silence to determine if the speech is over
minlen  = 20;    %Judgment is the minimum length of speech
status  = 0;     %Record the status of the voice segment
count   = 0;     %The length of the speech sequence
silence = 0;     %Silent length

%Calculate the zero crossing rate
tmp1  = enframe(x(1:end-1), FrameLen,inc);
tmp2  = enframe(x(2:end)  , FrameLen,inc);
signs = (tmp1.*tmp2)<0;
diffs = (tmp1 -tmp2)>0.02;
zcr   = sum(signs.*diffs,2);
avgzcr = sum(zcr(1:10,1))./10;%Average zero crossing rate for the first 10 frames

% Calculating short-term energy
amp = sum((abs(enframe(x, FrameLen, inc))).^2, 2);
avgamp = sum(amp(1:10,1))./10;%Average energy for the first 10 frames

%Adjust the energy threshold
amp11 = min(amp3, max(amp)/4);%Upperbound
amp12 = min(amp4, max(amp)/8);%Energy lowerbound

voicecount = 1;%Record the number of the segments of the voice
%Start the endpoint detection
for n=1:length(zcr)
   goto = 0;
   switch status
   case {0,1}                   % 0 = silence, 1 = probably begin
      if amp(n) > amp11 || zcr(n)>zcr1         % Make sure to enter the voice segment
         x11(voicecount) = max((n-count(voicecount)-1),1);  %  Record the starting point of the voice segment
         status  = 2;
         silence(voicecount) = 0;
         count(voicecount)   = count(voicecount) + 1;
      else                       % silent status
         status  = 0;
         count(voicecount)  = 0;
      end
   case 2                       %  2 = voice segment
      if amp(n) > amp11 ||zcr(n) > zcr1     % keep in voice segment
         count(voicecount) = count(voicecount) + 1;
         status = 2;
         silence(voicecount) = 0;
      else                                  % voice will end
         silence(voicecount) = silence(voicecount)+1;
         if silence(voicecount) < minsilence % silent piece isn't long enough and the voice doesn't end
            count(voicecount)  = count(voicecount) + 1;
            %status = 2;
         elseif count(voicecount) < minlen   %The speech is too short and is considered noise.
               status  = 0; 
               silence(voicecount) = 0;
               count(voicecount) = 0;
        else                 % voice end
              voicecount = voicecount + 1;
              status  = 3;
         end
      end
   case 3,
       status = 0;
       continue;
   end 
end
for i=1:length(count)
count(i) = count(i)-silence(i)/2;
x22(i) = x11(i) + count(i) -1;              %Record the ending point of the voice segment
end    
%Extracting speech information within the endpoints
X=[];         %Record valid voice segment information
for j=1:length(count)
  m(j) = (x22(j) - x11(j))*inc;
  for n=1:m(j)
    XY1(n) = x(x11(j)*inc + n);%etrieve voice information within each endpoint
  end
  X = [X,XY1];
end