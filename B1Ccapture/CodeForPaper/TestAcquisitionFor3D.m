%Author:LSQ
%Date:2019/4
%Description: 为学位论文用与对比的PCF捕获算法，给出了捕获结果3D图.

clc;
close all;

set(0,'defaultfigurecolor','w'); %将仿真图背景设置为白色

%%本程序仅对北斗B1C信号的导频分量进行捕获
%仿真参数设置
f_sample = 36*1.023e6;             %采样频率
f_sc_a = 1.023e6 ;                 %数据分量子载波速率
f_sc_b = 6*1.023e6 ;               %导频分量子载波速率
Rc = 1.023e6;                      %主码码速率
T_process = 25e-3;                 %处理时间
T_int = 10e-3;                      %相关运算时间
Non_Coh_Sums = 2;                  %(Non_Coh_Sums*T_int)ms非相干积分时间
t = 0 : 1/f_sample : T_process - 1/f_sample;
n = 0:length(t)-1;                 
j=sqrt(-1);
pi = 3.141592654;                  %圆周率
Num_int = floor(f_sample * T_int); %相干积分时间所对应的采样点数

%%模拟产生接收信号
subcarr1 = sign(sin(2*pi*f_sc_a*t));
subcarr1(1) = 1;
subcarr2 = sign(sin(2*pi*f_sc_b*t));
subcarr2(1) = 1;
code_r = generatecode(2);           %接收信号由PRN=2的扩频码序列调制
codeSample_r = code_r(mod(floor(t*Rc),10230)+1);
Qmboc_p = sqrt(1/11)*codeSample_r.*subcarr2 + ...
    j*sqrt(29/44)*codeSample_r.*subcarr1;

BOC_6_1 = codeSample_r.*subcarr2;
BOC_1_1 = codeSample_r.*subcarr1;

code_sample = floor(f_sample/Rc);   %单个码片所对应的采样数
num_boc = length(Qmboc_p);
delay = 306*code_sample;            %给伪码设定码相位延时
Qmboc_delay = [Qmboc_p(delay : num_boc) Qmboc_p(1 : delay-1)];

IF = 24.58e6;     %中频频率
fd = 1200;        %多普勒频移
signal_p = Qmboc_delay.*cos(2*pi*(IF+fd)*t); %模拟中频信号，只考虑IQ分量的I分量

signal = awgn(signal_p, -25);    %加高斯白噪声

%%基于PCF的北斗B1C信号捕获算法
FdSearchStep = 50;      %[Hz]
DopplerRange = 5000;      %[Hz]

FdVect= -DopplerRange:FdSearchStep:DopplerRange;     %多普勒频移搜索范围

%产生本地测距码序列
prn_p = generatecode(2);
index_code = mod(floor(Rc*t),10230)+1;
prn_local = prn_p(index_code);

%%导频信号QMBOC(6,1,4/33)
idx1 = mod(floor(12*Rc*t),12)+1;
prn1_qmboc11 = [j*sqrt(20/44),j*sqrt(20/44),j*sqrt(20/44),j*sqrt(20/44),j*sqrt(20/44),...
    j*sqrt(20/44),0,0,0,0,0,0];
s1_qmboc11 = prn1_qmboc11(idx1).*prn_local;
[g1_qmboc11 x]= xcorr(Qmboc_p, s1_qmboc11, 'coeff');
prn12_qmboc11 = [0,0,0,0,0,0,j*sqrt(20/44),j*sqrt(20/44),j*sqrt(20/44),j*sqrt(20/44),...
    j*sqrt(20/44),j*sqrt(20/44)];
s12_qmboc11 = prn12_qmboc11(idx1).*prn_local;
g12_qmboc11 = xcorr(Qmboc_p, s12_qmboc11, 'coeff');

corr_sum_qmboc = abs(g1_qmboc11)+abs(g12_qmboc11)-abs(g1_qmboc11+g12_qmboc11);
corr_qmboc = xcorr(Qmboc_p, Qmboc_p, 'coeff');

%横坐标尺度变换
index = x / floor(f_sample/Rc);

figure(1)
plot(index, corr_qmboc,'b',index,corr_sum_qmboc,'m');
xlabel('码片');
ylabel('归一化自相关函数');
legend('ACF','PCF');
axis([-1.5 1.5 -0.5 1.5]);

%%以下为PCF捕获算法验证
%生成矩阵用于存相关结果
C = zeros(length(FdVect),Num_int);     %用于所有码片的相关结果
idx = 1;     %矩阵行数

for ind_FD= 1:length(FdVect)
    corr_temp = zeros(1,Num_int) ;
    fd_ind = FdVect(ind_FD);
    %本地载波
    m = 1:Num_int;
    carrI = cos(2*pi*(IF+fd_ind)*m/f_sample);
    carrQ = sin(2*pi*(IF+fd_ind)*m/f_sample);
    for M = 0 : (Non_Coh_Sums - 1)
    %下变频
    SigIN = signal(1+M*Num_int : Num_int+M*Num_int);
    SigOUTI = SigIN .* carrI;
    SigOUTQ = SigIN .* carrQ;
    %本地码
    S1_qmboc11 = s1_qmboc11(1:Num_int);
    S12_qmboc11 = s12_qmboc11(1:Num_int);
    
    PRNLOCFFT_boc11_E = conj(fft(S1_qmboc11));
    PRNLOCFFT_boc11_L = conj(fft(S12_qmboc11));  
    %对基带信号进行FFT
    SigOUT = SigOUTI + SigOUTQ;
    Signal_fft = fft(SigOUT);
    %重构相关函数
    R_boc_prn_E_11 = Signal_fft.*PRNLOCFFT_boc11_E;
    R_boc_prn_L_11 = Signal_fft.*PRNLOCFFT_boc11_L;
    
    R_E_11 = ifft(R_boc_prn_E_11);
    R_L_11 = ifft(R_boc_prn_L_11);

    R_EL_11 = R_E_11 + R_L_11;
    
    corr_temp = corr_temp + abs(R_E_11) + abs(R_L_11) - abs(R_EL_11);
    end
       
    C(idx,:) = corr_temp;
    idx = idx + 1;
end

[value, ind_mixf] = max(max(C'));
[value, ind_mixc] = max(max(C));

code_phase = (Num_int-ind_mixc)/code_sample;
doppler =(ind_mixf-1)*FdSearchStep - DopplerRange;   %[HZ]

%自适应捕获检测判决
Num_code = 12;                %被检测码片单元周围的参考码片单元数目
ThresholdFactor = 9.34;      %虚警率为10e-6的门限比例因子
Z = 0;                        %功率估计值
for i=1:6
    Z = Z + C(ind_mixf,ind_mixc+i*code_sample)+C(ind_mixf,ind_mixc-i*code_sample);    
end
Z_aver = Z/Num_code;

Threshold = ThresholdFactor*Z_aver;    %得到自适应门限值

if C(ind_mixf,ind_mixc) > Threshold
    data = sprintf('The acquisition result\n Code phase:%f 码片\nDoppler frequency:%f Hz\nThreshold:%f \n',...
        code_phase,doppler,Threshold);
    disp(data);
else
    data = sprintf('Acquisition failed!\n');
    disp(data);
end

%画三维图
[C_y, C_x]=size(C);    %C_x为码相位，C_y为多普勒频移
X=1:C_x;Y=1:C_y;       %X为码相位，Y为多普勒频移
[x,y]=meshgrid(X,Y);
figure(2)
mesh((Num_int-x)/code_sample,(y-1)*FdSearchStep - DopplerRange,C);  %坐标变换
hold on;
plot3(code_phase,doppler,value,'k.','markersize',20);     %小黑点标记
text(code_phase,doppler,value,['X:',num2str(code_phase,4),char(10), ...
     'Y:',num2str(doppler,4),char(10),'Z:',num2str(value),char(10)]);  %标值
xlabel('码相位延时(码片)');ylabel('多普勒频移(Hz)');zlabel('相关值');
axis([0 10230 -5000 5000 0 value+1e4]);

