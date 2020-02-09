%Author:LSQ
%Date:2018/12
%Description:This program is for Beidou B1C satellite signal acquisition.
%Parameters: 
%          Sampling rate: 12.4MHz
%          Channel 1: Beidou B3
%          Channel 2: GPS L1
%          Sampling depth: 131072

clc;
close all;

%data_in_11 = AD1_IN_IBUF90(1:end);   %Channel 1
%data_in_22 = AD2_IN_IBUF90(1:end);   %Channel 2

data_in_1 = csvread('tianxian_14pm47_12.csv',1,3,[1 3 131072 3]);%Channel 1
data_in_2 = csvread('tianxian_14pm47_12.csv',1,4,[1 4 131072 4]);%Channel 2
%data_in_1 = csvread('L1_-40_62.csv',1,3,[1 3 8192 3]);%Channel 2

len = length(data_in_2);
freq = (1:len)./len * 12.4;

figure(1)
plot(data_in_2);

fft_data_squ = abs(fft(data_in_2)).^2;
fft_data_log = 10*log10(fft_data_squ);

figure(2)
plot(freq,fft_data_log);   %��ͨ��������ƵƵ��Ϊ9.22MHz��3.18MHz������Ϊ4.092MHz

%���ڲ�����Ϊ12.4MHz�����Խ��Ե�Ƶ�źŵ�BOC(1,1)�źųɷֽ��в���
f_sample = 12.4e6;             %����Ƶ��

%%����10ms�ı��ص�Ƶ�ź�
%��������
f_sc_a = 1.023e6 ;                 %BOC(1,1)���ز�����
f_sc_b = 6*1.023e6 ;               %BOC(6,1)���ز�����
Rc = 1.023e6;                      %����������
T_process = 10e-3;                 %����ʱ��
T_int = 5e-3;                      %�������ʱ��
t = 0 : 1/f_sample : T_process - 1/f_sample;
n = 0:length(t)-1;                 
j=sqrt(-1);
pi = 3.141592654;                  %Բ����
Num_int = floor(f_sample * T_int); %��ɻ���ʱ������Ӧ�Ĳ�������
IF = 3.18e6;            %[Hz]
FdSearchStep = 40;      %[Hz]
DopplerRange = 5000;      %[Hz]
code_sample = floor(f_sample/Rc);   %������Ƭ����Ӧ�Ĳ�����
FdVect= -DopplerRange:FdSearchStep:DopplerRange;     %������Ƶ��������Χ

SigIN1 = data_in_2(1 : 5*12.4e3);    %���������ݽض�Ϊ5ms
%SigIN = data_in_2(7073 : 131072);    %���������ݽض�Ϊ10ms
SigIN2 = data_in_2(5*12.4e3+1 : 10*12.4e3);    %���������ݽض�Ϊ5ms

%SigIN = SigIN';
SigIN1 = SigIN1';
SigIN2 = SigIN2';

%�������ص�Ƶα������
for prn_num = 1:63
   prn_p = generatecode(prn_num);
   index_code = mod(floor(Rc*t),10230)+1;
   prn_local = prn_p(index_code);

%��Ƶ�ź��е�BOC(1,1)
   idx1 = mod(floor(12*Rc*t),12)+1;
   prn1_qmboc11 = [j,0,0,0,0,0,0,0,0,0,0,0];
   s1_qmboc11 = prn1_qmboc11(idx1).*prn_local;
   
   prn12_qmboc11 = [0,0,0,0,0,0,0,0,0,0,0,j];
   s12_qmboc11 = prn12_qmboc11(idx1).*prn_local;

  %���ɾ������ڴ���ؽ��
  %C = zeros(length(FdVect),Num_int);     %����������Ƭ����ؽ��
  C = zeros(length(FdVect),f_sample*T_process*2-1);
  C_temp = zeros(length(FdVect),f_sample*T_process*2-1);
  C_temp2 = zeros(length(FdVect),f_sample*T_process*2-1);
   idx = 1;     %��������
   idx2 = 1;
   
   for ind_FD= 1:length(FdVect)
       %corr_temp = zeros(1,Num_int) ;
       fd_ind = FdVect(ind_FD);
       %�����ز�
       m = 1:Num_int;
       carrI = cos(2*pi*(IF+fd_ind)*m/f_sample);
       carrQ = sin(2*pi*(IF+fd_ind)*m/f_sample);
       %�±�Ƶ
       %SigOUTI = SigIN .* carrI;
       %SigOUTQ = SigIN .* carrQ;
       SigOUTI = SigIN1 .* carrI;
       SigOUTQ = SigIN1 .* carrQ;
       
       %������
       %S1_qmboc11 = s1_qmboc11(1:Num_int);
       %S12_qmboc11 = s12_qmboc11(1:Num_int);
       S1_qmboc11 = s1_qmboc11(1:floor(f_sample * T_process));
       S12_qmboc11 = s12_qmboc11(1:floor(f_sample * T_process));
       
       %PRNLOCFFT_boc11_E = conj(fft(S1_qmboc11));
       %PRNLOCFFT_boc11_L = conj(fft(S12_qmboc11));
       
       SigOUT = SigOUTI + SigOUTQ;
       %Signal_fft = fft(SigOUT);
       %�ع���غ���
       %R_boc_prn_E_11 = Signal_fft.*PRNLOCFFT_boc11_E;
       %R_boc_prn_L_11 = Signal_fft.*PRNLOCFFT_boc11_L;
       
       %R_E_11 = ifft(R_boc_prn_E_11);
       %R_L_11 = ifft(R_boc_prn_L_11);
       R_E_11 = xcorr(S1_qmboc11, SigOUT,'none');
       R_L_11 = xcorr(S12_qmboc11, SigOUT,'none');

       R_EL_11 = R_E_11 + R_L_11;
       
       corr_temp =abs(R_E_11) + abs(R_L_11) - abs(R_EL_11);
       
       %C(idx,:) = corr_temp;
       C_temp(idx,:) = corr_temp;     
       idx = idx + 1;
   end

    [value1, ind_mixf1] = max(max(C_temp'));
    [value2, ind_mixc1] = max(max(C_temp)); 
   
    for ind_FD2= 1:length(FdVect)
       %corr_temp = zeros(1,Num_int) ;
       fd_ind2 = FdVect(ind_FD2);
       %�����ز�
       m = 1:Num_int;
       carrI2 = cos(2*pi*(IF+fd_ind2)*m/f_sample);
       carrQ2 = sin(2*pi*(IF+fd_ind2)*m/f_sample);
       %�±�Ƶ
       SigOUTI2 = SigIN2 .* carrI2;
       SigOUTQ2 = SigIN2 .* carrQ2;
       
       %������
       S1_qmboc11 = s1_qmboc11(1:floor(f_sample * T_process));
       S12_qmboc11 = s12_qmboc11(1:floor(f_sample * T_process));
       
       SigOUT2 = SigOUTI2 + SigOUTQ2;

       %�ع���غ���
       R_E_11_2 = xcorr(S1_qmboc11, SigOUT2,'none');
       R_L_11_2 = xcorr(S12_qmboc11, SigOUT2,'none');

       R_EL_11_2 = R_E_11_2 + R_L_11_2;
       
       corr_temp2 =abs(R_E_11_2) + abs(R_L_11_2) - abs(R_EL_11_2);
       
       %C(idx,:) = corr_temp;
       C_temp2(idx2,:) = corr_temp2;     
       idx2 = idx2 + 1;
   end
   [value3, ind_mixf2] = max(max(C_temp2'));
   [value4, ind_mixc2] = max(max(C_temp2)); 
   
   if C_temp(ind_mixf1,ind_mixc1) > C_temp2(ind_mixf2,ind_mixc2)
       code_phase = (ind_mixc1-f_sample*T_process)/code_sample;
       doppler =(ind_mixf1-1)*FdSearchStep - DopplerRange;   %[HZ]
       C = C_temp;
   else
       code_phase = (ind_mixc2-f_sample*T_process)/code_sample;
       doppler =(ind_mixf2-1)*FdSearchStep - DopplerRange;   %[HZ]
       C = C_temp2;
   end
    
   [value, ind_mixf] = max(max(C'));
   [value, ind_mixc] = max(max(C)); 
   
   %code_phase = (Num_int-ind_mixc)/code_sample;
   %doppler =(ind_mixf-1)*FdSearchStep - DopplerRange;   %[HZ]
   
   %����Ӧ�������о�
% Num_code = 12;                %�������Ƭ��Ԫ��Χ�Ĳο���Ƭ��Ԫ��Ŀ
% ThresholdFactor = 9.34;      %�龯��Ϊ10e-6�����ޱ�������
% Z = 0;                        %���ʹ���ֵ
% for i=1:6
%     Z = Z + C(ind_mixf,ind_mixc+i*code_sample)+C(ind_mixf,ind_mixc-i*code_sample);    
% end
% Z_aver = Z/Num_code;
% 
% %Threshold = ThresholdFactor*Z_aver;    %�õ�����Ӧ����ֵ
% Threshold = 90000;

% if C(ind_mixf,ind_mixc) > Threshold
%     data = sprintf('The acquisition result\n Code phase:%f ��Ƭ\nDoppler frequency:%f Hz\nValue:%f \n',...
%         code_phase,doppler,C(ind_mixf,ind_mixc));
%     data_prn = sprintf('The satellite number is %d.\n',prn_num);
%     disp(data);
%     disp(data_prn);
% else
%     data = sprintf('Acquisition failed!\n');
%     data_prn = sprintf('Value:%f \nThe satellite number is %d.\n',C(ind_mixf,ind_mixc),prn_num);
%     disp(data);
%     disp(data_prn);
% end
     data = sprintf('The acquisition result\n Code phase:%f ��Ƭ\nDoppler frequency:%f Hz\nValue:%f \n',...
        code_phase,doppler,C(ind_mixf,ind_mixc));
    data_prn = sprintf('The satellite number is %d.\n',prn_num);
    disp(data);
    disp(data_prn);
  
 end

%����άͼ
% x1 = Num_int-2046*code_sample;
% x2 = Num_int;
% y1 = (-2000+DopplerRange)/FdSearchStep+1;
% y2 = (2000+DopplerRange)/FdSearchStep+1;
% C_part=C(y1:y2,x1:x2);
% [C_y, C_x]=size(C);    %C_xΪ����λ��C_yΪ������Ƶ��
% X=1:C_x;Y=1:C_y;       %XΪ����λ��YΪ������Ƶ��
% [x,y]=meshgrid(X,Y);
%figure(3)
%mesh((Num_int-x)/code_sample,(y-1)*FdSearchStep - DopplerRange,C);  %����任
%mesh((x2-x1-x)/code_sample,(y+y1-2)*FdSearchStep - DopplerRange,C_part);  %��С��ʾ��Χ
%view(0,0);                        %��ά�ӽ�
% hold on
% plot3(code_phase,doppler,value,'k.','markersize',20);     %С�ڵ���
% text(code_phase,doppler,value,['X:',num2str(code_phase,4),char(10), ...
%     'Y:',num2str(doppler,4),char(10),'Z:',num2str(value),char(10)]);  %��ֵ
%xlabel('����λ/��');ylabel('������Ƶ��/Hz');zlabel('���ֵ');
%axis([0 10230 -5000 5000 0 value+1e4]);
%title('����B1C�źŲ�����');