     function Idown=imdownsample(I,m)
     % Downsample the square image I by a factor of m
%http://biocomp.cnb.csic.es/~coss/Docencia/ImageProcessing/Tutorial/index.html
     [N,M]=size(I);

     % Apply ideal filter
     w=1/m;
     F=fftshift(fft2(I));
     for i=1:N
         for j=1:N
             r2=(i-round(N/2))^2+(j-round(N/2))^2;
             if (r2>round((N/2*w)^2)) F(i,j)=0; end;
         end;
     end;
     Idown=real(ifft2(fftshift(F)));

     % Now downsample
     Idown=imresize(Idown,[N/m,N/m],'nearest');

  
