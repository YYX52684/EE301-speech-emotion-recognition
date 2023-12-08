function [ features ] = mfcc( y,fs )
%% MFCC Extracts Features
    % Pre-emphasis
    yy = filter([1 -0.97],1,y);
    % Framing
    frame_yy = enframe(yy,512,285);% Divide x 512 points into one frame
    frame_count = size(frame_yy,1);
    % Window - Add 512 Hamming Windows to each frame.
    for i=1:frame_count
        win_frame_yy(i,:) = ((frame_yy(i,:))'.* hamming(512))';
    end
    % Calculate discrete Fourier transform and signal power
    for i=1:frame_count
        frame_YY(i,:) = fft((win_frame_yy(i,:))',512);
    end
        amp_frame_YY = abs(frame_YY);
        pow_frame_YY = amp_frame_YY.^2;
        %Intercept the first 257 of the energy spectrum
        newpow_frame_YY = pow_frame_YY(:,1:257);
        %mel filter bank Settings
        bank=melbankm(26,512,fs,0,0.5,'t');%The order of the Mel filter is 26, the length of the fft transformation is 512, and the sampling frequency is 16000Hz
        mel_energy = bank*newpow_frame_YY';
        log_mel_energy = log10(mel_energy);
        %Discrete cosine transform parameter
        for k=1:1:13 
            n=0:1:25;
            dctcoef(k,:)=cos((2*n+1)*k*pi/(2*26));% The first order MFCC is to be discarded, 
                                                  % so the first row of the transformation matrix here can be calculated arbitrarily,
                                                  % without strictly following the principle of DCT
        end
        mfcc1 = dctcoef*log_mel_energy;
        mfcc2 = mfcc1(2:13,:);
        mfcc = mfcc2;
        mean_mfcc = mean(mfcc,2);
        max_mfcc = max(mfcc,[],2);
        min_mfcc = min(mfcc,[],2);
        var_mfcc = var(mfcc,[],2);
        %Mix together
        features = [mean_mfcc',max_mfcc',min_mfcc',var_mfcc'];
        for i = 1:1:48
            if isnan(features(i)) == 1
                features(i) = randi([-3,3])*abs(randi([-3,3]));
            end
        end
end
