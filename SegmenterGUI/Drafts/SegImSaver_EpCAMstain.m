%Compile all the segmented 3 channel images for quality estimation

clear


h = figure()
set(h,'visible','off')
set(h,'Position',[66 1 1301 689],'Units','pixels')
    
%Number of channels in the image
numCh = 2; %Number of fluourescent channels not including nuclear channel
imExt = '.jpg';
%Use CIDRE correction model?
cidrecorrect = 0;
numLevels = 10;

%The noise filter used is 5.
noise_disk = 5;
%Use a background correction if cidre was used
if cidrecorrect
    tophat_rad = 0;  %Background correction
else
    tophat_rad = 50;  %To correct for uneven illumination
end

%Set up structure with the filenames of the images to be segmented
%Nuclei Directory (N)
NUC.dir = 'Nuc';
NUC.filnms = dir([NUC.dir filesep '*' imExt]);
NUC.filnms = strcat({NUC.dir}, '/', {NUC.filnms.name});

%Create a structure for each of the channels
for i = 1:numCh
    chnm = ['CH_' num2str(i)];
    Cyto.(chnm).dir = chnm;
    Cyto.(chnm).filnms = dir([chnm filesep '*' imExt]);
    Cyto.(chnm).filnms = strcat(chnm, '/', {Cyto.(chnm).filnms.name});
end

temp = strfind(NUC.filnms,'C04');
idx = find(cellfun(@isempty,temp)==0);

mkdir('Segmentation_Images')

%Segmentation occurs in multiple steps
%First nuclei are segmented using Otsu's method to determine background in 
%the nuclear channel.  The image is quantized into three tiers with the top
%two being assigned as nucleus (nucleus in focus and nucleus out of focus)
% Use of a watershed segmentation algorithm then assigns a label to each
% cell
%Each of the fluorescent channels are then binarized/segmented and the channel with
%the most amount of cell area is picked as defining the cytoplasm.
%The intensity in each channel for each cell is then subsequently measured.
%Subsequent use of a noise filter and hole filling smooths out the image and
%then use of a watershed segmentation to label all the cells.
%The label for the cell's cytoplasm is determined using a
%kmeans nearest neighbor algorithm from each nucleus
%Each segmented image is saved in a Segmentation folder.

%Preallocate for memory
tempIm = imread(char(NUC.filnms(1)));
Im_array  = zeros(size(tempIm,1),size(tempIm,2),numCh+1);
SegIm_array  = zeros(size(tempIm,1),size(tempIm,2),numCh+1);
Nuc_label = zeros(size(tempIm,1),size(tempIm,2),1);

wb = waitbar(0.000001,'Time to complete:');
%For all images
for i = 1:5:size(idx,2)
    tic
    CO = struct(); %Cellular object structure.  To be saved
    nm = char(NUC.filnms(idx(i)));
    foo = strfind(nm, '-');
    %Store the row and column names from the filename
    rw = nm(foo(2)+1:foo(2)+3);
    cl = nm(foo(3)+1:foo(3)+3);

    %Read in all the images and correct with for illumination with CIDRE or
    %tophat.  Store the nuclear image in the first!
    
    tempIm = imread(char(NUC.filnms(idx(i))));
    if size(tempIm,3) ~=1
        tempIm = rgb2gray(tempIm);
    end
    %Correct with CIDRE model or background correction
    if cidrecorrect
        tempIm = (double(tempIm)-NUC.CIDREmodel.z)./(NUC.CIDREmodel.v);
    elseif tophat_rad ~=0
        tempIm = imtophat(im2double(tempIm), strel('disk', tophat_rad));
    end
    %Convert to 16bit image
    tempIm = im2uint8(tempIm);
    Im_array(:,:,1) = tempIm;
    %read in all cytoplasmic channels
    for q = 1:numCh
        chnm = ['CH_' num2str(q)];
        tempIm = imread(char(Cyto.(chnm).filnms(idx(i))));
        if size(tempIm,3) ~=1
            tempIm = rgb2gray(tempIm);
        end
        %Correct with CIDRE model or background correction
        if cidrecorrect
            tempIm = (double(tempIm)-Cyto.(chnm).CIDREmodel.z)./(Cyto.(chnm).CIDREmodel.v);
        elseif tophat_rad ~=0
            tempIm = imtophat(im2double(tempIm), strel('disk', tophat_rad));
        end
        
%          if strcmp(chnm,corCH)
%              tempIm = im2double(tempIm) - corVal/100*im2double(Im_array(:,:,1));
%              %tempIm = im2double(tempIm) - corVal/100*im2double(Im_array(:,:,1));
%              tempIm = corVal/100*im2double(Im_array(:,:,1));
%              
%          end
        
        %Convert to 8bit image
        tempIm = im2uint8(tempIm);
        Im_array(:,:,q+1) = tempIm;
    end
    
    
    %Create image with all the channels as a composite
    
    %%
    %%Now segment the nucleus
    % To Binary Image with otsu's threshold
    num = multithresh(Im_array(:,:,1),2);
    SegIm_array(:,:,1)	= imquantize(Im_array(:,:,1), num);
    SegIm_array(SegIm_array(:,:,1) == 1) = 0; %Background
    SegIm_array(SegIm_array(:,:,1) == 2) = 1; %Out of focus/less bright nuclei
    SegIm_array(SegIm_array(:,:,1) == 3) = 1; %Bright nuclei
    
    % Remove Noise
    noise = imtophat(SegIm_array(:,:,1), strel('disk', noise_disk));
    SegIm_array(:,:,1) = SegIm_array(:,:,1) - noise;
    
    % Fill Holes
    SegIm_array(:,:,1) = imfill(SegIm_array(:,:,1), 'holes');
    
    %Compute the distance of the binary transformed image using the bright
    %areas of the image as the basins by negating the distance measure
    D = -bwdist(~SegIm_array(:,:,1));
    D = -imhmax(-D,1);  %To prevent oversegmentation...  Make variable in image segmentation in future?
    Nuc_label = watershed(D);
    Nuc_label(SegIm_array(:,:,1) == 0) = 0; %Write all the background to zero.
    
%     h = figure()
%     imshow(label2rgb(Nuc_label),[])
%     title('Segmented Nuclei')
%     str = sprintf('Segmentation_Images/Segmented Nucleus im_%i',idx(i));
%     savefig(h,str)
%     close(h)
    
    
    %Here would be a good place to load a baysian correction model that has
    %been predefined to fix the segmentation....
        

    %Now segement all the channels and chose the one with the largest
    %amount of cell staining as defining the cytoplasmic boundary
    %And use that information for subsequent analysis
    for q = 1:numCh
        chnm = ['CH_' num2str(q)];
        
%         %Correct for the channel bleed through. Assume from nuclear channel
%         %for now...
%         if strcmp(corCH,chnm)
%             nucPix = find(Nuc_label~=0);
%             tempIm = Im_array(:,:,q+1);
%             tempIm(nucPix) = tempIm(nucPix)-corVal/100*Im_array(nucPix);
%             tempIm(tempIm<0) = 0;
%             Im_array(:,:,q+1) = tempIm;
%         end
        %Run if the image has a minimum value of 50 to avoid segmenting Null Channels 
        %Speeds up computation.  Need to make unsupervised later...
        if max(max(Im_array(:,:,q+1))) > 50; %Approximately 20% of max 
             num = multithresh(Im_array(:,:,q+1),numLevels);
              tempIm	= imquantize(Im_array(:,:,q+1), num);
              tempIm(tempIm == 1) = 0; %Background
              for j = (numLevels+1):(-1):2
                  tempIm(tempIm == j) = 1;
              end
             
            %tempIm = im2bw(Im_array(:,:,q+1), .1);  %Under estimate background due to uneven staining.
            % Remove Noise
            noise = imtophat(tempIm, strel('disk', noise_disk));
            SegIm_array(:,:,q+1) = tempIm - noise;

            % Fill Holes
            SegIm_array(:,:,q+1) = imfill(SegIm_array(:,:,q+1), 'holes');
        else
            %Make all the image black so that the summation of all the
            %labels will be zero
            SegIm_array(:,:,q+1) = 0;
        end
    end
    
    Label_array = zeros(size(tempIm,1),size(tempIm,2),1);
    %Combine all the channels for cytoplasm segmentation
    for q=1:numCh
        Label_array = Label_array + SegIm_array(:,:,q+1);
    end
    Label_array(Label_array>1) = 1;
    
    
%      h = figure()
%      imshow(SegIm_array(:,:,2),[]);
%      title('EpCAM')
%      str = sprintf('Segmentation_Images/Cytoplasm channels im_%i',idx(i));
%      savefig(h,str)
%      close(h)
    
    Label_array = bwlabel(Label_array);
    
    
    numCytowoutNuc = 0; % Number of cyptoplasms found without nuclei
    
    %Now for each channel find the properties of the cytoplasm for each
    %nuclei.  Do not use cytplasms with no nuclei
    CytoLabel = zeros(size(Nuc_label));
    nucl_ids_left = 1:max(max(Nuc_label)); %Keep track of what nuclei have been assigned
    for j = 1:max(max(Label_array))
        cur_cluster = (Label_array==j);
        %get the nuclei ids present in the cluster
        nucl_ids=Nuc_label(cur_cluster);   
        nucl_ids=unique(nucl_ids);
        %remove the background id
        nucl_ids(nucl_ids==0)=[];
        if isempty(nucl_ids)
            %don't add objects without nuclei
            numCytowoutNuc = numCytowoutNuc + 1;
            continue;
        elseif (length(nucl_ids)==1)
            %only one nucleus - assign the entire cluster to that id
            %Only add if the cytoplasm is larger than the nucleus
            if (sum(sum(cur_cluster))) > sum(sum(ismember(Nuc_label,nucl_ids)))
                CytoLabel(cur_cluster)=nucl_ids;
                %delete the nucleus that have already been processed
                nucl_ids_left(nucl_ids_left==nucl_ids)=[];
            end
        else        
            %get an index to only the nuclei
            nucl_idx=ismember(Nuc_label,nucl_ids);
            %get the x-y coordinates
            %Down sample to reduce computational time
            [nucl_x nucl_y]=find(nucl_idx); %Location of all the nuclear pixels
            [cluster_x cluster_y]=find(cur_cluster);  %Location of all cytoplasm pixels
            group_data= Nuc_label(nucl_idx); %Classification of all nuclear labels

            %classify each pixel in the cluster
            %Dont need every pixel in the nucleus to find nearest neighbor.
            %Cuts down on model building timenumCytowoutNuc = 0; % Number of cyptoplasms found without nuclei
            %Build a model based on spatial information of what each group
            %each x y coordinate is assigned to then use to predict what each
            %cytoplasmic element belongs to...
            knnModel = fitcknn([nucl_x(1:10:end) nucl_y(1:10:end)],group_data(1:10:end));
            CytoLabel(cur_cluster) = predict(knnModel,[cluster_x cluster_y]);

            %delete the nucleus that have already been processed
            for elm = nucl_ids'   % why is there an ' ?
                nucl_ids_left(nucl_ids_left==elm)=[];
            end
        end
    end

%     h = figure()
%     subplot(2,2,1)
%     imshow(Im_array(:,:,1),[])
%     str = sprintf('Hoechst Nucleus image:%i\n%s',idx(i),char(NUC.filnms(idx(i))));
%     title(str)
%     subplot(2,2,2)
%     imshow(Im_array(:,:,2),[])
%     title('EpCAM')    
%     subplot(2,2,3)
%     imshow(label2rgb(CytoLabel),[])
%     title('Segmented Cytoplasm')
%     subplot(2,2,4)
%     imshowpair(CytoLabel,Nuc_label);
%     title('Merged Cytoplasm and Nuclear Segmentation')
%     str = sprintf('Segmentation_Images/Segmentation and Original im_%i',idx(i));
%     savefig(h,str)
%     close(h)
%     
%     subplot(1,2,1)
%     imshow(Im_array(:,:,1),[])
%     str = sprintf('Hoechst Nucleus image:%i\n%s',idx(i),char(NUC.filnms(idx(i))));
%     title(str)
%     subplot(1,2,2)
%     imshow(Im_array(:,:,2),[])
%     title('EpCAM')  
%     str = sprintf('Segmentation_Images/Original_new im_%i',idx(i));
%     savefig(h,str)
%     clf(h)
%     subplot(1,2,2)
%     imshow(label2rgb(CytoLabel),[])
%     title('Segmented Cytoplasm')
%     subplot(1,2,1)
%     imshowpair(CytoLabel,Nuc_label);
%     title('Merged Cytoplasm and Nuclear Segmentation')
%     str = sprintf('Segmentation_Images/Segmentation im_%i',idx(i));
%     savefig(h,str)
%     clf(h)
    
     subplot(2,2,1)
     imshow(Im_array(:,:,1),[])
     str = sprintf('Hoechst Nucleus image:%i\n%s',idx(i),char(NUC.filnms(idx(i))));
     title(str)
     subplot(2,2,2)
     imshow(Im_array(:,:,2),[])
     title('Calcein Stain')  
     subplot(2,2,3)
     imshow(Im_array(:,:,3),[])
     title('SmartFlare')  
     str = sprintf('Segmentation_Images/Original im_%i',idx(i));
     subplot(2,2,4)
     imshowpair(CytoLabel,Nuc_label);
     title('Merged Cytoplasm and Nuclear Segmentation')
     savefig(h,str)
     clf(h)
%      subplot(1,2,2)
%      imshow(label2rgb(CytoLabel),[])
%     title('Segmented Cytoplasm')
%      subplot(1,2,1)
%      imshowpair(CytoLabel,Nuc_label);
%      title('Merged Cytoplasm and Nuclear Segmentation')
%      str = sprintf('Segmentation_Images/Segmentation im_%i',idx(i));
%      savefig(h,str)
%      clf(h)
%     
    
    
     i %to see a read out as the program runs
    t(i) = toc;
    num = i./size(idx,2); 
    %Calculate the time remaining as a rolling average
    chnm = sprintf('Time to complete: %2.2f min', ((size(NUC.filnms,2)-i)*mean(t))./60);
    %Update waitbar
    waitbar(num,wb,chnm);
    
%     %imshow(label2rgb(CytoLabel),[])
% 
%     % Segment properties
%     p	= regionprops(CytoLabel,'PixelIdxList','Perimeter');
%     %For each channel read in the image and store the cytoplasmic
%     %information
%     for q = 1:numCh
%         chnm = ['CH_' num2str(q)];                   
%         %Now for each channel find the intensity and area 
%         Int = [];
%         Area = [];
%         Perimeter = [];
%         m = 1;
%         tempIm = Im_array(:,:,q+1);
%         if size(p,1) ~= 0
%             for k = 1:size(p,1)
%                 Int(m) = sum(tempIm(p(k).PixelIdxList));
%                 Area(m) = length(p(k).PixelIdxList);
%                 Perimeter(m) = p(k).Perimeter;
%                 m= m+1;
%             end
%         end
%         %For each channel save information into the structure
%         CO.(chnm).Intensity = Int;
%         CO.(chnm).Area = Area;
%         CO.(chnm).Perimeter = Perimeter;
%     end
%     %Save the nucleus information
%     %%Count the number of cells in the image from the number of labels
%     CO.cellCount = max(max(Nuc_label));     
%     CO.Nuc_label = Nuc_label;
%     CO.label = CytoLabel;
%     CO.numCytowoutNuc = numCytowoutNuc;
%     CO.numCyto = length(unique(CytoLabel))-1;
% 
%     h = figure()
%     scatter3(CO.CH_1.Intensity,CO.CH_2.Intensity,CO.CH_3.Intensity,'b.')
%     xlabel('CD44')
%     ylabel('EpCAM')
%     zlabel('CD24')
%     title('Single Cell Intensity')
%     str = sprintf('Segmentation_Images/Single Cell Intensity im_%i',idx(i));
%     savefig(h,str)
%     close(h)
%     
%     
%     h = figure()
%     scatter3(CO.CH_1.Intensity./CO.CH_1.Area,CO.CH_2.Intensity./CO.CH_2.Area,CO.CH_3.Intensity./CO.CH_3.Area,'b.')
%     xlabel('CD44')
%     ylabel('EpCAM')
%     zlabel('CD24')
%     title('Single Cell Intensity/Area')
%     str = sprintf('Segmentation_Images/Single Cell Intensity per Area im_%i',idx(i));
%     savefig(h,str)
%     close(h)
end

mkdir('Segmentation_Images/png/')
file_specs = dir('Segmentation_Images/*.fig');
for i = 1:size(file_specs,1)
    h = openfig(['Segmentation_Images/' file_specs(i).name])
    str = file_specs(i).name;
    id = strfind(str,'.')
    str = file_specs(i).name(1:id-1)
    print(h,['Segmentation_Images/png/' str],'-dpng');
    close(h)
end

mkdir('Segmentation_Images/matlab_fig/')
for i = 1:size(file_specs,1)
    movefile(['Segmentation_Images/' file_specs(i).name],'Segmentation_Images/matlab_fig/')
end
    