clc; clear; close all; 

% The below numbers indicate the index of data in the csv file. These
% correspond to the 3rd message exchange logged in the responder file.You
% will have to edit it for initiator file or for first message in reponder
% file.
IND_STARTDIAG = 1046;
NUM_DIAG_SAMPLES = 14;
IND_STARTCIR = 1061;
NUM_CIR_SAMPLES = 1016;
IND_STARTRANGE = 8;
NUM_RANGE_SAMPLES = 1;

IND_MAXNOISE = 1;
IND_STDNOISE = 2;
IND_FPAMP1 = 3;
IND_FPAMP2 = 4;
IND_FPAMP3 = 5;
IND_MAXGROWTHCIR = 6;
IND_RXPREAMCNT = 7;
IND_FPIND = 8;
IND_LDETHRESH = 9;
IND_LDECFG1 = 10;
IND_LDEPPIND = 11;
IND_LDEPPAMP = 12;

MTLB_IND_OFFSET = 1;

DataPath = pwd;
FRAME_RANGE = [0 0];
EXP_RANGE = [0 0];

for exp_num = EXP_RANGE(1):EXP_RANGE(2)
    figure;
    for frame_num = FRAME_RANGE(1):FRAME_RANGE(2)
        file = fullfile(DataPath,['exp',num2str(exp_num),'_msg',num2str(frame_num),'_R.csv']);

        CIR_Data = dlmread(file,',',[IND_STARTCIR 0 IND_STARTCIR+NUM_CIR_SAMPLES-1 1]);
        Diag_Data = dlmread(file,',',[IND_STARTDIAG 1 IND_STARTDIAG+NUM_DIAG_SAMPLES-1 1]);
        Range_Data = dlmread(file,',',[IND_STARTRANGE 1 IND_STARTRANGE+NUM_RANGE_SAMPLES-1 1]);
        
        DWT_TIME_UNITS =(1.0/499.2e6/128.0);
        CONV = 512/499.2/65536e6;
        SPEED_OF_LIGHT = 299702547;

        Plot_Title = ['3rd msg in exchange (Initiator to Responder)'];
                    
        CIR_Mag = sqrt(CIR_Data(:,1).^2 + CIR_Data(:,2).^2);

        plot(CIR_Mag,'-o','MarkerSize',2);hold on;
        plot([1 NUM_CIR_SAMPLES],[Diag_Data(IND_MAXNOISE) Diag_Data(IND_MAXNOISE)],'linewidth',2);
        plot([1 NUM_CIR_SAMPLES],[Diag_Data(IND_LDETHRESH) Diag_Data(IND_LDETHRESH)],'linewidth',2);                
        plot([Diag_Data(IND_FPIND)/2^6+MTLB_IND_OFFSET Diag_Data(IND_FPIND)/2^6+MTLB_IND_OFFSET],[0 max(CIR_Mag)],'linewidth',2);
        scatter([floor(Diag_Data(IND_FPIND)/2^6)+1+MTLB_IND_OFFSET:floor(Diag_Data(IND_FPIND)/2^6)+3+MTLB_IND_OFFSET],[Diag_Data(IND_FPAMP1:IND_FPAMP1+2)],60,'*');
        scatter(Diag_Data(IND_LDEPPIND)+MTLB_IND_OFFSET,Diag_Data(IND_LDEPPAMP),60,'r*');
        grid on;title(Plot_Title);
        legend({'CIR mag';'Max noise';'LDE threshold';'FP Ind';'FP Amp 1 2 3';'PP Ind Amp'});
        set(gca,'fontsize',14);
        xlim([740 810]);

        % Metric 1
        IDiff =  abs(Diag_Data(IND_LDEPPIND)-Diag_Data(IND_FPIND)/2^6);
        if (IDiff <= 3.3) 
            prNlos = 0.0;
        elseif ( (IDiff < 6.0) && (IDiff > 3.3) ) 
            prNlos = 0.39178*IDiff - 1.31719;
        else
            prNlos = 1.0;
        end


        % Metric 2
        Mc = max([Diag_Data(IND_FPAMP1:IND_FPAMP1+2)])/Diag_Data(IND_LDEPPAMP);

        NoiseThreshold = Diag_Data(IND_STDNOISE)*mod(Diag_Data(IND_LDECFG1),2^5);%Diag_Data(IND_MAXNOISE); 
        NewThreshold = 0.6*NoiseThreshold;
        Data_before_FP = CIR_Mag(floor(Diag_Data(IND_FPIND)/2^6)-15+MTLB_IND_OFFSET:floor(Diag_Data(IND_FPIND)/2^6)+MTLB_IND_OFFSET);
        iPeak = 0; 
        ind = find(Data_before_FP(1:end-1)>NewThreshold);
        for i = 1:length(ind)
            if Data_before_FP(ind(i))>Data_before_FP(ind(i)-1) && Data_before_FP(ind(i)) > Data_before_FP(ind(i)+1)
                iPeak = iPeak + 1;
            end 
        end
        Luep = iPeak/((length(Data_before_FP)-1)/2);

        if Luep > 0
            CL = 0;
        else
            if prNlos==0
                CL = 1;
            else
                if Mc >= 0.9
                    CL = 1;
                else
                    CL = 1-prNlos;
                end
            end
        end
        disp(['Confidence of LOS : ',num2str(CL)]);
        disp(['Range : ',num2str(Range_Data)]);
                 
    end
end

